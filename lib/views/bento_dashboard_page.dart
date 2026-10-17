import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:solducci/blocs/dashboard/dashboard_bloc.dart';
import 'package:solducci/blocs/dashboard/dashboard_event.dart';
import 'package:solducci/blocs/dashboard/dashboard_state.dart';
import 'package:solducci/widgets/dashboard/dashboard_widget_factory.dart';
import 'package:solducci/widgets/solducci_app_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:solducci/models/dashboard_config.dart';
import 'package:solducci/service/context_manager.dart';
import 'package:solducci/widgets/dashboard/bento_config_sheet.dart';
import 'package:solducci/widgets/dashboard/widget_gallery_sheet.dart';
import 'package:solducci/widgets/dashboard/bento_mosaic_engine.dart';
import 'package:solducci/widgets/dashboard/bento_resize_sheet.dart';
import 'package:solducci/widgets/dashboard/bento_preset_sheet.dart';
import 'package:solducci/widgets/dashboard/bento_dashboard_tabs_bar.dart';

class BentoDashboardPage extends StatelessWidget {
  const BentoDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DashboardBloc()..add(const LoadDashboard()),
      child: const _BentoDashboardView(),
    );
  }
}

class _DraggingItemData {
  final BentoWidgetDef def;
  final int? sourceIndex; // null if from library

  _DraggingItemData(this.def, this.sourceIndex);
}

class _BentoDashboardView extends StatefulWidget {
  const _BentoDashboardView();

  @override
  State<_BentoDashboardView> createState() => _BentoDashboardViewState();
}

