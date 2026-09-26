import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:solducci/features/csv_importer/models/csv_column_preset.dart';
import 'package:solducci/features/csv_importer/models/staging_transaction.dart';
import 'package:solducci/models/expense_form.dart';
import 'package:solducci/models/income_category.dart';

class CsvParseResult {
  final List<String> headers;
  final List<List<dynamic>> rawRows;
  final CsvColumnPreset? matchedPreset;
  final List<StagingTransaction> transactions;
  final String delimiter;

  CsvParseResult({
    required this.headers,
    required this.rawRows,
    this.matchedPreset,
    required this.transactions,
    required this.delimiter,
  });
}

class CsvParserService {
  static final CsvParserService _instance = CsvParserService._internal();
  factory CsvParserService() => _instance;
  CsvParserService._internal();

  final _uuid = const Uuid();

  /// Decodifica il contenuto binario gestendo UTF-8 con fallback a Latin1 / Windows-1252
  String decodeCsvBytes(List<int> bytes) {
    try {
      return utf8.decode(bytes);
    } catch (_) {
      try {
        return latin1.decode(bytes);
      } catch (_) {
        return String.fromCharCodes(bytes);
      }
    }
  }

  /// Rileva automaticamente il delimitatore (';', ',', '\t') analizzando le prime righe
  String detectDelimiter(String content) {
    final lines = content.split(RegExp(r'\r?\n')).take(5).toList();
    var semicolonCount = 0;
    var commaCount = 0;
    var tabCount = 0;

    for (final line in lines) {
      semicolonCount += ';'.allMatches(line).length;
      commaCount += ','.allMatches(line).length;
      tabCount += '\t'.allMatches(line).length;
    }

    if (semicolonCount >= commaCount && semicolonCount >= tabCount && semicolonCount > 0) {
      return ';';
    }
    if (tabCount > commaCount && tabCount > semicolonCount) {
      return '\t';
    }
    return ',';
  }

  /// Tenta di abbinare gli header letti con un preset noto (BNL, Revolut, ecc.)
  CsvColumnPreset? detectPreset(List<String> headers) {
    final normalizedHeaders = headers.map((h) => h.toLowerCase().trim()).toList();

    // 1. Controllo BNL (Data operazione, Causale, Importo)
    final hasBnlDate = normalizedHeaders.any((h) => h.contains('data operazione') || h == 'data op.');
    final hasBnlDesc = normalizedHeaders.any((h) => h.contains('causale') || h.contains('descrizione operazione'));
    final hasBnlAmount = normalizedHeaders.any((h) => h.contains('importo'));

    if (hasBnlDate && hasBnlDesc && hasBnlAmount) {
      final actualDateHeader = headers[normalizedHeaders.indexWhere((h) => h.contains('data operazione') || h == 'data op.')];
      final actualDescHeader = headers[normalizedHeaders.indexWhere((h) => h.contains('causale') || h.contains('descrizione operazione'))];
      final actualAmountHeader = headers[normalizedHeaders.indexWhere((h) => h.contains('importo'))];

      return CsvColumnPreset(
        id: 'bnl_detected',
        name: 'BNL (Rilevato)',
        dateColumnName: actualDateHeader,
        descriptionColumnName: actualDescHeader,
        amountColumnName: actualAmountHeader,
        dateFormat: 'dd/MM/yyyy',
        decimalSeparator: ',',
        delimiter: ';',
      );
    }

    // 2. Controllo Revolut
    final hasRevDate = normalizedHeaders.any((h) => h.contains('started date') || h.contains('completed date'));
    final hasRevDesc = normalizedHeaders.any((h) => h == 'description');
    final hasRevAmount = normalizedHeaders.any((h) => h == 'amount');

    if (hasRevDate && hasRevDesc && hasRevAmount) {
      final actualDateHeader = headers[normalizedHeaders.indexWhere((h) => h.contains('started date') || h.contains('completed date'))];
      final actualDescHeader = headers[normalizedHeaders.indexWhere((h) => h == 'description')];
      final actualAmountHeader = headers[normalizedHeaders.indexWhere((h) => h == 'amount')];

      return CsvColumnPreset(
        id: 'revolut_detected',
        name: 'Revolut (Rilevato)',
        dateColumnName: actualDateHeader,
        descriptionColumnName: actualDescHeader,
        amountColumnName: actualAmountHeader,
        dateFormat: 'yyyy-MM-dd',
        decimalSeparator: '.',
        delimiter: ',',
      );
    }

    // 3. Controllo Generico Italiano (Data, Descrizione/Causale, Importo)
    final hasGenDate = normalizedHeaders.any((h) => h.contains('data') || h.contains('date'));
    final hasGenDesc = normalizedHeaders.any((h) => h.contains('descriz') || h.contains('causale') || h.contains('movimento'));
    final hasGenAmount = normalizedHeaders.any((h) => h.contains('importo') || h.contains('amount') || h.contains('totale'));

    if (hasGenDate && hasGenDesc && hasGenAmount) {
      final actualDateHeader = headers[normalizedHeaders.indexWhere((h) => h.contains('data') || h.contains('date'))];
      final actualDescHeader = headers[normalizedHeaders.indexWhere((h) => h.contains('descriz') || h.contains('causale') || h.contains('movimento'))];
      final actualAmountHeader = headers[normalizedHeaders.indexWhere((h) => h.contains('importo') || h.contains('amount') || h.contains('totale'))];

      return CsvColumnPreset(
        id: 'generic_detected',
        name: 'Formato Riconosciuto',
        dateColumnName: actualDateHeader,
        descriptionColumnName: actualDescHeader,
        amountColumnName: actualAmountHeader,
        dateFormat: 'dd/MM/yyyy',
        decimalSeparator: ',',
        delimiter: ';',
      );
    }

    return null;
  }

