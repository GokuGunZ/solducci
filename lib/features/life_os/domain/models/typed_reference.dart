import 'package:equatable/equatable.dart';
import 'package:solducci/features/life_os/domain/models/enums.dart';

/// A polymorphic reference pointing to an external or internal target entity.
/// In Living Core v0.1, targets are constrained to [TargetType].
class TypedReference extends Equatable {
  final TargetType targetType;
  final String targetId;
  final String? title;
  final String? subtitle;

  const TypedReference({
    required this.targetType,
    required this.targetId,
    this.title,
    this.subtitle,
  });

  @override
  List<Object?> get props => [targetType, targetId, title, subtitle];
}
