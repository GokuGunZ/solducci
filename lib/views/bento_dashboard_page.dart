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

class _BentoDashboardView extends StatelessWidget {
  const _BentoDashboardView();

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
                return IconButton(
                  icon: Icon(state.isEditing ? Icons.check : Icons.edit, color: Colors.white),
                  onPressed: () {
                    context.read<DashboardBloc>().add(ToggleEditMode());
                    if (state.isEditing) {
                      context.read<DashboardBloc>().add(SaveDashboard());
                    }
                  },
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
            return _buildGrid(context, state);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildGrid(BuildContext context, DashboardLoaded state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: StaggeredGrid.count(
        crossAxisCount: 4,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: state.config.layout.asMap().entries.map((entry) {
          final index = entry.key;
          final widgetDef = entry.value;

          Widget content = Stack(
            children: [
              Positioned.fill(
                child: DashboardWidgetFactory.buildWidget(context, widgetDef),
              ),
              if (state.isEditing)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Center(
                      child: Icon(Icons.open_with, color: Colors.white),
                    ),
                  ),
                ),
            ],
          );

          if (state.isEditing) {
            content = DragTarget<int>(
              onWillAcceptWithDetails: (details) => details.data != index,
              onAcceptWithDetails: (details) {
                final fromIndex = details.data;
                final newLayout = List<BentoWidgetDef>.from(state.config.layout);
                final item = newLayout.removeAt(fromIndex);
                newLayout.insert(index, item);
                context.read<DashboardBloc>().add(UpdateLayout(newLayout));
              },
              builder: (context, candidateData, rejectedData) {
                return LongPressDraggable<int>(
                  data: index,
                  feedback: Material(
                    color: Colors.transparent,
                    child: Opacity(
                      opacity: 0.8,
                      child: SizedBox(
                        // Approximate size for the dragged item
                        width: widgetDef.size.crossAxisCellCount * 90.0,
                        height: widgetDef.size.mainAxisCellCount * 90.0,
                        child: content,
                      ),
                    ),
                  ),
                  childWhenDragging: Opacity(
                    opacity: 0.2,
                    child: content,
                  ),
                  child: content,
                );
              },
            );
          }

          return StaggeredGridTile.count(
            key: ValueKey(widgetDef.id),
            crossAxisCellCount: widgetDef.size.crossAxisCellCount,
            mainAxisCellCount: widgetDef.size.mainAxisCellCount,
            child: content
                .animate(key: ValueKey('${widgetDef.id}_anim'))
                .fadeIn(duration: 400.ms, curve: Curves.easeOut)
                .scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOutBack),
          );
        }).toList(),
      ),
    );
  }
}
