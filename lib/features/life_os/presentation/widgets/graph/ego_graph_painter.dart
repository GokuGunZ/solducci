import 'package:flutter/material.dart';
import 'package:solducci/features/life_os/domain/models/models.dart';
import 'package:solducci/theme/app_theme.dart';

class VisualGraphNode {
  final LifeEntity entity;
  final Offset position;
  final double radius;
  final bool isFocalRoot;
  final bool isClusterPill;
  final int childCount;
  final bool isSelected;

  const VisualGraphNode({
    required this.entity,
    required this.position,
    required this.radius,
    this.isFocalRoot = false,
    this.isClusterPill = false,
    this.childCount = 0,
    this.isSelected = false,
  });
}

class VisualGraphEdge {
  final Offset from;
  final Offset to;
  final bool isHighlighted;

  const VisualGraphEdge({
    required this.from,
    required this.to,
    this.isHighlighted = false,
  });
}

/// Native Canvas CustomPainter for 60/120 FPS Focused Ego-Graph rendering.
class EgoGraphPainter extends CustomPainter {
  final List<VisualGraphNode> nodes;
  final List<VisualGraphEdge> edges;
  final Offset center;

  EgoGraphPainter({
    required this.nodes,
    required this.edges,
    required this.center,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw subtle ambient concentric orbital guides
    final orbitPaint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(center, 130, orbitPaint);
    canvas.drawCircle(center, 220, orbitPaint);

    // 2. Draw Connection Edges
    final edgePaint = Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final highlightEdgePaint = Paint()
      ..color = AppTheme.primary.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (final edge in edges) {
      canvas.drawLine(
        edge.from,
        edge.to,
        edge.isHighlighted ? highlightEdgePaint : edgePaint,
      );
    }

    // 3. Draw Nodes
    for (final node in nodes) {
      _drawNode(canvas, node);
    }
  }

  void _drawNode(Canvas canvas, VisualGraphNode node) {
    final pos = node.position;

    if (node.isClusterPill) {
      // Draw Cluster Pill (Parent/Ancestor context)
      final pillRect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: pos, width: 140, height: 32),
        const Radius.circular(16),
      );

      final bgPaint = Paint()
        ..color = const Color(0xFF27272A)
        ..style = PaintingStyle.fill;
      final borderPaint = Paint()
        ..color = Colors.white24
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      canvas.drawRRect(pillRect, bgPaint);
      canvas.drawRRect(pillRect, borderPaint);

      _drawText(
        canvas,
        '▲ ${node.entity.title}',
        pos,
        maxWidth: 120,
        fontSize: 11,
        color: Colors.white70,
        isBold: true,
      );
      return;
    }

    // Selection Glow Ring
    if (node.isSelected) {
      final glowPaint = Paint()
        ..color = AppTheme.primary.withOpacity(0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0;
      canvas.drawCircle(pos, node.radius + 6, glowPaint);
    }

    // Focal Root Glow Halo
    if (node.isFocalRoot) {
      final haloPaint = Paint()
        ..color = AppTheme.primary.withOpacity(0.18)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pos, node.radius + 12, haloPaint);
    }

    // Base Circle
    final baseColor = node.isFocalRoot
        ? AppTheme.primary
        : _getNodeColor(node.entity.semanticRole);

    final fillPaint = Paint()
      ..color = node.isFocalRoot ? const Color(0xFF1E1B4B) : const Color(0xFF27272A)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = baseColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = node.isFocalRoot ? 2.5 : 1.8;

    canvas.drawCircle(pos, node.radius, fillPaint);
    canvas.drawCircle(pos, node.radius, borderPaint);

    // Inner icon or initial
    final labelInitial = node.entity.title.isNotEmpty ? node.entity.title.substring(0, 1).toUpperCase() : '?';
    _drawText(
      canvas,
      labelInitial,
      pos,
      maxWidth: node.radius * 2,
      fontSize: node.isFocalRoot ? 16 : 13,
      color: baseColor,
      isBold: true,
    );

    // Child count badge
    if (node.childCount > 0 && !node.isFocalRoot) {
      final badgeOffset = Offset(pos.dx + node.radius * 0.7, pos.dy - node.radius * 0.7);
      final badgeBg = Paint()
        ..color = AppTheme.primary
        ..style = PaintingStyle.fill;
      canvas.drawCircle(badgeOffset, 9, badgeBg);
      _drawText(
        canvas,
        '${node.childCount}',
        badgeOffset,
        maxWidth: 18,
        fontSize: 10,
        color: Colors.black,
        isBold: true,
      );
    }

    // Node Title underneath
    final titleOffset = Offset(pos.dx, pos.dy + node.radius + 12);
    _drawText(
      canvas,
      node.entity.title,
      titleOffset,
      maxWidth: 90,
      fontSize: 11,
      color: Colors.white,
      isBold: node.isFocalRoot,
    );
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset centerOffset, {
    required double maxWidth,
    required double fontSize,
    required Color color,
    bool isBold = false,
  }) {
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '...',
    )..layout(maxWidth: maxWidth);

    textPainter.paint(
      canvas,
      Offset(
        centerOffset.dx - (textPainter.width / 2),
        centerOffset.dy - (textPainter.height / 2),
      ),
    );
  }

  Color _getNodeColor(SemanticRole role) {
    switch (role) {
      case SemanticRole.seed:
        return const Color(0xFF10B981);
      case SemanticRole.idea:
        return const Color(0xFFF59E0B);
      case SemanticRole.project:
        return AppTheme.primary;
      case SemanticRole.practice:
        return const Color(0xFF06B6D4);
      case SemanticRole.concept:
        return const Color(0xFFA855F7);
    }
  }

  @override
  bool shouldRepaint(covariant EgoGraphPainter oldDelegate) {
    return true;
  }
}
