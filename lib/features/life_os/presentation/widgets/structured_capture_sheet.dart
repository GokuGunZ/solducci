import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:solducci/core/di/service_locator.dart';
import 'package:solducci/features/life_os/domain/models/models.dart';
import 'package:solducci/features/life_os/domain/repositories/repositories.dart';
import 'package:solducci/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Modal BottomSheet for rapid structured creation of a Project (or other container entity)
/// with immediate nested child thoughts/ideas connected via 'part_of' relations.
class StructuredCaptureSheet extends StatefulWidget {
  final String? initialTitle;
  final LifeEntityRepository? entityRepository;
  final EntityRelationRepository? relationRepository;

  const StructuredCaptureSheet({
    super.key,
    this.initialTitle,
    this.entityRepository,
    this.relationRepository,
  });

  static Future<LifeEntity?> show(
    BuildContext context, {
    String? initialTitle,
    LifeEntityRepository? entityRepository,
    EntityRelationRepository? relationRepository,
  }) {
    return showModalBottomSheet<LifeEntity>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StructuredCaptureSheet(
        initialTitle: initialTitle,
        entityRepository: entityRepository,
        relationRepository: relationRepository,
      ),
    );
  }

  @override
  State<StructuredCaptureSheet> createState() => _StructuredCaptureSheetState();
}

class _StructuredCaptureSheetState extends State<StructuredCaptureSheet> {
  final _uuid = const Uuid();
  late final TextEditingController _titleController;
  final TextEditingController _subIdeaController = TextEditingController();
  final FocusNode _subIdeaFocusNode = FocusNode();

  SemanticRole _selectedRole = SemanticRole.project;
  final List<String> _subIdeas = [];
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subIdeaController.dispose();
    _subIdeaFocusNode.dispose();
    super.dispose();
  }

  void _addSubIdea() {
    final text = _subIdeaController.text.trim();
    if (text.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() {
      _subIdeas.add(text);
      _subIdeaController.clear();
    });
    _subIdeaFocusNode.requestFocus();
  }

  void _removeSubIdea(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      _subIdeas.removeAt(index);
    });
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _errorMessage = 'Inserisci un titolo per il progetto.');
      return;
    }
    if (_isSaving) return;

    HapticFeedback.mediumImpact();
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final entityRepo = widget.entityRepository ?? getIt<LifeEntityRepository>();
      final relationRepo = widget.relationRepository ?? getIt<EntityRelationRepository>();

      String targetUserId = 'local-user';
      try {
        final currentId = Supabase.instance.client.auth.currentUser?.id;
        if (currentId != null) targetUserId = currentId;
      } catch (_) {}

      final now = DateTime.now();
      final rootId = _uuid.v4();

      // 1. Create root Project entity
      final rootEntity = LifeEntity(
        id: rootId,
        userId: targetUserId,
        title: title,
        semanticRole: _selectedRole,
        lifecycleState: LifecycleState.active,
        currentMode: OperationMode.exploration,
        createdAt: now,
        updatedAt: now,
      );

      final createdRoot = await entityRepo.createEntity(rootEntity);

      // 2. Create child sub-ideas and link via 'part_of' relations
      for (int i = 0; i < _subIdeas.length; i++) {
        final childText = _subIdeas[i];
        final childId = _uuid.v4();

        final childEntity = LifeEntity(
          id: childId,
          userId: targetUserId,
          title: childText,
          semanticRole: SemanticRole.seed,
          lifecycleState: LifecycleState.active,
          createdAt: now.add(Duration(milliseconds: (i + 1) * 10)),
          updatedAt: now.add(Duration(milliseconds: (i + 1) * 10)),
        );

        await entityRepo.createEntity(childEntity);

        final relation = EntityRelation(
          id: _uuid.v4(),
          userId: targetUserId,
          sourceId: childId,
          targetType: TargetType.entity,
          targetId: rootId,
          relationType: RelationType.partOf,
          metadata: {'order_index': i},
          createdAt: now.add(Duration(milliseconds: (i + 1) * 10)),
        );

        await relationRepo.createRelation(relation);
      }

      if (mounted) {
        Navigator.of(context).pop(createdRoot);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = 'Errore durante la creazione: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      decoration: const BoxDecoration(
        color: Color(0xFF18181B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: Colors.white12, width: 1),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.account_tree_rounded, color: AppTheme.primary, size: 20),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Nuovo Progetto Strutturato',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Role Selection Pills
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildRoleChip(SemanticRole.project, 'Progetto', Icons.account_tree_outlined),
                  const SizedBox(width: 8),
                  _buildRoleChip(SemanticRole.idea, 'Idea', Icons.lightbulb_outline_rounded),
                  const SizedBox(width: 8),
                  _buildRoleChip(SemanticRole.practice, 'Pratica', Icons.repeat_rounded),
                  const SizedBox(width: 8),
                  _buildRoleChip(SemanticRole.concept, 'Concetto', Icons.hub_outlined),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Title Input Field
            TextField(
              controller: _titleController,
              autofocus: widget.initialTitle == null || widget.initialTitle!.isEmpty,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: 'Titolo del progetto...',
                hintStyle: const TextStyle(color: Colors.white30, fontSize: 16),
                filled: true,
                fillColor: const Color(0xFF27272A),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Sub-ideas section label
            const Row(
              children: [
                Icon(Icons.subdirectory_arrow_right_rounded, color: Colors.white54, size: 16),
                SizedBox(width: 6),
                Text(
                  'Sotto-idee o pensieri inclusi (opzionale)',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Inline Sub-Idea Adder
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _subIdeaController,
                    focusNode: _subIdeaFocusNode,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _addSubIdea(),
                    decoration: InputDecoration(
                      hintText: 'Aggiungi una prima sotto-idea o nota...',
                      hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                      filled: true,
                      fillColor: const Color(0xFF202024),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(Icons.add_rounded, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF3F3F46),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _addSubIdea,
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Sub-ideas chips list
            if (_subIdeas.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _subIdeas.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final text = entry.value;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF27272A),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.circle, size: 6, color: AppTheme.primary),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            text,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => _removeSubIdea(idx),
                          child: const Icon(Icons.close_rounded, size: 14, color: Colors.white54),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            if (_errorMessage != null) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: AppTheme.error, fontSize: 13),
                ),
              ),
            ],

            // Submit Button
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : Text(
                        _subIdeas.isEmpty
                            ? 'Crea Progetto'
                            : 'Crea Progetto con ${_subIdeas.length} ${_subIdeas.length == 1 ? "elemento" : "elementi"}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleChip(SemanticRole role, String label, IconData icon) {
    final isSelected = _selectedRole == role;
    return ChoiceChip(
      avatar: Icon(
        icon,
        size: 14,
        color: isSelected ? Colors.black : Colors.white70,
      ),
      label: Text(label),
      selected: isSelected,
      selectedColor: AppTheme.primary,
      backgroundColor: const Color(0xFF27272A),
      labelStyle: TextStyle(
        color: isSelected ? Colors.black : Colors.white70,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      onSelected: (_) => setState(() => _selectedRole = role),
    );
  }
}
