import 'package:hive/hive.dart';

part 'split_type.g.dart';

/// Enum representing how an expense should be split among group members
@HiveType(typeId: 4)
enum SplitType {
  /// Split equally among all group members
  @HiveField(0)
  equal(
    'equal',
    'Equamente tra tutti',
    'Dividi l\'importo equamente tra tutti i membri del gruppo',
  ),

  @HiveField(1)
  lend('lend', 'Presta', 'Chi paga anticipa per tutti e verrà rimborsato'),

  /// Offer - payer offers the expense, no reimbursement
  @HiveField(2)
  offer('offer', 'Offri', 'Chi paga offre la spesa, nessun rimborso'),

  /// Custom split with specific amounts per member
  @HiveField(3)
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