class _BentoDashboardViewState extends State<_BentoDashboardView> {
  List<BentoWidgetDef>? _dragPreviewLayout;
  String? _draggingWidgetId;
  bool _isTabsOverlayOpen = false;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    ContextManager().addListener(_onContextChanged);
  }

  @override
  void dispose() {
    _pageController.dispose();
    ContextManager().removeListener(_onContextChanged);
    super.dispose();
  }

  void _onContextChanged() {
    final currentKey = ContextManager().currentContext.contextKey;
    context.read<DashboardBloc>().add(SwitchDashboardContext(currentKey));
    if (mounted) {
      setState(() {
        _isTabsOverlayOpen = false;
      });
    }
  }

  void _onDragStarted(List<BentoWidgetDef> currentLayout, String draggingId) {
    HapticFeedback.mediumImpact();
    setState(() {
      _isTabsOverlayOpen = false;
      _draggingWidgetId = draggingId;
      _dragPreviewLayout = List.from(currentLayout);
    });
  }

  void _onDragEnded() {
    setState(() {
      _draggingWidgetId = null;
      _dragPreviewLayout = null;
    });
  }

  void _onHover(int targetIndex, _DraggingItemData data, List<BentoWidgetDef> originalLayout) {
    if (_dragPreviewLayout == null) return;
    
    final newLayout = BentoMosaicEngine.previewDisplacement(
      currentLayout: originalLayout,
      draggingItem: data.def,
      targetIndex: targetIndex,
    );
    
    // Only rebuild if the layout actually changed from the current preview
    bool isDifferent = false;
    if (_dragPreviewLayout!.length != newLayout.length) {
      isDifferent = true;
    } else {
      for (int i = 0; i < newLayout.length; i++) {
        if (_dragPreviewLayout![i].id != newLayout[i].id) {
          isDifferent = true;
          break;
        }
      }
    }
    
    if (isDifferent) {
      HapticFeedback.selectionClick();
      setState(() {
        _dragPreviewLayout = newLayout;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B), // OLED Dark
      appBar: SolducciAppBar(
        title: BlocBuilder<DashboardBloc, DashboardState>(
          builder: (context, state) {
            if (state is DashboardLoaded) {
              final activeTab = state.activeTab;
              if (activeTab != null) {
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _isTabsOverlayOpen = !_isTabsOverlayOpen;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _isTabsOverlayOpen
                          ? Colors.white.withOpacity(0.08)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          getTabIconData(activeTab.iconName),
                          size: 18,
                          color: activeTab.accentColor,
                        ),
                        const SizedBox(width: 7),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          transitionBuilder: (child, anim) => FadeTransition(
                            opacity: anim,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.15),
                                end: Offset.zero,
                              ).animate(anim),
                              child: child,
                            ),
                          ),
                          child: Text(
                            activeTab.title,
                            key: ValueKey(activeTab.id),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        AnimatedRotation(
                          turns: _isTabsOverlayOpen ? 0.5 : 0.0,
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          child: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 20,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
            }
            return const Text(
              'Feed',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),
        centerTitle: true,
        elevation: 2,
        actions: [
          BlocBuilder<DashboardBloc, DashboardState>(
            builder: (context, state) {
              if (state is DashboardLoaded) {
                return Row(
                  children: [
                    if (state.isEditing) ...[
                      IconButton(
                        icon: const Icon(Icons.auto_awesome_mosaic_outlined, color: Colors.indigoAccent),
                        tooltip: 'Modelli & Preset',
                        onPressed: () => _openPresetSheet(context, state),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, color: Colors.orangeAccent),
                        tooltip: 'Aggiungi widget',
                        onPressed: () => _openWidgetGallery(context, state),
                      ),
                    ],
                    IconButton(
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        transitionBuilder: (child, anim) => RotationTransition(
                          turns: anim,
                          child: FadeTransition(opacity: anim, child: child),
                        ),
                        child: Icon(
                          state.isEditing ? Icons.check_rounded : Icons.edit_rounded,
                          key: ValueKey(state.isEditing),
                          color: state.isEditing ? const Color(0xFF10B981) : Colors.white,
                        ),
                      ),
                      tooltip: state.isEditing ? 'Salva modifiche' : 'Personalizza feed',
                      onPressed: () {
                        if (state.isEditing) {
                          HapticFeedback.mediumImpact();
                          context.read<DashboardBloc>().add(SaveDashboard());
                        } else {
                          HapticFeedback.heavyImpact();
                        }
                        setState(() {
                          _isTabsOverlayOpen = false;
                        });
                        context.read<DashboardBloc>().add(ToggleEditMode());
                      },
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.white), 
            onPressed: () {
              context.push('/profile');
            }
          ),
        ],
      ),
      body: BlocConsumer<DashboardBloc, DashboardState>(
        listener: (context, state) {
          if (state is DashboardLoaded) {
            final targetKey = ContextManager().currentContext.contextKey;
            if (state.currentContextKey != targetKey) {
              context.read<DashboardBloc>().add(SwitchDashboardContext(targetKey));
              return;
            }

            // Sync PageController with active tab
            final tabs = state.currentContextTabs;
            final activeIndex = tabs.indexWhere((t) => t.id == state.activeTab?.id);
            if (activeIndex != -1 && _pageController.hasClients) {
              final currentPage = _pageController.page?.round() ?? _pageController.initialPage;
              if (currentPage != activeIndex) {
                _pageController.animateToPage(
                  activeIndex,
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutCubic,
                );
              }
            }
          }
        },
        builder: (context, state) {
          if (state is DashboardLoading || state is DashboardInitial) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)));
          }

          if (state is DashboardError) {
            return Center(child: Text(state.message, style: const TextStyle(color: Colors.red)));
          }

          if (state is DashboardLoaded) {
            final tabs = state.currentContextTabs;

            return Stack(
              children: [
                // 1. Full-screen PageView for all dashboard tabs
                PageView.builder(
                  controller: _pageController,
                  physics: state.isEditing
                      ? const NeverScrollableScrollPhysics()
                      : const BouncingScrollPhysics(),
                  itemCount: tabs.length,
                  onPageChanged: (pageIndex) {
                    if (pageIndex >= 0 && pageIndex < tabs.length) {
                      final targetTab = tabs[pageIndex];
                      if (targetTab.id != state.activeTab?.id) {
                        HapticFeedback.selectionClick();
                        context.read<DashboardBloc>().add(SelectDashboardTab(targetTab.id));
                      }
                    }
                  },
                  itemBuilder: (context, pageIndex) {
                    final tab = tabs[pageIndex];
                    return ListenableBuilder(
                      listenable: ContextManager(),
                      builder: (context, _) {
                        return _buildGridForTab(context, state, tab, ContextManager().currentContext);
                      },
                    );
                  },
                ),

                // 2. Dismissible backdrop barrier when overlay is open
                if (_isTabsOverlayOpen)
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        setState(() => _isTabsOverlayOpen = false);
                      },
                      child: Container(
                        color: Colors.black.withOpacity(0.55),
                      ),
                    ),
                  ),

                // 3. Floating Glassmorphism Tabs Bar Overlay
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _buildTabsOverlay(context, state),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildTabsOverlay(BuildContext context, DashboardLoaded state) {
    return AnimatedCrossFade(
      duration: const Duration(milliseconds: 240),
      firstCurve: Curves.easeOutCubic,
      secondCurve: Curves.easeInCubic,
      crossFadeState: _isTabsOverlayOpen ? CrossFadeState.showFirst : CrossFadeState.showSecond,
      firstChild: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF101014).withOpacity(0.92),
          border: Border(
            bottom: BorderSide(
              color: Colors.white.withOpacity(0.12),
              width: 1.0,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.65),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: BentoDashboardTabsBar(
                state: state,
                onTabSelected: (tabId) {
                  setState(() => _isTabsOverlayOpen = false);
                  final index = state.currentContextTabs.indexWhere((t) => t.id == tabId);
                  if (index != -1 && _pageController.hasClients) {
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeOutCubic,
                    );
                  }
                },
              ),
            ),
          ),
        ),
      ),
      secondChild: const SizedBox(width: double.infinity, height: 0),
    );
  }

  Widget _buildGridForTab(
    BuildContext context,
    DashboardLoaded state,
    BentoDashboardTab tab,
    ExpenseContext appContext,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final columns = BentoMosaicEngine.getColumnCount(screenWidth);

    final bool isActiveTab = tab.id == state.activeTab?.id;
    final currentLayout = isActiveTab ? (_dragPreviewLayout ?? tab.layout) : tab.layout;
    final activeLayout = BentoMosaicEngine.reorderForMosaic(
      widgets: currentLayout,
      columns: columns,
    );
    
    if (activeLayout.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF18181B),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: const Icon(Icons.widgets_outlined, size: 40, color: Colors.white38),
              ),
              const SizedBox(height: 20),
              const Text(
                'Nessun widget nel Feed',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Personalizza la tua bento home aggiungendo widget per finanze, note e abitudini.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Galleria Widget'),
                    onPressed: () => _openWidgetGallery(context, state),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withOpacity(0.2)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(Icons.auto_awesome_mosaic_outlined, size: 18),
                    label: const Text('Modelli & Preset'),
                    onPressed: () => _openPresetSheet(context, state),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    final double availableWidth = screenWidth - 32;
    final double colWidth = (availableWidth - (columns - 1) * 16) / columns;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(
        left: 16.0, 
        right: 16.0, 
        top: 16.0, 
        bottom: 36.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StaggeredGrid.count(
            crossAxisCount: columns,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: activeLayout.asMap().entries.map((entry) {
          final index = entry.key;
          final widgetDef = entry.value;

          Widget baseContent = Stack(
            children: [
              Positioned.fill(
                child: DashboardWidgetFactory.buildWidget(
                  context,
                  widgetDef,
                  tabContext: appContext,
                ),
              ),
              if (state.isEditing)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.transparent, // Blocks inner taps
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              if (state.isEditing)
                Positioned(
                  top: 8,
                  left: 8,
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      final newLayout = List<BentoWidgetDef>.from(currentLayout);
                      newLayout.removeWhere((w) => w.id == widgetDef.id);
                      final packed = BentoMosaicEngine.reorderForMosaic(
                        widgets: newLayout,
                        columns: columns,
                      );
                      context.read<DashboardBloc>().add(UpdateLayout(packed));
                    },
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF27272A),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.18)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.close_rounded, size: 13, color: Color(0xFFEF4444)),
                    ),
                  ),
                ),
              if (state.isEditing && DashboardWidgetFactory.requiresInit(widgetDef.type))
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () async {
                      HapticFeedback.selectionClick();
                      final customProps = await _showInitModal(context, widgetDef.type, widgetDef.customProps);
                      if (customProps != null && context.mounted) {
                        final newLayout = List<BentoWidgetDef>.from(currentLayout);
                        final i = newLayout.indexWhere((w) => w.id == widgetDef.id);
                        if (i != -1) {
                          newLayout[i] = newLayout[i].copyWith(customProps: customProps);
                          context.read<DashboardBloc>().add(UpdateLayout(newLayout));
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF27272A),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.18)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.tune_rounded, size: 13, color: Color(0xFF60A5FA)),
                    ),
                  ),
                ),
              if (state.isEditing && DashboardWidgetFactory.getSupportedSizes(widgetDef.type).length > 1)
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () {
                      BentoResizeSheet.show(
                        context: context,
                        widgetDef: widgetDef,
                        onSizeSelected: (newSize) {
                          final newLayout = List<BentoWidgetDef>.from(currentLayout);
                          final targetIndex = newLayout.indexWhere((w) => w.id == widgetDef.id);
                          if (targetIndex != -1) {
                            newLayout[targetIndex] = newLayout[targetIndex].copyWith(size: newSize);
                            final packed = BentoMosaicEngine.reorderForMosaic(
                              widgets: newLayout,
                              columns: columns,
                            );
                            context.read<DashboardBloc>().add(UpdateLayout(packed));
                          }
                        },
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withOpacity(0.18)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${widgetDef.size.crossAxisCellCount}x${widgetDef.size.mainAxisCellCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.aspect_ratio_rounded, size: 13, color: Colors.white70),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );

          Widget finalContent = baseContent;
          if (state.isEditing) {
            final isBeingDragged = _draggingWidgetId == widgetDef.id;

            final Widget ghostSlot = Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFF6366F1).withOpacity(0.4),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.crop_free_rounded,
                    color: Color(0xFF818CF8),
                    size: 20,
                  ),
                ),
              ),
            );

            final double previewWidth = (widgetDef.size.crossAxisCellCount * colWidth + 
                (widgetDef.size.crossAxisCellCount - 1) * 16).clamp(80.0, availableWidth);
            final double previewHeight = widgetDef.size.mainAxisCellCount * 67.5;

            finalContent = DragTarget<_DraggingItemData>(
              onWillAcceptWithDetails: (details) {
                if (details.data.sourceIndex == index && details.data.def.id == widgetDef.id) {
                  return true; 
                }
                _onHover(index, details.data, currentLayout);
                return true;
              },
              onAcceptWithDetails: (details) async {
                final proposedLayout = _dragPreviewLayout;
                _onDragEnded();
                
                if (proposedLayout != null) {
                  if (details.data.sourceIndex == null && DashboardWidgetFactory.requiresInit(details.data.def.type)) {
                    final customProps = await _showInitModal(context, details.data.def.type);
                    if (customProps != null) {
                      final targetIndex = proposedLayout.indexWhere((w) => w.id == details.data.def.id);
                      if (targetIndex != -1) {
                        proposedLayout[targetIndex] = proposedLayout[targetIndex].copyWith(customProps: customProps);
                      }
                      if (context.mounted) {
                        final packed = BentoMosaicEngine.reorderForMosaic(
                          widgets: proposedLayout,
                          columns: columns,
                        );
                        context.read<DashboardBloc>().add(UpdateLayout(packed));
                      }
                    }
                  } else {
                    final packed = BentoMosaicEngine.reorderForMosaic(
                      widgets: proposedLayout,
                      columns: columns,
                    );
                    context.read<DashboardBloc>().add(UpdateLayout(packed));
                  }
                }
              },
              builder: (context, candidateData, rejectedData) {
                return LongPressDraggable<_DraggingItemData>(
                  data: _DraggingItemData(widgetDef, currentLayout.indexWhere((w) => w.id == widgetDef.id)),
                  onDragStarted: () => _onDragStarted(currentLayout, widgetDef.id),
                  onDragEnd: (details) => _onDragEnded(),
                  onDraggableCanceled: (velocity, offset) => _onDragEnded(),
                  feedback: Material(
                    color: Colors.transparent,
                    child: Transform.scale(
                      scale: 1.04,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.65),
                              blurRadius: 28,
                              offset: const Offset(0, 14),
                            ),
                            BoxShadow(
                              color: const Color(0xFF6366F1).withOpacity(0.35),
                              blurRadius: 18,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: SizedBox(
                          width: previewWidth,
                          height: previewHeight,
                          child: DashboardWidgetFactory.buildWidget(
                            context,
                            widgetDef,
                            tabContext: appContext,
                          ),
                        ),
                      ),
                    ),
                  ),
                  childWhenDragging: ghostSlot,
                  child: isBeingDragged ? ghostSlot : baseContent,
                );
              },
            );
          }

          final contextKeySuffix = appContext.groupId ?? 'personal';
          
          Widget animatedChild = finalContent
              .animate(key: ValueKey('${widgetDef.id}_pos_$contextKeySuffix'))
              .fadeIn(
                duration: 320.ms,
                delay: ((index * 25).clamp(0, 250)).ms,
                curve: Curves.easeOutQuad,
              )
              .scale(
                begin: const Offset(0.96, 0.96),
                duration: 320.ms,
                delay: ((index * 25).clamp(0, 250)).ms,
                curve: Curves.easeOutCubic,
              );

          return StaggeredGridTile.count(
            key: ValueKey('${widgetDef.id}_$contextKeySuffix'),
            crossAxisCellCount: widgetDef.size.crossAxisCellCount,
            mainAxisCellCount: widgetDef.size.mainAxisCellCount * 0.75,
            child: WobbleWidget(
              isWobbling: state.isEditing,
              wobbleSeed: index,
              child: animatedChild,
            ),
          );
        }).toList(),
      ),
      if (state.isEditing) ...[
        const SizedBox(height: 20),
        InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _openWidgetGallery(context, state),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: const Color(0xFF18181B),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: Colors.orangeAccent, size: 18),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Aggiungi Widget al Feed',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ],
  ),
);
}

  void _openWidgetGallery(BuildContext context, DashboardLoaded state) {
    final currentLayout = state.activeTab?.layout ?? state.config.layout;
    WidgetGallerySheet.show(
      context: context,
      currentLayout: currentLayout,
      onAddWidget: (newDef) {
        final screenWidth = MediaQuery.of(context).size.width;
        final columns = BentoMosaicEngine.getColumnCount(screenWidth);
        final newLayout = List<BentoWidgetDef>.from(currentLayout)..add(newDef);
        final packed = BentoMosaicEngine.reorderForMosaic(
          widgets: newLayout,
          columns: columns,
        );
        context.read<DashboardBloc>().add(UpdateLayout(packed));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Widget "${WidgetCatalog.findByType(newDef.type)?.name ?? newDef.type}" aggiunto a "${state.activeTab?.title ?? 'Feed'}"'),
            backgroundColor: const Color(0xFF27272A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      onConfigureWidget: (ctx, type) => _showInitModal(ctx, type),
    );
  }

  void _openPresetSheet(BuildContext context, DashboardLoaded state) {
    final isGroup = !ContextManager().isPersonalContext;
    final currentLayout = state.activeTab?.layout ?? state.config.layout;
    BentoPresetSheet.show(
      context: context,
      currentLayout: currentLayout,
      isGroupContext: isGroup,
      onApplyLayout: (newLayout) {
        final screenWidth = MediaQuery.of(context).size.width;
        final columns = BentoMosaicEngine.getColumnCount(screenWidth);
        final packed = BentoMosaicEngine.reorderForMosaic(
          widgets: newLayout,
          columns: columns,
        );
        context.read<DashboardBloc>().add(ApplyPresetLayout(packed));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Template applicato con successo a "${state.activeTab?.title ?? 'Feed'}"!'),
            backgroundColor: const Color(0xFF27272A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>?> _showInitModal(
    BuildContext context,
    String type, [
    Map<String, dynamic>? currentProps,
  ]) async {
    return await BentoConfigSheet.showForType(
      context: context,
      widgetType: type,
      currentProps: currentProps,
    );
  }
}


class WobbleWidget extends StatefulWidget {
  final bool isWobbling;
  final int wobbleSeed;
  final Widget child;

  const WobbleWidget({
    super.key,
    required this.isWobbling,
    required this.wobbleSeed,
    required this.child,
  });

  @override
  State<WobbleWidget> createState() => _WobbleWidgetState();
}

class _WobbleWidgetState extends State<WobbleWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Durata leggermente differenziata per ogni tile per evitare oscillazioni sincrone a blocco
    final durationMs = 280 + (widget.wobbleSeed % 4) * 25;
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: durationMs),
    );
    if (widget.isWobbling) {
      _controller.repeat(reverse: true);
    } else {
      _controller.value = 0.5; // Neutral position
    }
  }

  @override
  void didUpdateWidget(WobbleWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isWobbling && !oldWidget.isWobbling) {
      _controller.repeat(reverse: true);
    } else if (!widget.isWobbling && oldWidget.isWobbling) {
      _controller.animateTo(0.5, duration: const Duration(milliseconds: 180), curve: Curves.easeOutCubic);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEven = widget.wobbleSeed % 2 == 0;
    final double maxAngle = isEven ? 0.0035 : -0.0035;
    final double maxTranslate = isEven ? 0.75 : -0.75;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = (_controller.value * 2) - 1.0;
        final angle = value * maxAngle * 2 * 3.14159;
        final offset = Offset(value * maxTranslate, -value * maxTranslate * 0.4);

        return Transform.translate(
          offset: offset,
          child: Transform.rotate(
            angle: angle,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
