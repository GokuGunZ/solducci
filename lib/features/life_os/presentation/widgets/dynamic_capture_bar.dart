import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:solducci/features/life_os/domain/models/models.dart';
import 'package:solducci/features/life_os/presentation/widgets/entity_mention_picker.dart';
import 'package:solducci/features/life_os/presentation/widgets/seed_relation_switcher_sheet.dart';
import 'package:solducci/features/life_os/presentation/widgets/structured_capture_sheet.dart';
import 'package:solducci/theme/app_theme.dart';

/// Callback delivering the captured seed text and any associated @mentions.
typedef SeedCaptureCallback = void Function(String text, List<SeedMention> mentions);

/// Redesigned LifeOS Universal Capture Bar with:
/// 1. Dynamic Multiline Spatial Morphing (1-line inline ↔ multiline full-width).
/// 2. Slide-in action label ("Raccogli seme ") emerging from behind the send icon.
/// 3. Native '@' Mention Receptor with position-based default:
///    - Leading tag → "Figlio di" (partOf)
///    - Mid-text tag → "Semplice" (relatesTo)
/// 4. Top-row Tag Chip Tray with interactive type-switcher popover.
class DynamicCaptureBar extends StatefulWidget {
  final ValueChanged<String>? onCapture;
  final SeedCaptureCallback? onCaptureWithMentions;
  final ValueChanged<String>? onStructuredCapture;
  final List<LifeEntity> availableEntities;
  final bool isCapturing;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final String hintText;
  final FocusNode? focusNode;
  final TextEditingController? controller;

  const DynamicCaptureBar({
    super.key,
    this.onCapture,
    this.onCaptureWithMentions,
    this.onStructuredCapture,
    this.availableEntities = const [],
    this.isCapturing = false,
    this.errorMessage,
    this.onRetry,
    this.hintText = 'Cattura un pensiero, seme o @entità...',
    this.focusNode,
    this.controller,
  });

  @override
  State<DynamicCaptureBar> createState() => _DynamicCaptureBarState();
}

class _DynamicCaptureBarState extends State<DynamicCaptureBar> with SingleTickerProviderStateMixin {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _ownsController = false;
  bool _ownsFocusNode = false;

  bool _isMultiline = false;
  final List<SeedMention> _mentions = [];

  // Mention picker overlay state
  bool _showMentionPicker = false;
  String _mentionQuery = '';
  int _mentionStartIndex = -1;

