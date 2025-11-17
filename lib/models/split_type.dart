/// Enum representing how an expense should be split among group members
enum SplitType {
  /// Split equally among all group members
  equal(
    'equal',
    'Equamente tra tutti',
    'Dividi l\'importo equamente tra tutti i membri del gruppo',
  ),

  lend('lend', 'Presta', 'Chi paga anticipa per tutti e verrà rimborsato'),

  /// Offer - payer offers the expense, no reimbursement
  offer('offer', 'Offri', 'Chi paga offre la spesa, nessun rimborso'),

  /// Custom split with specific amounts per member
  custom(
    'custom',
    'Importi custom',
    'Specifica quanto deve pagare ogni membro',
  );

  /// Lend - payer advances for all and gets reimbursed by everyone

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
      case SplitType.lend:
        return '💸';
      case SplitType.offer:
        return '🎁';
    }
  }
}
