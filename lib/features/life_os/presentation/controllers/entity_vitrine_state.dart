import 'package:equatable/equatable.dart';
import 'package:solducci/features/life_os/domain/models/models.dart';

enum VitrineStatus { initial, loading, success, failure }

/// Human-centered operational intentions (Amendment C: hide ontology behind human intentions)
enum HumanIntention {
  explore,
  treatAsProject,
  cultivatePractice,
  organizeKnowledge,
  keepAsSeed,
}

class EntityVitrineState extends Equatable {
  final VitrineStatus status;
  final LifeEntity? entity;
  final UserEntityOverlay? overlay;
  final List<EntityRelation> relations;
  final bool isSaving;
  final String? errorMessage;
  final String? successMessage;

  const EntityVitrineState({
    this.status = VitrineStatus.initial,
    this.entity,
    this.overlay,
    this.relations = const [],
    this.isSaving = false,
    this.errorMessage,
    this.successMessage,
  });

  bool get isLoading => status == VitrineStatus.loading;
  bool get hasError => errorMessage != null;

  EntityVitrineState copyWith({
    VitrineStatus? status,
    LifeEntity? entity,
    UserEntityOverlay? overlay,
    List<EntityRelation>? relations,
    bool? isSaving,
    String? Function()? errorMessage,
    String? Function()? successMessage,
  }) {
    return EntityVitrineState(
      status: status ?? this.status,
      entity: entity ?? this.entity,
      overlay: overlay ?? this.overlay,
      relations: relations ?? this.relations,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      successMessage: successMessage != null ? successMessage() : this.successMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        entity,
        overlay,
        relations,
        isSaving,
        errorMessage,
        successMessage,
      ];
}
