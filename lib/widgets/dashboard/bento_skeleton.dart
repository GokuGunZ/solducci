import 'package:flutter/material.dart';
import 'package:solducci/models/dashboard_config.dart';

/// Archetipi geometrici per i placeholder di caricamento dei widget Bento
enum BentoSkeletonType {
  metric,
  list,
  chart,
  countdown,
  notes,
  generic,
}

/// Shimmer Dark OLED animato con gradiente diagonale a 45°
class BentoShimmer extends StatefulWidget {
  final Widget child;

  const BentoShimmer({
    super.key,
    required this.child,
  });

  @override
  State<BentoShimmer> createState() => _BentoShimmerState();
}

class _BentoShimmerState extends State<BentoShimmer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final progress = _controller.value;
            // Spostamento del gradiente da -1.0 a 2.0 lungo la diagonale
            final startX = -1.0 + (progress * 2.0);
            return LinearGradient(
              begin: Alignment(startX, -0.6),
              end: Alignment(startX + 1.0, 0.6),
              colors: [
                const Color(0xFF27272A).withOpacity(0.4),
                Colors.white.withOpacity(0.12),
                const Color(0xFF27272A).withOpacity(0.4),
              ],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Singolo elemento osseo geometrico dello skeleton
class BentoSkeletonBone extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  const BentoSkeletonBone({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 8,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: const Color(0xFF27272A),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Libreria di Skeleton Layouts pronti all'uso per i tile Bento
class BentoSkeleton extends StatelessWidget {
  final BentoSkeletonType type;

  const BentoSkeleton({
    super.key,
    this.type = BentoSkeletonType.generic,
  });

  /// Crea lo skeleton appropriato in base alle dimensioni del tile
  factory BentoSkeleton.autoForSize(BentoWidgetSize size) {
    if (size.crossAxisCellCount <= 2 && size.mainAxisCellCount <= 1) {
      return const BentoSkeleton(type: BentoSkeletonType.metric);
    } else if (size.mainAxisCellCount >= 3) {
      return const BentoSkeleton(type: BentoSkeletonType.list);
    } else if (size.crossAxisCellCount >= 3) {
      return const BentoSkeleton(type: BentoSkeletonType.chart);
    } else {
      return const BentoSkeleton(type: BentoSkeletonType.list);
    }
  }

  const BentoSkeleton.metric({super.key}) : type = BentoSkeletonType.metric;
  const BentoSkeleton.list({super.key}) : type = BentoSkeletonType.list;
  const BentoSkeleton.chart({super.key}) : type = BentoSkeletonType.chart;
  const BentoSkeleton.countdown({super.key}) : type = BentoSkeletonType.countdown;
  const BentoSkeleton.notes({super.key}) : type = BentoSkeletonType.notes;

  @override
  Widget build(BuildContext context) {
    return BentoShimmer(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildLayout(),
      ),
    );
  }

  Widget _buildLayout() {
    switch (type) {
      case BentoSkeletonType.metric:
        return const _MetricSkeletonLayout();
      case BentoSkeletonType.list:
        return const _ListSkeletonLayout();
      case BentoSkeletonType.chart:
        return const _ChartSkeletonLayout();
      case BentoSkeletonType.countdown:
        return const _CountdownSkeletonLayout();
      case BentoSkeletonType.notes:
        return const _NotesSkeletonLayout();
      case BentoSkeletonType.generic:
        return const _GenericSkeletonLayout();
    }
  }
}

class _MetricSkeletonLayout extends StatelessWidget {
  const _MetricSkeletonLayout();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        BentoSkeletonBone(width: 60, height: 10, borderRadius: 5),
        SizedBox(height: 10),
        BentoSkeletonBone(width: 120, height: 26, borderRadius: 8),
        SizedBox(height: 8),
        BentoSkeletonBone(width: 80, height: 10, borderRadius: 5),
      ],
    );
  }
}

class _ListSkeletonLayout extends StatelessWidget {
  const _ListSkeletonLayout();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        const Row(
          children: [
            BentoSkeletonBone(width: 22, height: 22, borderRadius: 6),
            SizedBox(width: 10),
            BentoSkeletonBone(width: 110, height: 14, borderRadius: 6),
          ],
        ),
        const SizedBox(height: 16),
        // Item 1
        const _ListItemRow(widthFactor: 0.8),
        const SizedBox(height: 10),
        // Item 2
        const _ListItemRow(widthFactor: 0.6),
        const SizedBox(height: 10),
        // Item 3
        const _ListItemRow(widthFactor: 0.7),
      ],
    );
  }
}

class _ListItemRow extends StatelessWidget {
  final double widthFactor;
  const _ListItemRow({required this.widthFactor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const BentoSkeletonBone(width: 16, height: 16, borderRadius: 4),
        const SizedBox(width: 10),
        Expanded(
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: widthFactor,
            child: const BentoSkeletonBone(height: 12, borderRadius: 6),
          ),
        ),
      ],
    );
  }
}

class _ChartSkeletonLayout extends StatelessWidget {
  const _ChartSkeletonLayout();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            BentoSkeletonBone(width: 90, height: 14, borderRadius: 6),
            BentoSkeletonBone(width: 45, height: 14, borderRadius: 6),
          ],
        ),
        const Spacer(),
        // Barra di progresso o grafico finto
        const BentoSkeletonBone(height: 16, borderRadius: 8),
        const SizedBox(height: 12),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            BentoSkeletonBone(width: 70, height: 10, borderRadius: 5),
            BentoSkeletonBone(width: 50, height: 10, borderRadius: 5),
          ],
        ),
      ],
    );
  }
}

class _CountdownSkeletonLayout extends StatelessWidget {
  const _CountdownSkeletonLayout();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        BentoSkeletonBone(width: 56, height: 56, borderRadius: 16),
        SizedBox(width: 14),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BentoSkeletonBone(width: 110, height: 14, borderRadius: 6),
              SizedBox(height: 8),
              BentoSkeletonBone(width: 70, height: 11, borderRadius: 5),
            ],
          ),
        ),
      ],
    );
  }
}

class _NotesSkeletonLayout extends StatelessWidget {
  const _NotesSkeletonLayout();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            BentoSkeletonBone(width: 18, height: 18, borderRadius: 5),
            SizedBox(width: 8),
            BentoSkeletonBone(width: 80, height: 12, borderRadius: 5),
          ],
        ),
        SizedBox(height: 14),
        BentoSkeletonBone(height: 10, borderRadius: 5),
        SizedBox(height: 8),
        BentoSkeletonBone(width: 130, height: 10, borderRadius: 5),
      ],
    );
  }
}

class _GenericSkeletonLayout extends StatelessWidget {
  const _GenericSkeletonLayout();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BentoSkeletonBone(width: 100, height: 14, borderRadius: 6),
        SizedBox(height: 12),
        Expanded(
          child: BentoSkeletonBone(height: double.infinity, borderRadius: 12),
        ),
      ],
    );
  }
}
