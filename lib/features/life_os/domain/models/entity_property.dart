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

  Map<String, dynamic> toJson() => {
        'key': key,
        'label': label,
        'value': value,
        'type': type.name,
      };

  factory EntityProperty.fromJson(Map<String, dynamic> json) {
    return EntityProperty(
      key: json['key'] as String? ?? '',
      label: json['label'] as String? ?? '',
      value: json['value']?.toString() ?? '',
      type: PropertyType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => PropertyType.text,
      ),
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
