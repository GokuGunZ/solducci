import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solducci/features/life_os/domain/models/models.dart';
import 'package:solducci/features/life_os/domain/repositories/repositories.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'entity_vitrine_state.dart';

class EntityVitrineCubit extends Cubit<EntityVitrineState> {
  final LifeEntityRepository _entityRepository;
  final EntityRelationRepository _relationRepository;
  final UserEntityOverlayRepository _overlayRepository;
  final String entityId;
  final String? _injectedUserId;
  final _uuid = const Uuid();

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

  /// Appends a new living content block to the entity (INT-D015)
  Future<bool> addBlock(String content) async {
    final current = state.entity;
    if (current == null) return false;

    final cleanText = content.trim();
    if (cleanText.isEmpty) return false;

    emit(state.copyWith(isSaving: true, errorMessage: () => null));

    final newBlock = EntityBlock(
      id: _uuid.v4(),
      content: cleanText,
      position: current.blocks.length,
      createdAt: DateTime.now(),
    );

    final updated = current.copyWith(
      blocks: [...current.blocks, newBlock],
      updatedAt: DateTime.now(),
    );

    try {
      final saved = await _entityRepository.updateEntity(updated);
      emit(state.copyWith(
        isSaving: false,
        entity: saved,
      ));
      return true;
    } catch (e) {
      emit(state.copyWith(
        isSaving: false,
        errorMessage: () => 'Impossibile aggiungere pensiero: verifica la connessione.',
      ));
      return false;
    }
  }

  /// Updates the text of an existing content block
  Future<bool> updateBlock(String blockId, String content) async {
    final current = state.entity;
    if (current == null) return false;

    final cleanText = content.trim();
    if (cleanText.isEmpty) return deleteBlock(blockId);

    final updatedBlocks = current.blocks.map((b) {
      if (b.id == blockId) {
        return b.copyWith(content: cleanText, updatedAt: DateTime.now());
      }
      return b;
    }).toList();

    final updated = current.copyWith(
      blocks: updatedBlocks,
      updatedAt: DateTime.now(),
    );

    try {
      final saved = await _entityRepository.updateEntity(updated);
      emit(state.copyWith(entity: saved));
      return true;
    } catch (e) {
      emit(state.copyWith(
        errorMessage: () => 'Impossibile aggiornare il blocco.',
      ));
      return false;
    }
  }

  /// Deletes a content block
  Future<bool> deleteBlock(String blockId) async {
    final current = state.entity;
    if (current == null) return false;

    final updatedBlocks = current.blocks.where((b) => b.id != blockId).toList();
    final updated = current.copyWith(
      blocks: updatedBlocks,
      updatedAt: DateTime.now(),
    );

    try {
      final saved = await _entityRepository.updateEntity(updated);
      emit(state.copyWith(entity: saved));
      return true;
    } catch (e) {
      emit(state.copyWith(
        errorMessage: () => 'Impossibile eliminare il blocco.',
      ));
      return false;
    }
  }

  /// Adds or updates a progressive property (INT-D016)
  /// Reuses existing key if present; preserves all other properties.
  Future<bool> addOrUpdateProperty(EntityProperty property) async {
    final current = state.entity;
    if (current == null) return false;

    emit(state.copyWith(isSaving: true, errorMessage: () => null));

    final existingIndex = current.properties.indexWhere((p) => p.key == property.key);
    final List<EntityProperty> newProperties = List.from(current.properties);

    if (existingIndex >= 0) {
      newProperties[existingIndex] = property;
    } else {
      newProperties.add(property);
    }

    final updated = current.copyWith(
      properties: newProperties,
      updatedAt: DateTime.now(),
    );

    try {
      final saved = await _entityRepository.updateEntity(updated);
      emit(state.copyWith(
        isSaving: false,
        entity: saved,
      ));
      return true;
    } catch (e) {
      emit(state.copyWith(
        isSaving: false,
        errorMessage: () => 'Impossibile salvare la proprietà.',
      ));
      return false;
    }
  }

  /// Removes a progressive property by key
  Future<bool> removeProperty(String key) async {
    final current = state.entity;
    if (current == null) return false;

    final newProperties = current.properties.where((p) => p.key != key).toList();
    final updated = current.copyWith(
      properties: newProperties,
      updatedAt: DateTime.now(),
    );

    try {
      final saved = await _entityRepository.updateEntity(updated);
      emit(state.copyWith(entity: saved));
      return true;
    } catch (e) {
      emit(state.copyWith(
        errorMessage: () => 'Impossibile rimuovere la proprietà.',
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
