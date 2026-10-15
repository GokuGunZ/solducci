import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:solducci/models/expense.dart';
import 'package:solducci/models/expense_form.dart';
import 'package:solducci/models/income.dart';
import 'package:solducci/models/income_category.dart';
import 'package:solducci/models/recurring_transaction.dart';
import 'package:solducci/service/context_manager.dart';
import 'package:solducci/service/expense_service_cached.dart';
import 'package:solducci/service/income_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RecurringTransactionService {
  static final RecurringTransactionService _instance = RecurringTransactionService._internal();
  factory RecurringTransactionService() => _instance;
  RecurringTransactionService._internal() {
    _contextManager.addListener(_onContextChanged);
    init();
  }

  final _supabase = Supabase.instance.client;
  final _contextManager = ContextManager();
  final _expenseService = ExpenseServiceCached();
  final _incomeService = IncomeService();

  final _streamController = StreamController<List<RecurringTransaction>>.broadcast();
  Stream<List<RecurringTransaction>> get stream => _streamController.stream;

  List<RecurringTransaction> _cachedItems = [];
  List<RecurringTransaction> get currentItems => _cachedItems;

  final ValueNotifier<int> pendingInboxCountNotifier = ValueNotifier<int>(0);

  bool _isProcessingDue = false;
  bool _initialized = false;

  void init() {
    if (_initialized) return;
    _initialized = true;
    fetchRecurringTransactions();
  }

  void _onContextChanged() {
    fetchRecurringTransactions();
  }

  void dispose() {
    _contextManager.removeListener(_onContextChanged);
    _streamController.close();
  }

  /// Recupera tutte le ricorrenze per il contesto attivo (Personale o di Gruppo)
  Future<List<RecurringTransaction>> fetchRecurringTransactions() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final currentContext = _contextManager.currentContext;

    try {
      var query = _supabase.from('recurring_transactions').select();

      if (currentContext.isGroup && currentContext.groupId != null) {
        query = query.eq('group_id', currentContext.groupId!);
      } else {
        query = query.eq('user_id', userId).isFilter('group_id', null);
      }

      final response = await query.order('next_due_date', ascending: true);
      final list = (response as List)
          .map((item) => RecurringTransaction.fromMap(item as Map<String, dynamic>))
          .toList();

      _cachedItems = list;
      _updatePendingCount();
      _streamController.add(list);

      // Esegue il controllo di addebito automatico per le voci scadute non interattive
      processDueTransactions();

      return list;
    } catch (e) {
      debugPrint('Error fetching recurring transactions: $e');
      return _cachedItems;
    }
  }

  void _updatePendingCount() {
    final count = _cachedItems.where((item) => item.isDueTodayOrOverdue && item.requiresConfirmation).length;
    pendingInboxCountNotifier.value = count;
  }

  /// Lista delle ricorrenze attualmente in Inbox (scadute o odierne che richiedono conferma)
  List<RecurringTransaction> getPendingInboxItems() {
    return _cachedItems.where((item) => item.isDueTodayOrOverdue && item.requiresConfirmation).toList();
  }

  /// Calcola la prossima data di scadenza data una frequenza e intervallo
  static DateTime calculateNextDueDate({
    required DateTime fromDate,
    required RecurringFrequency frequency,
    int interval = 1,
    int? dayOfMonth,
    int? dayOfWeek,
  }) {
    final base = DateTime(fromDate.year, fromDate.month, fromDate.day);

    switch (frequency) {
      case RecurringFrequency.weekly:
        return base.add(Duration(days: 7 * interval));

      case RecurringFrequency.biweekly:
        return base.add(Duration(days: 14 * interval));

      case RecurringFrequency.monthly:
      case RecurringFrequency.bimonthly:
      case RecurringFrequency.quarterly:
      case RecurringFrequency.semiannual:
        int monthsToAdd = interval;
        if (frequency == RecurringFrequency.bimonthly) monthsToAdd = 2 * interval;
        if (frequency == RecurringFrequency.quarterly) monthsToAdd = 3 * interval;
        if (frequency == RecurringFrequency.semiannual) monthsToAdd = 6 * interval;

        int newYear = base.year;
        int newMonth = base.month + monthsToAdd;
        while (newMonth > 12) {
          newYear += 1;
          newMonth -= 12;
        }

        final targetDay = dayOfMonth ?? base.day;
        final daysInNextMonth = DateTime(newYear, newMonth + 1, 0).day;
        final clampedDay = targetDay > daysInNextMonth ? daysInNextMonth : targetDay;

        return DateTime(newYear, newMonth, clampedDay);

      case RecurringFrequency.yearly:
        int newYear = base.year + interval;
        final targetDay = dayOfMonth ?? base.day;
        final daysInNextMonth = DateTime(newYear, base.month + 1, 0).day;
        final clampedDay = targetDay > daysInNextMonth ? daysInNextMonth : targetDay;

        return DateTime(newYear, base.month, clampedDay);
    }
  }

  /// Controlla e genera automaticamente le spese/entrate per cui `requiresConfirmation == false`
  Future<void> processDueTransactions() async {
    if (_isProcessingDue) return;
    _isProcessingDue = true;

    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final dueAutoItems = _cachedItems.where((item) {
        if (!item.isActive || item.requiresConfirmation) return false;
        final due = DateTime(item.nextDueDate.year, item.nextDueDate.month, item.nextDueDate.day);
        return due.isBefore(today) || due.isAtSameMomentAs(today);
      }).toList();

      for (final item in dueAutoItems) {
        await _generateTransaction(item, item.amount, item.nextDueDate);

        // Calcola nuovo next_due_date
        final nextDate = calculateNextDueDate(
          fromDate: item.nextDueDate,
          frequency: item.frequency,
          interval: item.intervalCount,
          dayOfMonth: item.dayOfMonth,
          dayOfWeek: item.dayOfWeek,
        );

        final shouldDeactivate = item.endDate != null && nextDate.isAfter(item.endDate!);

        final updated = item.copyWith(
          nextDueDate: nextDate,
          lastGeneratedAt: DateTime.now(),
          isActive: shouldDeactivate ? false : item.isActive,
        );

        await updateRecurringTransaction(updated);
      }
    } catch (e) {
      debugPrint('Error processing due recurring transactions: $e');
    } finally {
      _isProcessingDue = false;
    }
  }

  /// Crea la transazione reale (Expense o Income) sul database
  Future<void> _generateTransaction(
    RecurringTransaction item,
    double amount,
    DateTime date,
  ) async {
    if (item.isIncome) {
      final newIncome = Income(
        id: '',
        userId: item.userId,
        walletId: item.walletId,
        portfolioId: item.portfolioId,
        recurringTransactionId: item.id,
        amount: amount,
        description: item.title,
        date: date,
        category: IncomeCategory.fromDb(item.category),
        isRecurring: true,
      );
      await _incomeService.createIncome(newIncome);
    } else {
      Tipologia parsedType = Tipologia.altro;
      try {
        parsedType = Tipologia.values.firstWhere(
          (t) => t.name.toLowerCase() == item.category.toLowerCase() || t.label.toLowerCase() == item.category.toLowerCase(),
          orElse: () => Tipologia.altro,
        );
      } catch (_) {}

      final newExpense = Expense(
        id: 0,
        description: item.title,
        amount: amount,
        date: date,
        type: parsedType,
        userId: item.isPersonal ? item.userId : null,
        groupId: item.groupId,
        paidBy: item.paidBy ?? (item.isPersonal ? item.userId : null),
        splitType: item.splitType,
        splitData: item.splitData,
        walletId: item.walletId,
        portfolioId: item.portfolioId,
        recurringTransactionId: item.id,
      );

      await _expenseService.createExpense(newExpense);
    }
  }

  /// Conferma ed emette un movimento in sospeso (con eventuale importo/data personalizzati)
  Future<void> confirmOccurrence(
    RecurringTransaction item, {
    double? customAmount,
    DateTime? customDate,
    String? notes,
  }) async {
    final effectiveAmount = customAmount ?? item.amount;
    final effectiveDate = customDate ?? item.nextDueDate;

    // 1. Genera spesa o entrata effettiva
    await _generateTransaction(item, effectiveAmount, effectiveDate);

    // 2. Calcola prossimo ciclo
    final nextDate = calculateNextDueDate(
      fromDate: item.nextDueDate,
      frequency: item.frequency,
      interval: item.intervalCount,
      dayOfMonth: item.dayOfMonth,
      dayOfWeek: item.dayOfWeek,
    );

    final shouldDeactivate = item.endDate != null && nextDate.isAfter(item.endDate!);

    final updated = item.copyWith(
      nextDueDate: nextDate,
      lastGeneratedAt: DateTime.now(),
      isActive: shouldDeactivate ? false : item.isActive,
      notes: notes ?? item.notes,
    );

    await updateRecurringTransaction(updated);
  }

  /// Salta il ciclo corrente senza emettere la spesa/entrata
  Future<void> skipCycle(RecurringTransaction item) async {
    final nextDate = calculateNextDueDate(
      fromDate: item.nextDueDate,
      frequency: item.frequency,
      interval: item.intervalCount,
      dayOfMonth: item.dayOfMonth,
      dayOfWeek: item.dayOfWeek,
    );

    final shouldDeactivate = item.endDate != null && nextDate.isAfter(item.endDate!);

    final updated = item.copyWith(
      nextDueDate: nextDate,
      isActive: shouldDeactivate ? false : item.isActive,
    );

    await updateRecurringTransaction(updated);
  }

  /// Postpone la data di scadenza (es. +3 giorni)
  Future<void> postponeOccurrence(RecurringTransaction item, {int days = 3}) async {
    final newDueDate = item.nextDueDate.add(Duration(days: days));
    final updated = item.copyWith(nextDueDate: newDueDate);
    await updateRecurringTransaction(updated);
  }

  /// Creazione di una nuova ricorrenza
  Future<RecurringTransaction> createRecurringTransaction(RecurringTransaction item) async {
    final userId = _supabase.auth.currentUser?.id;
    final map = item.toMap();
    if (userId != null && map['user_id'] == null) {
      map['user_id'] = userId;
    }
    map.remove('id');

    final response = await _supabase
        .from('recurring_transactions')
        .insert(map)
        .select()
        .single();

    final created = RecurringTransaction.fromMap(response);
    _cachedItems.add(created);
    _cachedItems.sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));
    _updatePendingCount();
    _streamController.add(List.from(_cachedItems));

    // Se la data di inizio è oggi o nel passato e non richiede conferma, genera subito se necessario
    processDueTransactions();

    return created;
  }

  /// Aggiornamento ricorrenza esistente
  Future<void> updateRecurringTransaction(RecurringTransaction item) async {
    final map = item.toMap();
    await _supabase
        .from('recurring_transactions')
        .update(map)
        .eq('id', item.id);

    final idx = _cachedItems.indexWhere((i) => i.id == item.id);
    if (idx >= 0) {
      _cachedItems[idx] = item;
      _cachedItems.sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));
      _updatePendingCount();
      _streamController.add(List.from(_cachedItems));
    }
  }

  /// Eliminazione ricorrenza
  Future<void> deleteRecurringTransaction(String id) async {
    await _supabase.from('recurring_transactions').delete().eq('id', id);
    _cachedItems.removeWhere((i) => i.id == id);
    _updatePendingCount();
    _streamController.add(List.from(_cachedItems));
  }

  /// Toggle attiva/pausa
  Future<void> toggleActive(String id, bool active) async {
    final idx = _cachedItems.indexWhere((i) => i.id == id);
    if (idx >= 0) {
      final updated = _cachedItems[idx].copyWith(isActive: active);
      await updateRecurringTransaction(updated);
    }
  }
}
