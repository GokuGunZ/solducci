import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Service per persistere l'ultimo contesto selezionato dall'utente
/// Permette di ripristinare il contesto all'avvio dell'app
class ContextPersistenceService {
  static const String _lastContextKey = 'last_context';

  /// Salva l'ultimo contesto selezionato
  ///
  /// [type]: 'personal', 'group', o 'view'
  /// [id]: ID del gruppo o della vista (null per personal)
  Future<void> saveLastContext({
    required String type,
    String? id,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final contextData = {
        'type': type,
        'id': id,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final jsonString = json.encode(contextData);
      await prefs.setString(_lastContextKey, jsonString);
    } catch (e) {
      // Ignora errori di salvataggio
      print('Error saving last context: $e');
    }
  }

  /// Carica l'ultimo contesto salvato
  ///
  /// Ritorna null se non c'è nessun contesto salvato o in caso di errore
  ///
  /// Format ritornato:
  /// ```dart
  /// {
  ///   'type': 'personal' | 'group' | 'view',
  ///   'id': 'group_id' | 'view_id' | null,
  ///   'timestamp': '2025-12-01T10:00:00.000Z'
  /// }
  /// ```
  Future<Map<String, dynamic>?> loadLastContext() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_lastContextKey);

      if (jsonString == null || jsonString.isEmpty) {
        return null;
      }

      final Map<String, dynamic> contextData = json.decode(jsonString);

      // Valida che abbia i campi necessari
      if (!contextData.containsKey('type')) {
        return null;
      }

      return contextData;
    } catch (e) {
      // In caso di errore, ritorna null (fallback a personal)
      print('Error loading last context: $e');
      return null;
    }
  }

  /// Pulisce il contesto salvato
  Future<void> clearLastContext() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastContextKey);
    } catch (e) {
      print('Error clearing last context: $e');
    }
  }
}
