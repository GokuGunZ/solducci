import 'package:equatable/equatable.dart';
import 'package:solducci/models/dashboard_config.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();
  
  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final DashboardConfig config;
  final bool isEditing;
  final String currentContextKey;

  const DashboardLoaded({
    required this.config,
    this.isEditing = false,
    this.currentContextKey = 'personal',
  });

  /// All tabs belonging to the current context, ordered
  List<BentoDashboardTab> get currentContextTabs =>
      config.tabsForContext(currentContextKey);

  /// Active tab for current context, or first tab of context, or fallback
  BentoDashboardTab? get activeTab =>
      config.activeTabForContext(currentContextKey);

  DashboardLoaded copyWith({
    DashboardConfig? config,
    bool? isEditing,
    String? currentContextKey,
  }) {
    return DashboardLoaded(
      config: config ?? this.config,
      isEditing: isEditing ?? this.isEditing,
      currentContextKey: currentContextKey ?? this.currentContextKey,
    );
  }

  @override
  List<Object?> get props => [config, isEditing, currentContextKey];
}

class DashboardError extends DashboardState {
  final String message;

  const DashboardError(this.message);

  @override
  List<Object?> get props => [message];
}
