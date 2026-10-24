import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:solducci/core/di/service_locator.dart';
import 'package:solducci/features/life_os/domain/models/models.dart';
import 'package:solducci/features/life_os/domain/repositories/repositories.dart';
import 'package:solducci/models/dashboard_config.dart';
import 'package:solducci/theme/app_theme.dart';
import 'package:solducci/widgets/dashboard/bento_widget_container.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Bento Universal Capture Widget (INT-D014)
/// Provides zero-friction thought capture directly from the Solducci Feed.
/// Saves raw seeds without opening the LifeOS Center:
/// semanticRole = seed, lifecycleState = active, currentMode = null.
class LifeOsCaptureWidget extends StatefulWidget {
  final BentoWidgetDef def;

  const LifeOsCaptureWidget({super.key, required this.def});

  @override
  State<LifeOsCaptureWidget> createState() => _LifeOsCaptureWidgetState();
}

class _LifeOsCaptureWidgetState extends State<LifeOsCaptureWidget> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
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
      String? userId;
      try {
        userId = Supabase.instance.client.auth.currentUser?.id;
      } catch (_) {}

      final newSeed = LifeEntity(
        id: _uuid.v4(),
        userId: userId,
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
          _statusBanner = 'Seme salvato ✓';
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
          _statusBanner = 'Errore di salvataggio';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final is2x1 = widget.def.size.crossAxisCellCount == 2 && widget.def.size.mainAxisCellCount == 1;

    return BentoWidgetContainer(
      size: widget.def.size,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.bolt_rounded, size: 14, color: Color(0xFF8B5CF6)),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.def.customProps?['title'] as String? ?? 'Cattura Rapida',
                  style: const TextStyle(
                    color: Colors.white70,
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
                      fontWeight: FontWeight.w600,
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
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF141418),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: is2x1 ? 'Cattura un seme...' : 'Cattura un pensiero al volo...',
                        hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onSubmitted: (_) => _submitCapture(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_upward_rounded, size: 16, color: Color(0xFF8B5CF6)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    onPressed: _submitCapture,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
