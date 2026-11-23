import 'package:equatable/equatable.dart';
import 'package:solducci/features/life_os/domain/models/enums.dart';

/// Represents an entity referenced via '@' inside a seed capture.
class SeedMention extends Equatable {
  final String entityId;
  final String entityTitle;
  final SemanticRole role;
  final RelationType relationType;
  final bool isLeadingTag;

  const SeedMention({
    required this.entityId,
    required this.entityTitle,
    required this.role,
    required this.relationType,
    required this.isLeadingTag,
  });

  bool get isChildRelation => relationType == RelationType.partOf;

  SeedMention copyWith({
    String? entityId,
    String? entityTitle,
    SemanticRole? role,
    RelationType? relationType,
    bool? isLeadingTag,
  }) {
    return SeedMention(
      entityId: entityId ?? this.entityId,
      entityTitle: entityTitle ?? this.entityTitle,
      role: role ?? this.role,
      relationType: relationType ?? this.relationType,
      isLeadingTag: isLeadingTag ?? this.isLeadingTag,
    );
  }

  @override
  List<Object?> get props => [
        entityId,
        entityTitle,
        role,
        relationType,
        isLeadingTag,
      ];
}
