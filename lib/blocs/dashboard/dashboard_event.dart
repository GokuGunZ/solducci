import 'package:equatable/equatable.dart';
import 'package:solducci/models/dashboard_config.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

class LoadDashboard extends DashboardEvent {
  final String deviceType;
  const LoadDashboard({this.deviceType = 'mobile'});
  
  @override
  List<Object?> get props => [deviceType];
}

class ToggleEditMode extends DashboardEvent {}

class UpdateLayout extends DashboardEvent {
  final List<BentoWidgetDef> newLayout;
  const UpdateLayout(this.newLayout);
  
  @override
  List<Object?> get props => [newLayout];
}

class SaveDashboard extends DashboardEvent {}
