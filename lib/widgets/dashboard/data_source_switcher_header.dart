import 'package:flutter/material.dart';

class DataSourceSwitcherHeader extends StatelessWidget {
  final String title;
  final Color color;
  final IconData icon;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback? onTitleTap;

  const DataSourceSwitcherHeader({
    super.key,
    required this.title,
    required this.color,
    required this.icon,
    required this.onPrevious,
    required this.onNext,
    this.onTitleTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity < -100) {
          onNext();
        } else if (velocity > 100) {
          onPrevious();
        }
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Freccia Sinistra all'estremo
          GestureDetector(
            onTap: onPrevious,
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
              child: Icon(Icons.chevron_left_rounded, size: 18, color: Colors.white54),
            ),
          ),
          // Titolo e icona centrati
          Expanded(
            child: GestureDetector(
              onTap: onTitleTap,
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: color, size: 14),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      title.toUpperCase(),
                      style: TextStyle(
                        color: color.withOpacity(0.9),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Freccia Destra all'estremo
          GestureDetector(
            onTap: onNext,
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
              child: Icon(Icons.chevron_right_rounded, size: 18, color: Colors.white54),
            ),
          ),
        ],
      ),
    );
  }
}
