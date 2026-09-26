import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:solducci/models/investment_portfolio.dart';
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
}
