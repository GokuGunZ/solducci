import 'package:equatable/equatable.dart';
import 'package:solducci/features/life_os/domain/models/enums.dart';

/// Data type of an EntityProperty.
enum PropertyType { text, date, number, url }

/// Pure domain representation of a progressive property attached to a [LifeEntity].
class EntityProperty extends Equatable {
  final String key;
  final String label;
  final String value;
  final PropertyType type;

  const EntityProperty({
    required this.key,
    required this.label,
    required this.value,
    this.type = PropertyType.text,
  });

  EntityProperty copyWith({
    String? key,
    String? label,
    String? value,
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
        return num.tryParse(value) ?? value;
      case PropertyType.date:
        final parsed = DateTime.tryParse(value);
        return parsed != null ? parsed.toIso8601String() : value;
      case PropertyType.text:
      case PropertyType.url:
        return value;
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
    String valStr = '';
    if (rawVal != null) {
      if (type == PropertyType.date && rawVal is String) {
        valStr = DateTime.tryParse(rawVal)?.toIso8601String() ?? rawVal;
      } else {
        valStr = rawVal.toString();
      }
    }

    return EntityProperty(
      key: (json['key'] as String? ?? '').trim(),
      label: json['label'] as String? ?? '',
      value: valStr,
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
