import 'package:flutter/material.dart';

class DataSourceSwitcherHeader extends StatelessWidget {
  final String title;
  final Color color;
  final IconData icon;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const DataSourceSwitcherHeader({
    super.key,
    required this.title,
    required this.color,
    required this.icon,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: onPrevious,
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.0),
                  child: Icon(Icons.chevron_left, size: 16, color: Colors.white54),
                ),
              ),
              Flexible(
                child: Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    color: color.withValues(alpha: 0.8),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: onNext,
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.0),
                  child: Icon(Icons.chevron_right, size: 16, color: Colors.white54),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
