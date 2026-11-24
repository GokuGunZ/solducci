import 'package:flutter/material.dart';
import 'package:solducci/models/expense.dart';
import 'package:solducci/models/expense_form.dart';

class ExpenseFilterCriteria {
  final Set<Tipologia> categories;
  final DateTimeRange? dateRange;
  final String? datePreset; // 'today', 'week', 'month', 'custom'
  final String? paidByUserId;
  final String searchQuery;
  final double? minAmount;
  final double? maxAmount;

  const ExpenseFilterCriteria({
    this.categories = const {},
    this.dateRange,
    this.datePreset,
    this.paidByUserId,
    this.searchQuery = '',
    this.minAmount,
    this.maxAmount,
  });

  bool get isEmpty =>
      categories.isEmpty &&
      dateRange == null &&
      paidByUserId == null &&
      searchQuery.trim().isEmpty &&
      minAmount == null &&
      maxAmount == null;

  int get activeFilterCount {
    int count = 0;
    if (categories.isNotEmpty) count++;
    if (dateRange != null) count++;
    if (paidByUserId != null) count++;
    if (searchQuery.trim().isNotEmpty) count++;
    if (minAmount != null || maxAmount != null) count++;
    return count;
  }

  ExpenseFilterCriteria copyWith({
    Set<Tipologia>? categories,
    DateTimeRange? dateRange,
    String? datePreset,
    String? paidByUserId,
    String? searchQuery,
    double? minAmount,
    double? maxAmount,
    bool clearDateRange = false,
    bool clearPaidBy = false,
  }) {
    return ExpenseFilterCriteria(
      categories: categories ?? this.categories,
      dateRange: clearDateRange ? null : (dateRange ?? this.dateRange),
      datePreset: clearDateRange ? null : (datePreset ?? this.datePreset),
      paidByUserId: clearPaidBy ? null : (paidByUserId ?? this.paidByUserId),
      searchQuery: searchQuery ?? this.searchQuery,
      minAmount: minAmount ?? this.minAmount,
      maxAmount: maxAmount ?? this.maxAmount,
    );
  }

  bool matches(Expense expense) {
    // 1. Tipologia (multi-selection)
    if (categories.isNotEmpty && !categories.contains(expense.type)) {
      return false;
    }

    // 2. Date window
    if (dateRange != null) {
      final start = DateTime(dateRange!.start.year, dateRange!.start.month, dateRange!.start.day);
      final end = DateTime(dateRange!.end.year, dateRange!.end.month, dateRange!.end.day, 23, 59, 59);
      if (expense.date.isBefore(start) || expense.date.isAfter(end)) {
        return false;
      }
    }

    // 3. Paid by
    if (paidByUserId != null) {
      final actualPayer = expense.paidBy ?? expense.userId;
      if (actualPayer != paidByUserId) {
        return false;
      }
    }

    // 4. Description search
    if (searchQuery.trim().isNotEmpty) {
      final query = searchQuery.trim().toLowerCase();
      if (!expense.description.toLowerCase().contains(query)) {
        return false;
      }
    }

    // 5. Amount min / max
    if (minAmount != null && expense.amount < minAmount!) {
      return false;
    }
    if (maxAmount != null && expense.amount > maxAmount!) {
      return false;
    }

    return true;
  }
}
