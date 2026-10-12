import 'package:flutter/material.dart';

class BentoWidgetContainer extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onExpand;
  final bool isLoading;
  final bool hasError;
  final Widget? errorWidget;
  final String? heroTag;

  const BentoWidgetContainer({
    super.key,
    required this.child,
    this.onTap,
    this.onExpand,
    this.isLoading = false,
    this.hasError = false,
    this.errorWidget,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      decoration: BoxDecoration(
        color: const Color(0xFF18181B), // AppTheme.surface (Dark OLED)
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(child: _buildContent()),
          // Top subtle specular highlight
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 1,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.0),
                    Colors.white.withOpacity(0.12),
                    Colors.white.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          if (onExpand != null)
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: onExpand,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.open_in_full, size: 14, color: Colors.white54),
                ),
              ),
            ),
        ],
      ),
    );

    if (onTap != null) {
      content = GestureDetector(
        onTap: onTap,
        child: content,
      );
    }

    if (heroTag != null) {
      content = Hero(
        tag: heroTag!,
        child: Material(
          type: MaterialType.transparency,
          child: content,
        ),
      );
    }

    return content;
  }

  Widget _buildContent() {
    if (isLoading) {
      return const _SkeletonLoader();
    }
    
    if (hasError) {
      return errorWidget ?? const Center(
        child: Icon(Icons.error_outline, color: Colors.white54),
      );
    }

    return child;
  }
}

class _SkeletonLoader extends StatefulWidget {
  const _SkeletonLoader();

  @override
  State<_SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<_SkeletonLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorTween;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _colorTween = ColorTween(
      begin: const Color(0xFF18181B), // OLED Surface
      end: const Color(0xFF27272A),   // Zinc border highlight
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _colorTween,
      builder: (context, child) {
        return Container(
          color: _colorTween.value,
        );
      },
    );
  }
}
