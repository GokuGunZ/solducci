import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solducci/features/life_os/domain/models/models.dart';
import 'package:solducci/features/life_os/domain/repositories/repositories.dart';
import 'package:solducci/service/context_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'life_os_center_state.dart';

class LifeOsCenterCubit extends Cubit<LifeOsCenterState> {
  final LifeEntityRepository _entityRepository;
  final EntityRelationRepository? _relationRepository;
  final ContextManager? _contextManager;
  final String? _injectedUserId;
  final _uuid = const Uuid();

  LifeOsCenterCubit({
    required LifeEntityRepository entityRepository,
    EntityRelationRepository? relationRepository,
    ContextManager? contextManager,
    String? currentUserId,
  })  : _entityRepository = entityRepository,
        _relationRepository = relationRepository,
        _contextManager = contextManager ?? _tryGetContextManager(),
        _injectedUserId = currentUserId,
        super(const LifeOsCenterState()) {
    _contextManager?.addListener(_onContextChanged);
  }

  static ContextManager? _tryGetContextManager() {
    try {
      return ContextManager();
    } catch (_) {
      return null;
    }
  }

  String? get _currentUserId {
    if (_injectedUserId != null) return _injectedUserId;
    try {
      return Supabase.instance.client.auth.currentUser?.id;
    } catch (_) {
      return 'local-user';
    }
  }

  void _onContextChanged() {
    loadEntities();
  }

  @override
  Future<void> close() {
    _contextManager?.removeListener(_onContextChanged);
    return super.close();
  }

  /// Loads all entities for the current active context
  Future<void> loadEntities() async {
    emit(state.copyWith(status: LifeOsCenterStatus.loading, generalError: () => null));

    try {
      final context = _contextManager?.currentContext;
      final String? groupId = context != null && context.isGroup ? context.groupId : null;
      final bool isPersonal = context?.isPersonal ?? true;

      final all = await _entityRepository.getEntities(
        groupId: groupId,
        isPersonal: isPersonal,
      );

      final seeds = all
          .where((e) => e.isSeed && e.isActive)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      final active = all
          .where((e) => !e.isSeed && e.isActive)
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      emit(state.copyWith(
        status: LifeOsCenterStatus.success,
        seeds: seeds,
        activeEntities: active,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: LifeOsCenterStatus.failure,
        generalError: () => 'Impossibile caricare le entità LifeOS: $e',
      ));
    }
  }

  /// Captures a raw thought as a Seed entity (Amendment A: currentMode = null)
  Future<bool> captureSeed(String title, {String? description}) async {
    final result = await captureSeedWithMentions(title, const [], description: description);
    return result != null;
  }

  /// Captures a seed entity and persists any associated @mentions via entity_relations.
  Future<LifeEntity?> captureSeedWithMentions(
    String title,
    List<SeedMention> mentions, {
    String? description,
  }) async {
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty && mentions.isEmpty) return null;

    final actualTitle = cleanTitle.isNotEmpty
        ? cleanTitle
        : 'Seme collegato a ${mentions.map((m) => m.entityTitle).join(', ')}';

    emit(state.copyWith(
      isCapturing: true,
      captureError: () => null,
      lastFailedCaptureTitle: () => null,
    ));

    final context = _contextManager?.currentContext;
    final String? groupId = context != null && context.isGroup ? context.groupId : null;
    final currentUserId = _currentUserId;
    final now = DateTime.now();

    final newSeed = LifeEntity(
      id: _uuid.v4(),
      userId: currentUserId,
      groupId: groupId,
      title: actualTitle,
      description: description?.trim().isEmpty == true ? null : description?.trim(),
      semanticRole: SemanticRole.seed,
      lifecycleState: LifecycleState.active,
      currentMode: null,
      createdAt: now,
      updatedAt: now,
    );

    try {
      // 1. Commit new seed document first (PostgreSQL RLS safe)
      final createdEntity = await _entityRepository.createEntity(newSeed);

      // 2. Persist any relations for mentions and sync parent living blocks
      List<LifeEntity> updatedActiveEntities = state.activeEntities;
      List<LifeEntity> updatedSeeds = [createdEntity, ...state.seeds];

      if (_relationRepository != null && mentions.isNotEmpty) {
        for (final mention in mentions) {
          final rel = EntityRelation(
            id: _uuid.v4(),
            userId: currentUserId ?? '',
            sourceId: createdEntity.id,
            targetType: TargetType.entity,
            targetId: mention.entityId,
            relationType: mention.relationType,
            createdAt: now,
          );
          try {
            await _relationRepository.createRelation(rel);
          } catch (_) {
            // Non-blocking relation persistence
          }

          // If the mention is a parent relationship (partOf), append this new child
          // to the parent entity's living blocks (flusso evolutivo) so it appears in its vitrine!
          if (mention.relationType == RelationType.partOf) {
            try {
              final parent = await _entityRepository.getEntityById(mention.entityId);
              if (parent != null) {
                final parentBlock = EntityBlock(
                  id: _uuid.v4(),
                  content: createdEntity.title,
                  position: parent.blocks.length,
                  createdAt: now,
                );
                final updatedParent = parent.copyWith(
                  blocks: [...parent.blocks, parentBlock],
                  updatedAt: now,
                );
                await _entityRepository.updateEntity(updatedParent);

                // Reflect updated parent in cubit state lists if present
                final pEntIdx = updatedActiveEntities.indexWhere((e) => e.id == parent.id);
                if (pEntIdx != -1) {
                  updatedActiveEntities = [...updatedActiveEntities];
                  updatedActiveEntities[pEntIdx] = updatedParent;
                }
                final pSeedIdx = updatedSeeds.indexWhere((e) => e.id == parent.id);
                if (pSeedIdx != -1) {
                  updatedSeeds = [...updatedSeeds];
                  updatedSeeds[pSeedIdx] = updatedParent;
                }
              }
            } catch (_) {
              // Non-blocking parent block update
            }
          }
        }
      }

      emit(state.copyWith(
        isCapturing: false,
        seeds: updatedSeeds,
        activeEntities: updatedActiveEntities,
        captureError: () => null,
        lastFailedCaptureTitle: () => null,
      ));
      return createdEntity;
    } catch (e) {
      emit(state.copyWith(
        isCapturing: false,
        captureError: () => 'Impossibile salvare: connessione assente o errore di rete.',
        lastFailedCaptureTitle: () => actualTitle,
      ));
      return null;
    }
  }

  /// Updates an existing seed in state when edited via the chained overlay.
  void onSeedUpdated(LifeEntity updated) {
    final idx = state.seeds.indexWhere((s) => s.id == updated.id);
    if (idx != -1) {
      final updatedSeeds = List<LifeEntity>.from(state.seeds);
      updatedSeeds[idx] = updated;
      emit(state.copyWith(seeds: updatedSeeds));
    }
  }

  /// Adds a newly created chained seed directly to the state list.
  void onSeedAdded(LifeEntity newSeed) {
    if (!state.seeds.any((s) => s.id == newSeed.id)) {
      emit(state.copyWith(seeds: [newSeed, ...state.seeds]));
    }
  }

  /// Retries capturing the last failed seed title
  Future<bool> retryLastCapture() async {
    final title = state.lastFailedCaptureTitle;
    if (title != null && title.isNotEmpty) {
      return captureSeed(title);
    }
    return false;
  }
}
