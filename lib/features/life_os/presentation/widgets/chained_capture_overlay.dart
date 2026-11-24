import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:solducci/features/life_os/domain/models/models.dart';
import 'package:solducci/features/life_os/domain/repositories/repositories.dart';
import 'package:solducci/features/life_os/presentation/widgets/dynamic_capture_bar.dart';
import 'package:solducci/theme/app_theme.dart';
import 'package:uuid/uuid.dart';

/// Modal overlay that dims the background and presents the main seed fixed at the top
/// while allowing continuous addition of thoughts and sub-thoughts to its evolutionary flow.
///
/// Direct additions are created at the same level under the main seed (partOf).
/// Nested sub-thoughts can be added inside any secondary item via its "Aggiungi dentro" action.
class ChainedCaptureOverlay extends StatefulWidget {
  final LifeEntity initialSeed;
  final List<SeedMention> initialMentions;
  final List<LifeEntity> availableEntities;
  final LifeEntityRepository entityRepository;
  final EntityRelationRepository relationRepository;
  final VoidCallback onDismiss;
  final void Function(LifeEntity updatedSeed)? onSeedUpdated;
  final void Function(LifeEntity newSeed)? onSeedAdded;

  const ChainedCaptureOverlay({
    super.key,
    required this.initialSeed,
    this.initialMentions = const [],
    this.availableEntities = const [],
    required this.entityRepository,
    required this.relationRepository,
    required this.onDismiss,
    this.onSeedUpdated,
    this.onSeedAdded,
  });

  @override
  State<ChainedCaptureOverlay> createState() => _ChainedCaptureOverlayState();
}

class _ChainedCaptureOverlayState extends State<ChainedCaptureOverlay> {
  final _uuid = const Uuid();
  late LifeEntity _rootSeed;
  final List<LifeEntity> _childSeeds = [];
  final Map<String, String> _parentMap = {}; // childId -> parentId

  // Nesting target state (null means adding directly under _rootSeed)
  String? _targetParentId;
  String? _targetParentTitle;

