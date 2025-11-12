/// Enum representing how an expense should be split among group members
enum SplitType {
  /// Split equally among all group members
  equal('equal', 'Equamente tra tutti', 'Dividi l\'importo equamente tra tutti i membri del gruppo'),

  /// Custom split with specific amounts per member
  custom('custom', 'Importi custom', 'Specifica quanto deve pagare ogni membro'),

  /// One person pays the full amount (no split)
  full('full', 'Una persona paga tutto', 'Un solo membro paga l\'intera spesa'),

  /// No split - group expense but not divided
  none('none', 'Non dividere', 'Spesa di gruppo ma non divisa tra membri');

  const SplitType(this.value, this.label, this.description);

  final String value;
  final String label;
  final String description;

  /// Get SplitType from database value
  static SplitType fromValue(String value) {
    return SplitType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => SplitType.equal,
    );
  }

  /// Get icon for split type
  String get icon {
    switch (this) {
      case SplitType.equal:
        return '⚖️';
      case SplitType.custom:
        return '✏️';
      case SplitType.full:
        return '💰';
      case SplitType.none:
        return '🚫';
    }
  }
}
