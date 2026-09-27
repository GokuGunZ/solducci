import 'dart:math' as math;
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

  /// Recupera un asset per ID
  InvestmentAsset? getAssetById(String id) {
    return _assets.where((a) => a.id == id).firstOrNull;
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
    String? editionOrSet,
    String? conditionOrGrading,
    String? serialOrCertNumber,
    String? storageLocation,
    bool? isPhysical,
    String? note,
  }) async {
    final effectivePrice = currentPrice > 0
        ? currentPrice
        : (initialQuantity > 0 && initialCapital > 0 ? (initialCapital / initialQuantity) : 0.0);

    final effectiveCapital = initialCapital > 0
        ? initialCapital
        : (initialQuantity > 0 && currentPrice > 0 ? (initialQuantity * currentPrice) : 0.0);

    final newA = InvestmentAsset(
      id: '',
      portfolioId: portfolioId,
      name: name,
      ticker: ticker,
      assetClass: assetClass,
      totalQuantity: initialQuantity,
      investedCapital: effectiveCapital,
      currentPrice: effectivePrice,
      editionOrSet: editionOrSet,
      conditionOrGrading: conditionOrGrading,
      serialOrCertNumber: serialOrCertNumber,
      storageLocation: storageLocation,
      isPhysical: isPhysical,
      note: note,
    );

    final map = newA.toMap();
    map.remove('id');

    final response = await _supabase.from('investment_assets').insert(map).select().single();
    final created = InvestmentAsset.fromMap(response);

    final box = await _getBox();
    await box.put(created.id, created);
    _assets.add(created);

    // Se fornito un carico iniziale con quantità > 0, registriamo il primo evento di acquisto nello storico
    if (initialQuantity > 0) {
      final unitPrice = initialQuantity > 0 ? (effectiveCapital / initialQuantity) : effectivePrice;
      final snap = AssetPriceSnapshot(
        id: '',
        assetId: created.id,
        price: unitPrice,
        source: 'purchase',
        transactionType: 'purchase',
        quantityDelta: initialQuantity,
        totalAmount: effectiveCapital,
        note: 'Carico iniziale di creazione asset',
      );
      final snapMap = snap.toMap();
      snapMap.remove('id');
      await _supabase.from('asset_price_history').insert(snapMap);
    } else if (effectivePrice > 0) {
      await updateAssetPrice(
        assetId: created.id,
        newPrice: effectivePrice,
        source: 'manual',
        note: 'Quotazione iniziale di creazione',
      );
    }

    notifyListeners();
    return created;
  }

  /// Aggiorna i metadati anagrafici di un asset
  Future<void> updateAsset(InvestmentAsset updated) async {
    final map = updated.toMap();
    await _supabase.from('investment_assets').update(map).eq('id', updated.id);

    final idx = _assets.indexWhere((a) => a.id == updated.id);
    if (idx != -1) {
      _assets[idx] = updated;
      final box = await _getBox();
      await box.put(updated.id, updated);
      notifyListeners();
    }
  }

  /// Registra un acquisto o incremento quote/pezzi di un asset
  Future<void> recordBuyTransaction({
    required String assetId,
    required double quantityAdded,
    required double totalSpent,
    double? unitPrice,
    DateTime? date,
    String? note,
  }) async {
    if (quantityAdded <= 0 || totalSpent <= 0) return;

    final current = getAssetById(assetId);
    if (current == null) return;

    final newQuantity = current.totalQuantity + quantityAdded;
    final newCapital = current.investedCapital + totalSpent;
    final price = unitPrice ?? (totalSpent / quantityAdded);
    final now = date ?? DateTime.now();

    // 1. Inserisce snapshot storico di acquisto
    final snap = AssetPriceSnapshot(
      id: '',
      assetId: assetId,
      price: price,
      timestamp: now,
      source: 'purchase',
      transactionType: 'purchase',
      quantityDelta: quantityAdded,
      totalAmount: totalSpent,
      note: note ?? 'Acquisto quota/esemplare',
    );
    final snapMap = snap.toMap();
    snapMap.remove('id');
    await _supabase.from('asset_price_history').insert(snapMap);

    // 2. Aggiorna l'asset
    await _supabase.from('investment_assets').update({
      'total_quantity': newQuantity,
      'invested_capital': newCapital,
      'current_price': price,
      'last_price_update': now.toIso8601String(),
    }).eq('id', assetId);

    final updated = current.copyWith(
      totalQuantity: newQuantity,
      investedCapital: newCapital,
      currentPrice: price,
      lastPriceUpdate: now,
    );

    final idx = _assets.indexWhere((a) => a.id == assetId);
    if (idx != -1) {
      _assets[idx] = updated;
      final box = await _getBox();
      await box.put(updated.id, updated);
      notifyListeners();
    }
  }

  /// Registra una vendita o cessione quote/pezzi di un asset, restituendo la plusvalenza realizzata
  Future<double> recordSellTransaction({
    required String assetId,
    required double quantitySold,
    required double totalRealized,
    double? unitPrice,
    DateTime? date,
    String? note,
  }) async {
    if (quantitySold <= 0) return 0.0;

    final current = getAssetById(assetId);
    if (current == null) return 0.0;

    final pmc = current.averageBuyPrice;
    final costBasisSold = pmc * quantitySold;
    final realizedGain = totalRealized - costBasisSold;

    final newQuantity = math.max(0.0, current.totalQuantity - quantitySold);
    final newCapital = math.max(0.0, current.investedCapital - costBasisSold);
    final price = unitPrice ?? (quantitySold > 0 ? (totalRealized / quantitySold) : current.currentPrice);
    final now = date ?? DateTime.now();

    // 1. Inserisce snapshot storico di vendita
    final noteWithPnl = note != null && note.isNotEmpty
        ? '$note (P&L: ${realizedGain >= 0 ? '+' : ''}€${realizedGain.toStringAsFixed(2)})'
        : 'Vendita / Cessione (P&L: ${realizedGain >= 0 ? '+' : ''}€${realizedGain.toStringAsFixed(2)})';

    final snap = AssetPriceSnapshot(
      id: '',
      assetId: assetId,
      price: price,
      timestamp: now,
      source: 'sale',
      transactionType: 'sale',
      quantityDelta: -quantitySold,
      totalAmount: totalRealized,
      note: noteWithPnl,
    );
    final snapMap = snap.toMap();
    snapMap.remove('id');
    await _supabase.from('asset_price_history').insert(snapMap);

    // 2. Aggiorna l'asset
    await _supabase.from('investment_assets').update({
      'total_quantity': newQuantity,
      'invested_capital': newCapital,
      'current_price': price,
      'last_price_update': now.toIso8601String(),
    }).eq('id', assetId);

    final updated = current.copyWith(
      totalQuantity: newQuantity,
      investedCapital: newCapital,
      currentPrice: price,
      lastPriceUpdate: now,
    );

    final idx = _assets.indexWhere((a) => a.id == assetId);
    if (idx != -1) {
      _assets[idx] = updated;
      final box = await _getBox();
      await box.put(updated.id, updated);
      notifyListeners();
    }

    return realizedGain;
  }

  /// Rettifica rapida della quantità posseduta (inventario)
  Future<void> adjustQuantity({
    required String assetId,
    required double newQuantity,
    String? reason,
  }) async {
    final current = getAssetById(assetId);
    if (current == null) return;

    final delta = newQuantity - current.totalQuantity;
    final now = DateTime.now();

    final snap = AssetPriceSnapshot(
      id: '',
      assetId: assetId,
      price: current.currentPrice,
      timestamp: now,
      source: 'adjustment',
      transactionType: 'adjustment',
      quantityDelta: delta,
      note: reason ?? 'Rettifica quantità inventario',
    );
    final snapMap = snap.toMap();
    snapMap.remove('id');
    await _supabase.from('asset_price_history').insert(snapMap);

    await _supabase.from('investment_assets').update({
      'total_quantity': newQuantity,
      'last_price_update': now.toIso8601String(),
    }).eq('id', assetId);

    final updated = current.copyWith(
      totalQuantity: newQuantity,
      lastPriceUpdate: now,
    );

    final idx = _assets.indexWhere((a) => a.id == assetId);
    if (idx != -1) {
      _assets[idx] = updated;
      final box = await _getBox();
      await box.put(updated.id, updated);
      notifyListeners();
    }
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
      transactionType: 'snapshot',
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

  /// Recupera la cronologia prezzi e movimenti di un asset per timeline e grafici
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
        final snap = AssetPriceSnapshot(
          id: '',
          assetId: alloc.assetId,
          price: alloc.pricePerUnit,
          source: 'purchase',
          transactionType: 'purchase',
          quantityDelta: alloc.quantity,
          totalAmount: alloc.amount,
          note: 'Acquisto quota tramite spesa #$expenseId',
        );
        final snapMap = snap.toMap();
        snapMap.remove('id');
        await _supabase.from('asset_price_history').insert(snapMap);
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
