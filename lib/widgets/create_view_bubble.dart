import 'package:flutter/material.dart';

/// Widget nuvoletta informativa che suggerisce di creare una vista
/// Mostrato quando l'utente seleziona più gruppi ma non ha ancora viste create
class CreateViewBubble extends StatefulWidget {
  final VoidCallback? onDismiss;

  const CreateViewBubble({
    this.onDismiss,
    super.key,
  });

  @override
  State<CreateViewBubble> createState() => _CreateViewBubbleState();
}

class _CreateViewBubbleState extends State<CreateViewBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() async {
    await _controller.reverse();
    if (mounted) {
      widget.onDismiss?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: GestureDetector(
        onTap: _dismiss,
        behavior: HitTestBehavior.translucent,
        child: Container(
          color: Colors.transparent,
          child: Center(
            child: GestureDetector(
              onTap: () {}, // Blocca tap sulla bubble stessa
              child: CustomPaint(
                painter: _BubblePainter(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  margin: const EdgeInsets.only(top: 10), // Spazio per la freccia
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: Colors.blue[700],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Crea una vista',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Painter per disegnare la nuvoletta con freccia
class _BubblePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue[50]!
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.blue[200]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path();

    const arrowWidth = 16.0;
    const arrowHeight = 10.0;
    const radius = 12.0;

    // Inizia dalla punta della freccia (in alto, al centro)
    final centerX = size.width / 2;
    path.moveTo(centerX, 0);

    // Lato sinistro della freccia
    path.lineTo(centerX - arrowWidth / 2, arrowHeight);

    // Arrotonda verso sinistra
    path.lineTo(radius, arrowHeight);
    path.arcToPoint(
      Offset(0, arrowHeight + radius),
      radius: const Radius.circular(radius),
    );

    // Lato sinistro
    path.lineTo(0, size.height - radius);
    path.arcToPoint(
      Offset(radius, size.height),
      radius: const Radius.circular(radius),
    );

    // Lato inferiore
    path.lineTo(size.width - radius, size.height);
    path.arcToPoint(
      Offset(size.width, size.height - radius),
      radius: const Radius.circular(radius),
    );

    // Lato destro
    path.lineTo(size.width, arrowHeight + radius);
    path.arcToPoint(
      Offset(size.width - radius, arrowHeight),
      radius: const Radius.circular(radius),
    );

    // Lato destro della freccia
    path.lineTo(centerX + arrowWidth / 2, arrowHeight);

    // Chiudi la freccia
    path.lineTo(centerX, 0);

    path.close();

    // Disegna ombra
    canvas.drawShadow(path, Colors.black26, 4, false);

    // Disegna riempimento
    canvas.drawPath(path, paint);

    // Disegna bordo
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
