import 'package:flutter/material.dart';
import 'package:solducci/models/document.dart';
import 'package:solducci/models/tag.dart';
import 'package:solducci/blocs/unified_task_list/task_list_data_source.dart';
import 'package:solducci/features/documents/presentation/views/task_list_view.dart';
import 'package:solducci/service/task_service.dart';
import 'package:solducci/utils/task_state_manager.dart';
import 'package:solducci/core/di/service_locator.dart';

/// View showing all tasks (pending + in progress + assigned) for a document
///
/// **Phase 2 Migration**: This view now uses the unified TaskListView component
/// with DocumentTaskDataSource. The previous 347-line implementation has been
/// replaced with this ~50-line thin wrapper.
///
/// Architecture:
/// - Uses UnifiedTaskListBloc (via TaskListView)
/// - DocumentTaskDataSource for loading all document tasks
/// - Supports custom reordering (drag-and-drop)
/// - Granular rebuild system preserved (via GranularTaskItem)
/// - Same UX as before (inline creation, filters, animations)
///
/// Old Implementation: lib/views/documents/all_tasks_view.dart.phase1_backup
class AllTasksView extends StatelessWidget {
  final TodoDocument document;
  final ValueNotifier<bool>? showAllPropertiesNotifier;
  final void Function(VoidCallback?)? onInlineCreationCallbackChanged;
  final List<Tag>? availableTags; // Optional: tags for filtering

  const AllTasksView({
    super.key,
    required this.document,
    this.showAllPropertiesNotifier,
    this.onInlineCreationCallbackChanged,
    this.availableTags,
  });

  @override
  Widget build(BuildContext context) {
    // Create data source for all document tasks
    final dataSource = DocumentTaskDataSource(
      documentId: document.id,
      taskService: getIt<TaskService>(),
      stateManager: getIt<TaskStateManager>(),
    );

    // Use unified TaskListView component
    return TaskListView(
      document: document,
      dataSource: dataSource,
      showAllPropertiesNotifier: showAllPropertiesNotifier,
      onInlineCreationCallbackChanged: onInlineCreationCallbackChanged,
      availableTags: availableTags,
      showCompletedSection: false, // All tasks view: completed tasks inline
    );
  }
}
