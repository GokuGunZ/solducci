import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

/// Modal dialog that allows user to preview, zoom, pan, rotate, and crop an avatar.
/// Returns cropped [Uint8List] bytes or null if cancelled.
class AvatarCropPreviewDialog extends StatefulWidget {
  final Uint8List imageBytes;
  final String title;

  const AvatarCropPreviewDialog({
    super.key,
    required this.imageBytes,
    this.title = 'Ritaglia foto profilo',
  });

  static Future<Uint8List?> show(
    BuildContext context, {
    required Uint8List imageBytes,
    String title = 'Ritaglia foto profilo',
  }) {
    return showDialog<Uint8List>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AvatarCropPreviewDialog(
        imageBytes: imageBytes,
        title: title,
      ),
    );
  }

  @override
  State<AvatarCropPreviewDialog> createState() => _AvatarCropPreviewDialogState();
}

class _AvatarCropPreviewDialogState extends State<AvatarCropPreviewDialog> {
  final GlobalKey _cropKey = GlobalKey();
  final TransformationController _transformController = TransformationController();

  int _quarterTurns = 0;
  bool _isProcessing = false;

  void _rotateClockwise() {
    HapticFeedback.selectionClick();
    setState(() {
      _quarterTurns = (_quarterTurns + 1) % 4;
    });
  }

  void _resetTransform() {
    HapticFeedback.selectionClick();
    _transformController.value = Matrix4.identity();
    setState(() {
      _quarterTurns = 0;
    });
  }

  Future<void> _confirmAndCrop() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    HapticFeedback.mediumImpact();

    try {
      // Ensure the widget has laid out
      await Future.delayed(const Duration(milliseconds: 50));

      final boundary = _cropKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        if (mounted) Navigator.of(context).pop(null);
        return;
      }

      // 260px widget rendered at pixelRatio: 280 / 260 = ~280x280 target avatar
      final pixelRatio = 280.0 / 260.0;
      final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        final croppedBytes = byteData.buffer.asUint8List();
        if (mounted) {
          Navigator.of(context).pop(croppedBytes);
        }
      } else {
        if (mounted) {
          Navigator.of(context).pop(widget.imageBytes);
        }
      }
    } catch (e) {
      debugPrint('Error cropping avatar: $e');
      if (mounted) {
        Navigator.of(context).pop(widget.imageBytes);
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double cropSize = 260.0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: const Color(0xFF18181D),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF27272A), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title & close
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white60, size: 20),
                  onPressed: _isProcessing ? null : () => Navigator.of(context).pop(null),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Trascina o usa due dita per centrare e ridimensionare',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ),
            const SizedBox(height: 20),

            // Circular Crop Viewport with RepaintBoundary
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // The actual capture boundary
                  RepaintBoundary(
                    key: _cropKey,
                    child: ClipOval(
                      child: Container(
                        width: cropSize,
                        height: cropSize,
                        color: Colors.black,
                        child: RotatedBox(
                          quarterTurns: _quarterTurns,
                          child: InteractiveViewer(
                            transformationController: _transformController,
                            minScale: 0.8,
                            maxScale: 4.0,
                            boundaryMargin: const EdgeInsets.all(120),
                            child: Image.memory(
                              widget.imageBytes,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Overlay circular guide border (ignore pointer so gestures pass through)
                  IgnorePointer(
                    child: Container(
                      width: cropSize,
                      height: cropSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF10B981).withOpacity(0.7),
                          width: 2.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Actions: Rotate & Reset
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: _isProcessing ? null : _rotateClockwise,
                  icon: const Icon(Icons.rotate_right_rounded, size: 18, color: Colors.white70),
                  label: const Text('Ruota', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.06),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(width: 12),
                TextButton.icon(
                  onPressed: _isProcessing ? null : _resetTransform,
                  icon: const Icon(Icons.refresh_rounded, size: 18, color: Colors.white70),
                  label: const Text('Ripristina', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.06),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Bottom Confirm / Cancel buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isProcessing ? null : () => Navigator.of(context).pop(null),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Annulla', style: TextStyle(color: Colors.white70)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _confirmAndCrop,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                          )
                        : const Text(
                            'Conferma',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