  /// Converte un numero bancario (es. "-1.250,50 €", "-18,50", "12.30") in double
  double? parseAmount(dynamic rawValue, {String decimalSeparator = ','}) {
    if (rawValue == null) return null;
    var str = rawValue.toString().trim();
    if (str.isEmpty) return null;

    // Rimuovi simboli valuta e spazi
    str = str.replaceAll(RegExp(r'[€$£\s]'), '');

    if (decimalSeparator == ',') {
      // Formato italiano: punto migliaia, virgola decimali (es. -1.250,50)
      str = str.replaceAll('.', '');
      str = str.replaceAll(',', '.');
    } else {
      // Formato inglese: virgola migliaia, punto decimali (es. -1,250.50)
      str = str.replaceAll(',', '');
    }

    return double.tryParse(str);
  }

  /// Converte una data stringa in DateTime supportando diversi formati
  DateTime? parseDate(String rawDate, String format) {
    final clean = rawDate.trim();
    if (clean.isEmpty) return null;

    // 1. Prova con il formato indicato dal preset
    try {
      return DateFormat(format).parse(clean);
    } catch (_) {}

    // 2. Fallback su formati frequenti
    final fallbackFormats = [
      'dd/MM/yyyy',
      'dd/MM/yy',
      'yyyy-MM-dd',
      'dd-MM-yyyy',
      'yyyy-MM-dd HH:mm:ss',
      'dd/MM/yyyy HH:mm:ss',
    ];

    for (final f in fallbackFormats) {
      try {
        return DateFormat(f).parse(clean);
      } catch (_) {}
    }

    return DateTime.tryParse(clean);
  }

