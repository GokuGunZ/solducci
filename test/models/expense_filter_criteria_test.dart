import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solducci/models/expense.dart';
import 'package:solducci/models/expense_filter_criteria.dart';
import 'package:solducci/models/expense_form.dart';

void main() {
  group('ExpenseFilterCriteria', () {
    final e1 = Expense(
      id: 1,
      userId: 'u1',
      paidBy: 'u1',
      amount: 15.50,
      description: 'Pranzo al ristorante',
      type: Tipologia.ristorante,
      date: DateTime(2026, 11, 20, 13, 0),
    );

    final e2 = Expense(
      id: 2,
      userId: 'u1',
      paidBy: 'u2',
      amount: 120.00,
      description: 'Spesa Esselunga',
      type: Tipologia.cibo,
      date: DateTime(2026, 11, 10, 10, 0),
    );

    final e3 = Expense(
      id: 3,
      userId: 'u1',
      paidBy: 'u1',
      amount: 45.00,
      description: 'Bolletta luce',
      type: Tipologia.utenze,
      date: DateTime(2026, 10, 1, 9, 0),
    );

    test('matches default empty criteria', () {
      const criteria = ExpenseFilterCriteria();
      expect(criteria.isEmpty, isTrue);
      expect(criteria.activeFilterCount, equals(0));
      expect(criteria.matches(e1), isTrue);
      expect(criteria.matches(e2), isTrue);
      expect(criteria.matches(e3), isTrue);
    });

    test('filters by selected categories (multi-category)', () {
      final criteria = const ExpenseFilterCriteria().copyWith(
        categories: {Tipologia.ristorante, Tipologia.utenze},
      );
      expect(criteria.isEmpty, isFalse);
      expect(criteria.activeFilterCount, equals(1));
      expect(criteria.matches(e1), isTrue);
      expect(criteria.matches(e2), isFalse);
      expect(criteria.matches(e3), isTrue);
    });

    test('filters by search query case-insensitively', () {
      final criteria = const ExpenseFilterCriteria().copyWith(searchQuery: 'esselunga');
      expect(criteria.activeFilterCount, equals(1));
      expect(criteria.matches(e1), isFalse);
      expect(criteria.matches(e2), isTrue);
    });

    test('filters by payer', () {
      final criteria = const ExpenseFilterCriteria().copyWith(paidByUserId: 'u2');
      expect(criteria.activeFilterCount, equals(1));
      expect(criteria.matches(e1), isFalse);
      expect(criteria.matches(e2), isTrue);
    });

    test('filters by amount range', () {
      final criteria = const ExpenseFilterCriteria().copyWith(
        minAmount: 20.0,
        maxAmount: 100.0,
      );
      expect(criteria.activeFilterCount, equals(1));
      expect(criteria.matches(e1), isFalse);
      expect(criteria.matches(e2), isFalse);
      expect(criteria.matches(e3), isTrue);
    });

    test('filters by date range', () {
      final criteria = const ExpenseFilterCriteria().copyWith(
        dateRange: DateTimeRange(
          start: DateTime(2026, 11, 1),
          end: DateTime(2026, 11, 15),
        ),
      );
      expect(criteria.activeFilterCount, equals(1));
      expect(criteria.matches(e1), isFalse);
      expect(criteria.matches(e2), isTrue);
      expect(criteria.matches(e3), isFalse);
    });
  });
}
