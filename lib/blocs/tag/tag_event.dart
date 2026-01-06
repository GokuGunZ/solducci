import 'package:equatable/equatable.dart';
import 'package:solducci/widgets/documents/filter_sort_dialog.dart';

/// Events for TagBloc
sealed class TagEvent extends Equatable {
  const TagEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load tasks for a specific tag
class TagLoadRequested extends TagEvent {
  final String tagId;
  final String documentId;
  final bool includeCompleted;

  const TagLoadRequested({
    required this.tagId,
    required this.documentId,
    required this.includeCompleted,
  });

  @override
  List<Object?> get props => [tagId, documentId, includeCompleted];
}

/// Event to change filter/sort configuration
class TagFilterChanged extends TagEvent {
  final FilterSortConfig config;

  const TagFilterChanged(this.config);

  @override
  List<Object?> get props => [config];
}

/// Event to refresh tasks
class TagRefreshRequested extends TagEvent {
  const TagRefreshRequested();
}

/// User started inline task creation
///
/// Shows the task creation row and updates UI state.
class TagTaskCreationStarted extends TagEvent {
  const TagTaskCreationStarted();
}

/// Task creation completed (success or cancel)
///
/// Hides the task creation row and triggers list refresh.
class TagTaskCreationCompleted extends TagEvent {
  const TagTaskCreationCompleted();
}
