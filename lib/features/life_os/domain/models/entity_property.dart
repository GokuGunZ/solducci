import 'package:equatable/equatable.dart';
import 'package:solducci/features/life_os/domain/models/enums.dart';

/// Data type of an EntityProperty.
enum PropertyType { text, date, number, url }

/// Pure domain representation of a progressive property attached to a [LifeEntity].
class EntityProperty extends Equatable {
  final String key;
  final String label;
  final Object value;
  final PropertyType type;

  const EntityProperty({
    required this.key,
    required this.label,
    required this.value,
    this.type = PropertyType.text,
  });

  /// Returns typed value as [num] if [type] is [PropertyType.number], null if unparseable.
  num? get asNumber {
    if (value is num) return value as num;
    return num.tryParse(value.toString());
  }

  /// Returns typed value as [DateTime] if [type] is [PropertyType.date], null if unparseable.
  DateTime? get asDate {
    if (value is DateTime) return value as DateTime;
    return DateTime.tryParse(value.toString());
  }

  /// String value representation for display / text editing.
  String get displayValue => value.toString();

  EntityProperty copyWith({
    String? key,
    String? label,
    Object? value,
    PropertyType? type,
  }) {
    return EntityProperty(
      key: key ?? this.key,
      label: label ?? this.label,
      value: value ?? this.value,
      type: type ?? this.type,
    );
  }

  /// Returns the canonical JSON representation according to PropertyType (INT-D016):
  /// text   → JSON string
  /// url    → JSON string
  /// date   → ISO-8601 string
  /// number → JSON number
  dynamic get canonicalJsonValue {
    switch (type) {
      case PropertyType.number:
        return asNumber ?? 0;
      case PropertyType.date:
        final d = asDate;
        return d != null ? d.toIso8601String() : value.toString();
      case PropertyType.text:
      case PropertyType.url:
        return value.toString();
    }
  }

  Map<String, dynamic> toJson() => {
        'key': key.trim(),
        'label': label,
        'value': canonicalJsonValue,
        'type': type.name,
      };

  factory EntityProperty.fromJson(Map<String, dynamic> json) {
    final type = PropertyType.values.firstWhere(
      (t) => t.name == json['type'],
      orElse: () => PropertyType.text,
    );
    final rawVal = json['value'];
    Object typedVal;
    switch (type) {
      case PropertyType.number:
        if (rawVal is num) {
          typedVal = rawVal;
        } else if (rawVal != null) {
          typedVal = num.tryParse(rawVal.toString()) ?? 0;
        } else {
          typedVal = 0;
        }
        break;
      case PropertyType.date:
        if (rawVal is String) {
          final parsed = DateTime.tryParse(rawVal);
          typedVal = parsed != null ? parsed.toIso8601String() : rawVal;
        } else if (rawVal is DateTime) {
          typedVal = rawVal.toIso8601String();
        } else {
          typedVal = '';
        }
        break;
      case PropertyType.text:
      case PropertyType.url:
        typedVal = rawVal?.toString() ?? '';
        break;
    }

    return EntityProperty(
      key: (json['key'] as String? ?? '').trim(),
      label: json['label'] as String? ?? '',
      value: typedVal,
      type: type,
    );
  }

  @override
  List<Object?> get props => [key, label, value, type];
}

/// Suggested template from a [RolePropertyPacks].
class PropertyTemplate extends Equatable {
  final String key;
  final String label;
  final String placeholder;
  final PropertyType defaultType;

  const PropertyTemplate({
    required this.key,
    required this.label,
    required this.placeholder,
    this.defaultType = PropertyType.text,
  });

  Map<String, dynamic> toJson() => {
        'key': key,
        'label': label,
        'placeholder': placeholder,
        'type': defaultType.name,
      };

  factory PropertyTemplate.fromJson(Map<String, dynamic> json) => PropertyTemplate(
        key: json['key'] as String? ?? '',
        label: json['label'] as String? ?? '',
        placeholder: json['placeholder'] as String? ?? '',
        defaultType: PropertyType.values.firstWhere(
          (t) => t.name == json['type'],
          orElse: () => PropertyType.text,
        ),
      );

  @override
  List<Object?> get props => [key, label, placeholder, defaultType];
}

/// Suggested, non-prescriptive Property Packs per [SemanticRole].
class RolePropertyPacks {
  static List<PropertyTemplate> getSuggestionsForRole(SemanticRole role) {
    switch (role) {
      case SemanticRole.project:
        return const [
          PropertyTemplate(
            key: 'goal',
            label: 'Obiettivo',
            placeholder: 'Cosa definisce il compimento o il successo?',
          ),
          PropertyTemplate(
            key: 'next_step',
            label: 'Prossimo Passo',
            placeholder: 'Qual è la primissima mossa concreta da compiere?',
          ),
          PropertyTemplate(
            key: 'deadline',
            label: 'Scadenza / Orizzonte',
            placeholder: 'Entro quale orizzonte temporale o data target?',
            defaultType: PropertyType.date,
          ),
        ];

      case SemanticRole.practice:
        return const [
          PropertyTemplate(
            key: 'cadence',
            label: 'Cadenza',
            placeholder: 'Ogni giorno, 3 volte a settimana, weekend...',
          ),
          PropertyTemplate(
            key: 'method',
            label: 'Metodo',
            placeholder: 'Qual è il rituale o la modalità di esecuzione?',
          ),
          PropertyTemplate(
            key: 'metric',
            label: 'Metrica',
            placeholder: 'Durata minima, pagine, ripetizioni...',
          ),
        ];

      case SemanticRole.concept:
        return const [
          PropertyTemplate(
            key: 'understanding',
            label: 'Comprensione Chiave',
            placeholder: 'Qual è l\'intuizione o il principio da ricordare?',
          ),
          PropertyTemplate(
            key: 'open_questions',
            label: 'Domande Aperte',
            placeholder: 'Cosa rimane ancora da chiarire o approfondire?',
          ),
          PropertyTemplate(
            key: 'resources',
            label: 'Fonti / Risorse',
            placeholder: 'Libri, link, articoli o riferimenti cardine.',
            defaultType: PropertyType.url,
          ),
        ];

      case SemanticRole.idea:
        return const [
          PropertyTemplate(
            key: 'spark',
            label: 'Intuizione',
            placeholder: 'Cosa ha acceso questa intuizione?',
          ),
          PropertyTemplate(
            key: 'potential',
            label: 'Potenziale',
            placeholder: 'Quale valore o risvolto futuro potrebbe generare?',
          ),
        ];

      case SemanticRole.seed:
        return const [];
    }
  }
}
