import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solducci/core/logging/app_logger.dart';

/// Service per persistere l'ordine personalizzato delle task per documento
/// Salva solo localmente (non sincronizzato su Supabase)
///
/// L'ordine è salvato come lista di task IDs nella sequenza desiderata dall'utente
class TaskOrderPersistenceService {
  static const String _customOrderPrefix = 'task_custom_order_';

  /// Salva l'ordine personalizzato delle task per un documento
  ///
  /// [documentId]: ID del documento
  /// [taskIds]: Lista di task IDs nell'ordine desiderato
  Future<void> saveCustomOrder({
    required String documentId,
    required List<String> taskIds,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getKey(documentId);

      final orderData = {
        'task_ids': taskIds,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final jsonString = json.encode(orderData);
      await prefs.setString(key, jsonString);
    } catch (e) {
      // Ignora errori di salvataggio - l'ordine custom è opzionale
      AppLogger.debug('Error saving custom task order: $e');
    }
  }

  /// Carica l'ordine personalizzato salvato per un documento
  ///
  /// Ritorna null se non c'è un ordine salvato o in caso di errore
  ///
  /// Format ritornato:
  /// ```dart
  /// ['task_id_1', 'task_id_2', 'task_id_3', ...]
  /// ```
  Future<List<String>?> loadCustomOrder(String documentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getKey(documentId);
      final jsonString = prefs.getString(key);

      if (jsonString == null || jsonString.isEmpty) {
        return null;
      }

      final Map<String, dynamic> orderData = json.decode(jsonString);

      // Valida che abbia il campo necessario
      if (!orderData.containsKey('task_ids')) {
        return null;
      }

      final List<dynamic> taskIds = orderData['task_ids'];
      return taskIds.cast<String>();
    } catch (e) {
      // In caso di errore, ritorna null (fallback a default sort)
      AppLogger.debug('Error loading custom task order: $e');
      return null;
    }
  }

  /// Pulisce l'ordine personalizzato per un documento
  Future<void> clearCustomOrder(String documentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getKey(documentId);
      await prefs.remove(key);
    } catch (e) {
      AppLogger.debug('Error clearing custom task order: $e');
    }
  }

  /// Pulisce tutti gli ordini personalizzati (utile per logout o reset)
  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      // Rimuovi tutte le chiavi che iniziano con il prefisso
      for (final key in keys) {
        if (key.startsWith(_customOrderPrefix)) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      AppLogger.debug('Error clearing all custom task orders: $e');
    }
  }

  /// Verifica se esiste un ordine personalizzato per un documento
  Future<bool> hasCustomOrder(String documentId) async {
    final order = await loadCustomOrder(documentId);
    return order != null && order.isNotEmpty;
  }

  /// Rimuove task IDs non più esistenti dall'ordine salvato
  /// Utile quando task vengono eliminate
  Future<void> cleanupCustomOrder({
    required String documentId,
    required List<String> validTaskIds,
  }) async {
    final savedOrder = await loadCustomOrder(documentId);
    if (savedOrder == null) return;

    // Filtra solo task IDs validi
    final cleanedOrder = savedOrder.where((id) => validTaskIds.contains(id)).toList();

    if (cleanedOrder.length != savedOrder.length) {
      // Se abbiamo rimosso qualche ID, salva l'ordine pulito
      await saveCustomOrder(documentId: documentId, taskIds: cleanedOrder);
    }
  }

  /// Genera la chiave per SharedPreferences
  String _getKey(String documentId) {
    return '$_customOrderPrefix$documentId';
  }
}
