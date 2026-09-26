import 'package:flutter_test/flutter_test.dart';
import 'package:solducci/features/csv_importer/models/merchant_rule.dart';
import 'package:solducci/features/csv_importer/models/staging_transaction.dart';
import 'package:solducci/features/csv_importer/services/csv_parser_service.dart';
import 'package:solducci/features/csv_importer/services/merchant_rule_service.dart';
import 'package:solducci/models/expense.dart';
import 'package:solducci/models/expense_form.dart';
import 'package:solducci/models/income_category.dart';

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
}
