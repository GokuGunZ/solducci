import 'package:flutter/material.dart';
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
import 'package:solducci/service/wallet_service.dart';
import 'package:solducci/service/document_service.dart';
import 'package:solducci/service/time_management_service.dart';
import 'package:solducci/models/expense_form.dart';
import 'package:solducci/utils/category_helpers.dart';
import 'package:solducci/widgets/dashboard/widget_gallery_sheet.dart';

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

  void _onDragStarted(List<BentoWidgetDef> currentLayout) {
    setState(() {
      _dragPreviewLayout = List.from(currentLayout);
    });
  }

  void _onDragEnded() {
    setState(() {
      _dragPreviewLayout = null;
    });
  }

  void _onHover(int targetIndex, _DraggingItemData data, List<BentoWidgetDef> originalLayout) {
    if (_dragPreviewLayout == null) return;
    
    final newLayout = List<BentoWidgetDef>.from(originalLayout);
    
    if (data.sourceIndex != null) {
      // It's moving an existing widget
      final item = newLayout.removeAt(data.sourceIndex!);
      
      // If we are dropping it further down, the indices shift
      int adjustedTarget = targetIndex;
      if (data.sourceIndex! < targetIndex) {
        adjustedTarget -= 1;
      }
      
      newLayout.insert(adjustedTarget, item);
    } else {
      // It's a new widget from the library
      newLayout.insert(targetIndex, data.def);
    }
    
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
        titleText: 'Feed',
        centerTitle: true,
        elevation: 2,
        actions: [
          BlocBuilder<DashboardBloc, DashboardState>(
            builder: (context, state) {
              if (state is DashboardLoaded) {
                return Row(
                  children: [
                    if (state.isEditing)
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, color: Colors.orangeAccent),
                        tooltip: 'Aggiungi widget',
                        onPressed: () => _openWidgetGallery(context, state),
                      ),
                    IconButton(
                      icon: Icon(state.isEditing ? Icons.check : Icons.edit, color: Colors.white),
                      onPressed: () {
                        context.read<DashboardBloc>().add(ToggleEditMode());
                        if (state.isEditing) {
                          context.read<DashboardBloc>().add(SaveDashboard());
                        }
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
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          if (state is DashboardLoading || state is DashboardInitial) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)));
          }

          if (state is DashboardError) {
            return Center(child: Text(state.message, style: const TextStyle(color: Colors.red)));
          }

          if (state is DashboardLoaded) {
            return ListenableBuilder(
              listenable: ContextManager(),
              builder: (context, _) {
                return _buildGrid(context, state, ContextManager().currentContext);
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildGrid(BuildContext context, DashboardLoaded state, ExpenseContext appContext) {
    final activeLayout = _dragPreviewLayout ?? state.config.layout;
    
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
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Apri Galleria Widget'),
                onPressed: () => _openWidgetGallery(context, state),
              ),
            ],
          ),
        ),
      );
    }

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
            crossAxisCount: 4,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: activeLayout.asMap().entries.map((entry) {
          final index = entry.key;
          final widgetDef = entry.value;

          Widget baseContent = Stack(
            children: [
              Positioned.fill(
                child: DashboardWidgetFactory.buildWidget(context, widgetDef),
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
                      final newLayout = List<BentoWidgetDef>.from(state.config.layout);
                      newLayout.removeWhere((w) => w.id == widgetDef.id);
                      context.read<DashboardBloc>().add(UpdateLayout(newLayout));
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, size: 16, color: Colors.white),
                    ),
                  ),
                ),
              if (state.isEditing && DashboardWidgetFactory.requiresInit(widgetDef.type))
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () async {
                      final customProps = await _showInitModal(context, widgetDef.type);
                      if (customProps != null && context.mounted) {
                        final newLayout = List<BentoWidgetDef>.from(state.config.layout);
                        final i = newLayout.indexWhere((w) => w.id == widgetDef.id);
                        if (i != -1) {
                          newLayout[i] = newLayout[i].copyWith(customProps: customProps);
                          context.read<DashboardBloc>().add(UpdateLayout(newLayout));
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.grey,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.settings, size: 16, color: Colors.white),
                    ),
                  ),
                ),
              if (state.isEditing && DashboardWidgetFactory.getAllowedSizes(widgetDef.type).length > 1)
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () {
                      context.read<DashboardBloc>().add(ResizeWidget(widgetDef.id));
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.blueAccent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.aspect_ratio, size: 16, color: Colors.white),
                    ),
                  ),
                ),
            ],
          );

          Widget finalContent = baseContent;
          if (state.isEditing) {
            finalContent = DragTarget<_DraggingItemData>(
              onWillAcceptWithDetails: (details) {
                // If it's the exact same item from the exact same original index, ignore
                if (details.data.sourceIndex == index && details.data.def.id == widgetDef.id) {
                  return true; 
                }
                _onHover(index, details.data, state.config.layout);
                return true;
              },
              onAcceptWithDetails: (details) async {
                final proposedLayout = _dragPreviewLayout;
                _onDragEnded(); // Clear preview immediately
                
                if (proposedLayout != null) {
                  if (details.data.sourceIndex == null && DashboardWidgetFactory.requiresInit(details.data.def.type)) {
                    final customProps = await _showInitModal(context, details.data.def.type);
                    if (customProps != null) {
                      final index = proposedLayout.indexWhere((w) => w.id == details.data.def.id);
                      if (index != -1) {
                        proposedLayout[index] = proposedLayout[index].copyWith(customProps: customProps);
                      }
                      // Use mounted check ideally, but we are in a stateless widget closure, so context might be invalid if page is gone. 
                      // However, since it's a modal over the same page, it should be fine.
                      if (context.mounted) {
                        context.read<DashboardBloc>().add(UpdateLayout(proposedLayout));
                      }
                    }
                  } else {
                    context.read<DashboardBloc>().add(UpdateLayout(proposedLayout));
                  }
                }
              },
              builder: (context, candidateData, rejectedData) {
                // To support dragging to the very end of the list, we can add a fake target at the end.
                // But for now, every existing tile acts as a target that inserts BEFORE it.
                
                return LongPressDraggable<_DraggingItemData>(
                  data: _DraggingItemData(widgetDef, state.config.layout.indexWhere((w) => w.id == widgetDef.id)),
                  onDragStarted: () => _onDragStarted(state.config.layout),
                  onDragEnd: (details) => _onDragEnded(),
                  onDraggableCanceled: (velocity, offset) => _onDragEnded(),
                  feedback: Material(
                    color: Colors.transparent,
                    child: Opacity(
                      opacity: 0.8,
                      child: SizedBox(
                        width: widgetDef.size.crossAxisCellCount * 90.0,
                        height: widgetDef.size.mainAxisCellCount * 90.0,
                        child: baseContent,
                      ),
                    ),
                  ),
                  childWhenDragging: Opacity(
                    opacity: 0.1,
                    child: baseContent,
                  ),
                  child: baseContent,
                );
              },
            );
          }

          final contextKeySuffix = appContext.groupId ?? 'personal';
          
          Widget animatedChild = finalContent
              .animate(key: ValueKey('${widgetDef.id}_pos_$contextKeySuffix'))
              .fadeIn(duration: 300.ms)
              .scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOutQuad);

          return StaggeredGridTile.count(
            key: ValueKey('${widgetDef.id}_$contextKeySuffix'),
            crossAxisCellCount: widgetDef.size.crossAxisCellCount,
            mainAxisCellCount: widgetDef.size.mainAxisCellCount,
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
    WidgetGallerySheet.show(
      context: context,
      currentLayout: state.config.layout,
      onAddWidget: (newDef) {
        final newLayout = List<BentoWidgetDef>.from(state.config.layout)..add(newDef);
        context.read<DashboardBloc>().add(UpdateLayout(newLayout));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Widget "${WidgetCatalog.findByType(newDef.type)?.name ?? newDef.type}" aggiunto al Feed'),
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
  Future<Map<String, dynamic>?> _showInitModal(BuildContext context, String type) async {
    return await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: const Color(0xFF18181B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      isScrollControlled: true,
      builder: (modalContext) {
        return _DynamicInitModalSheet(type: type);
      },
    );
  }
}

class _WidgetOptionItem {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final Map<String, dynamic> customProps;

  const _WidgetOptionItem({
    required this.title,
    this.subtitle,
    required this.icon,
    required this.color,
    required this.customProps,
  });
}

class _DynamicInitModalSheet extends StatefulWidget {
  final String type;
  const _DynamicInitModalSheet({required this.type});

  @override
  State<_DynamicInitModalSheet> createState() => _DynamicInitModalSheetState();
}

class _DynamicInitModalSheetState extends State<_DynamicInitModalSheet> {
  bool _loading = true;
  String _title = 'Configura Widget';
  List<_WidgetOptionItem> _options = [];

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    final currentContext = ContextManager().currentContext;
    final options = <_WidgetOptionItem>[];

    try {
      if (widget.type == 'balance') {
        _title = 'Seleziona Conto o Saldo';
        options.add(const _WidgetOptionItem(
          title: 'Tutti i Portafogli (Panoramica)',
          subtitle: 'Mostra il totale e permette lo swipe tra i conti',
          icon: Icons.account_balance_wallet_rounded,
          color: Color(0xFF10B981),
          customProps: {'source': 'all', 'title': 'Tutti i Portafogli'},
        ));

        if (currentContext.isGroup) {
          options.add(const _WidgetOptionItem(
            title: 'Saldo di Gruppo',
            subtitle: 'Crediti e debiti con i membri del gruppo',
            icon: Icons.group_rounded,
            color: Color(0xFF6366F1),
            customProps: {'source': 'group_balance', 'title': 'Saldo di Gruppo'},
          ));
        }

        final wallets = await WalletService().fetchWallets();
        for (final w in wallets) {
          options.add(_WidgetOptionItem(
            title: w.name,
            subtitle: '${w.currentBalance.toStringAsFixed(2)} €',
            icon: w.type.icon,
            color: w.color,
            customProps: {'source': 'wallet', 'walletId': w.id, 'title': w.name},
          ));
        }
      } else if (widget.type == 'focus_tasks') {
        _title = 'Seleziona Focus Task';
        options.add(const _WidgetOptionItem(
          title: 'Focus Oggi & Urgenti',
          subtitle: 'Task con scadenza oggi o priorità alta',
          icon: Icons.bolt_rounded,
          color: Color(0xFFF59E0B),
          customProps: {'source': 'focus_today', 'title': 'Focus Oggi'},
        ));

        final docs = await DocumentService().getDocumentsForContext(currentContext, 'todo');
        for (final doc in docs) {
          options.add(_WidgetOptionItem(
            title: doc.title,
            subtitle: 'Lista Task Documento',
            icon: Icons.checklist_rounded,
            color: const Color(0xFF6366F1),
            customProps: {'source': 'document', 'documentId': doc.id, 'title': doc.title},
          ));
        }
      } else if (widget.type == 'shopping_quick_list') {
        _title = 'Seleziona Lista Spesa';
        final docs = await DocumentService().getDocumentsForContext(currentContext, 'shopping_list');
        if (docs.isEmpty) {
          options.add(const _WidgetOptionItem(
            title: 'Lista Spesa Principale',
            subtitle: 'Nessun documento creato, usa la lista base',
            icon: Icons.shopping_cart_rounded,
            color: Color(0xFF3B82F6),
            customProps: {'source': 'default', 'title': 'Spesa'},
          ));
        } else {
          for (final doc in docs) {
            options.add(_WidgetOptionItem(
              title: doc.title,
              subtitle: 'Lista della Spesa',
              icon: Icons.shopping_cart_rounded,
              color: const Color(0xFF3B82F6),
              customProps: {'source': 'document', 'documentId': doc.id, 'title': doc.title},
            ));
          }
        }
      } else if (widget.type == 'habit_tracker') {
        _title = 'Seleziona Routine';
        options.add(const _WidgetOptionItem(
          title: 'Tutte le Routine',
          subtitle: 'Panoramica di tutte le abitudini attive',
          icon: Icons.loop_rounded,
          color: Color(0xFF8B5CF6),
          customProps: {'source': 'all', 'title': 'Tutte le Routine'},
        ));

        try {
          final routines = await TimeManagementService().routinesStream.first.timeout(
            const Duration(milliseconds: 1500),
            onTimeout: () => [],
          );
          for (final r in routines) {
            options.add(_WidgetOptionItem(
              title: r.name,
              subtitle: 'Routine specifica',
              icon: Icons.repeat_rounded,
              color: const Color(0xFF8B5CF6),
              customProps: {'source': 'routine', 'routineId': r.id, 'title': r.name},
            ));
          }
        } catch (_) {}
      } else if (widget.type == 'monthly_burn_rate') {
        _title = 'Configura Burn Rate';
        options.add(const _WidgetOptionItem(
          title: 'Tutte le Spese (Totale)',
          subtitle: 'Media e uscite mensili complessive',
          icon: Icons.trending_down_rounded,
          color: Color(0xFFE068F1),
          customProps: {'source': 'all', 'title': 'Burn Rate Totale'},
        ));

        for (final t in Tipologia.values) {
          options.add(_WidgetOptionItem(
            title: t.name.toUpperCase(),
            subtitle: 'Solo categoria ${t.name}',
            icon: CategoryHelpers.getCategoryIcon(t),
            color: CategoryHelpers.getCategoryColor(t),
            customProps: {'source': 'category', 'category': t.name, 'title': t.name.toUpperCase()},
          ));
        }
      } else if (widget.type == 'hero_countdown') {
        _title = 'Seleziona Evento o Viaggio';
        options.add(const _WidgetOptionItem(
          title: 'Prossimo Evento in Arrivo',
          subtitle: 'Seleziona automaticamente l\'evento futuro più vicino',
          icon: Icons.auto_awesome_rounded,
          color: Color(0xFF818CF8),
          customProps: {'source': 'auto', 'title': 'Prossimo Evento'},
        ));

        try {
          final scenarios = await TimeManagementService().timeScenariosStream.first.timeout(
            const Duration(milliseconds: 1500),
            onTimeout: () => [],
          );
          for (final s in scenarios) {
            IconData icon = Icons.event_rounded;
            Color color = const Color(0xFF818CF8);
            if (s.scenarioType.toLowerCase() == 'trip') {
              icon = Icons.flight_takeoff_rounded;
              color = const Color(0xFF38BDF8);
            } else if (s.scenarioType.toLowerCase() == 'outing') {
              icon = Icons.restaurant_rounded;
              color = const Color(0xFFFBBF24);
            } else if (s.scenarioType.toLowerCase() == 'event') {
              icon = Icons.celebration_rounded;
              color = const Color(0xFFF472B6);
            }

            options.add(_WidgetOptionItem(
              title: s.title,
              subtitle: '${s.scenarioType.toUpperCase()} - ${s.startDate.day}/${s.startDate.month}/${s.startDate.year}',
              icon: icon,
              color: color,
              customProps: {'source': 'scenario', 'scenarioId': s.id, 'title': s.title},
            ));
          }
        } catch (_) {}
      } else if (widget.type == 'pantry_alert') {
        _title = 'Seleziona Dispensa';
        final docs = await DocumentService().getDocumentsForContext(currentContext, 'dispensa');
        if (docs.isEmpty) {
          options.add(const _WidgetOptionItem(
            title: 'Dispensa Principale',
            subtitle: 'Monitora la dispensa base',
            icon: Icons.kitchen_rounded,
            color: Color(0xFF10B981),
            customProps: {'source': 'default', 'title': 'Dispensa'},
          ));
        } else {
          for (final doc in docs) {
            options.add(_WidgetOptionItem(
              title: doc.title,
              subtitle: 'Monitora scorte e soglie minime',
              icon: Icons.kitchen_rounded,
              color: const Color(0xFF10B981),
              customProps: {'source': 'document', 'documentId': doc.id, 'title': doc.title},
            ));
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading init modal options: $e');
    }

    if (mounted) {
      setState(() {
        _options = options;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40.0),
                child: Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
              )
            else if (_options.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40.0),
                child: Center(
                  child: Text('Nessuna opzione disponibile', style: TextStyle(color: Colors.white54)),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _options.length,
                  separatorBuilder: (context, index) => const Divider(color: Colors.white10, height: 1),
                  itemBuilder: (context, index) {
                    final item = _options[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: item.color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: item.color.withOpacity(0.3), width: 1),
                        ),
                        child: Icon(item.icon, color: item.color, size: 20),
                      ),
                      title: Text(
                        item.title,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      subtitle: item.subtitle != null
                          ? Text(
                              item.subtitle!,
                              style: const TextStyle(color: Colors.white54, fontSize: 12),
                            )
                          : null,
                      trailing: const Icon(Icons.chevron_right, color: Colors.white30, size: 18),
                      onTap: () {
                        Navigator.of(context).pop(item.customProps);
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
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
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 370),
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
      _controller.animateTo(0.5, duration: const Duration(milliseconds: 150), curve: Curves.easeOut);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 0.003 turns ~ 1 degree
    final double maxAngle = (widget.wobbleSeed % 2 == 0) ? 0.003 : -0.003;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Map 0..1 to -1..1
        final value = (_controller.value * 2) - 1.0;
        // Convert maxAngle (turns) to radians
        final angle = value * maxAngle * 2 * 3.14159;

        return Transform.rotate(
          angle: angle,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
