import 'package:solducci/core/logging/app_logger.dart';
import 'package:solducci/models/document.dart';
import '../models/line_element.dart';
import '../models/document_markdown_config.dart';
import '../reconciler/hybrid_line_reconciler.dart';
import 'data_source_adapter.dart';
import 'offline_mutation_queue.dart';

/// Orchestrates out-of-band data synchronization between Markdown line elements
/// and registered domain entity adapters.
///
/// Follows the Data Binding Safety Contract:
/// - Deterministic idempotency keys.
/// - Strict context boundary checks.
/// - Explicit reconciliation states (certain, probable, ambiguous, conflict, unlinked).
/// - Non-destructive unlinking when identity is uncertain or deleted.
class MarkdownDataBindingEngine {
  final Map<String, DataSourceAdapter> _adapters = {};
  final OfflineMutationQueue mutationQueue;
  final HybridLineReconciler reconciler;

  MarkdownDataBindingEngine({
    OfflineMutationQueue? queue,
    HybridLineReconciler? reconciler,
  })  : mutationQueue = queue ?? OfflineMutationQueue(),
        reconciler = reconciler ?? HybridLineReconciler();

  void registerAdapter(DataSourceAdapter adapter) {
    _adapters[adapter.entityType] = adapter;
    AppLogger.info('MarkdownDataBindingEngine: Registered adapter for ${adapter.entityType}');
  }

  DataSourceAdapter? getAdapter(String entityType) => _adapters[entityType];

