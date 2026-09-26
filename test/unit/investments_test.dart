import 'package:flutter_test/flutter_test.dart';
import 'package:solducci/models/asset_class.dart';
import 'package:solducci/models/asset_price_snapshot.dart';
import 'package:solducci/models/expense.dart';
import 'package:solducci/models/expense_asset_allocation.dart';
import 'package:solducci/models/expense_form.dart';
import 'package:solducci/models/investment_asset.dart';
import 'package:solducci/models/investment_portfolio.dart';

void main() {
  group('Investments Models & Calculations Tests', () {
    test('Tipologia.investimento serialization and values', () {
      expect(Tipologia.investimento.name, equals('investimento'));
      expect(Tipologia.values.contains(Tipologia.investimento), isTrue);
    });

    test('AssetClass label, dbValue and fromDb mapping', () {
      expect(AssetClass.etf.label, equals('ETF'));
      expect(AssetClass.stock.label, equals('Azioni'));
      expect(AssetClass.crypto.label, equals('Criptovalute'));
      expect(AssetClass.bond.label, equals('Obbligazioni / BTP'));
      expect(AssetClass.commodity.label, equals('Materie Prime / Oro'));
      expect(AssetClass.realEstate.label, equals('Immobili'));
      expect(AssetClass.other.label, equals('Altro'));

      expect(AssetClass.fromDb('etf'), equals(AssetClass.etf));
      expect(AssetClass.fromDb('stock'), equals(AssetClass.stock));
      expect(AssetClass.fromDb('unknown_thing'), equals(AssetClass.other));
    });

    test('InvestmentPortfolio toMap and fromMap serialization', () {
      final now = DateTime(2026, 9, 27, 10, 0);
      final portfolio = InvestmentPortfolio(
        id: 'port-123',
        userId: 'user-abc',
        name: 'PAC Degiro ETF World',
        description: 'Piano di accumulo a lungo termine',
        brokerName: 'DEGIRO',
        colorHex: '#10B981',
        icon: 'trending_up',
        createdAt: now,
        updatedAt: now,
      );

      final map = portfolio.toMap();
      expect(map['id'], equals('port-123'));
      expect(map['user_id'], equals('user-abc'));
      expect(map['name'], equals('PAC Degiro ETF World'));
      expect(map['broker_name'], equals('DEGIRO'));
      expect(map['color_hex'], equals('#10B981'));

      final restored = InvestmentPortfolio.fromMap(map);
      expect(restored.id, equals(portfolio.id));
      expect(restored.name, equals(portfolio.name));
      expect(restored.brokerName, equals('DEGIRO'));
      expect(restored.colorHex, equals('#10B981'));
      expect(restored.groupId, isNull);
    });

    test('InvestmentAsset financial math (P&L, ROI, Current Value)', () {
      final now = DateTime(2026, 9, 27, 10, 0);
      // Esempio: VWCE ETF
      // 10 quote acquistate per un totale di 1000€ (investedCapital = 1000, PMC = 100€)
      // Prezzo attuale: 125€ -> Valore attuale: 1250€ (+250€, +25%)
      final asset = InvestmentAsset(
        id: 'asset-vwce',
        portfolioId: 'port-123',
        ticker: 'VWCE',
        name: 'Vanguard FTSE All-World UCITS ETF',
        assetClass: AssetClass.etf,
        totalQuantity: 10.0,
        investedCapital: 1000.0,
        currentPrice: 125.0,
        note: 'Accumulo trimestrale',
        lastPriceUpdate: now,
        createdAt: now,
        updatedAt: now,
      );

      expect(asset.investedCapital, equals(1000.0));
      expect(asset.averageBuyPrice, equals(100.0));
      expect(asset.currentValue, equals(1250.0));
      expect(asset.unrealizedPnl, equals(250.0));
      expect(asset.roiPercent, closeTo(25.0, 0.001));

      // Test toMap / fromMap
      final map = asset.toMap();
      expect(map['ticker'], equals('VWCE'));
      expect(map['asset_class'], equals('etf'));
      expect(map['total_quantity'], equals(10.0));
      expect(map['invested_capital'], equals(1000.0));
      expect(map['current_price'], equals(125.0));

      final restored = InvestmentAsset.fromMap(map);
      expect(restored.id, equals(asset.id));
      expect(restored.ticker, equals('VWCE'));
      expect(restored.assetClass, equals(AssetClass.etf));
      expect(restored.totalQuantity, equals(10.0));
      expect(restored.unrealizedPnl, equals(250.0));
      expect(restored.roiPercent, closeTo(25.0, 0.001));
    });

    test('InvestmentAsset negative ROI handling', () {
      final now = DateTime(2026, 9, 27);
      // Esempio in perdita: 5 quote comprate con 1000€ investiti (PMC 200€), ora quotate a 160€ (valore 800€)
      final asset = InvestmentAsset(
        id: 'asset-loss',
        portfolioId: 'port-123',
        ticker: 'TECH',
        name: 'Tech Stock',
        assetClass: AssetClass.stock,
        totalQuantity: 5.0,
        investedCapital: 1000.0,
        currentPrice: 160.0,
        createdAt: now,
        updatedAt: now,
      );

      expect(asset.investedCapital, equals(1000.0));
      expect(asset.averageBuyPrice, equals(200.0));
      expect(asset.currentValue, equals(800.0));
      expect(asset.unrealizedPnl, equals(-200.0));
      expect(asset.roiPercent, closeTo(-20.0, 0.001));
    });

    test('AssetPriceSnapshot serialization', () {
      final now = DateTime(2026, 9, 27, 12, 0);
      final snapshot = AssetPriceSnapshot(
        id: 'snap-1',
        assetId: 'asset-vwce',
        price: 128.50,
        source: 'manual',
        note: 'Aggiornamento trimestrale',
        timestamp: now,
      );

      final map = snapshot.toMap();
      expect(map['asset_id'], equals('asset-vwce'));
      expect(map['price'], equals(128.50));
      expect(map['note'], equals('Aggiornamento trimestrale'));
      expect(map['source'], equals('manual'));

      final restored = AssetPriceSnapshot.fromMap(map);
      expect(restored.id, equals('snap-1'));
      expect(restored.price, equals(128.50));
      expect(restored.source, equals('manual'));
      expect(restored.note, equals('Aggiornamento trimestrale'));
    });

    test('ExpenseAssetAllocation multi-asset split serialization', () {
      final now = DateTime(2026, 9, 27, 14, 0);
      // Esempio spesa PAC da 500€: 300€ su VWCE e 200€ su S&P500
      final alloc1 = ExpenseAssetAllocation(
        id: 'alloc-1',
        expenseId: 101,
        assetId: 'asset-vwce',
        quantity: 2.5,
        pricePerUnit: 120.0,
        amount: 300.0,
        createdAt: now,
      );

      final alloc2 = ExpenseAssetAllocation(
        id: 'alloc-2',
        expenseId: 101,
        assetId: 'asset-sp500',
        quantity: 0.4,
        pricePerUnit: 500.0,
        amount: 200.0,
        createdAt: now,
      );

      expect(alloc1.amount + alloc2.amount, equals(500.0));

      final map = alloc1.toMap();
      expect(map['expense_id'], equals(101));
      expect(map['asset_id'], equals('asset-vwce'));
      expect(map['quantity'], equals(2.5));
      expect(map['price_per_unit'], equals(120.0));
      expect(map['amount'], equals(300.0));

      final restored = ExpenseAssetAllocation.fromMap(map);
      expect(restored.id, equals('alloc-1'));
      expect(restored.quantity, equals(2.5));
      expect(restored.amount, equals(300.0));
    });

    test('Expense with Tipologia.investimento and portfolioId association', () {
      final now = DateTime(2026, 9, 27);
      final expense = Expense(
        id: 1,
        userId: 'user-1',
        walletId: 'wallet-conto-1',
        portfolioId: 'port-123',
        amount: 500.0,
        description: 'PAC Mensile Settembre',
        date: now,
        type: Tipologia.investimento,
      );

      expect(expense.type, equals(Tipologia.investimento));
      expect(expense.portfolioId, equals('port-123'));

      final map = expense.toMap();
      expect(map['type'], equals('investimento'));
      expect(map['portfolio_id'], equals('port-123'));

      final restored = Expense.fromMap(map);
      expect(restored.type, equals(Tipologia.investimento));
      expect(restored.portfolioId, equals('port-123'));
    });

    test('Separation of Investment vs Consumption expenses in Cashflow', () {
      final now = DateTime(2026, 9, 27);
      final expenses = [
        Expense(
          id: 1,
          userId: 'u1',
          amount: 50.0,
          description: 'Spesa Esselunga',
          date: now,
          type: Tipologia.cibo,
        ),
        Expense(
          id: 2,
          userId: 'u1',
          amount: 30.0,
          description: 'Cena fuori',
          date: now,
          type: Tipologia.ristorante,
        ),
        Expense(
          id: 3,
          userId: 'u1',
          amount: 500.0,
          description: 'Acquisto ETF',
          date: now,
          type: Tipologia.investimento,
          portfolioId: 'port-123',
        ),
      ];

      // Calcolo spese di consumo (escludendo investimenti)
      final consumptionExpenses = expenses
          .where((e) => e.type != Tipologia.investimento)
          .fold<double>(0.0, (sum, e) => sum + e.amount);

      // Calcolo capitale investito
      final investedCapital = expenses
          .where((e) => e.type == Tipologia.investimento)
          .fold<double>(0.0, (sum, e) => sum + e.amount);

      expect(consumptionExpenses, equals(80.0));
      expect(investedCapital, equals(500.0));

      // Entrate mensili ipotetiche: 2000€
      const monthlyIncome = 2000.0;
      // Tasso di risparmio considerando investimenti come patrimonio accresciuto:
      // Risparmio = Entrate - Spese di consumo = 2000 - 80 = 1920€
      final savings = monthlyIncome - consumptionExpenses;
      final savingsRate = (savings / monthlyIncome) * 100;
      expect(savingsRate, equals(96.0));
    });

    test('Multi-asset allocation math and residual balance invariant', () {
      const totalExpenseAmount = 600.0;
      final allocations = [
        {'asset': 'VWCE', 'amount': 350.0, 'qty': 2.8},
        {'asset': 'BTC', 'amount': 150.0, 'qty': 0.0025},
        {'asset': 'BTP', 'amount': 100.0, 'qty': 1.0},
      ];

      final totalAllocated = allocations.fold<double>(
        0.0,
        (sum, a) => sum + (a['amount'] as double),
      );
      final residual = totalExpenseAmount - totalAllocated;

      expect(totalAllocated, equals(600.0));
      expect(residual, equals(0.0));

      // Verifica prezzo unitario calcolato per ciascun asset
      final vwceUnitPrice = (allocations[0]['amount'] as double) / (allocations[0]['qty'] as double);
      expect(vwceUnitPrice, closeTo(125.0, 0.0001));

      final btcUnitPrice = (allocations[1]['amount'] as double) / (allocations[1]['qty'] as double);
      expect(btcUnitPrice, equals(60000.0));
    });
  });
}
