import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:solducci/core/di/service_locator.dart';
import 'package:solducci/features/life_os/domain/models/models.dart';
import 'package:solducci/features/life_os/domain/repositories/repositories.dart';
import 'package:solducci/features/life_os/presentation/controllers/life_os_center_cubit.dart';
import 'package:solducci/features/life_os/presentation/controllers/life_os_center_state.dart';
import 'package:solducci/features/life_os/presentation/widgets/active_entities_section.dart';
import 'package:solducci/features/life_os/presentation/widgets/chained_capture_overlay.dart';
import 'package:solducci/features/life_os/presentation/widgets/dynamic_capture_bar.dart';
import 'package:solducci/features/life_os/presentation/widgets/how_life_os_works_section.dart';
import 'package:solducci/features/life_os/presentation/widgets/recent_seeds_section.dart';
import 'package:solducci/theme/app_theme.dart';
import 'package:solducci/widgets/solducci_app_bar.dart';

class LifeOsCenterView extends StatelessWidget {
  final LifeOsCenterCubit? cubit;
  final bool showContextSwitcher;

  const LifeOsCenterView({
    super.key,
    this.cubit,
    this.showContextSwitcher = true,
  });

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider.value(
        value: cubit!..loadEntities(),
        child: _LifeOsCenterContent(showContextSwitcher: showContextSwitcher),
      );
    }
    return BlocProvider(
      create: (context) => LifeOsCenterCubit(
        entityRepository: getIt<LifeEntityRepository>(),
        relationRepository: getIt<EntityRelationRepository>(),
      )..loadEntities(),
      child: _LifeOsCenterContent(showContextSwitcher: showContextSwitcher),
    );
  }
}

class _LifeOsCenterContent extends StatefulWidget {
  final bool showContextSwitcher;

  const _LifeOsCenterContent({this.showContextSwitcher = true});

  @override
  State<_LifeOsCenterContent> createState() => _LifeOsCenterContentState();
}

class _LifeOsCenterContentState extends State<_LifeOsCenterContent> {
  LifeEntity? _activeChainRootSeed;
  List<SeedMention> _activeChainMentions = const [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: SolducciAppBar(
        showContextSwitcher: widget.showContextSwitcher,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'LifeOS Center',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              'Centro Operativo & Orientamento',
              style: TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Personalizza Nature e Proprietà',
            icon: const Icon(Icons.tune_rounded, color: Colors.white70),
            onPressed: () => context.push('/life_os/customize'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            onPressed: () => context.read<LifeOsCenterCubit>().loadEntities(),
          ),
        ],
      ),
      body: BlocConsumer<LifeOsCenterCubit, LifeOsCenterState>(
        listener: (context, state) {
          if (state.generalError != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.generalError!),
                backgroundColor: AppTheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          final cubit = context.read<LifeOsCenterCubit>();
          final allEntities = [...state.seeds, ...state.activeEntities];

          return Stack(
            children: [
              // Main Scrollable Dashboard Content
              RefreshIndicator(
                onRefresh: () => cubit.loadEntities(),
                color: AppTheme.primary,
                backgroundColor: const Color(0xFF18181B),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  children: [
                    // 1. System Orientation Header
                    _buildSystemOrientationHeader(state),
                    const SizedBox(height: 16),

                    // 2. Redesigned Dynamic Capture Bar with Spatial Morphing & Mentions
                    DynamicCaptureBar(
                      availableEntities: allEntities,
                      isCapturing: state.isCapturing,
                      errorMessage: state.captureError,
                      onRetry: () => cubit.retryLastCapture(),
                      onCaptureWithMentions: (title, mentions) async {
                        final created = await cubit.captureSeedWithMentions(title, mentions);
                        if (created != null && mounted) {
                          setState(() {
                            _activeChainRootSeed = created;
                            _activeChainMentions = mentions;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 24),

                    // 3. Recent Seeds Section
                    RecentSeedsSection(
                      seeds: state.seeds,
                      onRefresh: () => cubit.loadEntities(),
                    ),
                    const SizedBox(height: 24),

                    // 4. Active Entities Section (if present)
                    if (state.activeEntities.isNotEmpty) ...[
                      ActiveEntitiesSection(entities: state.activeEntities),
                      const SizedBox(height: 24),
                    ],

                    // 5. How LifeOS Works Section
                    HowLifeOsWorksSection(
                      seedCount: state.seedCount,
                      activeCount: state.activeEntityCount,
                    ),
                  ],
                ),
              ),

              // Chained Seed Capture Modal Overlay ("Raccogli una catena di semi")
              if (_activeChainRootSeed != null)
                ChainedCaptureOverlay(
                  initialSeed: _activeChainRootSeed!,
                  initialMentions: _activeChainMentions,
                  availableEntities: allEntities,
                  entityRepository: getIt<LifeEntityRepository>(),
                  relationRepository: getIt<EntityRelationRepository>(),
                  onDismiss: () => setState(() => _activeChainRootSeed = null),
                  onSeedUpdated: (updated) => cubit.onSeedUpdated(updated),
                  onSeedAdded: (newSeed) => cubit.onSeedAdded(newSeed),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSystemOrientationHeader(LifeOsCenterState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: state.isLoading
                  ? const Color(0xFFF59E0B)
                  : const Color(0xFF10B981),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              state.isLoading
                  ? 'Sincronizzazione in corso...'
                  : '${state.seedCount} ${state.seedCount == 1 ? "Seme" : "Semi"} in attesa · ${state.activeEntityCount} ${state.activeEntityCount == 1 ? "Attiva" : "Attive"}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
