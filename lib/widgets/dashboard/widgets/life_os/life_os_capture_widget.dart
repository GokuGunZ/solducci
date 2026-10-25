import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:solducci/core/di/service_locator.dart';
import 'package:solducci/theme/app_theme.dart';
import 'package:solducci/features/life_os/domain/models/models.dart';
import 'package:solducci/features/life_os/domain/repositories/repositories.dart';
import 'package:solducci/models/dashboard_config.dart';
import 'package:solducci/widgets/common/view_group_picker_sheet.dart';
import 'package:solducci/widgets/dashboard/bento_widget_container.dart';
import 'package:solducci/widgets/dashboard/context/dashboard_context_scope.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Bento Universal Capture Widget (INT-D014 / Step 3.2 Refactor)
/// Incarnates a single capability: write and send something immediately.
/// Dimension-aware composition according to WIDGET_DESIGN_PHILOSOPHY_AND_DIMENSIONS:
/// - 2x1 & 4x1 (H1 ~54px): Pure composer row [ ∞  Scrivi qualcosa...  ↑ ] with zero chrome.
/// - 2x2 (H2 ~124px): Dominant spacious composer with ambient ∞ signature.
class LifeOsCaptureWidget extends StatefulWidget {
  final BentoWidgetDef def;

  const LifeOsCaptureWidget({super.key, required this.def});

  @override
  State<LifeOsCaptureWidget> createState() => _LifeOsCaptureWidgetState();
}

class _LifeOsCaptureWidgetState extends State<LifeOsCaptureWidget> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final _uuid = const Uuid();

  bool _isSaving = false;
  String? _statusBanner;
  Timer? _bannerTimer;

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submitCapture() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSaving) return;

    HapticFeedback.lightImpact();
    setState(() {
      _isSaving = true;
      _statusBanner = null;
    });

    try {
      final repository = getIt<LifeEntityRepository>();
      ExpenseContext? currentContext;
      try {
        currentContext = DashboardContextScope.of(context);
      } catch (_) {}

      String? targetGroupId = currentContext?.groupId;
      String? targetUserId;
      try {
        targetUserId = Supabase.instance.client.auth.currentUser?.id;
      } catch (_) {}

      if (currentContext?.isView == true) {
        if (!mounted) return;
        final choice = await ViewGroupPickerSheet.show(
          context,
          title: 'Life OS',
          subtitle: 'Scegli in quale contesto salvare questo seme',
        );
        if (choice == null) {
          setState(() => _isSaving = false);
          return;
        }
        targetGroupId = choice.groupId;
      }

      final newSeed = LifeEntity(
        id: _uuid.v4(),
        userId: targetUserId,
        groupId: targetGroupId,
        title: text,
        semanticRole: SemanticRole.seed,
        lifecycleState: LifecycleState.active,
        currentMode: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repository.createEntity(newSeed);

      if (mounted) {
        setState(() {
          _isSaving = false;
          _statusBanner = '✓ Salvato';
          _textController.clear();
        });

        _bannerTimer?.cancel();
        _bannerTimer = Timer(const Duration(seconds: 2), () {
          if (mounted && _statusBanner != null) {
            setState(() => _statusBanner = null);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _statusBanner = 'Errore';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.def.size;
    final isH1 = size.mainAxisCellCount == 1; // 2x1 or 4x1 (~54px)
    final is4x1 = size.crossAxisCellCount == 4 && isH1;

    return BentoWidgetContainer(
      size: size,
      child: isH1
          ? _buildH1Composer(is4x1: is4x1)
          : _buildH2Composer(),
    );
  }

  /// H1 (~54px) Mini-Banner: Pure composer row with zero chrome or nested cards
  Widget _buildH1Composer({required bool is4x1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Ambient ∞ LifeOS Glyph
          const Icon(
            Icons.all_inclusive_rounded,
            size: 17,
            color: Color(0xFF8B5CF6),
          ),
          const SizedBox(width: 10),

          // Direct input line
          Expanded(
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              autofocus: false,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: is4x1
                    ? 'Cattura un pensiero al volo...'
                    : 'Scrivi qualcosa...',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _submitCapture(),
            ),
          ),

          const SizedBox(width: 8),

          // Submit action / Transient status feedback
          if (_statusBanner != null)
            Text(
              _statusBanner!,
              style: TextStyle(
                color: _statusBanner!.contains('✓') ? AppTheme.success : AppTheme.error,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            )
          else if (_isSaving)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF8B5CF6)),
            )
          else
            GestureDetector(
              onTap: _submitCapture,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withOpacity(0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.arrow_upward_rounded,
                  size: 15,
                  color: Color(0xFF8B5CF6),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// H2 (~124px) Banner: Dominant spacious composer with ambient watermark
  Widget _buildH2Composer() {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: discrete ∞ brand mark + status
          Row(
            children: [
              const Icon(
                Icons.all_inclusive_rounded,
                size: 15,
                color: Color(0xFF8B5CF6),
              ),
              const SizedBox(width: 6),
              const Text(
                'Cattura Rapida',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (_statusBanner != null)
                Text(
                  _statusBanner!,
                  style: TextStyle(
                    color: _statusBanner!.contains('✓') ? AppTheme.success : AppTheme.error,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                )
              else if (_isSaving)
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF8B5CF6)),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Spacious input area
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF141418),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                autofocus: false,
                maxLines: null,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'Cattura un pensiero, intuizione o seme...',
                  hintStyle: TextStyle(color: Colors.white30, fontSize: 12),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _submitCapture(),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Action row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: _submitCapture,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Salva',
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_upward_rounded, size: 12, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
