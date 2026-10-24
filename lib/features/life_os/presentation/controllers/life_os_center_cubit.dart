import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solducci/features/life_os/domain/models/models.dart';
import 'package:solducci/features/life_os/domain/repositories/repositories.dart';
import 'package:solducci/service/context_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'life_os_center_state.dart';

class LifeOsCenterCubit extends Cubit<LifeOsCenterState> {
  final LifeEntityRepository _entityRepository;
  final ContextManager? _contextManager;
  final String? _injectedUserId;
  final _uuid = const Uuid();

  LifeOsCenterCubit({
    required LifeEntityRepository entityRepository,
    ContextManager? contextManager,
    String? currentUserId,
  })  : _entityRepository = entityRepository,
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
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) return false;

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
      title: cleanTitle,
      description: description?.trim().isEmpty == true ? null : description?.trim(),
      semanticRole: SemanticRole.seed,
      lifecycleState: LifecycleState.active,
      currentMode: null, // Amendment A: absence of mode is valid domain structure
      createdAt: now,
      updatedAt: now,
    );

    try {
      final createdEntity = await _entityRepository.createEntity(newSeed);
      final updatedSeeds = [createdEntity, ...state.seeds];
      emit(state.copyWith(
        isCapturing: false,
        seeds: updatedSeeds,
        captureError: () => null,
        lastFailedCaptureTitle: () => null,
      ));
      return true;
    } catch (e) {
      // Truthful error handling (Amendment B: no fake offline sync queue)
      emit(state.copyWith(
        isCapturing: false,
        captureError: () => 'Impossibile salvare: connessione assente o errore di rete.',
        lastFailedCaptureTitle: () => cleanTitle,
      ));
      return false;
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
