import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solducci/features/csv_importer/models/staging_transaction.dart';

/// Servizio Local-First per la persistenza e gestione dello stato
/// della Staging Inbox di Solducci.
/// Permette l'import a tappe, la persistenza tra sessioni e la notifica
/// reattiva del conteggio movimenti in sospeso a tutta l'app.
class CsvStagingService {
  static final CsvStagingService _instance = CsvStagingService._internal();
  factory CsvStagingService() => _instance;
  CsvStagingService._internal();

  static const String _prefKeyTransactions = 'solducci_csv_staging_transactions_v1';
  static const String _prefKeyMetadata = 'solducci_csv_staging_metadata_v1';

  List<StagingTransaction>? _cachedTransactions;
  String? _cachedFileName;
  DateTime? _cachedUpdatedAt;

  /// Notifier reattivo del numero di transazioni pendenti per badge e banner
  final ValueNotifier<int> pendingCountNotifier = ValueNotifier<int>(0);

  /// Inizializza il servizio caricando il conteggio pendente
  Future<void> init() async {
    final count = await getPendingCount();
    pendingCountNotifier.value = count;
  }

  /// Restituisce la lista di transazioni attualmente in bozza
  Future<List<StagingTransaction>> getStagedTransactions() async {
    if (_cachedTransactions != null) {
      return List<StagingTransaction>.from(_cachedTransactions!);
    }

    final prefs = await SharedPreferences.getInstance();
    final rawJson = prefs.getString(_prefKeyTransactions);

    if (rawJson == null || rawJson.isEmpty) {
      _cachedTransactions = [];
      pendingCountNotifier.value = 0;
      return [];
    }

    try {
      final List decoded = jsonDecode(rawJson) as List;
      _cachedTransactions = decoded
          .map((item) => StagingTransaction.fromMap(item as Map<String, dynamic>))
          .toList();
      pendingCountNotifier.value = _cachedTransactions!.length;

      final rawMeta = prefs.getString(_prefKeyMetadata);
      if (rawMeta != null && rawMeta.isNotEmpty) {
        final meta = jsonDecode(rawMeta) as Map<String, dynamic>;
        _cachedFileName = meta['fileName'] as String?;
        if (meta['updatedAt'] != null) {
          _cachedUpdatedAt = DateTime.tryParse(meta['updatedAt'] as String);
        }
      }

      return List<StagingTransaction>.from(_cachedTransactions!);
    } catch (e) {
      debugPrint('⚠️ Errore durante il caricamento dello staging CSV: $e');
      _cachedTransactions = [];
      pendingCountNotifier.value = 0;
      return [];
    }
  }

  /// Salva o aggiorna l'intera lista di transazioni in bozza
  Future<void> saveStagedTransactions(
    List<StagingTransaction> transactions, {
    String? fileName,
  }) async {
    _cachedTransactions = List<StagingTransaction>.from(transactions);
    if (fileName != null) {
      _cachedFileName = fileName;
    }
    _cachedUpdatedAt = DateTime.now();
    pendingCountNotifier.value = transactions.length;

    await _persist();
  }

  /// Unisce nuove transazioni alla bozza già esistente
  Future<void> appendTransactions(
    List<StagingTransaction> newTransactions, {
    String? fileName,
  }) async {
    final current = await getStagedTransactions();
    
    // Evita duplicati di ID all'interno dello staging
    final existingIds = current.map((t) => t.id).toSet();
    final filteredNew = newTransactions.where((t) => !existingIds.contains(t.id)).toList();

    current.addAll(filteredNew);
    _cachedTransactions = current;
    if (fileName != null) {
      _cachedFileName = fileName;
    }
    _cachedUpdatedAt = DateTime.now();
    pendingCountNotifier.value = current.length;

    await _persist();
  }

  /// Rimuove una lista di transazioni (ad es. importate o scartate)
  Future<void> removeTransactions(List<String> transactionIds) async {
    final current = await getStagedTransactions();
    final toRemove = transactionIds.toSet();
    current.removeWhere((t) => toRemove.contains(t.id));

    _cachedTransactions = current;
    _cachedUpdatedAt = DateTime.now();
    pendingCountNotifier.value = current.length;

    if (current.isEmpty) {
      await clearStaging();
    } else {
      await _persist();
    }
  }

  /// Svuota completamente l'inbox e cancella i dati salvati
  Future<void> clearStaging() async {
    _cachedTransactions = [];
    _cachedFileName = null;
    _cachedUpdatedAt = null;
    pendingCountNotifier.value = 0;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKeyTransactions);
    await prefs.remove(_prefKeyMetadata);
  }

  /// Verifica se è presente una bozza con almeno un movimento
  Future<bool> hasPendingDraft() async {
    final count = await getPendingCount();
    return count > 0;
  }

  /// Restituisce il numero di transazioni pendenti
  Future<int> getPendingCount() async {
    if (_cachedTransactions != null) {
      return _cachedTransactions!.length;
    }
    final prefs = await SharedPreferences.getInstance();
    final rawJson = prefs.getString(_prefKeyTransactions);
    if (rawJson == null || rawJson.isEmpty) return 0;
    try {
      final List decoded = jsonDecode(rawJson) as List;
      return decoded.length;
    } catch (_) {
      return 0;
    }
  }

  String? get activeFileName => _cachedFileName;
  DateTime? get lastUpdatedAt => _cachedUpdatedAt;

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    if (_cachedTransactions == null || _cachedTransactions!.isEmpty) {
      await prefs.remove(_prefKeyTransactions);
      await prefs.remove(_prefKeyMetadata);
      return;
    }

    final mapped = _cachedTransactions!.map((t) => t.toMap()).toList();
    final jsonStr = jsonEncode(mapped);
    await prefs.setString(_prefKeyTransactions, jsonStr);

    final meta = {
      'fileName': _cachedFileName,
      'updatedAt': _cachedUpdatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
    await prefs.setString(_prefKeyMetadata, jsonEncode(meta));
  }
}
