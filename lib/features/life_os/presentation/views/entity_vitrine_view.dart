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
  late TextEditingController _composerController;

  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _descFocusNode = FocusNode();
  final FocusNode _composerFocusNode = FocusNode();

  bool _isTechnicalDetailsExpanded = false;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<EntityVitrineCubit>();
    final initial = cubit.state.entity;
    _titleController = TextEditingController(text: initial?.title ?? '');
    _descController = TextEditingController(text: initial?.description ?? '');
    _composerController = TextEditingController();

    _titleFocusNode.addListener(() {
      if (!_titleFocusNode.hasFocus) {
        _saveTitle();
      }
    });

    _descFocusNode.addListener(() {
      if (!_descFocusNode.hasFocus) {
        _saveDescription();
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _composerController.dispose();
    _titleFocusNode.dispose();
    _descFocusNode.dispose();
    _composerFocusNode.dispose();
    super.dispose();
  }

  void _saveTitle() {
    final entity = context.read<EntityVitrineCubit>().state.entity;
    if (entity == null) return;
    final clean = _titleController.text.trim();
    if (clean.isNotEmpty && clean != entity.title) {
      context.read<EntityVitrineCubit>().updateDetails(
            title: clean,
            description: _descController.text,
          );
    }
  }

  void _saveDescription() {
    final entity = context.read<EntityVitrineCubit>().state.entity;
    if (entity == null) return;
    final clean = _descController.text.trim();
    if (clean != (entity.description ?? '')) {
      context.read<EntityVitrineCubit>().updateDetails(
            title: _titleController.text,
            description: clean,
          );
    }
  }

  void _submitComposer() {
    final text = _composerController.text.trim();
    if (text.isEmpty) return;
    context.read<EntityVitrineCubit>().addBlock(text);
    _composerController.clear();
  }

  String _roleShortLabel(SemanticRole role) {
    switch (role) {
      case SemanticRole.seed:
        return 'Seme';
      case SemanticRole.project:
        return 'Progetto';
      case SemanticRole.practice:
        return 'Pratica';
      case SemanticRole.concept:
        return 'Concetto';
      case SemanticRole.idea:
        return 'Idea';
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

  String _modeShortLabel(OperationMode? mode) {
    if (mode == null) return 'A riposo';
    switch (mode) {
      case OperationMode.exploration:
        return 'Esplorazione';
      case OperationMode.execution:
        return 'Esecuzione';
      case OperationMode.practice:
        return 'In Pratica';
      case OperationMode.reflection:
        return 'Riflessione';
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

        // Sync title and description if not focused
        if (!_titleFocusNode.hasFocus && _titleController.text != entity.title) {
          _titleController.text = entity.title;
        }
        if (!_descFocusNode.hasFocus &&
            _descController.text != (entity.description ?? '')) {
          _descController.text = entity.description ?? '';
        }

        final isInWeeklyRail = state.overlay?.isInWeeklyRail ?? false;
        final suggestedTemplates = RolePropertyPacks.getSuggestionsForRole(entity.semanticRole)
            .where((t) => !entity.properties.any((p) => p.key == t.key))
            .toList();

        return Scaffold(
          backgroundColor: const Color(0xFF09090B),
          appBar: SolducciAppBar(
            showContextSwitcher: widget.showContextSwitcher,
            titleText: 'Vitrine',
          ),
          body: Stack(
            children: [
              // 1. Scrollable Living Entity Surface
              ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
                physics: const BouncingScrollPhysics(),
                children: [
                  // --- Inline Editable Title (View = Edit, Wrap, Typographic) ---
                  TextField(
                    controller: _titleController,
                    focusNode: _titleFocusNode,
                    maxLines: null,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.4,
                      height: 1.25,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      hintText: 'Titolo entità...',
                      hintStyle: TextStyle(color: Colors.white30),
                    ),
                    onSubmitted: (_) => _saveTitle(),
                  ),
                  const SizedBox(height: 14),

                  // --- Compact Semantic Controls (Natura, Modalità, Focus) ---
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // Natura Chip
                      _CompactSemanticChip(
                        icon: _roleIcon(entity.semanticRole),
                        label: _roleShortLabel(entity.semanticRole),
                        color: _roleColor(entity.semanticRole),
                        onTap: () => HumanRoleActionSheet.show(
                          context,
                          currentRole: entity.semanticRole,
                          onSelectRole: (role) =>
                              context.read<EntityVitrineCubit>().setRole(role),
                        ),
                      ),

                      // Modalità Chip
                      _CompactSemanticChip(
                        icon: _modeIcon(entity.currentMode),
                        label: _modeShortLabel(entity.currentMode),
                        color: _modeColor(entity.currentMode),
                        onTap: () => HumanModeActionSheet.show(
                          context,
                          currentMode: entity.currentMode,
                          onSelectMode: (mode) =>
                              context.read<EntityVitrineCubit>().setMode(mode),
                        ),
                      ),

                      // Focus / Weekly Rail Chip
                      _CompactSemanticChip(
                        icon: isInWeeklyRail ? Icons.star_rounded : Icons.star_outline_rounded,
                        label: isInWeeklyRail ? 'Weekly Rail' : 'Focus ☆',
                        color: isInWeeklyRail ? const Color(0xFFF59E0B) : Colors.white38,
                        isActive: isInWeeklyRail,
                        onTap: () =>
                            context.read<EntityVitrineCubit>().toggleWeeklyRail(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // --- Inline Editable Description / Context ---
                  TextField(
                    controller: _descController,
                    focusNode: _descFocusNode,
                    maxLines: null,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      height: 1.5,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      hintText: 'Aggiungi una descrizione o contesto iniziale...',
                      hintStyle: TextStyle(color: Colors.white24),
                    ),
                    onSubmitted: (_) => _saveDescription(),
                  ),

                  // --- Progressive Properties Section (INT-D016) ---
                  if (entity.properties.isNotEmpty || suggestedTemplates.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'PROPRIETÀ',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Active Properties List
                    ...entity.properties.map((prop) {
                      return _PropertyItemRow(
                        property: prop,
                        onChanged: (newVal) {
                          context.read<EntityVitrineCubit>().addOrUpdateProperty(
                                prop.copyWith(value: newVal),
                              );
                        },
                        onDelete: () {
                          context.read<EntityVitrineCubit>().removeProperty(prop.key);
                        },
                      );
                    }),

                    // Suggested Role Property Packs
                    if (suggestedTemplates.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: suggestedTemplates.map((template) {
                          return ActionChip(
                            avatar: const Icon(Icons.add_rounded, size: 14, color: AppTheme.primary),
                            label: Text(
                              template.label,
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                            backgroundColor: const Color(0xFF18181B),
                            side: BorderSide(color: Colors.white.withOpacity(0.08)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            onPressed: () {
                              _showAddPropertyDialog(context, template);
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ],

                  // --- Living Evolvable Content Blocks (INT-D015) ---
                  if (entity.blocks.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    const Text(
                      'FLUSSO EVOLUTIVO',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...entity.blocks.map((block) {
                      return _LivingBlockCard(
                        block: block,
                        onUpdate: (newContent) {
                          context.read<EntityVitrineCubit>().updateBlock(block.id, newContent);
                        },
                        onDelete: () {
                          context.read<EntityVitrineCubit>().deleteBlock(block.id);
                        },
                      );
                    }),
                  ],

                  // --- Collapsible Technical & Lifecycle Drawer ---
                  const SizedBox(height: 36),
                  Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      initiallyExpanded: _isTechnicalDetailsExpanded,
                      onExpansionChanged: (val) =>
                          setState(() => _isTechnicalDetailsExpanded = val),
                      tilePadding: EdgeInsets.zero,
                      title: const Text(
                        'Dettagli tecnici & Ciclo di vita',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF131316),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withOpacity(0.04)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _TechItem(label: 'ID', value: entity.id),
                              _TechItem(label: 'Stato Tecnico', value: entity.lifecycleState.value),
                              _TechItem(
                                label: 'Visibilità',
                                value: entity.isPersonal ? 'Personale' : 'Gruppo Condiviso',
                              ),
                              _TechItem(
                                label: 'Creazione',
                                value: entity.createdAt.toLocal().toString().split('.').first,
                              ),
                              if (entity.lastMeaningfulActivityAt != null)
                                _TechItem(
                                  label: 'Ultima Attività Significativa',
                                  value: entity.lastMeaningfulActivityAt!
                                      .toLocal()
                                      .toString()
                                      .split('.')
                                      .first,
                                ),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.archive_outlined, size: 16, color: Colors.white54),
                                label: const Text('Archivia Entità',
                                    style: TextStyle(color: Colors.white70, fontSize: 13)),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: Colors.white.withOpacity(0.1)),
                                ),
                                onPressed: () async {
                                  final nav = Navigator.of(context);
                                  final ok = await context.read<EntityVitrineCubit>().archive();
                                  if (ok) nav.pop();
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // 2. Bottom Floating Composer Bar (INT-D015)
              Positioned(
                left: 16,
                right: 16,
                bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A20),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.12)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.55),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.add_comment_rounded, color: AppTheme.primary, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _composerController,
                          focusNode: _composerFocusNode,
                          minLines: 1,
                          maxLines: 4,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: const InputDecoration(
                            hintText: 'Aggiungi qualcosa a questa entità...',
                            hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 8),
                          ),
                          onSubmitted: (_) => _submitComposer(),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_upward_rounded, color: AppTheme.primary, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        onPressed: _submitComposer,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddPropertyDialog(BuildContext context, PropertyTemplate template) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(
            template.label,
            style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: textController,
            autofocus: true,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: template.placeholder,
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
              border: const UnderlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Annulla', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
              onPressed: () {
                final val = textController.text.trim();
                if (val.isNotEmpty) {
                  context.read<EntityVitrineCubit>().addOrUpdateProperty(
                        EntityProperty(
                          key: template.key,
                          label: template.label,
                          value: val,
                          type: template.defaultType,
                        ),
                      );
                }
                Navigator.pop(dialogContext);
              },
              child: const Text('Aggiungi', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}

/// Compact Semantic Chip (surface = compact, decision sheet = explanatory)
class _CompactSemanticChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isActive;
  final VoidCallback onTap;

  const _CompactSemanticChip({
    required this.icon,
    required this.label,
    required this.color,
    this.isActive = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Active Property Item Row with inline editing
class _PropertyItemRow extends StatefulWidget {
  final EntityProperty property;
  final ValueChanged<String> onChanged;
  final VoidCallback onDelete;

  const _PropertyItemRow({
    required this.property,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  State<_PropertyItemRow> createState() => _PropertyItemRowState();
}

class _PropertyItemRowState extends State<_PropertyItemRow> {
  late TextEditingController _valController;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _valController = TextEditingController(text: widget.property.value);
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        widget.onChanged(_valController.text.trim());
      }
    });
  }

  @override
  void didUpdateWidget(covariant _PropertyItemRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.property.value != widget.property.value && !_focusNode.hasFocus) {
      _valController.text = widget.property.value;
    }
  }

  @override
  void dispose() {
    _valController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF141418),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              widget.property.label,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _valController,
              focusNode: _focusNode,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onSubmitted: (val) => widget.onChanged(val.trim()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 14, color: Colors.white38),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onPressed: widget.onDelete,
          ),
        ],
      ),
    );
  }
}

/// Living Content Block Card in the sequential stream
class _LivingBlockCard extends StatelessWidget {
  final EntityBlock block;
  final ValueChanged<String> onUpdate;
  final VoidCallback onDelete;

  const _LivingBlockCard({
    required this.block,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF141418),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  block.content,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz_rounded, size: 16, color: Colors.white38),
                color: const Color(0xFF222228),
                onSelected: (val) {
                  if (val == 'delete') onDelete();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Elimina blocco', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${block.createdAt.hour.toString().padLeft(2, '0')}:${block.createdAt.minute.toString().padLeft(2, '0')} · ${block.createdAt.day}/${block.createdAt.month}',
            style: const TextStyle(color: Colors.white24, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _TechItem extends StatelessWidget {
  final String label;
  final String value;

  const _TechItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }
}
