import 'dart:ui';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solducci/models/dashboard_config.dart';
import 'package:solducci/service/dashboard_service.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';
import 'package:uuid/uuid.dart';

import 'package:solducci/widgets/dashboard/dashboard_widget_factory.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final DashboardService _dashboardService = DashboardService();

  DashboardBloc() : super(DashboardInitial()) {
    on<LoadDashboard>(_onLoadDashboard);
    on<ToggleEditMode>(_onToggleEditMode);
    on<UpdateLayout>(_onUpdateLayout);
    on<SaveDashboard>(_onSaveDashboard);
    on<ResizeWidget>(_onResizeWidget);
    on<ApplyPresetLayout>(_onApplyPresetLayout);
    on<SwitchDashboardContext>(_onSwitchDashboardContext);
    on<SelectDashboardTab>(_onSelectDashboardTab);
    on<CreateDashboardTab>(_onCreateDashboardTab);
    on<DeleteDashboardTab>(_onDeleteDashboardTab);
    on<ReorderDashboardTabs>(_onReorderDashboardTabs);
    on<UpdateDashboardTabInfo>(_onUpdateDashboardTabInfo);
  }

  Future<void> _onLoadDashboard(LoadDashboard event, Emitter<DashboardState> emit) async {
    // Fast path: render cached dashboard immediately at 0ms latency
    final cached = await _dashboardService.getCachedDashboardConfig(deviceType: event.deviceType);
    if (cached != null) {
      emit(DashboardLoaded(config: cached, currentContextKey: 'personal'));
    } else {
      emit(DashboardLoading());
    }
    try {
      DashboardConfig? config = await _dashboardService.getDashboardConfig(deviceType: event.deviceType);
      
      DashboardConfig loadedConfig;
      
      // If no config exists, create a default one with initial Home tab
      if (config == null) {
        final initialTab = BentoDashboardTab(
          id: 'tab_personal_home',
          contextKey: 'personal',
          title: 'Home',
          iconName: 'home',
          accentColor: const Color(0xFF6366F1),
          orderIndex: 0,
          layout: _getDefaultLayout(),
          isDefault: true,
        );
        loadedConfig = DashboardConfig(
          id: const Uuid().v4(),
          userId: '', // Will be populated by service on save
          deviceType: event.deviceType,
          tabs: [initialTab],
          activeTabId: initialTab.id,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      } else {
        // If config has no tabs, initialize with default tab
        var currentTabs = config.tabs;
        if (currentTabs.isEmpty) {
          currentTabs = [
            BentoDashboardTab(
              id: 'tab_personal_home',
              contextKey: 'personal',
              title: 'Home',
              iconName: 'home',
              accentColor: const Color(0xFF6366F1),
              orderIndex: 0,
              layout: _getDefaultLayout(),
              isDefault: true,
            ),
          ];
        }

        // Auto-migrate quick_expense and dense list widgets to 2x4 across all tabs
        bool changed = false;
        final updatedTabs = currentTabs.map((tab) {
          final newLayout = tab.layout.map((def) {
            if (def.type == 'quick_expense' && def.size.mainAxisCellCount < 4) {
              changed = true;
              return BentoWidgetDef(
                id: def.id, 
                type: def.type, 
                size: const BentoWidgetSize(2, 4),
                customProps: def.customProps,
              );
            }
            if ((def.type == 'shopping_quick_list' || def.type == 'focus_tasks' || def.type == 'recent_notes') && def.size.mainAxisCellCount < 3) {
              changed = true;
              return BentoWidgetDef(
                id: def.id,
                type: def.type,
                size: BentoWidgetSize(def.size.crossAxisCellCount, 4),
                customProps: def.customProps,
              );
            }
            return def;
          }).toList();
          return tab.copyWith(layout: newLayout);
        }).toList();

        final activePersonal = updatedTabs.where((t) => t.contextKey == 'personal').firstOrNull;
        final targetActiveId = config.activeTabId ?? activePersonal?.id;

        loadedConfig = config.copyWith(
          tabs: updatedTabs,
          activeTabId: targetActiveId,
        );

        if (changed || config.tabs.isEmpty) {
          _dashboardService.saveDashboardConfig(loadedConfig);
        }
      }
      
      emit(DashboardLoaded(config: loadedConfig, currentContextKey: 'personal'));
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

  void _onSwitchDashboardContext(SwitchDashboardContext event, Emitter<DashboardState> emit) {
    if (state is DashboardLoaded) {
      final currentState = state as DashboardLoaded;
      final contextKey = event.contextKey;

      var tabs = List<BentoDashboardTab>.from(currentState.config.tabs);
      var contextTabs = tabs.where((t) => t.contextKey == contextKey).toList();

      DashboardConfig updatedConfig = currentState.config;

      if (contextTabs.isEmpty) {
        // Auto-generate initial tab for this context
        final String defaultTitle;
        final String defaultIcon;
        final Color defaultColor;
        if (contextKey.startsWith('group_')) {
          defaultTitle = 'Gruppo';
          defaultIcon = 'group';
          defaultColor = const Color(0xFF10B981);
        } else if (contextKey.startsWith('view_')) {
          defaultTitle = 'Vista';
          defaultIcon = 'visibility';
          defaultColor = const Color(0xFF0EA5E9);
        } else {
          defaultTitle = 'Home';
          defaultIcon = 'home';
          defaultColor = const Color(0xFF6366F1);
        }

        final newTab = BentoDashboardTab(
          id: 'tab_${const Uuid().v4()}',
          contextKey: contextKey,
          title: defaultTitle,
          iconName: defaultIcon,
          accentColor: defaultColor,
          orderIndex: 0,
          layout: _getDefaultLayout(),
          isDefault: true,
        );
        tabs.add(newTab);
        updatedConfig = updatedConfig.copyWith(
          tabs: tabs,
          activeTabId: newTab.id,
          updatedAt: DateTime.now(),
        );
        _dashboardService.saveDashboardConfig(updatedConfig);
      } else {
        final activeForCtx = currentState.config.activeTabForContext(contextKey);
        if (activeForCtx != null) {
          updatedConfig = updatedConfig.copyWith(activeTabId: activeForCtx.id);
        }
      }

      emit(currentState.copyWith(
        config: updatedConfig,
        currentContextKey: contextKey,
      ));
    }
  }

  void _onSelectDashboardTab(SelectDashboardTab event, Emitter<DashboardState> emit) {
    if (state is DashboardLoaded) {
      final currentState = state as DashboardLoaded;
      final tabExists = currentState.config.tabs.any((t) => t.id == event.tabId);
      if (!tabExists) return;

      final updatedConfig = currentState.config.copyWith(
        activeTabId: event.tabId,
        updatedAt: DateTime.now(),
      );
      emit(currentState.copyWith(config: updatedConfig));
      _dashboardService.saveDashboardConfig(updatedConfig);
    }
  }

  void _onCreateDashboardTab(CreateDashboardTab event, Emitter<DashboardState> emit) {
    if (state is DashboardLoaded) {
      final currentState = state as DashboardLoaded;
      final contextTabs = currentState.config.tabsForContext(event.contextKey);

      final newTab = BentoDashboardTab(
        id: 'tab_${const Uuid().v4()}',
        contextKey: event.contextKey,
        title: event.title,
        iconName: event.iconName,
        accentColor: event.accentColor,
        orderIndex: contextTabs.length,
        layout: event.initialLayout ?? _getDefaultLayout(),
        isDefault: contextTabs.isEmpty,
      );

      final updatedTabs = [...currentState.config.tabs, newTab];
      final updatedConfig = currentState.config.copyWith(
        tabs: updatedTabs,
        activeTabId: newTab.id,
        updatedAt: DateTime.now(),
      );
      emit(currentState.copyWith(
        config: updatedConfig,
        currentContextKey: event.contextKey,
      ));
      _dashboardService.saveDashboardConfig(updatedConfig);
    }
  }

  void _onDeleteDashboardTab(DeleteDashboardTab event, Emitter<DashboardState> emit) {
    if (state is DashboardLoaded) {
      final currentState = state as DashboardLoaded;
      final tabToDelete = currentState.config.tabs.where((t) => t.id == event.tabId).firstOrNull;
      if (tabToDelete == null) return;

      final contextTabs = currentState.config.tabsForContext(tabToDelete.contextKey);
      // Don't delete if it's the last remaining tab in this context
      if (contextTabs.length <= 1) return;

      final updatedTabs = currentState.config.tabs.where((t) => t.id != event.tabId).toList();
      String? newActiveTabId = currentState.config.activeTabId;

      if (currentState.config.activeTabId == event.tabId) {
        final remainingForContext = updatedTabs.where((t) => t.contextKey == tabToDelete.contextKey).toList();
        remainingForContext.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
        newActiveTabId = remainingForContext.firstOrNull?.id;
      }

      final updatedConfig = currentState.config.copyWith(
        tabs: updatedTabs,
        activeTabId: newActiveTabId,
        updatedAt: DateTime.now(),
      );
      emit(currentState.copyWith(config: updatedConfig));
      _dashboardService.saveDashboardConfig(updatedConfig);
    }
  }

  void _onReorderDashboardTabs(ReorderDashboardTabs event, Emitter<DashboardState> emit) {
    if (state is DashboardLoaded) {
      final currentState = state as DashboardLoaded;
      final updatedTabs = currentState.config.tabs.map((tab) {
        final newIndex = event.orderedTabIds.indexOf(tab.id);
        if (newIndex != -1) {
          return tab.copyWith(orderIndex: newIndex);
        }
        return tab;
      }).toList();

      final updatedConfig = currentState.config.copyWith(
        tabs: updatedTabs,
        updatedAt: DateTime.now(),
      );
      emit(currentState.copyWith(config: updatedConfig));
      _dashboardService.saveDashboardConfig(updatedConfig);
    }
  }

  void _onUpdateDashboardTabInfo(UpdateDashboardTabInfo event, Emitter<DashboardState> emit) {
    if (state is DashboardLoaded) {
      final currentState = state as DashboardLoaded;
      final updatedTabs = currentState.config.tabs.map((tab) {
        if (tab.id == event.tabId) {
          return tab.copyWith(
            title: event.title ?? tab.title,
            iconName: event.iconName ?? tab.iconName,
            accentColor: event.accentColor ?? tab.accentColor,
          );
        }
        return tab;
      }).toList();

      final updatedConfig = currentState.config.copyWith(
        tabs: updatedTabs,
        updatedAt: DateTime.now(),
      );
      emit(currentState.copyWith(config: updatedConfig));
      _dashboardService.saveDashboardConfig(updatedConfig);
    }
  }

  void _onUpdateLayout(UpdateLayout event, Emitter<DashboardState> emit) {
    if (state is DashboardLoaded) {
      final currentState = state as DashboardLoaded;
      final active = currentState.activeTab;
      if (active == null) return;

      final updatedTabs = currentState.config.tabs.map((tab) {
        if (tab.id == active.id) {
          return tab.copyWith(layout: event.newLayout);
        }
        return tab;
      }).toList();

      final updatedConfig = currentState.config.copyWith(
        tabs: updatedTabs,
        updatedAt: DateTime.now(),
      );
      emit(currentState.copyWith(config: updatedConfig));
    }
  }

  void _onApplyPresetLayout(ApplyPresetLayout event, Emitter<DashboardState> emit) {
    if (state is DashboardLoaded) {
      final currentState = state as DashboardLoaded;
      final active = currentState.activeTab;
      if (active == null) return;

      final updatedTabs = currentState.config.tabs.map((tab) {
        if (tab.id == active.id) {
          return tab.copyWith(layout: event.layout);
        }
        return tab;
      }).toList();

      final updatedConfig = currentState.config.copyWith(
        tabs: updatedTabs,
        updatedAt: DateTime.now(),
      );
      emit(currentState.copyWith(config: updatedConfig));
      _dashboardService.saveDashboardConfig(updatedConfig);
    }
  }

  Future<void> _onSaveDashboard(SaveDashboard event, Emitter<DashboardState> emit) async {
    if (state is DashboardLoaded) {
      final currentState = state as DashboardLoaded;
      try {
        await _dashboardService.saveDashboardConfig(currentState.config);
      } catch (e) {
        // Handle save error silently or emit error state
      }
    }
  }

  void _onResizeWidget(ResizeWidget event, Emitter<DashboardState> emit) {
    if (state is DashboardLoaded) {
      final currentState = state as DashboardLoaded;
      final active = currentState.activeTab;
      if (active == null) return;

      final layout = List<BentoWidgetDef>.from(active.layout);
      final index = layout.indexWhere((w) => w.id == event.widgetId);
      if (index != -1) {
        final widgetDef = layout[index];
        final allowedSizes = DashboardWidgetFactory.getAllowedSizes(widgetDef.type);
        
        if (allowedSizes.length > 1) {
          final currentSizeIndex = allowedSizes.indexOf(widgetDef.size);
          final nextSizeIndex = (currentSizeIndex + 1) % allowedSizes.length;
          
          layout[index] = widgetDef.copyWith(size: allowedSizes[nextSizeIndex]);
          
          final updatedTabs = currentState.config.tabs.map((tab) {
            if (tab.id == active.id) {
              return tab.copyWith(layout: layout);
            }
            return tab;
          }).toList();

          final updatedConfig = currentState.config.copyWith(
            tabs: updatedTabs,
            updatedAt: DateTime.now(),
          );
          emit(currentState.copyWith(config: updatedConfig));
        }
      }
    }
  }

  List<BentoWidgetDef> _getDefaultLayout() {
    return [
      BentoWidgetDef(id: 'w1', type: 'balance', size: const BentoWidgetSize(2, 1)),
      BentoWidgetDef(id: 'w2', type: 'quick_expense', size: const BentoWidgetSize(2, 4)),
      BentoWidgetDef(id: 'w3', type: 'focus_tasks', size: const BentoWidgetSize(2, 4)),
      BentoWidgetDef(id: 'w4', type: 'monthly_burn_rate', size: const BentoWidgetSize(2, 2)),
    ];
  }
}
