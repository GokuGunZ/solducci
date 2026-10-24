import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:solducci/theme/app_theme.dart';

class UniversalCaptureBar extends StatefulWidget {
  final ValueChanged<String> onCapture;
  final bool isCapturing;
  final String? errorMessage;
  final VoidCallback? onRetry;

  const UniversalCaptureBar({
    super.key,
    required this.onCapture,
    this.isCapturing = false,
    this.errorMessage,
    this.onRetry,
  });

  @override
  State<UniversalCaptureBar> createState() => _UniversalCaptureBarState();
}

class _UniversalCaptureBarState extends State<UniversalCaptureBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.isCapturing) return;

    HapticFeedback.mediumImpact();
    widget.onCapture(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Riprova', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF18181B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _focusNode.hasFocus ? AppTheme.primary : Colors.white.withOpacity(0.1),
              width: 1.2,
            ),
          ),
          child: Row(
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
                  decoration: const InputDecoration(
                    hintText: 'Cattura un pensiero, seme o progetto...',
                    hintStyle: TextStyle(color: Colors.white30, fontSize: 14),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              widget.isCapturing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
                    )
                  : IconButton(
                      icon: const Icon(Icons.arrow_upward_rounded, color: AppTheme.primary, size: 22),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: _submit,
                    ),
            ],
          ),
        ),
      ],
    );
  }
}
