import 'package:solducci/features/csv_importer/models/staging_transaction.dart';
import 'package:solducci/models/expense.dart';
import 'package:solducci/service/expense_service_cached.dart';

class DeduplicationService {
  static final DeduplicationService _instance = DeduplicationService._internal();
  factory DeduplicationService() => _instance;
  DeduplicationService._internal();

  /// Esegue la deduplicazione intelligente a 3 livelli:
  /// 1. Esatto: stessa data e importo identico al centesimo (differenza < 0.005)
  /// 2. Fuzzy: data +-2 giorni e importo +-0.09 €
  /// 3. Nessuno: nuova spesa
  Future<void> runDeduplication(List<StagingTransaction> transactions) async {
    // Recupera tutte le spese memorizzate in cache o dal backend
    var existingExpenses = ExpenseServiceCached().getAllCachedExpenses();
    if (existingExpenses.isEmpty) {
      existingExpenses = await ExpenseServiceCached().fetchAll();
    }

    for (final tx in transactions) {
      if (tx.isIncome) {
        // Al momento Solducci traccia prevalentemente spese (amount negativi o uscite)
        continue;
      }

      Expense? exactMatch;
      Expense? fuzzyMatch;
      double minAmountDiff = 999999.0;

      for (final exp in existingExpenses) {
        final daysDiff = (tx.date.difference(exp.date).inDays).abs();
        final amountDiff = (tx.amount - exp.amount).abs();

        // 1. Controllo Match Esatto: data identica e stesso importo
        final isSameDate = tx.date.year == exp.date.year &&
            tx.date.month == exp.date.month &&
            tx.date.day == exp.date.day;

        if (isSameDate && amountDiff < 0.005) {
          exactMatch = exp;
          break; // Match esatto trovato
        }

        // 2. Controllo Match Fuzzy: +-2 giorni e +-0.09 €
        if (daysDiff <= 2 && amountDiff <= 0.091) {
          if (amountDiff < minAmountDiff) {
            minAmountDiff = amountDiff;
            fuzzyMatch = exp;
          }
        }
      }

      if (exactMatch != null) {
        tx.duplicateStatus = DuplicateStatus.exactMatch;
        tx.matchedExistingExpense = exactMatch;
        tx.amountDifference = 0.0;
        tx.isSelected = false; // Deselezionato di default per evitare duplicati
      } else if (fuzzyMatch != null) {
        tx.duplicateStatus = DuplicateStatus.fuzzyMatch;
        tx.matchedExistingExpense = fuzzyMatch;
        tx.amountDifference = tx.amount - fuzzyMatch.amount;
        tx.isSelected = false; // Richiede verifica da parte dell'utente
      } else {
        tx.duplicateStatus = DuplicateStatus.none;
        tx.isSelected = true; // Selezionata come nuova spesa
      }
    }
  }
}