  /// Esegue il parsing completo del testo CSV
  CsvParseResult parseCsvContent(String content, {CsvColumnPreset? preset}) {
    final delimiter = preset?.delimiter ?? detectDelimiter(content);

    final converter = CsvToListConverter(
      fieldDelimiter: delimiter,
      eol: '\n',
      shouldParseNumbers: false,
    );

    // Normalizza i ritorni a capo per evitare bug con \r\n
    final normalizedContent = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final rows = converter.convert(normalizedContent);

    if (rows.isEmpty) {
      return CsvParseResult(
        headers: [],
        rawRows: [],
        matchedPreset: null,
        transactions: [],
        delimiter: delimiter,
      );
    }

    // Trova la riga di header (spesso la riga 0, ma alcune banche mettono 1-2 righe di intestazione prima)
    var headerRowIndex = 0;
    for (var i = 0; i < rows.length && i < 5; i++) {
      final rowStr = rows[i].map((e) => e.toString().toLowerCase()).join(' ');
      if (rowStr.contains('data') || rowStr.contains('date') || rowStr.contains('importo') || rowStr.contains('amount')) {
        headerRowIndex = i;
        break;
      }
    }

    final headers = rows[headerRowIndex].map((e) => e.toString().trim()).toList();
    final dataRows = rows.sublist(headerRowIndex + 1);

    // Determina il preset
    final activePreset = preset ?? detectPreset(headers);

    final transactions = <StagingTransaction>[];

    if (activePreset != null) {
      final dateColIdx = headers.indexOf(activePreset.dateColumnName);
      final descColIdx = headers.indexOf(activePreset.descriptionColumnName);
      final amountColIdx = activePreset.amountColumnName != null
          ? headers.indexOf(activePreset.amountColumnName!)
          : -1;
      final expenseColIdx = activePreset.expenseColumnName != null
          ? headers.indexOf(activePreset.expenseColumnName!)
          : -1;
      final incomeColIdx = activePreset.incomeColumnName != null
          ? headers.indexOf(activePreset.incomeColumnName!)
          : -1;

      for (final row in dataRows) {
        if (row.length <= dateColIdx || row.length <= descColIdx) continue;

        final rawDate = row[dateColIdx].toString();
        final rawDesc = row[descColIdx].toString().trim();

        if (rawDate.isEmpty && rawDesc.isEmpty) continue;

        final date = parseDate(rawDate, activePreset.dateFormat) ?? DateTime.now();

        double? parsedAmount;
        var isIncome = false;

        if (amountColIdx >= 0 && row.length > amountColIdx) {
          final amt = parseAmount(row[amountColIdx], decimalSeparator: activePreset.decimalSeparator);
          if (amt != null) {
            isIncome = amt > 0;
            parsedAmount = amt.abs();
          }
        } else {
          // Colonne separate Entrate/Uscite
          if (expenseColIdx >= 0 && row.length > expenseColIdx) {
            final exp = parseAmount(row[expenseColIdx], decimalSeparator: activePreset.decimalSeparator);
            if (exp != null && exp > 0) {
              parsedAmount = exp;
              isIncome = false;
            }
          }
          if (parsedAmount == null && incomeColIdx >= 0 && row.length > incomeColIdx) {
            final inc = parseAmount(row[incomeColIdx], decimalSeparator: activePreset.decimalSeparator);
            if (inc != null && inc > 0) {
              parsedAmount = inc;
              isIncome = true;
            }
          }
        }

        if (parsedAmount == null || parsedAmount == 0.0) continue;

        final incomeCat = isIncome ? detectIncomeCategory(rawDesc) : IncomeCategory.altro;

        transactions.add(
          StagingTransaction(
            id: _uuid.v4(),
            date: date,
            amount: parsedAmount,
            isIncome: isIncome,
            rawDescription: rawDesc,
            cleanDescription: rawDesc,
            category: Tipologia.altro,
            incomeCategory: incomeCat,
            isSelected: true, // Selezionate di default per un'importazione completa
          ),
        );
      }
    }

    return CsvParseResult(
      headers: headers,
      rawRows: dataRows,
      matchedPreset: activePreset,
      transactions: transactions,
      delimiter: delimiter,
    );
  }

  /// Categorizza automaticamente le entrate in base alle parole chiave bancarie frequenti
  IncomeCategory detectIncomeCategory(String rawDescription) {
    final lower = rawDescription.toLowerCase();
    if (lower.contains('stipendio') ||
        lower.contains('emolumenti') ||
        lower.contains('retribuz') ||
        lower.contains('salary') ||
        lower.contains('busta paga') ||
        lower.contains('pensione')) {
      return IncomeCategory.stipendio;
    }
    if (lower.contains('dividendo') ||
        lower.contains('cedola') ||
        lower.contains('interessi') ||
        lower.contains('rendita') ||
        lower.contains('coupon') ||
        lower.contains('yield')) {
      return IncomeCategory.rendita;
    }
    if (lower.contains('rimborso') ||
        lower.contains('refund') ||
        lower.contains('cashback') ||
        lower.contains('storno') ||
        lower.contains('chargeback')) {
      return IncomeCategory.rimborso;
    }
    if (lower.contains('regalo') ||
        lower.contains('gift') ||
        lower.contains('compleanno') ||
        lower.contains('mancia')) {
      return IncomeCategory.regalo;
    }
    if (lower.contains('vinted') ||
        lower.contains('wallapop') ||
        lower.contains('ebay') ||
        lower.contains('subito') ||
        lower.contains('vendit')) {
      return IncomeCategory.vendite;
    }
    return IncomeCategory.altro;
  }
}
