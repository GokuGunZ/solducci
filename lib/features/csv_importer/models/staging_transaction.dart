import 'package:solducci/models/expense.dart';
import 'package:solducci/models/expense_form.dart';

enum DuplicateStatus {
  none,       // Nessuna corrispondenza: nuova spesa
  exactMatch, // Data identica e importo identico al centesimo
  fuzzyMatch, // Data entro +-2 giorni e importo entro +-0.09 €
}

class StagingTransaction {
  final String id;
  final DateTime date;
  final double amount; // Sempre positivo
  final bool isIncome; // true se accredito/stipendio, false se spesa
  final String rawDescription;

  String cleanDescription;
  Tipologia category;
  bool isSelected;

  DuplicateStatus duplicateStatus;
  Expense? matchedExistingExpense;
  double? amountDifference; // Per fuzzy match (+-0.09 €)

  StagingTransaction({
    required this.id,
    required this.date,
    required this.amount,
    required this.isIncome,
    required this.rawDescription,
    required this.cleanDescription,
    required this.category,
    this.isSelected = true,
    this.duplicateStatus = DuplicateStatus.none,
    this.matchedExistingExpense,
    this.amountDifference,
  });

  bool get isDuplicate => duplicateStatus != DuplicateStatus.none;

  StagingTransaction copyWith({
    String? cleanDescription,
    Tipologia? category,
    bool? isSelected,
    DuplicateStatus? duplicateStatus,
    Expense? matchedExistingExpense,
    double? amountDifference,
  }) {
    return StagingTransaction(
      id: id,
      date: date,
      amount: amount,
      isIncome: isIncome,
      rawDescription: rawDescription,
      cleanDescription: cleanDescription ?? this.cleanDescription,
      category: category ?? this.category,
      isSelected: isSelected ?? this.isSelected,
      duplicateStatus: duplicateStatus ?? this.duplicateStatus,
      matchedExistingExpense: matchedExistingExpense ?? this.matchedExistingExpense,
      amountDifference: amountDifference ?? this.amountDifference,
    );
  }
}
