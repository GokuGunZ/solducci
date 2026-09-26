import 'package:solducci/models/expense_form.dart';

class MerchantRule {
  final String id;
  final String pattern; // Stringa cercata nella causale (case-insensitive o regex)
  final String cleanName; // Nome pulito dell'esercente (es. "Conad", "Amazon")
  final Tipologia defaultCategory;
  final bool isRegex;
  final DateTime createdAt;

  MerchantRule({
    required this.id,
    required this.pattern,
    required this.cleanName,
    required this.defaultCategory,
    this.isRegex = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool matches(String rawDescription) {
    if (isRegex) {
      try {
        return RegExp(pattern, caseSensitive: false).hasMatch(rawDescription);
      } catch (_) {
        return false;
      }
    }
    return rawDescription.toLowerCase().contains(pattern.toLowerCase());
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'pattern': pattern,
    'cleanName': cleanName,
    'defaultCategory': defaultCategory.name,
    'isRegex': isRegex,
    'createdAt': createdAt.toIso8601String(),
  };

  factory MerchantRule.fromMap(Map<String, dynamic> map) => MerchantRule(
    id: map['id'] as String,
    pattern: map['pattern'] as String,
    cleanName: map['cleanName'] as String,
    defaultCategory: Tipologia.values.firstWhere(
      (e) => e.name == map['defaultCategory'],
      orElse: () => Tipologia.altro,
    ),
    isRegex: map['isRegex'] as bool? ?? false,
    createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
  );

  // Regole predefinite out-of-the-box per l'Italia
  static List<MerchantRule> get defaultRules => [
    MerchantRule(
      id: 'rule_esselunga',
      pattern: 'esselunga',
      cleanName: 'Esselunga',
      defaultCategory: Tipologia.cibo,
    ),
    MerchantRule(
      id: 'rule_conad',
      pattern: 'conad',
      cleanName: 'Conad',
      defaultCategory: Tipologia.cibo,
    ),
    MerchantRule(
      id: 'rule_coop',
      pattern: 'coop',
      cleanName: 'Coop',
      defaultCategory: Tipologia.cibo,
    ),
    MerchantRule(
      id: 'rule_carrefour',
      pattern: 'carrefour',
      cleanName: 'Carrefour',
      defaultCategory: Tipologia.cibo,
    ),
    MerchantRule(
      id: 'rule_lidl',
      pattern: 'lidl',
      cleanName: 'Lidl',
      defaultCategory: Tipologia.cibo,
    ),
    MerchantRule(
      id: 'rule_mcdonald',
      pattern: 'mcdonald',
      cleanName: "McDonald's",
      defaultCategory: Tipologia.ristorante,
    ),
    MerchantRule(
      id: 'rule_burger_king',
      pattern: 'burger king',
      cleanName: 'Burger King',
      defaultCategory: Tipologia.ristorante,
    ),
    MerchantRule(
      id: 'rule_bar',
      pattern: 'pasticceria',
      cleanName: 'Bar / Pasticceria',
      defaultCategory: Tipologia.ristorante,
    ),
    MerchantRule(
      id: 'rule_netflix',
      pattern: 'netflix',
      cleanName: 'Netflix',
      defaultCategory: Tipologia.tempoLibero,
    ),
    MerchantRule(
      id: 'rule_spotify',
      pattern: 'spotify',
      cleanName: 'Spotify',
      defaultCategory: Tipologia.tempoLibero,
    ),
    MerchantRule(
      id: 'rule_amazon',
      pattern: 'amazon',
      cleanName: 'Amazon',
      defaultCategory: Tipologia.tempoLibero,
    ),
    MerchantRule(
      id: 'rule_eni',
      pattern: 'eni station',
      cleanName: 'Eni Station',
      defaultCategory: Tipologia.altro,
    ),
    MerchantRule(
      id: 'rule_q8',
      pattern: 'q8',
      cleanName: 'Q8 Rifornimento',
      defaultCategory: Tipologia.altro,
    ),
    MerchantRule(
      id: 'rule_farmacia',
      pattern: 'farmacia',
      cleanName: 'Farmacia',
      defaultCategory: Tipologia.prodottiCasa,
    ),
    MerchantRule(
      id: 'rule_enel',
      pattern: 'enel',
      cleanName: 'Enel Energia',
      defaultCategory: Tipologia.utenze,
    ),
  ];
}
