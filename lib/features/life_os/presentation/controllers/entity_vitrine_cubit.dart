import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solducci/features/life_os/domain/models/models.dart';
import 'package:solducci/features/life_os/domain/repositories/repositories.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'entity_vitrine_state.dart';

class EntityVitrineCubit extends Cubit<EntityVitrineState> {
  final LifeEntityRepository _entityRepository;
  final EntityRelationRepository _relationRepository;
  final UserEntityOverlayRepository _overlayRepository;
  final String entityId;
  final String? _injectedUserId;

  EntityVitrineCubit({
    required this.entityId,
    required LifeEntityRepository entityRepository,
    required EntityRelationRepository relationRepository,
    required UserEntityOverlayRepository overlayRepository,
    LifeEntity? initialEntity,
    String? currentUserId,
  })  : _entityRepository = entityRepository,
        _relationRepository = relationRepository,
        _overlayRepository = overlayRepository,
        _injectedUserId = currentUserId,
        super(EntityVitrineState(
          status: initialEntity != null ? VitrineStatus.success : VitrineStatus.initial,
          entity: initialEntity,
        ));

  String? get _currentUserId {
    if (_injectedUserId != null) return _injectedUserId;
    try {
      return Supabase.instance.client.auth.currentUser?.id;
    } catch (_) {
      return 'local-user';
    }
  }

  /// Loads full entity, relations, and personal overlay
  Future<void> load() async {
    emit(state.copyWith(status: VitrineStatus.loading, errorMessage: () => null));

    try {
      final entity = await _entityRepository.getEntityById(entityId);
      if (entity == null) {
        emit(state.copyWith(
          status: VitrineStatus.failure,
          errorMessage: () => 'Entità non trovata.',
        ));
        return;
      }

      // Load relations
      List<EntityRelation> relations = [];
      try {
        relations = await _relationRepository.getRelationsForSource(entityId);
      } catch (_) {}

      // Load overlay (lazy created, may be null)
      UserEntityOverlay? overlay;
      try {
        overlay = await _overlayRepository.getOverlay(entityId);
      } catch (_) {}

      emit(state.copyWith(
        status: VitrineStatus.success,
        entity: entity,
        relations: relations,
        overlay: overlay,
        errorMessage: () => null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: VitrineStatus.failure,
        errorMessage: () => 'Errore durante il caricamento: $e',
      ));
    }
  }

  /// Applies human intention to the entity (Amendment C: hide ontology behind human intentions)
  Future<bool> applyIntention(HumanIntention intention) async {
    final current = state.entity;
    if (current == null) return false;

    emit(state.copyWith(isSaving: true, errorMessage: () => null));

    LifeEntity updated;
    switch (intention) {
      case HumanIntention.explore:
        // Explores without rigid commitment
        updated = current.copyWith(
          semanticRole: current.isSeed ? SemanticRole.idea : current.semanticRole,
          currentMode: () => OperationMode.exploration,
          updatedAt: DateTime.now(),
        );
        break;
      case HumanIntention.treatAsProject:
        // Converts to active project in execution mode
        updated = current.copyWith(
          semanticRole: SemanticRole.project,
          currentMode: () => OperationMode.execution,
          updatedAt: DateTime.now(),
        );
        break;
      case HumanIntention.cultivatePractice:
        // Converts to practice
        updated = current.copyWith(
          semanticRole: SemanticRole.practice,
          currentMode: () => OperationMode.practice,
          updatedAt: DateTime.now(),
        );
        break;
      case HumanIntention.organizeKnowledge:
        // Converts to knowledge / concept
        updated = current.copyWith(
          semanticRole: SemanticRole.concept,
          currentMode: () => OperationMode.reflection,
          updatedAt: DateTime.now(),
        );
        break;
      case HumanIntention.keepAsSeed:
        // Reverts back to raw seed without mode
        updated = current.copyWith(
          semanticRole: SemanticRole.seed,
          currentMode: () => null,
          updatedAt: DateTime.now(),
        );
        break;
    }

    try {
      final saved = await _entityRepository.updateEntity(updated);
      emit(state.copyWith(
        isSaving: false,
        entity: saved,
        successMessage: () => 'Intenzione applicata con successo.',
      ));
      return true;
    } catch (e) {
      emit(state.copyWith(
        isSaving: false,
        errorMessage: () => 'Impossibile aggiornare: connessione assente o errore di rete.',
      ));
      return false;
    }
  }

  /// Updates title or description
  Future<bool> updateDetails({required String title, String? description}) async {
    final current = state.entity;
    if (current == null) return false;

    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) {
      emit(state.copyWith(errorMessage: () => 'Il titolo non può essere vuoto.'));
      return false;
    }

    emit(state.copyWith(isSaving: true, errorMessage: () => null));

    final updated = current.copyWith(
      title: cleanTitle,
      description: description?.trim().isEmpty == true ? null : description?.trim(),
      updatedAt: DateTime.now(),
    );

    try {
      final saved = await _entityRepository.updateEntity(updated);
      emit(state.copyWith(
        isSaving: false,
        entity: saved,
        successMessage: () => 'Modifiche salvate.',
      ));
      return true;
    } catch (e) {
      emit(state.copyWith(
        isSaving: false,
        errorMessage: () => 'Impossibile salvare: connessione assente o errore di rete.',
      ));
      return false;
    }
  }

  /// Toggles personal Weekly Rail status (Amendment B)
  Future<bool> toggleWeeklyRail() async {
    final userId = _currentUserId;
    if (userId == null) return false;

    emit(state.copyWith(isSaving: true, errorMessage: () => null));

    final currentOverlay = state.overlay;
    final newRailState = !(currentOverlay?.isInWeeklyRail ?? false);

    final overlayToSave = (currentOverlay ??
            UserEntityOverlay(
              entityId: entityId,
              userId: userId,
              updatedAt: DateTime.now(),
            ))
        .copyWith(
      isInWeeklyRail: newRailState,
      updatedAt: DateTime.now(),
    );

    try {
      final saved = await _overlayRepository.saveOverlay(overlayToSave);
      emit(state.copyWith(
        isSaving: false,
        overlay: saved,
        successMessage: () => newRailState
            ? 'Aggiunto al Weekly Rail.'
            : 'Rimosso dal Weekly Rail.',
      ));
      return true;
    } catch (e) {
      emit(state.copyWith(
        isSaving: false,
        errorMessage: () => 'Impossibile aggiornare Weekly Rail: verifica la connessione.',
      ));
      return false;
    }
  }

  /// Archives the entity
  Future<bool> archive() async {
    final current = state.entity;
    if (current == null) return false;

    emit(state.copyWith(isSaving: true, errorMessage: () => null));

    final updated = current.copyWith(
      lifecycleState: LifecycleState.archived,
      updatedAt: DateTime.now(),
    );

    try {
      final saved = await _entityRepository.updateEntity(updated);
      emit(state.copyWith(
        isSaving: false,
        entity: saved,
        successMessage: () => 'Entità archiviata.',
      ));
      return true;
    } catch (e) {
      emit(state.copyWith(
        isSaving: false,
        errorMessage: () => 'Errore durante l\'archiviazione.',
      ));
      return false;
    }
  }
}
