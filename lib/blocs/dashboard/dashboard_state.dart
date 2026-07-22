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

  const DashboardLoaded({
    required this.config,
    this.isEditing = false,
  });

  DashboardLoaded copyWith({
    DashboardConfig? config,
    bool? isEditing,
  }) {
    return DashboardLoaded(
      config: config ?? this.config,
      isEditing: isEditing ?? this.isEditing,
    );
  }

  @override
  List<Object?> get props => [config, isEditing];
}

class DashboardError extends DashboardState {
  final String message;

  const DashboardError(this.message);

  @override
  List<Object?> get props => [message];
}
