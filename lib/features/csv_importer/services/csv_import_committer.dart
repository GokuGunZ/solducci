import 'package:solducci/features/csv_importer/models/staging_transaction.dart';
import 'package:solducci/models/expense.dart';
import 'package:solducci/models/income.dart';
import 'package:solducci/models/income_category.dart';
import 'package:solducci/models/split_type.dart';
import 'package:solducci/service/expense_service_cached.dart';
import 'package:solducci/service/group_service_cached.dart';
import 'package:solducci/service/income_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CsvImportCommitter {
  static final CsvImportCommitter _instance = CsvImportCommitter._internal();
  factory CsvImportCommitter() => _instance;
  CsvImportCommitter._internal();

  final _supabase = Supabase.instance.client;

  /// Inserisce in blocco tutte le transazioni selezionate in Solducci:
  /// - Spese (isIncome == false) nella tabella `expenses`
  /// - Accrediti/Entrate (isIncome == true) nella tabella `incomes`
  /// Assegna il walletId selezionato a tutti i movimenti creati.
  /// Se una spesa appartiene a un gruppo, genera automaticamente gli `expense_splits`.
  Future<int> commitTransactions(
    List<StagingTransaction> transactions, {
    String? walletId,
  }) async {
    final selected = transactions.where((t) => t.isSelected).toList();
    if (selected.isEmpty) return 0;

    final currentUserId = _supabase.auth.currentUser?.id;

    final expensesToInsert = <Map<String, dynamic>>[];
    final incomesToInsert = <Map<String, dynamic>>[];

    for (final t in selected) {
      if (t.isIncome) {
        // Categoria intelligente per entrate basata su parole chiave
        final rawLower = t.rawDescription.toLowerCase();
        IncomeCategory cat = IncomeCategory.altro;
        if (rawLower.contains('stipendio') ||
            rawLower.contains('emolumenti') ||
            rawLower.contains('retribuz') ||
            rawLower.contains('salary')) {
          cat = IncomeCategory.stipendio;
        } else if (rawLower.contains('rimborso') || rawLower.contains('refund')) {
          cat = IncomeCategory.rimborso;
        } else if (rawLower.contains('regalo') || rawLower.contains('gift')) {
          cat = IncomeCategory.regalo;
        } else if (rawLower.contains('dividendo') ||
            rawLower.contains('cedola') ||
            rawLower.contains('interessi')) {
          cat = IncomeCategory.rendita;
        }

        final income = Income(
          id: '',
          userId: currentUserId ?? '',
          walletId: walletId,
          amount: t.amount,
          description: t.cleanDescription.isNotEmpty ? t.cleanDescription : t.rawDescription,
          date: t.date,
          category: cat,
        );
        final map = income.toMap();
        map.remove('id'); // Generato da Supabase UUID
        incomesToInsert.add(map);
      } else {
        final expense = Expense(
          id: -1, // Supabase assegnerà il sequence ID
          description: t.cleanDescription,
          amount: t.amount,
          date: t.date,
          type: t.category,
          userId: currentUserId,
          walletId: walletId,
          groupId: t.groupId,
          portfolioId: t.portfolioId,
          paidBy: t.groupId != null ? currentUserId : null,
          splitType: t.groupId != null ? t.splitType : null,
          splitData: t.groupId != null ? t.customSplitData : null,
        );
        expensesToInsert.add(expense.toMap());
      }
    }

    // Inserimento batch in Supabase per le spese (blocchi da 50 per sicurezza)
    const chunkSize = 50;
    for (var i = 0; i < expensesToInsert.length; i += chunkSize) {
      final end = (i + chunkSize < expensesToInsert.length)
          ? i + chunkSize
          : expensesToInsert.length;
      final chunk = expensesToInsert.sublist(i, end);
      
      final insertedRows = await _supabase.from('expenses').insert(chunk).select();

      // Per ciascuna spesa di gruppo inserita, creiamo i record di ripartizione in expense_splits
      for (final row in insertedRows) {
        final gId = row['group_id'] as String?;
        if (gId != null) {
          final expId = row['id'] as int;
          final splitTypeStr = row['split_type'] as String?;
          final splitType = splitTypeStr != null ? SplitType.fromValue(splitTypeStr) : SplitType.equal;
          final amt = (row['amount'] as num).toDouble();
          final payerId = row['paid_by'] as String? ?? currentUserId ?? '';

          final members = await GroupServiceCached().getGroupMembers(gId);
          if (members.isNotEmpty) {
            final splits = <Map<String, dynamic>>[];
            if (splitType == SplitType.equal) {
              final perPerson = amt / members.length;
              final rounded = double.parse(perPerson.toStringAsFixed(2));
              for (final m in members) {
                splits.add({
                  'expense_id': expId,
                  'user_id': m.userId,
                  'amount': rounded,
                  'is_paid': m.userId == payerId,
                });
              }
            } else if (splitType == SplitType.custom && row['split_data'] != null) {
              final customMap = row['split_data'] as Map;
              customMap.forEach((uId, val) {
                final numVal = (val as num).toDouble();
                if (numVal > 0) {
                  splits.add({
                    'expense_id': expId,
                    'user_id': uId.toString(),
                    'amount': numVal,
                    'is_paid': uId.toString() == payerId,
                  });
                }
              });
            }

            if (splits.isNotEmpty) {
              try {
                await _supabase.from('expense_splits').insert(splits);
              } catch (_) {
                // Ignore split insert errors if already present
              }
            }
          }
        }
      }
    }

    // Inserimento batch in Supabase per le entrate
    for (var i = 0; i < incomesToInsert.length; i += chunkSize) {
      final end = (i + chunkSize < incomesToInsert.length)
          ? i + chunkSize
          : incomesToInsert.length;
      final chunk = incomesToInsert.sublist(i, end);
      await _supabase.from('incomes').insert(chunk);
    }

    // Forza il rinfresco delle cache e degli stream di Solducci
    if (expensesToInsert.isNotEmpty) {
      ExpenseServiceCached().invalidateCache();
    }
    if (incomesToInsert.isNotEmpty) {
      await IncomeService().fetchIncomes();
    }

    return selected.length;
  }

  /// Allinea una spesa già esistente all'importo esatto al centesimo della banca
  Future<void> alignExistingExpense(StagingTransaction tx) async {
    if (tx.matchedExistingExpense == null) return;

    final updated = tx.matchedExistingExpense!.copyWith(
      amount: tx.amount,
      description: tx.cleanDescription.isNotEmpty
          ? tx.cleanDescription
          : tx.matchedExistingExpense!.description,
    );

    await ExpenseServiceCached().updateExpense(updated);
  }
}
