import 'package:flutter_test/flutter_test.dart';
import 'package:solducci/features/csv_importer/models/merchant_rule.dart';
import 'package:solducci/features/csv_importer/models/staging_transaction.dart';
import 'package:solducci/features/csv_importer/services/csv_parser_service.dart';
import 'package:solducci/features/csv_importer/services/merchant_rule_service.dart';
import 'package:solducci/models/expense.dart';
import 'package:solducci/models/expense_form.dart';
import 'package:solducci/models/income_category.dart';
import 'package:solducci/models/split_type.dart';

void main() {
  group('CsvParserService Tests', () {
    final parser = CsvParserService();

    test('Rileva correttamente delimitatore punto e virgola', () {
      const sample = 'Data;Causale;Importo\n24/09/2026;Spesa Conad;-18,50';
      expect(parser.detectDelimiter(sample), equals(';'));
    });

    test('Rileva correttamente delimitatore virgola', () {
      const sample = 'Started Date,Description,Amount\n2026-09-24,Amazon,-15.99';
      expect(parser.detectDelimiter(sample), equals(','));
    });

    test('Converte importi italiani con virgola e separatori di migliaia', () {
      expect(parser.parseAmount('-18,50'), equals(-18.50));
      expect(parser.parseAmount('1.250,50'), equals(1250.50));
      expect(parser.parseAmount('-1.250,50 €'), equals(-1250.50));
      expect(parser.parseAmount(' -35,00 '), equals(-35.00));
    });

    test('Riconosce automaticamente il formato BNL e genera le StagingTransaction', () {
      const bnlCsv = '''
Data operazione;Data valuta;Causale / Descrizione operazione;Importo (EUR)
24/09/2026;25/09/2026;PAGAMENTO POS CARTA 24/09 14.30 ESERCENTE: CONAD VIA ROMA;-18,50
22/09/2026;22/09/2026;DISPOSIZIONE DI BONIFICO A FAVORE DI MARIO ROSSI;-250,00
20/09/2026;20/09/2026;ACCREDITO STIPENDIO AZIENDA SPA;+1800,00
''';

      final result = parser.parseCsvContent(bnlCsv);
      expect(result.matchedPreset, isNotNull);
      expect(result.matchedPreset!.id, equals('bnl_detected'));
      expect(result.transactions.length, equals(3));

      // Prima transazione (spesa conad)
      final t1 = result.transactions[0];
      expect(t1.amount, equals(18.50));
      expect(t1.isIncome, isFalse);
      expect(t1.isSelected, isTrue);
      expect(t1.date.day, equals(24));
      expect(t1.date.month, equals(9));

      // Terza transazione (accredito stipendio)
      final t3 = result.transactions[2];
      expect(t3.amount, equals(1800.00));
      expect(t3.isIncome, isTrue);
      expect(t3.isSelected, isTrue); // Entrate selezionate di default per importazione completa
      expect(t3.incomeCategory, equals(IncomeCategory.stipendio));
    });

    test('Distingue chiaramente entrate e spese e assegna IncomeCategory corretto', () {
      expect(parser.detectIncomeCategory('BONIFICO EMOLUMENTI STIPENDIO SETTEMBRE'), equals(IncomeCategory.stipendio));
      expect(parser.detectIncomeCategory('DIVIDENDO AZIONI APPLE INC'), equals(IncomeCategory.rendita));
      expect(parser.detectIncomeCategory('PAGAMENTO CEDOLA BTP ITALIA 2030'), equals(IncomeCategory.rendita));
      expect(parser.detectIncomeCategory('RIMBORSO SPESE TRASFERTA REFUND'), equals(IncomeCategory.rimborso));
      expect(parser.detectIncomeCategory('BONIFICO REGALO COMPLEANNO NONNA'), equals(IncomeCategory.regalo));
      expect(parser.detectIncomeCategory('ACCREDITO VINTED PAYMENTS SALDO'), equals(IncomeCategory.vendite));
      expect(parser.detectIncomeCategory('BONIFICO GIROCONTO PERSONALE'), equals(IncomeCategory.altro));
    });

    test('Supporta assegnazione portfolioId e assetId su StagingTransaction di rendita', () {
      final txRendita = StagingTransaction(
        id: 'tx_rendita_1',
        date: DateTime(2026, 9, 20),
        amount: 85.50,
        isIncome: true,
        rawDescription: 'DIVIDENDO VWCE ISHARES ETF',
        cleanDescription: 'Dividendo VWCE',
        category: Tipologia.altro,
        incomeCategory: IncomeCategory.rendita,
        portfolioId: 'port_degiro',
        assetId: 'asset_vwce',
      );

      expect(txRendita.isIncome, isTrue);
      expect(txRendita.incomeCategory, equals(IncomeCategory.rendita));
      expect(txRendita.portfolioId, equals('port_degiro'));
      expect(txRendita.assetId, equals('asset_vwce'));

      final modified = txRendita.copyWith(incomeCategory: IncomeCategory.stipendio, clearPortfolioId: true);
      expect(modified.incomeCategory, equals(IncomeCategory.stipendio));
      expect(modified.portfolioId, isNull);
    });
  });

  group('MerchantRuleService Tests', () {
    final ruleService = MerchantRuleService();

    test('Pulisce le causali bancarie rimuovendo timestamp e prefissi inutili', () {
      const raw = 'PAGAMENTO POS CARTA 24/09/2026 ORE 14.30 ESERCENTE: CONAD VIA ROMA 00492';
      final cleaned = ruleService.cleanRawDescription(raw);
      expect(cleaned.toLowerCase(), contains('conad'));
      expect(cleaned.contains('14.30'), isFalse);
      expect(cleaned.contains('24/09/2026'), isFalse);
      expect(cleaned.toLowerCase().contains('pagamento pos'), isFalse);
    });

    test('Applica la regola a tutte le transazioni simili nel batch', () {
      final transactions = [
        StagingTransaction(
          id: '1',
          date: DateTime(2026, 9, 24),
          amount: 15.0,
          isIncome: false,
          rawDescription: 'PAGAMENTO POS BAR PASTICCERIA DA GIGI',
          cleanDescription: 'Bar Gigi',
          category: Tipologia.altro,
        ),
        StagingTransaction(
          id: '2',
          date: DateTime(2026, 9, 20),
          amount: 8.5,
          isIncome: false,
          rawDescription: 'POS 20/09 PASTICCERIA DA GIGI MILANO',
          cleanDescription: 'Pasticceria Gigi',
          category: Tipologia.altro,
        ),
        StagingTransaction(
          id: '3',
          date: DateTime(2026, 9, 18),
          amount: 45.0,
          isIncome: false,
          rawDescription: 'PAGAMENTO CARTA ENI STATION',
          cleanDescription: 'Eni',
          category: Tipologia.altro,
        ),
      ];

      final count = ruleService.applyRuleToSimilarTransactions(
        transactions: transactions,
        pattern: 'PASTICCERIA DA GIGI',
        cleanName: 'Bar Gigi',
        category: Tipologia.ristorante,
      );

      expect(count, equals(2));
      expect(transactions[0].cleanDescription, equals('Bar Gigi'));
      expect(transactions[0].category, equals(Tipologia.ristorante));
      expect(transactions[1].cleanDescription, equals('Bar Gigi'));
      expect(transactions[1].category, equals(Tipologia.ristorante));
      expect(transactions[2].category, equals(Tipologia.altro));
    });
  });

  group('Smart Deduplication Logic Tests (+-2 giorni, +-0.09 €)', () {
    test('Distingue correttamente duplicati esatti, fuzzy e nessuna corrispondenza', () {
      final existingExpense = Expense(
        id: 100,
        description: 'Pranzo',
        amount: 15.00,
        date: DateTime(2026, 9, 20),
        type: Tipologia.ristorante,
      );

      // Caso 1: Match Esatto (stessa data, importo identico)
      final txExact = StagingTransaction(
        id: 't_exact',
        date: DateTime(2026, 9, 20),
        amount: 15.00,
        isIncome: false,
        rawDescription: 'POS BAR',
        cleanDescription: 'Bar',
        category: Tipologia.ristorante,
      );

      final isExact = txExact.date.year == existingExpense.date.year &&
          txExact.date.month == existingExpense.date.month &&
          txExact.date.day == existingExpense.date.day &&
          (txExact.amount - existingExpense.amount).abs() < 0.005;

      expect(isExact, isTrue);

      // Caso 2: Match Fuzzy (+2 giorni, differenza di 0.05 € = entro 0.09 €)
      final txFuzzy = StagingTransaction(
        id: 't_fuzzy',
        date: DateTime(2026, 9, 22),
        amount: 14.95,
        isIncome: false,
        rawDescription: 'POS BAR PASTICCERIA',
        cleanDescription: 'Bar Pasticceria',
        category: Tipologia.ristorante,
      );

      final daysDiff = (txFuzzy.date.difference(existingExpense.date).inDays).abs();
      final amountDiff = (txFuzzy.amount - existingExpense.amount).abs();
      final isFuzzy = daysDiff <= 2 && amountDiff <= 0.091;

      expect(daysDiff, equals(2));
      expect(amountDiff, closeTo(0.05, 0.001));
      expect(isFuzzy, isTrue);

      // Caso 3: Fuori tolleranza (+3 giorni o differenza di 0.20 €)
      final txFar = StagingTransaction(
        id: 't_far',
        date: DateTime(2026, 9, 25), // 5 giorni dopo
        amount: 15.00,
        isIncome: false,
        rawDescription: 'POS BAR',
        cleanDescription: 'Bar',
        category: Tipologia.ristorante,
      );

      final daysDiffFar = (txFar.date.difference(existingExpense.date).inDays).abs();
      expect(daysDiffFar <= 2, isFalse);
    });

    test('Riconoscimento broker e PAC con assegnazione automatica Tipologia.investimento e portfolioId', () {
      final rules = MerchantRule.defaultRules;
      final degiroRule = MerchantRuleService().findMatchingRule('BONIFICO A FAVORE DI DEGIRO CUSTODY', rules);
      expect(degiroRule, isNotNull);
      expect(degiroRule!.defaultCategory, equals(Tipologia.investimento));

      final scalableRule = MerchantRuleService().findMatchingRule('ADDEBITO DIRETTO SCALABLE CAPITAL BROKER', rules);
      expect(scalableRule, isNotNull);
      expect(scalableRule!.defaultCategory, equals(Tipologia.investimento));

      final tradeRepRule = MerchantRuleService().findMatchingRule('TRADE REPUBLIC BANK GMBH PAC', rules);
      expect(tradeRepRule, isNotNull);
      expect(tradeRepRule!.defaultCategory, equals(Tipologia.investimento));

      // Test assegnazione portfolioId e copyWith
      final tx = StagingTransaction(
        id: 'tx_pac_1',
        date: DateTime(2026, 9, 20),
        amount: 400.0,
        isIncome: false,
        rawDescription: 'BONIFICO DEGIRO',
        cleanDescription: 'Degiro PAC',
        category: Tipologia.investimento,
        portfolioId: 'port_degiro_pac',
      );

      expect(tx.portfolioId, equals('port_degiro_pac'));
      expect(tx.category, equals(Tipologia.investimento));

      final updated = tx.copyWith(portfolioId: 'port_trade_rep');
      expect(updated.portfolioId, equals('port_trade_rep'));

      final cleared = updated.copyWith(clearPortfolioId: true);
      expect(cleared.portfolioId, isNull);
    });
  });

  group('Staging Sessions, Persistence & Monthly Grouping Tests', () {
    test('StagingTransaction toMap and fromMap serialization preserves all fields', () {
      final tx = StagingTransaction(
        id: 'tx_persisted_1',
        date: DateTime(2026, 7, 15, 12, 30),
        amount: 85.50,
        isIncome: false,
        rawDescription: 'ESSELUNGA MILANO CORSO ITALIA',
        cleanDescription: 'Esselunga Spesa',
        category: Tipologia.cibo,
        incomeCategory: IncomeCategory.altro,
        isSelected: true,
        groupId: 'group_casa_123',
        walletId: 'wallet_intesa_99',
        splitType: SplitType.custom,
        customSplitData: {'user_1': 45.0, 'user_2': 40.50},
        portfolioId: null,
        assetId: null,
        duplicateStatus: DuplicateStatus.fuzzyMatch,
        amountDifference: 0.05,
      );

      final map = tx.toMap();
      expect(map['id'], equals('tx_persisted_1'));
      expect(map['amount'], equals(85.50));
      expect(map['category'], equals('cibo'));
      expect(map['groupId'], equals('group_casa_123'));
      expect(map['walletId'], equals('wallet_intesa_99'));
      expect(map['splitType'], equals('custom'));
      expect(map['customSplitData'], equals({'user_1': 45.0, 'user_2': 40.50}));
      expect(map['duplicateStatus'], equals('fuzzyMatch'));
      expect(map['amountDifference'], equals(0.05));

      final restored = StagingTransaction.fromMap(map);
      expect(restored.id, equals(tx.id));
      expect(restored.date.year, equals(2026));
      expect(restored.date.month, equals(7));
      expect(restored.date.day, equals(15));
      expect(restored.amount, equals(85.50));
      expect(restored.isIncome, isFalse);
      expect(restored.cleanDescription, equals('Esselunga Spesa'));
      expect(restored.category, equals(Tipologia.cibo));
      expect(restored.groupId, equals('group_casa_123'));
      expect(restored.walletId, equals('wallet_intesa_99'));
      expect(restored.splitType, equals(SplitType.custom));
      expect(restored.customSplitData, equals({'user_1': 45.0, 'user_2': 40.50}));
      expect(restored.duplicateStatus, equals(DuplicateStatus.fuzzyMatch));
      expect(restored.amountDifference, equals(0.05));
    });

    test('Raggruppa correttamente transazioni su più mesi con ordinamento decrescente', () {
      final transactions = [
        StagingTransaction(
          id: 't_luglio',
          date: DateTime(2026, 7, 20),
          amount: 50.0,
          isIncome: false,
          rawDescription: 'SPESA LUGLIO',
          cleanDescription: 'Luglio',
          category: Tipologia.cibo,
        ),
        StagingTransaction(
          id: 't_maggio_1',
          date: DateTime(2026, 5, 10),
          amount: 120.0,
          isIncome: false,
          rawDescription: 'SPESA MAGGIO',
          cleanDescription: 'Maggio 1',
          category: Tipologia.ristorante,
        ),
        StagingTransaction(
          id: 't_giugno',
          date: DateTime(2026, 6, 15),
          amount: 1500.0,
          isIncome: true,
          rawDescription: 'STIPENDIO GIUGNO',
          cleanDescription: 'Giugno Stipendio',
          category: Tipologia.altro,
          incomeCategory: IncomeCategory.stipendio,
        ),
        StagingTransaction(
          id: 't_maggio_2',
          date: DateTime(2026, 5, 25),
          amount: 30.0,
          isIncome: false,
          rawDescription: 'BAR MAGGIO',
          cleanDescription: 'Maggio 2',
          category: Tipologia.tempoLibero,
        ),
      ];

      final grouped = <DateTime, List<StagingTransaction>>{};
      for (final t in transactions) {
        final monthKey = DateTime(t.date.year, t.date.month, 1);
        grouped.putIfAbsent(monthKey, () => []).add(t);
      }

      final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

      expect(sortedKeys.length, equals(3));
      // Il mese più recente (Luglio) deve essere il primo
      expect(sortedKeys[0], equals(DateTime(2026, 7, 1)));
      expect(sortedKeys[1], equals(DateTime(2026, 6, 1)));
      expect(sortedKeys[2], equals(DateTime(2026, 5, 1)));

      // Conteggi e subtotali
      expect(grouped[DateTime(2026, 7, 1)]!.length, equals(1));
      expect(grouped[DateTime(2026, 6, 1)]!.length, equals(1));
      expect(grouped[DateTime(2026, 5, 1)]!.length, equals(2));

      // Maggio ha 2 spese per un totale di 150.0
      final maggioTotal = grouped[DateTime(2026, 5, 1)]!
          .where((t) => !t.isIncome)
          .fold(0.0, (sum, t) => sum + t.amount);
      expect(maggioTotal, equals(150.0));
    });

    test('Calcolo logica Tri-State per selezione mensile anche con duplicati a DB', () {
      final tx1 = StagingTransaction(
        id: '1',
        date: DateTime(2026, 8, 1),
        amount: 10,
        isIncome: false,
        rawDescription: 'nuova spesa 1',
        cleanDescription: 'nuova spesa 1',
        category: Tipologia.altro,
        isSelected: false,
      );
      final tx2 = StagingTransaction(
        id: '2',
        date: DateTime(2026, 8, 2),
        amount: 20,
        isIncome: false,
        rawDescription: 'duplicato gia a db',
        cleanDescription: 'duplicato gia a db',
        category: Tipologia.altro,
        duplicateStatus: DuplicateStatus.exactMatch,
        isSelected: false,
      );
      final list = [tx1, tx2];

      bool? computeTriState(List<StagingTransaction> items) {
        final totalCount = items.length;
        final selectedCount = items.where((t) => t.isSelected).length;
        final nonDuplicates = items.where((t) => t.duplicateStatus != DuplicateStatus.exactMatch).toList();
        final effectiveTarget = nonDuplicates.isNotEmpty ? nonDuplicates : items;
        final targetSelectedCount = effectiveTarget.where((t) => t.isSelected).length;

        if (totalCount == 0 || selectedCount == 0) return false;
        if (targetSelectedCount == effectiveTarget.length) return true;
        return null;
      }

      // Inizialmente nessuno è selezionato -> false
      expect(computeTriState(list), isFalse);

      // Seleziona la spesa valida (esclusa la duplicata a DB) -> true (mese pronto per l'import!)
      tx1.isSelected = true;
      expect(computeTriState(list), isTrue);

      // Deseleziona tutto -> false
      tx1.isSelected = false;
      expect(computeTriState(list), isFalse);

      // Caso: mese con soli duplicati
      final allDups = [
        tx2,
        StagingTransaction(
          id: '3',
          date: DateTime(2026, 8, 3),
          amount: 30,
          isIncome: false,
          rawDescription: 'duplicato 2',
          cleanDescription: 'duplicato 2',
          category: Tipologia.altro,
          duplicateStatus: DuplicateStatus.exactMatch,
          isSelected: false,
        ),
      ];
      expect(computeTriState(allDups), isFalse);
      allDups[0].isSelected = true;
      expect(computeTriState(allDups), isNull);
      allDups[1].isSelected = true;
      expect(computeTriState(allDups), isTrue);
    });
  });
}