  // Animation controller for the slide-in "Raccogli seme " label
  late final AnimationController _labelAnimController;
  late final Animation<Offset> _labelSlideAnimation;
  late final Animation<double> _labelFadeAnimation;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = TextEditingController();
      _ownsController = true;
    }

    if (widget.focusNode != null) {
      _focusNode = widget.focusNode!;
    } else {
      _focusNode = FocusNode();
      _ownsFocusNode = true;
    }

    _controller.addListener(_handleTextChanged);
    _focusNode.addListener(_handleFocusChanged);

    _labelAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );

    _labelSlideAnimation = Tween<Offset>(
      begin: const Offset(0.45, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _labelAnimController,
      curve: Curves.easeOutCubic,
    ));

    _labelFadeAnimation = CurvedAnimation(
      parent: _labelAnimController,
      curve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTextChanged);
    _focusNode.removeListener(_handleFocusChanged);
    _labelAnimController.dispose();
    if (_ownsController) _controller.dispose();
    if (_ownsFocusNode) _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChanged() {
    if (!_focusNode.hasFocus && _showMentionPicker) {
      setState(() => _showMentionPicker = false);
    }
  }

  void _handleTextChanged() {
    final text = _controller.text;

    // 1. Line count calculation
    final newlineCount = '\n'.allMatches(text).length;
    // Estimated line wrap based on average character length (~34 chars per line on mobile)
    final estimatedLines = (text.length / 32).floor();
    final isMulti = newlineCount >= 1 || estimatedLines >= 1;

    if (isMulti != _isMultiline) {
      setState(() {
        _isMultiline = isMulti;
      });

      if (_isMultiline) {
        _labelAnimController.forward();
      } else {
        _labelAnimController.reverse();
      }
    }

    // 2. Mention trigger (@) detection
    final selection = _controller.selection;
    if (selection.isValid && selection.isCollapsed) {
      final cursor = selection.baseOffset;
      if (cursor > 0) {
        final textBeforeCursor = text.substring(0, cursor);
        final lastAt = textBeforeCursor.lastIndexOf('@');
        if (lastAt >= 0) {
          // Check if @ is preceded by whitespace or at line start
          final isStart = lastAt == 0 || textBeforeCursor[lastAt - 1] == ' ' || textBeforeCursor[lastAt - 1] == '\n';
          final query = textBeforeCursor.substring(lastAt + 1);
          // Query should not contain spaces
          if (isStart && !query.contains(' ') && !query.contains('\n')) {
            setState(() {
              _showMentionPicker = true;
              _mentionQuery = query;
              _mentionStartIndex = lastAt;
            });
            return;
          }
        }
      }
    }

    if (_showMentionPicker) {
      setState(() => _showMentionPicker = false);
    }
  }

  void _selectMention(LifeEntity entity) {
    HapticFeedback.lightImpact();
    final text = _controller.text;
    final cursor = _controller.selection.baseOffset;

    // Determine if this mention is at the very start of the text
    final isLeading = _mentionStartIndex == 0 || text.substring(0, _mentionStartIndex).trim().isEmpty;

    // Heuristic rule: Leading tag defaults to 'partOf', mid-text defaults to 'relatesTo'
    final relationType = isLeading ? RelationType.partOf : RelationType.relatesTo;

    final newMention = SeedMention(
      entityId: entity.id,
      entityTitle: entity.title,
      role: entity.semanticRole,
      relationType: relationType,
      isLeadingTag: isLeading,
    );

    // Replace @query in text with clean title or remove if leading
    String before = text.substring(0, _mentionStartIndex);
    String after = cursor <= text.length ? text.substring(cursor) : '';

    String updatedText;
    if (isLeading) {
      // Clean leading space if present
      updatedText = after.trimLeft();
    } else {
      updatedText = '$before@${entity.title} $after';
    }

    setState(() {
      _mentions.add(newMention);
      _showMentionPicker = false;
    });

    _controller.text = updatedText;
    _controller.selection = TextSelection.collapsed(offset: updatedText.length);
  }

  void _openMentionSwitcher(int index) async {
    HapticFeedback.selectionClick();
    final current = _mentions[index];
    final updated = await SeedRelationSwitcherSheet.show(context, mention: current);

    if (!mounted) return;
    setState(() {
      if (updated == null) {
        // User chose to remove tag
        _mentions.removeAt(index);
      } else {
        _mentions[index] = updated;
      }
    });
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty && _mentions.isEmpty) return;
    if (widget.isCapturing) return;

    HapticFeedback.mediumImpact();

    final capturedText = text.isNotEmpty ? text : (_mentions.isNotEmpty ? 'Seme collegato a ${_mentions.map((m) => m.entityTitle).join(', ')}' : '');
    final capturedMentions = List<SeedMention>.from(_mentions);

    if (widget.onCaptureWithMentions != null) {
      widget.onCaptureWithMentions!(capturedText, capturedMentions);
    } else if (widget.onCapture != null) {
      widget.onCapture!(capturedText);
    }

    _controller.clear();
    setState(() {
      _mentions.clear();
      _isMultiline = false;
      _showMentionPicker = false;
    });
    _labelAnimController.reverse();
  }

  Future<void> _handleLongPress() async {
    final text = _controller.text.trim();
    HapticFeedback.mediumImpact();
    if (widget.onStructuredCapture != null) {
      widget.onStructuredCapture!(text);
      _controller.clear();
      return;
    }

    final created = await StructuredCaptureSheet.show(
      context,
      initialTitle: text.isNotEmpty ? text : null,
    );

    if (created != null && mounted) {
      _controller.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Progetto "${created.title}" creato!'),
          backgroundColor: const Color(0xFF27272A),
          action: SnackBarAction(
            label: 'Apri',
            textColor: AppTheme.primary,
            onPressed: () => context.push('/life_os/entity/${created.id}'),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Error Banner (if any)
        if (widget.errorMessage != null)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.error.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.error.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.wifi_off_rounded, color: AppTheme.error, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.errorMessage!,
                    style: const TextStyle(color: AppTheme.error, fontSize: 12),
                  ),
                ),
                if (widget.onRetry != null)
                  TextButton(
                    onPressed: widget.onRetry,
                    child: const Text('Riprova', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),

        // 2. Floating Entity Mention Picker (when @ is active)
        if (_showMentionPicker)
          EntityMentionPicker(
            entities: widget.availableEntities,
            query: _mentionQuery,
            onSelected: _selectMention,
          ),

        // 3. Dynamic Morphing Capture Container
        AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeInOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF18181B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _focusNode.hasFocus ? AppTheme.primary : Colors.white.withOpacity(0.12),
              width: 1.2,
            ),
            boxShadow: [
              if (_focusNode.hasFocus)
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: _isMultiline || _mentions.isNotEmpty ? _buildMultiLineLayout() : _buildSingleLineLayout(),
        ),
      ],
    );
  }

  /// Single-line (Compact inline) layout: [ Leaf ] [ TextField ] [ Send Arrow ]
  Widget _buildSingleLineLayout() {
    return Row(
      children: [
        const Icon(Icons.eco_outlined, color: Colors.white38, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: const TextStyle(color: Colors.white30, fontSize: 14),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
        const SizedBox(width: 6),
        _buildSendButton(),
      ],
    );
  }

  /// Multi-line (Two-tier spatial morphing) layout:
  /// Row 1: [ Leaf ] [ Tag Chips Tray ] [ Slide-in "Raccogli seme " ] [ Send Arrow ]
  /// Row 2: [ Full Width Wrapping TextField ]
  Widget _buildMultiLineLayout() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Tier 1: Action & Tag Tray Row
        Row(
          children: [
            const Icon(Icons.eco_outlined, color: Colors.white38, size: 20),
            const SizedBox(width: 8),

            // Tag Chips Tray
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    for (int i = 0; i < _mentions.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: _buildMentionChip(_mentions[i], i),
                      ),
                  ],
                ),
              ),
            ),

            // Slide-in Text Label: "Raccogli seme "
            ClipRect(
              child: SlideTransition(
                position: _labelSlideAnimation,
                child: FadeTransition(
                  opacity: _labelFadeAnimation,
                  child: const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Text(
                      'Raccogli seme ',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Send Button
            _buildSendButton(),
          ],
        ),
        const SizedBox(height: 6),

        // Tier 2: Full-width Multiline TextField (Zero Horizontal Margin Restrictions)
        ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: 48,
            maxHeight: 180,
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            style: const TextStyle(color: Colors.white, fontSize: 14.5, height: 1.4),
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: const TextStyle(color: Colors.white30, fontSize: 14),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 4),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMentionChip(SeedMention mention, int index) {
    final isChild = mention.relationType == RelationType.partOf;
    return InkWell(
      onTap: () => _openMentionSwitcher(index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isChild ? const Color(0xFF8B5CF6).withOpacity(0.2) : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isChild ? const Color(0xFF8B5CF6).withOpacity(0.5) : Colors.white12,
            width: 0.9,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isChild ? Icons.subdirectory_arrow_right_rounded : Icons.link_rounded,
              color: isChild ? const Color(0xFF8B5CF6) : Colors.white70,
              size: 13,
            ),
            const SizedBox(width: 4),
            Text(
              '@${mention.entityTitle}',
              style: TextStyle(
                color: isChild ? Colors.white : Colors.white70,
                fontSize: 11.5,
                fontWeight: isChild ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSendButton() {
    if (widget.isCapturing) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _submit,
        onLongPress: _handleLongPress,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFF8B5CF6).withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.arrow_upward_rounded,
            color: AppTheme.primary,
            size: 20,
          ),
        ),
      ),
    );
  }
}
