import 'dart:ui';
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

class ResizeWidget extends DashboardEvent {
  final String widgetId;
  const ResizeWidget(this.widgetId);
  
  @override
  List<Object?> get props => [widgetId];
}

class ApplyPresetLayout extends DashboardEvent {
  final List<BentoWidgetDef> layout;
  const ApplyPresetLayout(this.layout);

  @override
  List<Object?> get props => [layout];
}

/// Switches the active context (e.g. 'personal', 'group_<id>', 'view_<id>')
class SwitchDashboardContext extends DashboardEvent {
  final String contextKey;
  const SwitchDashboardContext(this.contextKey);

  @override
  List<Object?> get props => [contextKey];
}

/// Selects a specific dashboard tab/page in the current context
class SelectDashboardTab extends DashboardEvent {
  final String tabId;
  const SelectDashboardTab(this.tabId);

  @override
  List<Object?> get props => [tabId];
}

/// Creates a new dashboard tab in the given context
class CreateDashboardTab extends DashboardEvent {
  final String title;
  final String contextKey;
  final String iconName;
  final Color accentColor;
  final List<BentoWidgetDef>? initialLayout;

  const CreateDashboardTab({
    required this.title,
    required this.contextKey,
    this.iconName = 'dashboard',
    this.accentColor = const Color(0xFF6366F1),
    this.initialLayout,
  });

  @override
  List<Object?> get props => [title, contextKey, iconName, accentColor, initialLayout];
}

/// Deletes a dashboard tab by id
class DeleteDashboardTab extends DashboardEvent {
  final String tabId;
  const DeleteDashboardTab(this.tabId);

  @override
  List<Object?> get props => [tabId];
}

/// Reorders dashboard tabs in the current context
class ReorderDashboardTabs extends DashboardEvent {
  final List<String> orderedTabIds;
  const ReorderDashboardTabs(this.orderedTabIds);

  @override
  List<Object?> get props => [orderedTabIds];
}

/// Updates metadata (title, icon, color) of an existing dashboard tab
class UpdateDashboardTabInfo extends DashboardEvent {
  final String tabId;
  final String? title;
  final String? iconName;
  final Color? accentColor;

  const UpdateDashboardTabInfo({
    required this.tabId,
    this.title,
    this.iconName,
    this.accentColor,
  });

  @override
  List<Object?> get props => [tabId, title, iconName, accentColor];
}