  /// Synchronizes parsed [elements] of a [document] with connected data sources.
  /// Returns the updated [DocumentMarkdownConfig] containing refreshed bindings and states.
  Future<DocumentMarkdownConfig> syncDocument({
    required Document document,
    required List<LineElement> elements,
  }) async {
    final currentConfig = document.markdownConfig;
    final updatedBindings = Map<String, LineBindingLink>.from(currentConfig.bindings);

    // 1. Flush any queued offline mutations if online
    for (var adapter in _adapters.values) {
      if (mutationQueue.isOnline && mutationQueue.pendingCount > 0) {
        await mutationQueue.flush(adapter);
      }
    }

    final candidateLines = elements.map((e) => e.rawSourceLine).toList();

    // 2. Prepare initial anchors from existing bindings
    final entityIdToText = <String, String>{};
    for (var entry in currentConfig.bindings.entries) {
      entityIdToText[entry.key] = entry.value.lastKnownText;
    }

    reconciler.setInitialAnchors(candidateLines, entityIdToText);

    // 3. Run Hybrid Reconciliation
    final result = reconciler.reconcile(candidateLines);

    // Track which line indices have been claimed by existing bindings
    final matchedLineIndices = <int>{};

    // 4. Handle quarantined / ambiguous anchors
    for (var anchorKey in result.quarantined) {
      final existingLink = updatedBindings[anchorKey];
      if (existingLink != null) {
        AppLogger.warning('MarkdownDataBindingEngine: Anchor $anchorKey is ambiguous - quarantined');
        updatedBindings[anchorKey] = existingLink.copyWith(
          syncState: LineSyncState.ambiguous,
          updatedAt: DateTime.now(),
        );
      }
    }

    // 5. Handle matched anchors
    for (var entry in result.matched.entries) {
      final anchorKey = entry.key;
      final lineIdx = entry.value;
      final existingLink = updatedBindings[anchorKey];
      if (existingLink == null) continue;

      final adapter = _adapters[existingLink.targetEntityType];
      matchedLineIndices.add(lineIdx);

      if (lineIdx >= 0 && lineIdx < elements.length) {
        final element = elements[lineIdx];
        final conf = result.confidence[anchorKey] ?? 1.0;
        final syncState = conf >= 0.90 ? LineSyncState.certain : LineSyncState.probable;

        // Check text modification
        if (element.textContent != existingLink.lastKnownText && adapter != null) {
          if (mutationQueue.isOnline) {
            try {
              await adapter.updateItem(
                entityId: existingLink.targetEntityId,
                text: element.textContent,
                contextScope: document.isGroup ? 'group' : 'personal',
              );
            } catch (e) {
              AppLogger.error('Sync error updating text: $e. Enqueuing mutation.');
              mutationQueue.enqueue(QueuedMutation(
                id: 'mut-${DateTime.now().millisecondsSinceEpoch}',
                entityType: existingLink.targetEntityType,
                action: MutationAction.update,
                entityId: existingLink.targetEntityId,
                text: element.textContent,
                contextScope: document.isGroup ? 'group' : 'personal',
              ));
            }
          }
        }

        // Check completion toggle
        if (element.markerType == LineMarkerType.checkbox && adapter != null) {
          if (mutationQueue.isOnline) {
            try {
              await adapter.toggleItem(
                entityId: existingLink.targetEntityId,
                isCompleted: element.isChecked,
                contextScope: document.isGroup ? 'group' : 'personal',
              );
            } catch (e) {
              AppLogger.error('Sync error toggling checkbox: $e. Enqueuing mutation.');
              mutationQueue.enqueue(QueuedMutation(
                id: 'mut-${DateTime.now().millisecondsSinceEpoch}',
                entityType: existingLink.targetEntityType,
                action: MutationAction.toggle,
                entityId: existingLink.targetEntityId,
                isCompleted: element.isChecked,
                contextScope: document.isGroup ? 'group' : 'personal',
              ));
            }
          }
        }

        updatedBindings[anchorKey] = existingLink.copyWith(
          lastKnownText: element.textContent,
          lastKnownLineIndex: element.lineIndex,
          syncState: syncState,
          updatedAt: DateTime.now(),
        );
      } else {
        // Line was not found in candidate lines (lineIdx == -1): mark as UNLINKED
        updatedBindings[anchorKey] = existingLink.copyWith(
          syncState: LineSyncState.unlinked,
          updatedAt: DateTime.now(),
        );
      }
    }

    // 6. Handle unlinked anchors (present in bindings, but not matched and not quarantined)
    for (var anchorKey in currentConfig.bindings.keys) {
      final lineIdx = result.matched[anchorKey];
      if ((lineIdx == null || lineIdx < 0) && !result.quarantined.contains(anchorKey)) {
        final existingLink = updatedBindings[anchorKey];
        if (existingLink != null) {
          // Never delete remote entity on missing line; safely mark unlinked
          updatedBindings[anchorKey] = existingLink.copyWith(
            syncState: LineSyncState.unlinked,
            updatedAt: DateTime.now(),
          );
        }
      }
    }

    // 7. Create bindings for newly inserted elements that match active rules
    for (int i = 0; i < elements.length; i++) {
      if (matchedLineIndices.contains(i)) continue;

      final element = elements[i];
      final rule = currentConfig.rules[element.markerType];

      if (rule != null && rule.dataSource.isConnected) {
        final adapter = _adapters[rule.dataSource.targetEntityType];
        if (adapter == null) continue;

        final anchorKey = 'anchor_${element.id}';
        // If already bound to this anchor, skip creation
        if (updatedBindings.containsKey(anchorKey) &&
            updatedBindings[anchorKey]!.syncState != LineSyncState.unlinked) {
          continue;
        }

        final idempotencyKey = '${document.id}_anchor_${anchorKey}_${element.lineIndex}';

        if (mutationQueue.isOnline) {
          try {
            final entityId = await adapter.createItem(
              documentId: document.id,
              text: element.textContent,
              isCompleted: element.isChecked,
              contextScope: document.isGroup ? 'group' : 'personal',
              userId: document.userId,
              groupId: document.groupId,
              idempotencyKey: idempotencyKey,
            );

            updatedBindings[anchorKey] = LineBindingLink(
              anchorKey: anchorKey,
              targetEntityType: adapter.entityType,
              targetEntityId: entityId,
              lastKnownText: element.textContent,
              lastKnownLineIndex: element.lineIndex,
              syncState: LineSyncState.synced,
              updatedAt: DateTime.now(),
            );
          } catch (e) {
            AppLogger.error('Failed to create bound item: $e. Enqueuing offline mutation.');
            mutationQueue.enqueue(QueuedMutation(
              id: 'mut-${DateTime.now().millisecondsSinceEpoch}',
              entityType: adapter.entityType,
              action: MutationAction.create,
              documentId: document.id,
              text: element.textContent,
              isCompleted: element.isChecked,
              idempotencyKey: idempotencyKey,
              contextScope: document.isGroup ? 'group' : 'personal',
              userId: document.userId,
              groupId: document.groupId,
            ));
          }
        }
      }
    }

    return currentConfig.copyWith(bindings: updatedBindings);
  }
}
