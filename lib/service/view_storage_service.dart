import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solducci/models/expense_view.dart';

/// Service per gestire storage locale delle viste
/// Le viste sono salvate solo localmente (non sincronizzate su Supabase)
class ViewStorageService {
  static const String _viewsKey = 'expense_views';

  /// Carica tutte le viste salvate localmente
  Future<List<ExpenseView>> loadViews() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final viewsJson = prefs.getString(_viewsKey);

      if (viewsJson == null || viewsJson.isEmpty) {
        return [];
      }

      final List<dynamic> decoded = json.decode(viewsJson);
      return decoded.map((json) => ExpenseView.fromJson(json)).toList();
    } catch (e) {
      // In caso di errore, ritorna lista vuota invece di crashare
      return [];
    }
  }

  /// Salva tutte le viste in storage locale
  Future<void> saveViews(List<ExpenseView> views) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final viewsJson = json.encode(views.map((v) => v.toJson()).toList());
      await prefs.setString(_viewsKey, viewsJson);
    } catch (e) {
      rethrow;
    }
  }

  /// Aggiungi una nuova vista
  Future<void> addView(ExpenseView view) async {
    final views = await loadViews();
    views.add(view);
    await saveViews(views);
  }

  /// Aggiorna una vista esistente
  Future<void> updateView(ExpenseView updatedView) async {
    final views = await loadViews();
    final index = views.indexWhere((v) => v.id == updatedView.id);

    if (index == -1) {
      throw Exception('View not found: ${updatedView.id}');
    }

    views[index] = updatedView;
    await saveViews(views);
  }

  /// Elimina una vista
  Future<void> deleteView(String viewId) async {
    final views = await loadViews();
    views.removeWhere((v) => v.id == viewId);
    await saveViews(views);
  }

  /// Imposta preferenza "include personal" per una vista
  Future<void> setIncludePersonal(String viewId, bool include) async {
    final views = await loadViews();
    final index = views.indexWhere((v) => v.id == viewId);

    if (index == -1) {
      throw Exception('View not found: $viewId');
    }

    views[index] = views[index].copyWith(includePersonal: include);
    await saveViews(views);
  }

  /// Ottieni preferenza "include personal" per una vista
  Future<bool> getIncludePersonal(String viewId) async {
    final views = await loadViews();
    final view = views.firstWhere(
      (v) => v.id == viewId,
      orElse: () => throw Exception('View not found: $viewId'),
    );
    return view.includePersonal;
  }

  /// Cancella tutte le viste (utile per logout o reset)
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_viewsKey);
  }

  /// Verifica se esistono viste salvate
  Future<bool> hasViews() async {
    final views = await loadViews();
    return views.isNotEmpty;
  }

  /// Ottieni una vista specifica per ID
  Future<ExpenseView?> getViewById(String viewId) async {
    final views = await loadViews();
    try {
      return views.firstWhere((v) => v.id == viewId);
    } catch (e) {
      return null;
    }
  }
}
