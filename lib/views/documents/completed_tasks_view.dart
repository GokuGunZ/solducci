import 'package:flutter/material.dart';
import 'package:solducci/models/document.dart';
import 'package:solducci/blocs/unified_task_list/task_list_data_source.dart';
import 'package:solducci/features/documents/presentation/views/task_list_view.dart';
import 'package:solducci/service/task_service.dart';
import 'package:solducci/utils/task_state_manager.dart';
import 'package:solducci/core/di/service_locator.dart';

/// View showing only completed tasks for a document
///
/// **Phase 4 Migration**: This view now uses the unified TaskListView component
/// with CompletedTaskDataSource. The previous implementation has been replaced
/// with this thin wrapper.
///
/// Architecture:
/// - Uses UnifiedTaskListBloc (via TaskListView)
/// - CompletedTaskDataSource for loading only completed tasks
/// - Automatically filters to show only completed tasks
/// - Granular rebuild system preserved (via GranularTaskItem)
/// - Same UX as before
///
/// Old Implementation: lib/views/documents/completed_tasks_view.dart.phase3_backup
class CompletedTasksView extends StatelessWidget {
  final TodoDocument document;
  final ValueNotifier<bool>? showAllPropertiesNotifier;

  const CompletedTasksView({
    super.key,
    required this.document,
    this.showAllPropertiesNotifier,
  });

  @override
  Widget build(BuildContext context) {
    // Create data source for completed tasks only
    final dataSource = CompletedTaskDataSource(
      documentId: document.id,
      taskService: getIt<TaskService>(),
      stateManager: getIt<TaskStateManager>(),
    );

    // Use unified TaskListView component
    return TaskListView(
      document: document,
      dataSource: dataSource,
      showAllPropertiesNotifier: showAllPropertiesNotifier,
      showCompletedSection: false, // All tasks are completed, no need for separate section
    );
  }
}
