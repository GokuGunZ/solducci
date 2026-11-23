import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MarkdownSettingsService extends ChangeNotifier {
  static final MarkdownSettingsService _instance = MarkdownSettingsService._internal();
  factory MarkdownSettingsService() => _instance;
  MarkdownSettingsService._internal();

  static const String _keyDefaultExpanded = 'md_setting_default_expanded';
  static const String _keyFontSize = 'md_setting_font_size';
  static const String _keyReadOnlyLock = 'md_setting_readonly_lock';

  bool _defaultExpanded = true;
  double _fontSize = 14.5;
  bool _readOnlyLock = false;
  bool _isInitialized = false;

  bool get defaultExpanded => _defaultExpanded;
  double get fontSize => _fontSize;
  bool get readOnlyLock => _readOnlyLock;
  bool get isInitialized => _isInitialized;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _defaultExpanded = prefs.getBool(_keyDefaultExpanded) ?? true;
      _fontSize = prefs.getDouble(_keyFontSize) ?? 14.5;
      _readOnlyLock = prefs.getBool(_keyReadOnlyLock) ?? false;
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Errore inizializzazione MarkdownSettingsService: $e');
    }
  }

  Future<void> setDefaultExpanded(bool value) async {
    _defaultExpanded = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyDefaultExpanded, value);
    } catch (e) {
      debugPrint('Errore salvataggio defaultExpanded: $e');
    }
  }

  Future<void> setFontSize(double value) async {
    _fontSize = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_keyFontSize, value);
    } catch (e) {
      debugPrint('Errore salvataggio fontSize: $e');
    }
  }

  Future<void> setReadOnlyLock(bool value) async {
    _readOnlyLock = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyReadOnlyLock, value);
    } catch (e) {
      debugPrint('Errore salvataggio readOnlyLock: $e');
    }
  }

  Future<void> resetDefaults() async {
    _defaultExpanded = true;
    _fontSize = 14.5;
    _readOnlyLock = false;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyDefaultExpanded);
      await prefs.remove(_keyFontSize);
      await prefs.remove(_keyReadOnlyLock);
    } catch (e) {
      debugPrint('Errore reset impostazioni MD: $e');
    }
  }
}
