import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:solducci/models/asset_class.dart';
import 'package:solducci/models/asset_price_snapshot.dart';
import 'package:solducci/models/expense_asset_allocation.dart';
import 'package:solducci/models/investment_asset.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InvestmentAssetService extends ChangeNotifier {
  static final InvestmentAssetService _instance = InvestmentAssetService._internal();
  factory InvestmentAssetService() => _instance;
  InvestmentAssetService._internal();

  final _supabase = Supabase.instance.client;
  static const String _boxName = 'investment_assets_box';

  List<InvestmentAsset> _assets = [];
  List<InvestmentAsset> get currentAssets => List.unmodifiable(_assets);

  Box<InvestmentAsset>? _box;

  Future<Box<InvestmentAsset>> _getBox() async {
    if (_box != null && _box!.isOpen) return _box!;
    _box = await Hive.openBox<InvestmentAsset>(_boxName);
    return _box!;
  }

  /// Inizializza e carica gli asset dalla cache locale
  Future<void> init() async {
    final box = await _getBox();
    _assets = box.values.toList();
    notifyListeners();
  }

  /// Recupera tutti gli asset appartenenti ai portafogli accessibili
  Future<List<InvestmentAsset>> fetchAllAssets() async {
    try {
      final response = await _supabase
          .from('investment_assets')
          .select()
          .order('name', ascending: true);

      final list = (response as List)
          .map((m) => InvestmentAsset.fromMap(m as Map<String, dynamic>))
          .toList();

      final box = await _getBox();
      await box.clear();
      for (final a in list) {
        await box.put(a.id, a);
      }

      _assets = list;
      notifyListeners();
      return list;
    } catch (_) {
      final box = await _getBox();
      _assets = box.values.toList();
      notifyListeners();
      return _assets;
    }
  }

  /// Recupera gli asset di un singolo portafoglio
  List<InvestmentAsset> getAssetsForPortfolio(String portfolioId) {
    return _assets.where((a) => a.portfolioId == portfolioId).toList();
  }

  /// Crea un nuovo asset all'interno di un portafoglio
  Future<InvestmentAsset> createAsset({
    required String portfolioId,
    required String name,
    String? ticker,
    AssetClass assetClass = AssetClass.etf,
    double initialQuantity = 0.0,
    double initialCapital = 0.0,
    double currentPrice = 0.0,
    String? note,
  }) async {
    final newA = InvestmentAsset(
      id: '',
      portfolioId: portfolioId,
      name: name,
      ticker: ticker,
      assetClass: assetClass,
      totalQuantity: initialQuantity,
      investedCapital: initialCapital,
      currentPrice: currentPrice,
      note: note,
    );

    final map = newA.toMap();
    map.remove('id');

    final response = await _supabase.from('investment_assets').insert(map).select().single();
    final created = InvestmentAsset.fromMap(response);

    final box = await _getBox();
    await box.put(created.id, created);
    _assets.add(created);

    // Se fornito un prezzo iniziale > 0, registriamo il primo snapshot nello storico
    if (currentPrice > 0) {
      await updateAssetPrice(
        assetId: created.id,
        newPrice: currentPrice,
        source: initialQuantity > 0 ? 'purchase' : 'manual',
        note: 'Prezzo iniziale di creazione',
      );
    }

    notifyListeners();
    return created;
  }

  /// Aggiorna il prezzo corrente di un asset e registra lo snapshot storico
  Future<void> updateAssetPrice({
    required String assetId,
    required double newPrice,
    String source = 'manual',
    String? note,
  }) async {
    final now = DateTime.now();

    // 1. Registra snapshot nella tabella storico
    final snapshot = AssetPriceSnapshot(
      id: '',
      assetId: assetId,
      price: newPrice,
      timestamp: now,
      source: source,
      note: note,
    );
    final snapMap = snapshot.toMap();
    snapMap.remove('id');
    await _supabase.from('asset_price_history').insert(snapMap);

    // 2. Aggiorna prezzo e data sull'asset
    await _supabase.from('investment_assets').update({
      'current_price': newPrice,
      'last_price_update': now.toIso8601String(),
    }).eq('id', assetId);

    // 3. Aggiorna in locale
    final idx = _assets.indexWhere((a) => a.id == assetId);
    if (idx != -1) {
      final updated = _assets[idx].copyWith(
        currentPrice: newPrice,
        lastPriceUpdate: now,
      );
      _assets[idx] = updated;
      final box = await _getBox();
      await box.put(updated.id, updated);
      notifyListeners();
    }
  }

  /// Recupera la cronologia prezzi di un asset per il grafico temporale
  Future<List<AssetPriceSnapshot>> fetchPriceHistory(String assetId) async {
    try {
      final response = await _supabase
          .from('asset_price_history')
          .select()
          .eq('asset_id', assetId)
          .order('timestamp', ascending: true);

      return (response as List)
          .map((m) => AssetPriceSnapshot.fromMap(m as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Registra le allocazioni multi-asset di una spesa
  Future<void> recordExpenseAllocations({
    required int expenseId,
    required List<ExpenseAssetAllocation> allocations,
  }) async {
    if (allocations.isEmpty) return;

    final rowsToInsert = <Map<String, dynamic>>[];
    for (final alloc in allocations) {
      final map = alloc.toMap();
      map.remove('id');
      rowsToInsert.add(map);
    }

    await _supabase.from('expense_asset_allocations').insert(rowsToInsert);

    // Aggiorna le quantità e i prezzi degli asset coinvolti
    for (final alloc in allocations) {
      final idx = _assets.indexWhere((a) => a.id == alloc.assetId);
      if (idx != -1) {
        final current = _assets[idx];
        final newQuantity = current.totalQuantity + alloc.quantity;
        final newCapital = current.investedCapital + alloc.amount;

        await _supabase.from('investment_assets').update({
          'total_quantity': newQuantity,
          'invested_capital': newCapital,
          'current_price': alloc.pricePerUnit,
          'last_price_update': DateTime.now().toIso8601String(),
        }).eq('id', alloc.assetId);

        final updated = current.copyWith(
          totalQuantity: newQuantity,
          investedCapital: newCapital,
          currentPrice: alloc.pricePerUnit,
          lastPriceUpdate: DateTime.now(),
        );
        _assets[idx] = updated;

        final box = await _getBox();
        await box.put(updated.id, updated);

        // Registra snapshot di acquisto
        await updateAssetPrice(
          assetId: alloc.assetId,
          newPrice: alloc.pricePerUnit,
          source: 'purchase',
          note: 'Acquisto quota tramite spesa #$expenseId',
        );
      }
    }

    notifyListeners();
  }

  /// Elimina un asset
  Future<void> deleteAsset(String assetId) async {
    await _supabase.from('investment_assets').delete().eq('id', assetId);

    final box = await _getBox();
    await box.delete(assetId);
    _assets.removeWhere((a) => a.id == assetId);
    notifyListeners();
  }
}
