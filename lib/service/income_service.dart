import 'dart:async';
import 'package:solducci/models/income.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class IncomeService {
  static final IncomeService _instance = IncomeService._internal();
  factory IncomeService() => _instance;
  IncomeService._internal();

  final _supabase = Supabase.instance.client;
  final _incomesStreamController = StreamController<List<Income>>.broadcast();

  Stream<List<Income>> get stream => _incomesStreamController.stream;
  List<Income> _cachedIncomes = [];
  List<Income> get currentIncomes => _cachedIncomes;

  /// Recupera tutte le entrate dell'utente autenticato
  Future<List<Income>> fetchIncomes() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await _supabase
          .from('incomes')
          .select()
          .eq('user_id', userId)
          .order('date', ascending: false);

      final list = (response as List)
          .map((item) => Income.fromMap(item as Map<String, dynamic>))
          .toList();

      _cachedIncomes = list;
      _incomesStreamController.add(list);
      return list;
    } catch (e) {
      return _cachedIncomes;
    }
  }

  /// Crea una nuova entrata
  Future<Income> createIncome(Income newIncome) async {
    final userId = _supabase.auth.currentUser?.id;
    final map = newIncome.toMap();
    map['user_id'] = userId;
    map.remove('id'); // Generato da Supabase

    final response = await _supabase
        .from('incomes')
        .insert(map)
        .select()
        .single();

    final created = Income.fromMap(response);
    _cachedIncomes.insert(0, created);
    _incomesStreamController.add(_cachedIncomes);
    return created;
  }

  /// Aggiorna un'entrata esistente
  Future<void> updateIncome(Income income) async {
    final map = income.toMap();
    await _supabase
        .from('incomes')
        .update(map)
        .eq('id', income.id);

    final idx = _cachedIncomes.indexWhere((i) => i.id == income.id);
    if (idx >= 0) {
      _cachedIncomes[idx] = income;
      _incomesStreamController.add(_cachedIncomes);
    }
  }

  /// Elimina un'entrata
  Future<void> deleteIncome(String id) async {
    await _supabase.from('incomes').delete().eq('id', id);
    _cachedIncomes.removeWhere((i) => i.id == id);
    _incomesStreamController.add(_cachedIncomes);
  }

  /// Calcola la somma delle entrate per un mese specifico
  double getMonthlyTotal(DateTime month) {
    return _cachedIncomes
        .where((i) => i.date.year == month.year && i.date.month == month.month)
        .fold(0.0, (sum, i) => sum + i.amount);
  }

  /// Ritorna la somma dei dividendi e cedole incassati per un asset specifico
  double getTotalDividendsForAsset(String assetId) {
    return _cachedIncomes
        .where((i) => i.assetId == assetId)
        .fold<double>(0.0, (sum, i) => sum + i.amount);
  }

  /// Ritorna la somma dei dividendi incassati per un intero portafoglio
  double getTotalDividendsForPortfolio(String portfolioId) {
    return _cachedIncomes
        .where((i) => i.portfolioId == portfolioId)
        .fold<double>(0.0, (sum, i) => sum + i.amount);
  }
}
