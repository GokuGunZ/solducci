import 'package:flutter/material.dart';
import 'package:solducci/utils/app_image_helper.dart';

/// Fullscreen photo viewer with pinch-to-zoom, pan, double-tap zoom,
/// dark backdrop, and optional edit action.
class AppImageViewer extends StatefulWidget {
  final String imageUrl;
  final String? title;
  final String? subtitle;
  final VoidCallback? onEdit;
  final String? heroTag;

  const AppImageViewer({
    super.key,
    required this.imageUrl,
    this.title,
    this.subtitle,
    this.onEdit,
    this.heroTag,
  });

  /// Displays the full-screen image viewer as a modal route.
  static Future<void> show(
    BuildContext context, {
    required String imageUrl,
    String? title,
    String? subtitle,
    VoidCallback? onEdit,
    String? heroTag,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black.withOpacity(0.92),
        pageBuilder: (context, _, __) => AppImageViewer(
          imageUrl: imageUrl,
          title: title,
          subtitle: subtitle,
          onEdit: onEdit,
          heroTag: heroTag,
        ),
        transitionsBuilder: (context, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  State<AppImageViewer> createState() => _AppImageViewerState();
}

class _AppImageViewerState extends State<AppImageViewer> {
  final TransformationController _transformationController =
      TransformationController();
  TapDownDetails? _doubleTapDetails;
  bool _showControls = true;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    if (_transformationController.value != Matrix4.identity()) {
      _transformationController.value = Matrix4.identity();
    } else {
      final position = _doubleTapDetails?.localPosition ?? Offset.zero;
      _transformationController.value = Matrix4.identity()
        ..translate(-position.dx * 1.5, -position.dy * 1.5)
        ..scale(2.5);
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageProvider = AppImageHelper.getImageProvider(widget.imageUrl);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Dismiss on background tap
          GestureDetector(
            onTap: () {
              setState(() => _showControls = !_showControls);
            },
            onDoubleTapDown: (details) => _doubleTapDetails = details,
            onDoubleTap: _handleDoubleTap,
            child: Container(color: Colors.transparent),
          ),

          // Center zoomable image
          Center(
            child: imageProvider == null
                ? const Icon(Icons.broken_image_rounded, size: 64, color: Colors.white38)
                : InteractiveViewer(
                    transformationController: _transformationController,
                    minScale: 0.8,
                    maxScale: 4.5,
                    boundaryMargin: const EdgeInsets.all(80),
                    child: widget.heroTag != null
                        ? Hero(
                            tag: widget.heroTag!,
                            child: Image(
                              image: imageProvider,
                              fit: BoxFit.contain,
                            ),
                          )
                        : Image(
                            image: imageProvider,
                            fit: BoxFit.contain,
                          ),
                  ),
          ),

          // Top App Bar Controls
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            top: _showControls ? 0 : -100,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                bottom: 12,
                left: 12,
                right: 12,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.85),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.title != null)
                          Text(
                            widget.title!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (widget.subtitle != null)
                          Text(
                            widget.subtitle!,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  if (widget.onEdit != null)
                    IconButton(
                      icon: const Icon(Icons.edit_rounded, color: Colors.white),
                      tooltip: 'Modifica foto',
                      onPressed: () {
                        Navigator.of(context).pop();
                        widget.onEdit!();
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
