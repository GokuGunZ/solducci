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
  final bool showContextSwitcher;

  const EntityVitrineView({
    super.key,
    required this.entityId,
    this.initialEntity,
    this.showContextSwitcher = true,
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
      child: _EntityVitrineContent(showContextSwitcher: showContextSwitcher),
    );
  }
}

class _EntityVitrineContent extends StatefulWidget {
  final bool showContextSwitcher;

  const _EntityVitrineContent({this.showContextSwitcher = true});

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

  String _roleTitle(SemanticRole role) {
    switch (role) {
      case SemanticRole.seed:
        return 'Seme grezzo a riposo';
      case SemanticRole.project:
        return 'Progetto';
      case SemanticRole.practice:
        return 'Pratica continua';
      case SemanticRole.concept:
        return 'Conoscenza & Memoria';
      case SemanticRole.idea:
        return 'Idea in maturazione';
    }
  }

  String _roleSubtitle(SemanticRole role) {
    switch (role) {
      case SemanticRole.seed:
        return 'Nessun impegno o struttura. Pronto a germogliare quando serve.';
      case SemanticRole.project:
        return 'Iniziativa orientata al raggiungimento di un traguardo chiaro.';
      case SemanticRole.practice:
        return 'Disciplina o routine in cui conta la costanza, non una scadenza.';
      case SemanticRole.concept:
        return 'Modello mentale o riferimento informativo da consultare nel tempo.';
      case SemanticRole.idea:
        return 'Spunto aperto in fase di studio e formulazione iniziale.';
    }
  }

  Color _roleColor(SemanticRole role) {
    switch (role) {
      case SemanticRole.project:
        return const Color(0xFF6366F1);
      case SemanticRole.practice:
        return const Color(0xFF10B981);
      case SemanticRole.concept:
        return const Color(0xFF3B82F6);
      case SemanticRole.idea:
        return const Color(0xFFF59E0B);
      case SemanticRole.seed:
        return Colors.white54;
    }
  }

  IconData _roleIcon(SemanticRole role) {
    switch (role) {
      case SemanticRole.project:
        return Icons.rocket_launch_rounded;
      case SemanticRole.practice:
        return Icons.repeat_rounded;
      case SemanticRole.concept:
        return Icons.menu_book_rounded;
      case SemanticRole.idea:
        return Icons.lightbulb_outline_rounded;
      case SemanticRole.seed:
        return Icons.eco_outlined;
    }
  }

  String _modeTitle(OperationMode? mode) {
    if (mode == null) return 'Nessuna modalità (A riposo)';
    switch (mode) {
      case OperationMode.exploration:
        return 'In Esplorazione';
      case OperationMode.execution:
        return 'In Lavorazione (Esecuzione)';
      case OperationMode.practice:
        return 'In Pratica';
      case OperationMode.reflection:
        return 'In Riflessione';
    }
  }

  String _modeSubtitle(OperationMode? mode) {
    if (mode == null) {
      return 'L\'entità non assorbe attenzione attiva in questo momento.';
    }
    switch (mode) {
      case OperationMode.exploration:
        return 'Ricerca aperta, sperimentazione, studio o raccolta spunti.';
      case OperationMode.execution:
        return 'Azione diretta e focalizzata per completare e rilasciare.';
      case OperationMode.practice:
        return 'Esercizio, routine quotidiana o allenamento di abilità.';
      case OperationMode.reflection:
        return 'Revisione retrospettiva, valutazione o sintesi del quadro.';
    }
  }

  Color _modeColor(OperationMode? mode) {
    if (mode == null) return Colors.white38;
    switch (mode) {
      case OperationMode.exploration:
        return const Color(0xFFF59E0B);
      case OperationMode.execution:
        return const Color(0xFF6366F1);
      case OperationMode.practice:
        return const Color(0xFF10B981);
      case OperationMode.reflection:
        return const Color(0xFF3B82F6);
    }
  }

  IconData _modeIcon(OperationMode? mode) {
    if (mode == null) return Icons.pause_circle_outline_rounded;
    switch (mode) {
      case OperationMode.exploration:
        return Icons.search_rounded;
      case OperationMode.execution:
        return Icons.bolt_rounded;
      case OperationMode.practice:
        return Icons.fitness_center_rounded;
      case OperationMode.reflection:
        return Icons.self_improvement_rounded;
    }
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
            appBar: SolducciAppBar(
              showContextSwitcher: widget.showContextSwitcher,
              titleText: 'Entità',
            ),
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

        final rColor = _roleColor(entity.semanticRole);
        final mColor = _modeColor(entity.currentMode);
        final isInWeeklyRail = state.overlay?.isInWeeklyRail ?? false;

        return Scaffold(
          backgroundColor: const Color(0xFF09090B),
          appBar: SolducciAppBar(
            showContextSwitcher: widget.showContextSwitcher,
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

              // 2. Semantic Nature Card (SemanticRole)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Che natura ha?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.2,
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                    label: const Text('Cambia natura'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () {
                      HumanRoleActionSheet.show(
                        context,
                        currentRole: entity.semanticRole,
                        onSelectRole: (role) {
                          context.read<EntityVitrineCubit>().setRole(role);
                        },
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: () {
                  HumanRoleActionSheet.show(
                    context,
                    currentRole: entity.semanticRole,
                    onSelectRole: (role) {
                      context.read<EntityVitrineCubit>().setRole(role);
                    },
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF18181B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: rColor.withOpacity(0.35)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: rColor.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _roleIcon(entity.semanticRole),
                          color: rColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _roleTitle(entity.semanticRole),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _roleSubtitle(entity.semanticRole),
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
              const SizedBox(height: 16),

              // 3. Operational Mode Card (Current Mode)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Come la stai affrontando?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.2,
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.tune_rounded, size: 16),
                    label: const Text('Cambia modalità'),
                    style: TextButton.styleFrom(
                      foregroundColor: mColor,
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () {
                      HumanModeActionSheet.show(
                        context,
                        currentMode: entity.currentMode,
                        onSelectMode: (mode) {
                          context.read<EntityVitrineCubit>().setMode(mode);
                        },
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: () {
                  HumanModeActionSheet.show(
                    context,
                    currentMode: entity.currentMode,
                    onSelectMode: (mode) {
                      context.read<EntityVitrineCubit>().setMode(mode);
                    },
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF18181B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: mColor.withOpacity(0.35)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: mColor.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _modeIcon(entity.currentMode),
                          color: mColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _modeTitle(entity.currentMode),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _modeSubtitle(entity.currentMode),
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

              // 4. Weekly Rail Commitment (Amendment B)
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

              // 5. Subtle System Metadata (Discreet, secondary)
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

              // 6. Destructive / Archive Actions
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
