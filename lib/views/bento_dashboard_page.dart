import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:solducci/blocs/dashboard/dashboard_bloc.dart';
import 'package:solducci/blocs/dashboard/dashboard_event.dart';
import 'package:solducci/blocs/dashboard/dashboard_state.dart';
import 'package:solducci/widgets/dashboard/dashboard_widget_factory.dart';
import 'package:solducci/widgets/solducci_app_bar.dart';
import 'package:go_router/go_router.dart';

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
        children: state.config.layout.map((widgetDef) {
          return StaggeredGridTile.count(
            crossAxisCellCount: widgetDef.size.crossAxisCellCount,
            mainAxisCellCount: widgetDef.size.mainAxisCellCount,
            child: Stack(
              children: [
                Positioned.fill(
                  child: DashboardWidgetFactory.buildWidget(context, widgetDef),
                ),
                if (state.isEditing)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Center(
                        child: Icon(Icons.open_with, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
