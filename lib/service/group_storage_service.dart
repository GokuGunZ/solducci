import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Service per gestire le preferenze locali dei gruppi
/// Memorizza per ogni gruppo se includere le spese personali
class GroupStorageService {
  static const String _prefsKey = 'group_preferences';

  /// Carica tutte le preferenze dei gruppi
  /// Ritorna una mappa groupId -> includePersonal
  Future<Map<String, bool>> loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_prefsKey);

      if (jsonString == null || jsonString.isEmpty) {
        return {};
      }

      final Map<String, dynamic> decoded = json.decode(jsonString);
      // Converte dynamic values a bool
      return decoded.map((key, value) => MapEntry(key, value as bool));
    } catch (e) {
      // In caso di errore, ritorna mappa vuota
      return {};
    }
  }

  /// Salva tutte le preferenze dei gruppi
  Future<void> _savePreferences(Map<String, bool> preferences) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(preferences);
    await prefs.setString(_prefsKey, jsonString);
  }

  /// Imposta la preferenza "include personal" per un gruppo specifico
  Future<void> setIncludePersonal(String groupId, bool include) async {
    final preferences = await loadPreferences();
    preferences[groupId] = include;
    await _savePreferences(preferences);
  }

  /// Ottieni la preferenza "include personal" per un gruppo specifico
  /// Ritorna false se la preferenza non esiste
  Future<bool> getIncludePersonal(String groupId) async {
    final preferences = await loadPreferences();
    return preferences[groupId] ?? false;
  }

  /// Rimuove la preferenza per un gruppo specifico
  Future<void> removePreference(String groupId) async {
    final preferences = await loadPreferences();
    preferences.remove(groupId);
    await _savePreferences(preferences);
  }

  /// Pulisce tutte le preferenze salvate
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }
}
