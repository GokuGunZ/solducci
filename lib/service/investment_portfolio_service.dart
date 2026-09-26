import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:solducci/models/asset_class.dart';
import 'package:solducci/models/expense_form.dart';
import 'package:solducci/models/investment_portfolio.dart';
import 'package:solducci/service/expense_service_cached.dart';
import 'package:solducci/service/investment_asset_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InvestmentPortfolioService extends ChangeNotifier {
  static final InvestmentPortfolioService _instance = InvestmentPortfolioService._internal();
  factory InvestmentPortfolioService() => _instance;
  InvestmentPortfolioService._internal();

  final _supabase = Supabase.instance.client;
  static const String _boxName = 'investment_portfolios_box';

  List<InvestmentPortfolio> _portfolios = [];
  List<InvestmentPortfolio> get currentPortfolios => List.unmodifiable(_portfolios);

  Box<InvestmentPortfolio>? _box;

  Future<Box<InvestmentPortfolio>> _getBox() async {
    if (_box != null && _box!.isOpen) return _box!;
    _box = await Hive.openBox<InvestmentPortfolio>(_boxName);
    return _box!;
  }

  /// Inizializza e carica i portafogli dalla cache locale
  Future<void> init() async {
    final box = await _getBox();
    _portfolios = box.values.toList();
    notifyListeners();
  }

  /// Recupera tutti i portafogli dell'utente o di un gruppo specifico
  Future<List<InvestmentPortfolio>> fetchPortfolios({String? groupId}) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) {
      final box = await _getBox();
      _portfolios = box.values.toList();
      return _portfolios;
    }

    try {
      var query = _supabase.from('investment_portfolios').select();
      if (groupId != null) {
        query = query.eq('group_id', groupId);
      } else {
        query = query.or('user_id.eq.$currentUserId,group_id.is.null');
      }

      final response = await query.order('created_at', ascending: true);
      final list = (response as List)
          .map((m) => InvestmentPortfolio.fromMap(m as Map<String, dynamic>))
          .toList();

      final box = await _getBox();
      await box.clear();
      for (final p in list) {
        await box.put(p.id, p);
      }

      _portfolios = list;
      notifyListeners();
      return list;
    } catch (e) {
      final box = await _getBox();
      _portfolios = box.values.toList();
      notifyListeners();
      return _portfolios;
    }
  }

  /// Crea un nuovo portafoglio investimenti
  Future<InvestmentPortfolio> createPortfolio({
    required String name,
    String? brokerName,
    String colorHex = '#6366F1',
    String icon = 'trending_up',
    String? description,
    String? groupId,
  }) async {
    final currentUserId = _supabase.auth.currentUser?.id ?? '';
    final newP = InvestmentPortfolio(
      id: '',
      userId: currentUserId,
      groupId: groupId,
      name: name,
      brokerName: brokerName,
      colorHex: colorHex,
      icon: icon,
      description: description,
    );

    final map = newP.toMap();
    map.remove('id'); // Generato da Supabase

    final response = await _supabase.from('investment_portfolios').insert(map).select().single();
    final created = InvestmentPortfolio.fromMap(response);

    final box = await _getBox();
    await box.put(created.id, created);
    _portfolios.add(created);
    notifyListeners();
    return created;
  }

  /// Modifica un portafoglio esistente
  Future<void> updatePortfolio(InvestmentPortfolio portfolio) async {
    await _supabase
        .from('investment_portfolios')
        .update(portfolio.toMap())
        .eq('id', portfolio.id);

    final box = await _getBox();
    await box.put(portfolio.id, portfolio);
    final idx = _portfolios.indexWhere((p) => p.id == portfolio.id);
    if (idx != -1) {
      _portfolios[idx] = portfolio;
    }
    notifyListeners();
  }

  /// Elimina un portafoglio
  Future<void> deletePortfolio(String portfolioId) async {
    await _supabase.from('investment_portfolios').delete().eq('id', portfolioId);

    final box = await _getBox();
    await box.delete(portfolioId);
    _portfolios.removeWhere((p) => p.id == portfolioId);
    notifyListeners();
  }

  /// Calcola il controvalore totale di tutti i portafogli attuali
  double getTotalCurrentValue() {
    final assetService = InvestmentAssetService();
    return assetService.currentAssets.fold(0.0, (sum, a) => sum + a.currentValue);
  }

  /// Calcola il capitale totale investito
  double getTotalInvestedCapital() {
    final assetService = InvestmentAssetService();
    return assetService.currentAssets.fold(0.0, (sum, a) => sum + a.investedCapital);
  }

  /// Plusvalenza totale non realizzata (€)
  double getTotalUnrealizedPnl() {
    return getTotalCurrentValue() - getTotalInvestedCapital();
  }

  /// Rendimento percentuale complessivo (ROI %)
  double getTotalRoiPercent() {
    final invested = getTotalInvestedCapital();
    if (invested <= 0) return 0.0;
    return (getTotalUnrealizedPnl() / invested) * 100;
  }

  /// Genera la serie storica dei controvalori patrimoniali per il grafico di performance
  List<double> getHistoricalPerformancePoints() {
    final expenses = ExpenseServiceCached()
        .getAllCachedExpenses()
        .where((e) => e.type == Tipologia.investimento)
        .toList();

    final totalCurrentVal = getTotalCurrentValue();
    final totalInvested = getTotalInvestedCapital();

    if (expenses.isEmpty && totalCurrentVal <= 0) {
      return [0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
    }

    expenses.sort((a, b) => a.date.compareTo(b.date));

    // Genera 6 punti temporali (ultimi 6 mesi o progressione dei versamenti)
    final now = DateTime.now();
    final List<double> points = [];

    for (int i = 5; i >= 0; i--) {
      final monthTarget = DateTime(now.year, now.month - i + 1, 0, 23, 59, 59);
      final cumulativeInvestedAtMonth = expenses
          .where((e) => e.date.isBefore(monthTarget) || e.date.isAtSameMomentAs(monthTarget))
          .fold<double>(0.0, (sum, e) => sum + e.amount);

      if (i == 0) {
        // Mese corrente: usa il valore attuale reale del patrimonio
        points.add(totalCurrentVal > 0 ? totalCurrentVal : cumulativeInvestedAtMonth);
      } else {
        // Mesi passati: stima proporzionale o cumulativo versato
        if (totalInvested > 0 && totalCurrentVal > 0) {
          final growthRatio = totalCurrentVal / totalInvested;
          points.add(cumulativeInvestedAtMonth * growthRatio);
        } else {
          points.add(cumulativeInvestedAtMonth);
        }
      }
    }

    // Se tutti i punti sono 0 tranne l'ultimo, crea una rampa fluida
    if (points.take(5).every((p) => p == 0.0) && totalCurrentVal > 0) {
      return [
        totalCurrentVal * 0.70,
        totalCurrentVal * 0.78,
        totalCurrentVal * 0.85,
        totalCurrentVal * 0.90,
        totalCurrentVal * 0.95,
        totalCurrentVal,
      ];
    }

    return points;
  }

  static const String _targetBoxName = 'investment_target_allocation_box';
  Map<AssetClass, double>? _cachedTargetAllocation;

  /// Restituisce la target asset allocation (es. ETF: 60%, Bond: 20%, Stock: 10%, Crypto: 10%)
  Future<Map<AssetClass, double>> getTargetAllocation() async {
    if (_cachedTargetAllocation != null) return _cachedTargetAllocation!;
    try {
      final box = await Hive.openBox(_targetBoxName);
      final rawMap = box.get('targets');
      if (rawMap != null && rawMap is Map) {
        final result = <AssetClass, double>{};
        for (final entry in rawMap.entries) {
          final ac = AssetClass.fromDb(entry.key.toString());
          result[ac] = (entry.value as num).toDouble();
        }
        _cachedTargetAllocation = result;
        return result;
      }
    } catch (_) {}

    // Default bilanciato
    return {
      AssetClass.etf: 60.0,
      AssetClass.bond: 20.0,
      AssetClass.stock: 10.0,
      AssetClass.crypto: 10.0,
    };
  }

  /// Salva la target asset allocation
  Future<void> saveTargetAllocation(Map<AssetClass, double> targets) async {
    try {
      final box = await Hive.openBox(_targetBoxName);
      final rawMap = targets.map((k, v) => MapEntry(k.dbValue, v));
      await box.put('targets', rawMap);
      _cachedTargetAllocation = targets;
      notifyListeners();
    } catch (_) {}
  }

  /// Calcola la deviazione attuale rispetto ai target
  /// Ritorna una mappa: AssetClass -> (Percentuale Attuale - Percentuale Target)
  Map<AssetClass, double> calculateRebalancingDeviations(Map<AssetClass, double> targets) {
    final totalVal = getTotalCurrentValue();
    if (totalVal <= 0) return {};

    final currentAssets = InvestmentAssetService().currentAssets;
    final currentValues = <AssetClass, double>{};
    for (final a in currentAssets) {
      currentValues[a.assetClass] = (currentValues[a.assetClass] ?? 0.0) + a.currentValue;
    }

    final deviations = <AssetClass, double>{};
    for (final ac in AssetClass.values) {
      final actualPct = ((currentValues[ac] ?? 0.0) / totalVal) * 100;
      final targetPct = targets[ac] ?? 0.0;
      if (targetPct > 0 || actualPct > 0) {
        deviations[ac] = actualPct - targetPct;
      }
    }
    return deviations;
  }

  /// Restituisce un suggerimento di rebalancing prioritario (la classe più sottopesata)
  String? getRebalancingSuggestion(Map<AssetClass, double> targets) {
    final deviations = calculateRebalancingDeviations(targets);
    if (deviations.isEmpty) return null;

    AssetClass? mostUnderweighted;
    double minDeviation = 0.0;

    for (final entry in deviations.entries) {
      if (entry.value < minDeviation) {
        minDeviation = entry.value;
        mostUnderweighted = entry.key;
      }
    }

    if (mostUnderweighted != null && minDeviation.abs() >= 2.0) {
      final underPct = minDeviation.abs().toStringAsFixed(0);
      return '${mostUnderweighted.label} è sotto target del $underPct%. Valuta di indirizzare i prossimi acquisti qui.';
    }
    return null;
  }
}
