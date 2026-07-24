import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solducci/models/dashboard_config.dart';
import 'package:solducci/service/dashboard_service.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';
import 'package:uuid/uuid.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final DashboardService _dashboardService = DashboardService();

  DashboardBloc() : super(DashboardInitial()) {
    on<LoadDashboard>(_onLoadDashboard);
    on<ToggleEditMode>(_onToggleEditMode);
    on<UpdateLayout>(_onUpdateLayout);
    on<SaveDashboard>(_onSaveDashboard);
  }

  Future<void> _onLoadDashboard(LoadDashboard event, Emitter<DashboardState> emit) async {
    emit(DashboardLoading());
    try {
      DashboardConfig? config = await _dashboardService.getDashboardConfig(deviceType: event.deviceType);
      
      DashboardConfig loadedConfig;
      
      // If no config exists, create a default one
      if (config == null) {
        loadedConfig = DashboardConfig(
          id: const Uuid().v4(),
          userId: '', // Will be populated by service on save
          deviceType: event.deviceType,
          layout: _getDefaultLayout(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      } else {
        // Auto-migrate quick_expense to 2x3
        bool changed = false;
        final newLayout = config.layout.map((def) {
          if (def.type == 'quick_expense' && def.size.mainAxisCellCount < 3) {
            changed = true;
            return BentoWidgetDef(
              id: def.id, 
              type: def.type, 
              size: BentoWidgetSize(def.size.crossAxisCellCount, 3)
            );
          }
          return def;
        }).toList();

        if (changed) {
          loadedConfig = config.copyWith(layout: newLayout);
          _dashboardService.saveDashboardConfig(loadedConfig);
        } else {
          loadedConfig = config;
        }
      }
      
      emit(DashboardLoaded(config: loadedConfig));
    } catch (e) {
      emit(DashboardError('Failed to load dashboard: $e'));
    }
  }

  void _onToggleEditMode(ToggleEditMode event, Emitter<DashboardState> emit) {
    if (state is DashboardLoaded) {
      final currentState = state as DashboardLoaded;
      emit(currentState.copyWith(isEditing: !currentState.isEditing));
    }
  }

  void _onUpdateLayout(UpdateLayout event, Emitter<DashboardState> emit) {
    if (state is DashboardLoaded) {
      final currentState = state as DashboardLoaded;
      
      final updatedConfig = DashboardConfig(
        id: currentState.config.id,
        userId: currentState.config.userId,
        deviceType: currentState.config.deviceType,
        layout: event.newLayout,
        createdAt: currentState.config.createdAt,
        updatedAt: DateTime.now(),
      );
      
      emit(currentState.copyWith(config: updatedConfig));
    }
  }

  Future<void> _onSaveDashboard(SaveDashboard event, Emitter<DashboardState> emit) async {
    if (state is DashboardLoaded) {
      final currentState = state as DashboardLoaded;
      try {
        await _dashboardService.saveDashboardConfig(currentState.config);
        // Optional: emit a temporary "Saved" state or just keep loaded
      } catch (e) {
        // Handle save error silently or emit error state
        print('Error saving dashboard: $e');
      }
    }
  }

  List<BentoWidgetDef> _getDefaultLayout() {
    return [
      BentoWidgetDef(id: 'w1', type: 'balance', size: const BentoWidgetSize(2, 1)),
      BentoWidgetDef(id: 'w2', type: 'quick_expense', size: const BentoWidgetSize(2, 3)),
      BentoWidgetDef(id: 'w3', type: 'focus_tasks', size: const BentoWidgetSize(2, 2)),
      BentoWidgetDef(id: 'w4', type: 'monthly_burn_rate', size: const BentoWidgetSize(2, 2)),
    ];
  }
}
