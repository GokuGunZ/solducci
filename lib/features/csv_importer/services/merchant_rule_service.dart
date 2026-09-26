import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solducci/features/csv_importer/models/merchant_rule.dart';
import 'package:solducci/features/csv_importer/models/staging_transaction.dart';
import 'package:solducci/models/expense_form.dart';

class MerchantRuleService {
  static final MerchantRuleService _instance = MerchantRuleService._internal();
  factory MerchantRuleService() => _instance;
  MerchantRuleService._internal();

  static const String _prefKey = 'solducci_merchant_rules_v1';
  List<MerchantRule>? _cachedRules;

  /// Inizializza o carica le regole memorizzate, integrando i default se vuoto
  Future<List<MerchantRule>> getRules() async {
    if (_cachedRules != null) return _cachedRules!;

    final prefs = await SharedPreferences.getInstance();
    final rawJson = prefs.getString(_prefKey);

    if (rawJson != null && rawJson.isNotEmpty) {
      try {
        final List decoded = jsonDecode(rawJson) as List;
        _cachedRules = decoded
            .map((item) => MerchantRule.fromMap(item as Map<String, dynamic>))
            .toList();
      } catch (_) {
        _cachedRules = List.from(MerchantRule.defaultRules);
      }
    } else {
      _cachedRules = List.from(MerchantRule.defaultRules);
      await _persist();
    }

    return _cachedRules!;
  }

  /// Salva o aggiorna una regola e la persiste
  Future<void> saveRule(MerchantRule rule) async {
    final rules = await getRules();
    final existingIndex = rules.indexWhere(
      (r) => r.id == rule.id || r.pattern.toLowerCase() == rule.pattern.toLowerCase(),
    );

    if (existingIndex >= 0) {
      rules[existingIndex] = rule;
    } else {
      rules.insert(0, rule);
    }

    _cachedRules = rules;
    await _persist();
  }

  /// Elimina una regola memorizzata
  Future<void> deleteRule(String ruleId) async {
    final rules = await getRules();
    rules.removeWhere((r) => r.id == ruleId);
    _cachedRules = rules;
    await _persist();
  }

  /// Ripristina le regole predefinite di default
  Future<void> resetToDefaults() async {
    _cachedRules = List.from(MerchantRule.defaultRules);
    await _persist();
  }

  /// Trova la regola corrispondente a una descrizione grezza
  MerchantRule? findMatchingRule(String rawDescription, List<MerchantRule> rules) {
    for (final rule in rules) {
      if (rule.matches(rawDescription)) {
        return rule;
      }
    }
    return null;
  }

  /// Pulisce le stringhe bancarie rimuovendo timestamp e codici operazione comuni
  String cleanRawDescription(String raw) {
    var cleaned = raw;

    // Rimuovi prefissi bancari standard (POS, PAGAMENTO CARTA, BONIFICO, ETC.)
    cleaned = cleaned.replaceAll(
      RegExp(
        r'^(PAGAMENTO\s+(POS|CARTA|BANCOMAT)|DISPOSIZIONE\s+DI\s+BONIFICO|ACCREDITO|COMMISSIONI|PRELIEVO\s+ATM)\b',
        caseSensitive: false,
      ),
      '',
    );

    // Rimuovi timestamp e orari tipo "24/09/2026 14:32" o "ORE 18.30"
    cleaned = cleaned.replaceAll(
      RegExp(r'\b\d{2}[/-]\d{2}([/-]\d{2,4})?\b'),
      '',
    );
    cleaned = cleaned.replaceAll(
      RegExp(r'\b(ORE\s+)?\d{1,2}[:.]\d{2}\b', caseSensitive: false),
      '',
    );

    // Rimuovi parole come "ESERCENTE:", "TERMINALE:", "COD.", "PRESSO"
    cleaned = cleaned.replaceAll(
      RegExp(r'\b(ESERCENTE|TERMINALE|COD|C\.COMM|PRESSO|DEL)\b[:.]?', caseSensitive: false),
      '',
    );

    // Rimuovi numeri isolati lunghi (codici terminale o scontrino)
    cleaned = cleaned.replaceAll(RegExp(r'\b\d{4,}\b'), '');

    // Rimuovi spazi multipli e trim
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (cleaned.isEmpty) {
      return raw.trim();
    }

    // Capitalizza la prima lettera di ogni parola
    return cleaned
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}' : '')
        .join(' ');
  }

  /// Applica le regole note ad una lista di transazioni grezze
  Future<void> enrichWithRules(List<StagingTransaction> transactions) async {
    final rules = await getRules();

    for (final tx in transactions) {
      final matchedRule = findMatchingRule(tx.rawDescription, rules);
      if (matchedRule != null) {
        tx.cleanDescription = matchedRule.cleanName;
        tx.category = matchedRule.defaultCategory;
      } else {
        tx.cleanDescription = cleanRawDescription(tx.rawDescription);
      }
    }
  }

  /// Aggiorna in blocco tutte le transazioni simili nel file corrente
  int applyRuleToSimilarTransactions({
    required List<StagingTransaction> transactions,
    required String pattern,
    required String cleanName,
    required Tipologia category,
  }) {
    var count = 0;
    final p = pattern.toLowerCase().trim();

    for (final tx in transactions) {
      if (tx.rawDescription.toLowerCase().contains(p) ||
          tx.cleanDescription.toLowerCase().contains(p)) {
        tx.cleanDescription = cleanName;
        tx.category = category;
        count++;
      }
    }

    return count;
  }

  Future<void> _persist() async {
    if (_cachedRules == null) return;
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_cachedRules!.map((r) => r.toMap()).toList());
    await prefs.setString(_prefKey, encoded);
  }
}
