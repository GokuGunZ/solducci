import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solducci/core/di/service_locator.dart';
import 'package:solducci/features/life_os/domain/models/models.dart';
import 'package:solducci/features/life_os/domain/repositories/repositories.dart';
import 'package:solducci/features/life_os/presentation/controllers/entity_vitrine_cubit.dart';
import 'package:solducci/features/life_os/presentation/controllers/entity_vitrine_state.dart';
import 'package:solducci/features/life_os/presentation/widgets/human_intention_action_sheet.dart';
import 'package:solducci/theme/app_theme.dart';
import 'package:solducci/widgets/solducci_app_bar.dart';

class EntityVitrineView extends StatelessWidget {
  final String entityId;
  final LifeEntity? initialEntity;

  const EntityVitrineView({
    super.key,
    required this.entityId,
    this.initialEntity,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => EntityVitrineCubit(
        entityId: entityId,
        entityRepository: getIt<LifeEntityRepository>(),
        relationRepository: getIt<EntityRelationRepository>(),
        overlayRepository: getIt<UserEntityOverlayRepository>(),
        initialEntity: initialEntity,
      )..load(),
      child: const _EntityVitrineContent(),
    );
  }
}

class _EntityVitrineContent extends StatefulWidget {
  const _EntityVitrineContent();

  @override
  State<_EntityVitrineContent> createState() => _EntityVitrineContentState();
}

