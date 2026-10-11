import 'package:solducci/models/expense.dart';
import 'package:solducci/models/expense_form.dart';
import 'package:solducci/models/income_category.dart';
import 'package:solducci/models/split_type.dart';

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
  Tipologia category; // Categoria spesa
  IncomeCategory incomeCategory; // Categoria entrata (se isIncome == true)
  bool isSelected;

  // Contesto di spesa (Personale vs Gruppo)
  String? groupId; // null = Personale (default)
  SplitType splitType; // default SplitType.equal se groupId != null
  Map<String, double>? customSplitData; // Se personalizzato tramite Volume Slider

  // Contesto Investimenti (se category == Tipologia.investimento o incomeCategory == IncomeCategory.rendita)
  String? portfolioId;
  String? assetId; // Opzionale se associato a un asset specifico per rendite/dividendi

  String? walletId; // Opzionale se assegnato a un conto specifico
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
    this.incomeCategory = IncomeCategory.altro,
    this.isSelected = true,
    this.groupId,
    this.walletId,
    this.splitType = SplitType.equal,
    this.customSplitData,
    this.portfolioId,
    this.assetId,
    this.duplicateStatus = DuplicateStatus.none,
    this.matchedExistingExpense,
    this.amountDifference,
  });

  bool get isDuplicate => duplicateStatus != DuplicateStatus.none;
  bool get isGroup => groupId != null;
  bool get isPersonal => groupId == null;

  StagingTransaction copyWith({
    String? cleanDescription,
    Tipologia? category,
    IncomeCategory? incomeCategory,
    bool? isSelected,
    String? groupId,
    bool clearGroupId = false,
    String? walletId,
    bool clearWalletId = false,
    SplitType? splitType,
    Map<String, double>? customSplitData,
    bool clearCustomSplitData = false,
    String? portfolioId,
    bool clearPortfolioId = false,
    String? assetId,
    bool clearAssetId = false,
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
      incomeCategory: incomeCategory ?? this.incomeCategory,
      isSelected: isSelected ?? this.isSelected,
      groupId: clearGroupId ? null : (groupId ?? this.groupId),
      walletId: clearWalletId ? null : (walletId ?? this.walletId),
      splitType: splitType ?? this.splitType,
      customSplitData: clearCustomSplitData ? null : (customSplitData ?? this.customSplitData),
      portfolioId: clearPortfolioId ? null : (portfolioId ?? this.portfolioId),
      assetId: clearAssetId ? null : (assetId ?? this.assetId),
      duplicateStatus: duplicateStatus ?? this.duplicateStatus,
      matchedExistingExpense: matchedExistingExpense ?? this.matchedExistingExpense,
      amountDifference: amountDifference ?? this.amountDifference,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'amount': amount,
      'isIncome': isIncome,
      'rawDescription': rawDescription,
      'cleanDescription': cleanDescription,
      'category': category.name,
      'incomeCategory': incomeCategory.name,
      'isSelected': isSelected,
      'groupId': groupId,
      'walletId': walletId,
      'splitType': splitType.value,
      'customSplitData': customSplitData,
      'portfolioId': portfolioId,
      'assetId': assetId,
      'duplicateStatus': duplicateStatus.name,
      'amountDifference': amountDifference,
      if (matchedExistingExpense != null)
        'matchedExistingExpense': matchedExistingExpense!.toMap(),
    };
  }

  factory StagingTransaction.fromMap(Map<String, dynamic> map) {
    final catStr = map['category'] as String?;
    final parsedCategory = Tipologia.values.firstWhere(
      (t) => t.name == catStr || t.label == catStr,
      orElse: () => Tipologia.altro,
    );

    final incCatStr = map['incomeCategory'] as String?;
    final parsedIncomeCategory = IncomeCategory.values.firstWhere(
      (c) => c.name == incCatStr,
      orElse: () => IncomeCategory.altro,
    );

    final dupStr = map['duplicateStatus'] as String?;
    final parsedDuplicate = DuplicateStatus.values.firstWhere(
      (d) => d.name == dupStr,
      orElse: () => DuplicateStatus.none,
    );

    final splitTypeStr = map['splitType'] as String?;
    final parsedSplitType = splitTypeStr != null
        ? SplitType.fromValue(splitTypeStr)
        : SplitType.equal;

    Map<String, double>? parsedCustomSplit;
    if (map['customSplitData'] is Map) {
      parsedCustomSplit = {};
      (map['customSplitData'] as Map).forEach((k, v) {
        if (v is num) {
          parsedCustomSplit![k.toString()] = v.toDouble();
        }
      });
    }

    Expense? matchedExp;
    if (map['matchedExistingExpense'] is Map<String, dynamic>) {
      try {
        matchedExp = Expense.fromMap(map['matchedExistingExpense'] as Map<String, dynamic>);
      } catch (_) {}
    }

    return StagingTransaction(
      id: map['id'] as String? ?? '',
      date: DateTime.tryParse(map['date'] as String? ?? '') ?? DateTime.now(),
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      isIncome: map['isIncome'] as bool? ?? false,
      rawDescription: map['rawDescription'] as String? ?? '',
      cleanDescription: map['cleanDescription'] as String? ?? '',
      category: parsedCategory,
      incomeCategory: parsedIncomeCategory,
      isSelected: map['isSelected'] as bool? ?? true,
      groupId: map['groupId'] as String?,
      walletId: map['walletId'] as String?,
      splitType: parsedSplitType,
      customSplitData: parsedCustomSplit,
      portfolioId: map['portfolioId'] as String?,
      assetId: map['assetId'] as String?,
      duplicateStatus: parsedDuplicate,
      matchedExistingExpense: matchedExp,
      amountDifference: (map['amountDifference'] as num?)?.toDouble(),
    );
  }
}

