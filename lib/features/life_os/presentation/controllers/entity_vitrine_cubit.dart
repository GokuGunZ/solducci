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

  /// Sets the semantic role, leaving currentMode strictly untouched (Step 2.1 Rule)
  Future<bool> setRole(SemanticRole role) async {
    final current = state.entity;
    if (current == null) return false;

    emit(state.copyWith(isSaving: true, errorMessage: () => null));

    final updated = current.copyWith(
      semanticRole: role,
      updatedAt: DateTime.now(),
    );

    try {
      final saved = await _entityRepository.updateEntity(updated);
      emit(state.copyWith(
        isSaving: false,
        entity: saved,
        successMessage: () => 'Natura aggiornata.',
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

  /// Sets the current operational mode, leaving semanticRole strictly untouched (Step 2.1 Rule)
  Future<bool> setMode(OperationMode? mode) async {
    final current = state.entity;
    if (current == null) return false;

    emit(state.copyWith(isSaving: true, errorMessage: () => null));

    final updated = current.copyWith(
      currentMode: () => mode,
      updatedAt: DateTime.now(),
    );

    try {
      final saved = await _entityRepository.updateEntity(updated);
      emit(state.copyWith(
        isSaving: false,
        entity: saved,
        successMessage: () => mode == null
            ? 'Modalità rimossa (a riposo).'
            : 'Modalità operativa aggiornata.',
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

  /// Human intention adapter respecting strict Role / Mode orthogonality (Step 2.1)
  Future<bool> applyIntention(HumanIntention intention) async {
    switch (intention) {
      case HumanIntention.explore:
        // "Esplora" sets currentMode to exploration WITHOUT altering semanticRole
        return setMode(OperationMode.exploration);
      case HumanIntention.treatAsProject:
        // "Trattalo come progetto" sets semanticRole to project WITHOUT forcing mode
        return setRole(SemanticRole.project);
      case HumanIntention.cultivatePractice:
        // "Coltivalo come pratica" sets semanticRole to practice WITHOUT forcing mode
        return setRole(SemanticRole.practice);
      case HumanIntention.organizeKnowledge:
        // "Organizzalo come conoscenza" sets semanticRole to concept WITHOUT forcing mode
        return setRole(SemanticRole.concept);
      case HumanIntention.keepAsSeed:
        // "Lascialo come seme" sets semanticRole to seed WITHOUT forcing mode
        return setRole(SemanticRole.seed);
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