class _EntityVitrineContentState extends State<_EntityVitrineContent> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  bool _isEditingDetails = false;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<EntityVitrineCubit>();
    final initial = cubit.state.entity;
    _titleController = TextEditingController(text: initial?.title ?? '');
    _descController = TextEditingController(text: initial?.description ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _saveDetails() {
    context.read<EntityVitrineCubit>().updateDetails(
          title: _titleController.text,
          description: _descController.text,
        );
    setState(() {
      _isEditingDetails = false;
    });
  }

  HumanIntention _mapEntityToIntention(LifeEntity entity) {
    if (entity.isSeed) return HumanIntention.keepAsSeed;
    if (entity.isProject) return HumanIntention.treatAsProject;
    if (entity.isPractice) return HumanIntention.cultivatePractice;
    if (entity.isConcept) return HumanIntention.organizeKnowledge;
    return HumanIntention.explore;
  }

  String _intentionTitle(LifeEntity entity) {
    if (entity.isSeed) return 'Seme grezzo a riposo';
    if (entity.isProject) return 'Progetto in esecuzione';
    if (entity.isPractice) return 'Pratica continuativa';
    if (entity.isConcept) return 'Memoria & Conoscenza';
    return 'Esplorazione aperta';
  }

  String _intentionSubtitle(LifeEntity entity) {
    if (entity.isSeed) {
      return 'Nessun impegno o modalità assegnata. Pronto a germogliare quando serve.';
    }
    if (entity.isProject) {
      return 'Orientato al risultato. Le azioni convergono verso un traguardo.';
    }
    if (entity.isPractice) {
      return 'Allenamento ricorrente. L\'enfasi è sulla costanza, non su una scadenza.';
    }
    if (entity.isConcept) {
      return 'Riferimento informativo o modello mentale da consultare nel tempo.';
    }
    return 'Sviluppo libero del pensiero.';
  }

  Color _intentionColor(LifeEntity entity) {
    if (entity.isProject) return const Color(0xFF6366F1);
    if (entity.isPractice) return const Color(0xFF10B981);
    if (entity.isConcept) return const Color(0xFF3B82F6);
    if (entity.isIdea) return const Color(0xFFF59E0B);
    return Colors.white54;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EntityVitrineCubit, EntityVitrineState>(
      listener: (context, state) {
        if (state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.successMessage!),
              backgroundColor: AppTheme.success,
              duration: const Duration(seconds: 2),
            ),
          );
        }
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      },
      builder: (context, state) {
        final entity = state.entity;

        if (state.isLoading && entity == null) {
          return const Scaffold(
            backgroundColor: Color(0xFF09090B),
            body: Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            ),
          );
        }

        if (entity == null) {
          return Scaffold(
            backgroundColor: const Color(0xFF09090B),
            appBar: const SolducciAppBar(titleText: 'Entità'),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Entità non trovata o non autorizzata.',
                      style: TextStyle(color: Colors.white54)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Torna indietro'),
                  ),
                ],
              ),
            ),
          );
        }

        // Sync controllers if not currently editing
        if (!_isEditingDetails) {
          _titleController.text = entity.title;
          _descController.text = entity.description ?? '';
        }

        final intColor = _intentionColor(entity);
        final isInWeeklyRail = state.overlay?.isInWeeklyRail ?? false;

        return Scaffold(
          backgroundColor: const Color(0xFF09090B),
          appBar: SolducciAppBar(
            title: Text(
              entity.title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: -0.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              if (_isEditingDetails)
                IconButton(
                  icon: const Icon(Icons.check_rounded, color: AppTheme.primary),
                  onPressed: _saveDetails,
                )
              else
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.white70),
                  onPressed: () {
                    setState(() {
                      _isEditingDetails = true;
                    });
                  },
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            physics: const BouncingScrollPhysics(),
            children: [
              // 1. Title & Description Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF18181B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_isEditingDetails) ...[
                      TextField(
                        controller: _titleController,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Titolo',
                          labelStyle: TextStyle(color: Colors.white54),
                          border: UnderlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _descController,
                        maxLines: 4,
                        minLines: 2,
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                        decoration: const InputDecoration(
                          labelText: 'Descrizione / Note',
                          labelStyle: TextStyle(color: Colors.white54),
                          border: UnderlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isEditingDetails = false;
                              });
                            },
                            child: const Text('Annulla', style: TextStyle(color: Colors.white54)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _saveDetails,
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                            child: const Text('Salva', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ] else ...[
                      Text(
                        entity.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3,
                        ),
                      ),
                      if (entity.description != null && entity.description!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          entity.description!,
                          style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 2. Human Intention Section (Amendment C)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Cosa vuoi farne?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.2,
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                    label: const Text('Cambia'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () {
                      HumanIntentionActionSheet.show(
                        context,
                        currentIntention: _mapEntityToIntention(entity),
                        onSelectIntention: (intention) {
                          context.read<EntityVitrineCubit>().applyIntention(intention);
                        },
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () {
                  HumanIntentionActionSheet.show(
                    context,
                    currentIntention: _mapEntityToIntention(entity),
                    onSelectIntention: (intention) {
                      context.read<EntityVitrineCubit>().applyIntention(intention);
                    },
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF18181B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: intColor.withOpacity(0.35)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: intColor.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          entity.isProject
                              ? Icons.rocket_launch_rounded
                              : entity.isPractice
                                  ? Icons.repeat_rounded
                                  : entity.isConcept
                                      ? Icons.menu_book_rounded
                                      : entity.isIdea
                                          ? Icons.search_rounded
                                          : Icons.eco_outlined,
                          color: intColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _intentionTitle(entity),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _intentionSubtitle(entity),
                              style: const TextStyle(color: Colors.white54, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 14),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 3. Weekly Rail Commitment (Amendment B)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF18181B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star_outline_rounded, color: Color(0xFFF59E0B), size: 22),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Focus della Settimana (Weekly Rail)',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Mantieni quest\'entità al centro della tua attenzione personale.',
                            style: TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: isInWeeklyRail,
                      activeColor: const Color(0xFFF59E0B),
                      onChanged: (val) {
                        context.read<EntityVitrineCubit>().toggleWeeklyRail();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 4. Subtle System Metadata (Discreet, secondary)
              Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: const Text(
                    'Dettagli tecnici & Ciclo di vita',
                    style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          _buildMetaRow('ID', entity.id),
                          _buildMetaRow('Ruolo Semantico', entity.semanticRole.name),
                          _buildMetaRow('Stato Ciclo di Vita', entity.lifecycleState.name),
                          _buildMetaRow('Modalità Operativa', entity.currentMode?.name ?? 'Nessuna'),
                          _buildMetaRow('Creato il', entity.createdAt.toIso8601String().substring(0, 10)),
                          _buildMetaRow('Ultimo aggiornamento', entity.updatedAt.toIso8601String().substring(0, 10)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 5. Destructive / Archive Actions
              Center(
                child: TextButton.icon(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: const Color(0xFF18181B),
                        title: const Text('Archiviare questa entità?', style: TextStyle(color: Colors.white)),
                        content: const Text(
                          'L\'entità non verrà eliminata, ma rimarrà archiviata per preservare la tua storia.',
                          style: TextStyle(color: Colors.white70),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Annulla', style: TextStyle(color: Colors.white54)),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                            child: const Text('Archivia', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true && context.mounted) {
                      final ok = await context.read<EntityVitrineCubit>().archive();
                      if (ok && context.mounted) {
                        Navigator.pop(context);
                      }
                    }
                  },
                  icon: const Icon(Icons.archive_outlined, color: Colors.white38, size: 18),
                  label: const Text('Archivia entità', style: TextStyle(color: Colors.white38, fontSize: 13)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
          Text(value, style: const TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'monospace')),
        ],
      ),
    );
  }
}
