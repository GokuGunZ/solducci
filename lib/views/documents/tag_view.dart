import 'package:flutter/material.dart';
import 'package:solducci/models/document.dart';
import 'package:solducci/models/tag.dart';
import 'package:solducci/blocs/unified_task_list/task_list_data_source.dart';
import 'package:solducci/features/documents/presentation/views/task_list_view.dart';
import 'package:solducci/service/task_service.dart';
import 'package:solducci/utils/task_state_manager.dart';
import 'package:solducci/core/di/service_locator.dart';

/// View showing tasks filtered by a specific tag
///
/// **Phase 3 Migration**: This view now uses the unified TaskListView component
/// with TagTaskDataSource. The previous 731-line implementation has been
/// replaced with this ~70-line thin wrapper.
///
/// Architecture:
/// - Uses UnifiedTaskListBloc (via TaskListView)
/// - TagTaskDataSource for loading tag-filtered tasks
/// - Auto-selects tag when creating inline tasks
/// - Optional completed tasks section (if tag.showCompleted)
/// - Granular rebuild system preserved (via GranularTaskItem)
/// - Same UX as before (inline creation, filters, animations)
///
/// Old Implementation: lib/views/documents/tag_view.dart.phase2_backup
class TagView extends StatelessWidget {
  final TodoDocument document;
  final Tag tag;
  final ValueNotifier<bool>? showAllPropertiesNotifier;
  final void Function(VoidCallback?)? onInlineCreationCallbackChanged;

  const TagView({
    super.key,
    required this.document,
    required this.tag,
    this.showAllPropertiesNotifier,
    this.onInlineCreationCallbackChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Create data source for tag-filtered tasks
    final dataSource = TagTaskDataSource(
      tagId: tag.id,
      documentId: document.id,
      includeCompleted: tag.showCompleted,
      taskService: getIt<TaskService>(),
      stateManager: getIt<TaskStateManager>(),
    );

    // Use unified TaskListView component
    return TaskListView(
      document: document,
      dataSource: dataSource,
      showAllPropertiesNotifier: showAllPropertiesNotifier,
      onInlineCreationCallbackChanged: onInlineCreationCallbackChanged,
      initialTags: tag.id.isNotEmpty ? [tag] : null, // Pre-select this tag
      showCompletedSection: tag.showCompleted, // Separate completed section
    );
  }
}
