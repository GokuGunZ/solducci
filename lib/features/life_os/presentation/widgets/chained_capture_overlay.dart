import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:solducci/features/life_os/domain/models/models.dart';
import 'package:solducci/features/life_os/domain/repositories/repositories.dart';
import 'package:solducci/features/life_os/presentation/widgets/dynamic_capture_bar.dart';
import 'package:solducci/theme/app_theme.dart';
import 'package:uuid/uuid.dart';

/// Modal overlay that dims the background and allows continuous collection
/// of interconnected chained seeds ("Raccogli una catena di semi").
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
  final List<LifeEntity> _chainSeeds = [];

  // Editing state for a specific seed in the chain
  String? _editingSeedId;
  final TextEditingController _editController = TextEditingController();

  bool _isSavingChain = false;

  @override
  void initState() {
    super.initState();
    _chainSeeds.add(widget.initialSeed);
  }

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  void _startEditing(LifeEntity seed) {
    HapticFeedback.selectionClick();
    setState(() {
      _editingSeedId = seed.id;
      _editController.text = seed.title;
    });
  }

  Future<void> _saveEdit(LifeEntity seed) async {
    final clean = _editController.text.trim();
    if (clean.isEmpty) return;

    HapticFeedback.lightImpact();
    final updated = seed.copyWith(
      title: clean,
      updatedAt: DateTime.now(),
    );

    try {
      await widget.entityRepository.updateEntity(updated);
      final idx = _chainSeeds.indexWhere((s) => s.id == seed.id);
      if (idx != -1) {
        setState(() {
          _chainSeeds[idx] = updated;
          _editingSeedId = null;
        });
      }
      widget.onSeedUpdated?.call(updated);
    } catch (_) {
      // Revert editing mode on error
      setState(() => _editingSeedId = null);
    }
  }

  Future<void> _handleChainedCapture(String text, List<SeedMention> mentions) async {
    final clean = text.trim();
    if (clean.isEmpty && mentions.isEmpty) return;
    if (_isSavingChain) return;

    setState(() => _isSavingChain = true);
    HapticFeedback.mediumImpact();

    try {
      final now = DateTime.now();
      final parentSeed = _chainSeeds.last;
      final newSeedId = _uuid.v4();

      final newSeed = LifeEntity(
        id: newSeedId,
        userId: widget.initialSeed.userId,
        groupId: widget.initialSeed.groupId,
        title: clean.isNotEmpty ? clean : 'Seme collegato',
        semanticRole: SemanticRole.seed,
        lifecycleState: LifecycleState.active,
        currentMode: null,
        createdAt: now,
        updatedAt: now,
      );

      // 1. Commit new seed document first (RLS safe)
      final createdSeed = await widget.entityRepository.createEntity(newSeed);

      // 2. Link as child of previous seed in chain (partOf)
      final chainRelation = EntityRelation(
        id: _uuid.v4(),
        userId: widget.initialSeed.userId ?? '',
        sourceId: createdSeed.id,
        targetType: TargetType.entity,
        targetId: parentSeed.id,
        relationType: RelationType.partOf,
        metadata: {
          'chain_root_id': widget.initialSeed.id,
          'chain_order': _chainSeeds.length,
        },
        createdAt: now,
      );
      await widget.relationRepository.createRelation(chainRelation);

      // 3. Link any explicit mentions
      for (final m in mentions) {
        final mentionRel = EntityRelation(
          id: _uuid.v4(),
          userId: widget.initialSeed.userId ?? '',
          sourceId: createdSeed.id,
          targetType: TargetType.entity,
          targetId: m.entityId,
          relationType: m.relationType,
          createdAt: now,
        );
        await widget.relationRepository.createRelation(mentionRel);
      }

      if (mounted) {
        setState(() {
          _chainSeeds.add(createdSeed);
          _isSavingChain = false;
        });
        widget.onSeedAdded?.call(createdSeed);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSavingChain = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore salvataggio seme: $e'),
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
        // 1. Dimmed Background Scrim (80% dark overlay)
        Positioned.fill(
          child: GestureDetector(
            onTap: widget.onDismiss,
            behavior: HitTestBehavior.opaque,
            child: Container(
              color: const Color(0xCC09090B),
            ),
          ),
        ),

        // 2. Foreground Chained Interface
        Positioned(
          left: 16,
          right: 16,
          bottom: bottomInset > 0 ? bottomInset + 12 : 24,
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Dismiss / Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withOpacity(0.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.all_inclusive_rounded, color: AppTheme.primary, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            'Catena di Semi (${_chainSeeds.length})',
                            style: const TextStyle(
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

                // Stream of Committed Seeds ("Box Definitivo")
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.35,
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    reverse: true, // Auto-scroll to latest
                    child: Column(
                      children: [
                        for (int i = 0; i < _chainSeeds.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _buildCommittedSeedCard(_chainSeeds[i], index: i),
                          ),
                      ],
                    ),
                  ),
                ),

                // Separator Label: "Raccogli una catena di semi"
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(child: Divider(color: Colors.white.withOpacity(0.12), thickness: 1)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          children: [
                            const Icon(Icons.link_rounded, color: Color(0xFF8B5CF6), size: 14),
                            const SizedBox(width: 6),
                            Text(
                              'Raccogli una catena di semi',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.white.withOpacity(0.12), thickness: 1)),
                    ],
                  ),
                ),

                // Active Secondary DynamicCaptureBar
                DynamicCaptureBar(
                  onCaptureWithMentions: _handleChainedCapture,
                  availableEntities: widget.availableEntities,
                  isCapturing: _isSavingChain,
                  hintText: 'Aggiungi il prossimo seme connesso...',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Renders a finalized committed seed card with "Edit" button
  Widget _buildCommittedSeedCard(LifeEntity seed, {required int index}) {
    final isEditing = _editingSeedId == seed.id;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: index == _chainSeeds.length - 1
              ? const Color(0xFF8B5CF6).withOpacity(0.4)
              : Colors.white.withOpacity(0.08),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Link level badge + Edit action
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  index == 0 ? 'Seme Principale' : 'Anello #${index + 1}',
                  style: TextStyle(
                    color: index == 0 ? const Color(0xFF8B5CF6) : Colors.white60,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              if (isEditing) ...[
                TextButton(
                  onPressed: () => setState(() => _editingSeedId = null),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Annulla', style: TextStyle(color: Colors.white54, fontSize: 11)),
                ),
                const SizedBox(width: 6),
                ElevatedButton(
                  onPressed: () => _saveEdit(seed),
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
                  onTap: () => _startEditing(seed),
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

          // Seed Content (Editable vs Read-only)
          if (isEditing)
            TextField(
              controller: _editController,
              autofocus: true,
              maxLines: null,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            )
          else
            Text(
              seed.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.35,
              ),
            ),
        ],
      ),
    );
  }
}
