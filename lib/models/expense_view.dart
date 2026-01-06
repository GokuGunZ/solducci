import 'package:solducci/models/group.dart';
import 'package:uuid/uuid.dart';

/// Vista personalizzata: unione di più gruppi per visualizzare spese aggregate
/// Le viste sono salvate solo localmente (SharedPreferences), non su Supabase
class ExpenseView {
  final String id; // UUID generato localmente
  String name;
  String? description;
  final List<String> groupIds; // IDs dei gruppi Supabase
  bool includePersonal; // Preferenza locale: include anche spese personali?
  final DateTime createdAt;
  DateTime updatedAt;

  // Denormalizzato per UI (non salvato in JSON)
  List<ExpenseGroup>? groups;

  ExpenseView({
    required this.id,
    required this.name,
    this.description,
    required this.groupIds,
    this.includePersonal = false,
    required this.createdAt,
    required this.updatedAt,
    this.groups,
  });

  /// Factory per creare nuova vista con ID generato
  factory ExpenseView.create({
    required String name,
    String? description,
    required List<String> groupIds,
    bool includePersonal = false,
  }) {
    final now = DateTime.now();
    return ExpenseView(
      id: const Uuid().v4(),
      name: name,
      description: description,
      groupIds: groupIds,
      includePersonal: includePersonal,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Serializzazione JSON per storage locale
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'groupIds': groupIds,
        'includePersonal': includePersonal,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  /// Deserializzazione JSON da storage locale
  factory ExpenseView.fromJson(Map<String, dynamic> json) {
    return ExpenseView(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      groupIds: (json['groupIds'] as List).cast<String>(),
      includePersonal: json['includePersonal'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Crea copia con campi modificati
  ExpenseView copyWith({
    String? name,
    String? description,
    List<String>? groupIds,
    bool? includePersonal,
  }) {
    return ExpenseView(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      groupIds: groupIds ?? this.groupIds,
      includePersonal: includePersonal ?? this.includePersonal,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  /// Ottieni tutti i gruppi unici da una lista di viste (flatten hierarchy)
  static List<String> flattenGroupIds(List<ExpenseView> views) {
    final allIds = <String>{};
    for (final view in views) {
      allIds.addAll(view.groupIds);
    }
    return allIds.toList();
  }

  /// Verifica se la vista contiene un gruppo specifico
  bool containsGroup(String groupId) {
    return groupIds.contains(groupId);
  }

  /// Conteggio gruppi nella vista
  int get groupCount => groupIds.length;

  @override
  String toString() {
    return 'ExpenseView(id: $id, name: $name, groups: ${groupIds.length}, includePersonal: $includePersonal)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExpenseView && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
