import 'package:flutter_test/flutter_test.dart';
import 'package:solducci/models/expense.dart';
import 'package:solducci/models/expense_form.dart';
import 'package:solducci/models/income.dart';
import 'package:solducci/models/income_category.dart';
import 'package:solducci/models/wallet.dart';
import 'package:solducci/models/wallet_transfer.dart';
import 'package:solducci/models/wallet_type.dart';

void main() {
  group('Wallet & Model Serialization Tests', () {
    test('Wallet serializzazione e deserializzazione corretta', () {
      final now = DateTime(2026, 9, 26);
      final wallet = Wallet(
        id: 'wallet-bnl-1',
        userId: 'user-123',
        name: 'BNL Conto Corrente',
        type: WalletType.bank,
        initialBalance: 1250.50,
        colorHex: '#10B981',
        isDefault: true,
        createdAt: now,
        updatedAt: now,
      );

      final map = wallet.toMap();
      expect(map['id'], equals('wallet-bnl-1'));
      expect(map['user_id'], equals('user-123'));
      expect(map['type'], equals('bank'));
      expect(map['initial_balance'], equals(1250.50));
      expect(map['is_default'], isTrue);

      final restored = Wallet.fromMap(map);
      expect(restored.id, equals(wallet.id));
      expect(restored.name, equals(wallet.name));
      expect(restored.type, equals(WalletType.bank));
      expect(restored.initialBalance, equals(1250.50));
      expect(restored.isDefault, isTrue);
    });

    test('Income serializzazione e categoria corretta', () {
      final now = DateTime(2026, 9, 20);
      final income = Income(
        id: 'inc-1',
        userId: 'user-123',
        walletId: 'wallet-bnl-1',
        amount: 2200.0,
        description: 'Stipendio Settembre',
        date: now,
        category: IncomeCategory.stipendio,
      );

      final map = income.toMap();
      expect(map['amount'], equals(2200.0));
      expect(map['category'], equals('stipendio'));
      expect(map['wallet_id'], equals('wallet-bnl-1'));

      final restored = Income.fromMap(map);
      expect(restored.amount, equals(2200.0));
      expect(restored.category, equals(IncomeCategory.stipendio));
      expect(restored.description, equals('Stipendio Settembre'));
    });

    test('Expense con walletId opzionale', () {
      final expenseWithWallet = Expense(
        id: 10,
        description: 'Spesa Esselunga',
        amount: 65.40,
        date: DateTime.now(),
        type: Tipologia.cibo,
        walletId: 'wallet-bnl-1',
      );

      final map = expenseWithWallet.toMap();
      expect(map['wallet_id'], equals('wallet-bnl-1'));

      final restored = Expense.fromMap(map);
      expect(restored.walletId, equals('wallet-bnl-1'));
    });

    test('WalletTransfer da un conto all\'altro', () {
      final transfer = WalletTransfer(
        id: 'tr-1',
        userId: 'user-123',
        fromWalletId: 'wallet-bnl-1',
        toWalletId: 'wallet-savings-2',
        amount: 500.0,
        date: DateTime.now(),
        notes: 'Giroconto verso risparmi',
      );

      final map = transfer.toMap();
      expect(map['from_wallet_id'], equals('wallet-bnl-1'));
      expect(map['to_wallet_id'], equals('wallet-savings-2'));
      expect(map['amount'], equals(500.0));

      final restored = WalletTransfer.fromMap(map);
      expect(restored.fromWalletId, equals('wallet-bnl-1'));
      expect(restored.toWalletId, equals('wallet-savings-2'));
    });
  });

  group('Deterministic Balance & Cashflow Calculations Tests', () {
    test('Calcolo esatto del saldo deterministico con spese, entrate e trasferimenti', () {
      // Wallet 1: BNL Conto Corrente (Iniziale: 1000)
      final wallet1 = Wallet(
        id: 'w1',
        userId: 'u1',
        name: 'BNL',
        type: WalletType.bank,
        initialBalance: 1000.0,
      );

      // Wallet 2: Risparmi (Iniziale: 500)
      final wallet2 = Wallet(
        id: 'w2',
        userId: 'u1',
        name: 'Salvadanaio',
        type: WalletType.savings,
        initialBalance: 500.0,
      );

      // Entrate: 1500 su W1
      final incomes = [
        Income(
          id: 'i1',
          userId: 'u1',
          walletId: 'w1',
          amount: 1500.0,
          description: 'Stipendio',
          date: DateTime.now(),
          category: IncomeCategory.stipendio,
        ),
      ];

      // Spese: 200 da W1
      final expenses = [
        Expense(
          id: 1,
          description: 'Spesa Conad',
          amount: 200.0,
          date: DateTime.now(),
          type: Tipologia.cibo,
          walletId: 'w1',
        ),
      ];

      // Giroconto: 300 da W1 a W2
      final transfers = [
        WalletTransfer(
          id: 't1',
          userId: 'u1',
          fromWalletId: 'w1',
          toWalletId: 'w2',
          amount: 300.0,
          date: DateTime.now(),
        ),
      ];

      // Calcolo W1: Iniziale(1000) + Incomes(1500) - Expenses(200) - TransfersOut(300) + TransfersIn(0) = 2000
      var w1Balance = wallet1.initialBalance;
      for (final inc in incomes.where((i) => i.walletId == 'w1')) {
        w1Balance += inc.amount;
      }
      for (final exp in expenses.where((e) => e.walletId == 'w1')) {
        w1Balance -= exp.amount;
      }
      for (final tr in transfers.where((t) => t.fromWalletId == 'w1')) {
        w1Balance -= tr.amount;
      }
      for (final tr in transfers.where((t) => t.toWalletId == 'w1')) {
        w1Balance += tr.amount;
      }
      expect(w1Balance, equals(2000.0));

      // Calcolo W2: Iniziale(500) + TransfersIn(300) = 800
      var w2Balance = wallet2.initialBalance;
      for (final inc in incomes.where((i) => i.walletId == 'w2')) {
        w2Balance += inc.amount;
      }
      for (final exp in expenses.where((e) => e.walletId == 'w2')) {
        w2Balance -= exp.amount;
      }
      for (final tr in transfers.where((t) => t.fromWalletId == 'w2')) {
        w2Balance -= tr.amount;
      }
      for (final tr in transfers.where((t) => t.toWalletId == 'w2')) {
        w2Balance += tr.amount;
      }
      expect(w2Balance, equals(800.0));

      // Patrimonio Netto Totale (Net Worth)
      final netWorth = w1Balance + w2Balance;
      expect(netWorth, equals(2800.0));

      // Metriche mensili
      final monthlyIncome = incomes.fold(0.0, (sum, i) => sum + i.amount);
      final monthlyExpense = expenses.fold(0.0, (sum, e) => sum + e.amount);
      final monthlyCashflow = monthlyIncome - monthlyExpense;
      final savingsRate = monthlyIncome > 0 ? (monthlyCashflow / monthlyIncome) * 100 : 0.0;

      expect(monthlyIncome, equals(1500.0));
      expect(monthlyExpense, equals(200.0));
      expect(monthlyCashflow, equals(1300.0));
      expect(savingsRate, closeTo(86.66, 0.1));
    });
  });
}