  // Editing state for any item
  String? _editingEntityId;
  final TextEditingController _editController = TextEditingController();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _rootSeed = widget.initialSeed;
  }

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  void _startEditing(LifeEntity entity) {
    HapticFeedback.selectionClick();
    setState(() {
      _editingEntityId = entity.id;
      _editController.text = entity.title;
    });
  }

  Future<void> _saveEdit(LifeEntity entity) async {
    final clean = _editController.text.trim();
    if (clean.isEmpty) return;

    HapticFeedback.lightImpact();
    final updated = entity.copyWith(
      title: clean,
      updatedAt: DateTime.now(),
    );

    try {
      await widget.entityRepository.updateEntity(updated);
      if (entity.id == _rootSeed.id) {
        setState(() {
          _rootSeed = updated;
          _editingEntityId = null;
        });
        widget.onSeedUpdated?.call(updated);
      } else {
        final idx = _childSeeds.indexWhere((s) => s.id == entity.id);
        if (idx != -1) {
          setState(() {
            _childSeeds[idx] = updated;
            _editingEntityId = null;
          });
        }
      }
    } catch (_) {
      setState(() => _editingEntityId = null);
    }
  }

  void _setTargetParent(LifeEntity entity) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_targetParentId == entity.id) {
        // Toggle off if already targeted
        _targetParentId = null;
        _targetParentTitle = null;
      } else {
        _targetParentId = entity.id;
        _targetParentTitle = entity.title;
      }
    });
  }

  Future<void> _handleThoughtCapture(String text, List<SeedMention> mentions) async {
    final clean = text.trim();
    if (clean.isEmpty && mentions.isEmpty) return;
    if (_isSaving) return;

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      final now = DateTime.now();
      final activeTargetId = _targetParentId ?? _rootSeed.id;
      final newChildId = _uuid.v4();

      // 1. Create child entity document
      final newChild = LifeEntity(
        id: newChildId,
        userId: _rootSeed.userId,
        groupId: _rootSeed.groupId,
        title: clean.isNotEmpty ? clean : 'Seme collegato',
        semanticRole: SemanticRole.seed,
        lifecycleState: LifecycleState.active,
        currentMode: null,
        createdAt: now,
        updatedAt: now,
      );

      final createdChild = await widget.entityRepository.createEntity(newChild);

      // 2. Link as partOf active target parent (root by default, or nested)
      final relation = EntityRelation(
        id: _uuid.v4(),
        userId: _rootSeed.userId ?? '',
        sourceId: createdChild.id,
        targetType: TargetType.entity,
        targetId: activeTargetId,
        relationType: RelationType.partOf,
        metadata: {
          'chain_root_id': _rootSeed.id,
          'order_index': _childSeeds.length,
        },
        createdAt: now,
      );
      await widget.relationRepository.createRelation(relation);

      // 3. Persist any explicit mentions
      for (final m in mentions) {
        final mentionRel = EntityRelation(
          id: _uuid.v4(),
          userId: _rootSeed.userId ?? '',
          sourceId: createdChild.id,
          targetType: TargetType.entity,
          targetId: m.entityId,
          relationType: m.relationType,
          createdAt: now,
        );
        await widget.relationRepository.createRelation(mentionRel);
      }

      // 4. Also append to root seed's living blocks (flusso evolutivo) so it is 100% equivalent to vitrine additions!
      final newBlock = EntityBlock(
        id: _uuid.v4(),
        content: clean,
        position: _rootSeed.blocks.length,
        createdAt: now,
      );
      final updatedRoot = _rootSeed.copyWith(
        blocks: [..._rootSeed.blocks, newBlock],
        updatedAt: now,
      );
      await widget.entityRepository.updateEntity(updatedRoot);

      if (mounted) {
        setState(() {
          _rootSeed = updatedRoot;
          _childSeeds.add(createdChild);
          _parentMap[createdChild.id] = activeTargetId;
          _isSaving = false;
        });
        widget.onSeedUpdated?.call(updatedRoot);
        widget.onSeedAdded?.call(createdChild);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore durante il salvataggio: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Stack(
      children: [
        // 1. Dimmed Background Scrim (80% opacity)
        Positioned.fill(
          child: GestureDetector(
            onTap: widget.onDismiss,
            behavior: HitTestBehavior.opaque,
            child: Container(
              color: const Color(0xCC09090B),
            ),
          ),
        ),

        // 2. Foreground Overlay Interface
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),

                // Top Navigation Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withOpacity(0.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.all_inclusive_rounded, color: AppTheme.primary, size: 14),
                          SizedBox(width: 6),
                          Text(
                            'Flusso del Seme',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: widget.onDismiss,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white70,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      ),
                      icon: const Icon(Icons.check_rounded, color: AppTheme.primary, size: 16),
                      label: const Text('Fatto', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Main Seed Card - Fixed in Place at the Top
                _buildMainSeedCard(),
                const SizedBox(height: 12),

                // Section Divider: Flusso Evolutivo
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.white.withOpacity(0.12), thickness: 1)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        children: [
                          const Icon(Icons.hub_outlined, color: Color(0xFF8B5CF6), size: 14),
                          const SizedBox(width: 6),
                          Text(
                            _childSeeds.isEmpty
                                ? 'FLUSSO EVOLUTIVO'
                                : 'FLUSSO EVOLUTIVO (${_childSeeds.length} aggiunti)',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.white.withOpacity(0.12), thickness: 1)),
                  ],
                ),
                const SizedBox(height: 8),

                // Scrollable List of Thoughts and Sub-thoughts
                Expanded(
                  child: _childSeeds.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'Aggiungi pensieri o idee collegate per arricchire questo seme.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.35),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        )
                      : ListView(
                          physics: const BouncingScrollPhysics(),
                          children: _buildTreeItems(),
                        ),
                ),

                // Active Target Indicator (if nested inside a secondary item)
                if (_targetParentId != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.subdirectory_arrow_right_rounded, color: AppTheme.primary, size: 15),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Aggiungi dentro: "${_targetParentTitle ?? ''}"',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        InkWell(
                          onTap: () => setState(() {
                            _targetParentId = null;
                            _targetParentTitle = null;
                          }),
                          child: const Icon(Icons.close_rounded, color: Colors.white54, size: 16),
                        ),
                      ],
                    ),
                  ),

                // Active Input Bar Anchored Directly Above Software Keyboard
                Padding(
                  padding: EdgeInsets.only(bottom: bottomInset > 0 ? bottomInset + 8 : 12),
                  child: DynamicCaptureBar(
                    onCaptureWithMentions: _handleThoughtCapture,
                    availableEntities: widget.availableEntities,
                    isCapturing: _isSaving,
                    hintText: _targetParentId != null
                        ? 'Aggiungi sotto a "${_targetParentTitle ?? ''}"...'
                        : 'Aggiungi un pensiero al flusso evolutivo...',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the top fixed card for the main seed
  Widget _buildMainSeedCard() {
    final isEditing = _editingEntityId == _rootSeed.id;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF8B5CF6).withOpacity(0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'SEME PRINCIPALE',
                  style: TextStyle(
                    color: Color(0xFF8B5CF6),
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              const Spacer(),
              if (isEditing) ...[
                TextButton(
                  onPressed: () => setState(() => _editingEntityId = null),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Annulla', style: TextStyle(color: Colors.white54, fontSize: 11)),
                ),
                const SizedBox(width: 6),
                ElevatedButton(
                  onPressed: () => _saveEdit(_rootSeed),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Salva', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ] else
                InkWell(
                  onTap: () => _startEditing(_rootSeed),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.edit_outlined, color: Color(0xFF8B5CF6), size: 13),
                        SizedBox(width: 4),
                        Text(
                          'Modifica',
                          style: TextStyle(
                            color: Color(0xFF8B5CF6),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Main Seed Text
          if (isEditing)
            TextField(
              controller: _editController,
              autofocus: true,
              maxLines: null,
              style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w600),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            )
          else
            Text(
              _rootSeed.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
        ],
      ),
    );
  }

  /// Builds a structured hierarchical list of thoughts
  List<Widget> _buildTreeItems() {
    final widgets = <Widget>[];

    // Find direct children of root
    final directChildren = _childSeeds.where((c) => _parentMap[c.id] == _rootSeed.id || !_parentMap.containsKey(c.id)).toList();

    for (final direct in directChildren) {
      widgets.add(_buildThoughtCard(direct, isNested: false));

      // Find any children nested inside this direct child
      final nestedChildren = _childSeeds.where((c) => _parentMap[c.id] == direct.id).toList();
      for (final nested in nestedChildren) {
        widgets.add(_buildThoughtCard(nested, isNested: true, parentTitle: direct.title));
      }
    }

    return widgets;
  }

  Widget _buildThoughtCard(LifeEntity entity, {required bool isNested, String? parentTitle}) {
    final isEditing = _editingEntityId == entity.id;
    final isTargeted = _targetParentId == entity.id;

    return Container(
      margin: EdgeInsets.only(left: isNested ? 24 : 0, bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 10),
      decoration: BoxDecoration(
        color: isTargeted
            ? const Color(0xFF8B5CF6).withOpacity(0.12)
            : const Color(0xFF141418),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isTargeted
              ? const Color(0xFF8B5CF6).withOpacity(0.6)
              : Colors.white.withOpacity(0.08),
          width: isTargeted ? 1.2 : 0.9,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header with Nested indicator and Action buttons
          Row(
            children: [
              if (isNested) ...[
                const Icon(Icons.subdirectory_arrow_right_rounded, color: Color(0xFF8B5CF6), size: 14),
                const SizedBox(width: 4),
                Text(
                  'dentro "$parentTitle"',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ] else ...[
                Icon(Icons.bubble_chart_outlined, color: Colors.white.withOpacity(0.4), size: 14),
                const SizedBox(width: 4),
                Text(
                  'Pensiero',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
              const Spacer(),

              // "Aggiungi dentro" action button
              if (!isEditing)
                InkWell(
                  onTap: () => _setTargetParent(entity),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: isTargeted ? const Color(0xFF8B5CF6) : Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.subdirectory_arrow_right_rounded,
                          size: 11,
                          color: isTargeted ? Colors.white : const Color(0xFF8B5CF6),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          isTargeted ? 'Selezionato' : 'Aggiungi dentro',
                          style: TextStyle(
                            color: isTargeted ? Colors.white : const Color(0xFF8B5CF6),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(width: 6),

              // Edit action button
              if (isEditing) ...[
                TextButton(
                  onPressed: () => setState(() => _editingEntityId = null),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Annulla', style: TextStyle(color: Colors.white54, fontSize: 11)),
                ),
                const SizedBox(width: 4),
                ElevatedButton(
                  onPressed: () => _saveEdit(entity),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Salva', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ] else
                InkWell(
                  onTap: () => _startEditing(entity),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Icon(Icons.edit_outlined, color: Colors.white.withOpacity(0.35), size: 13),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),

          // Thought content
          if (isEditing)
            TextField(
              controller: _editController,
              autofocus: true,
              maxLines: null,
              style: const TextStyle(color: Colors.white, fontSize: 13.5),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            )
          else
            Text(
              entity.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13.5,
                height: 1.35,
              ),
            ),
        ],
      ),
    );
  }
}
