import 'package:flutter/material.dart';
import 'package:solducci/theme/app_theme.dart';

class BentoWidgetContainer extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool isLoading;
  final bool hasError;
  final Widget? errorWidget;

  const BentoWidgetContainer({
    super.key,
    required this.child,
    this.onTap,
    this.isLoading = false,
    this.hasError = false,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF18181B), // AppTheme.surface
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white10,
            width: 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: _buildContent(),
      ),
    );
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
      begin: const Color(0xFF1E1E2C), // Slightly lighter than surface
      end: const Color(0xFF2C2C3E),   // Even lighter
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
