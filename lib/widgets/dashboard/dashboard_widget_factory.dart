import 'package:flutter/material.dart';
import 'package:solducci/models/dashboard_config.dart';
import 'package:solducci/widgets/dashboard/bento_widget_container.dart';

// Placeholder imports for the specific widgets we will build in Phase 3 & 4
// import 'package:solducci/widgets/dashboard/widgets/balance_pill_widget.dart';
// import 'package:solducci/widgets/dashboard/widgets/focus_tasks_widget.dart';
// import 'package:solducci/widgets/dashboard/widgets/quick_expense_widget.dart';

class DashboardWidgetFactory {
  /// Maps a widget definition string to its actual Flutter Widget
  static Widget buildWidget(BuildContext context, BentoWidgetDef def) {
    switch (def.type) {
      case 'balance':
        // return BalancePillWidget(def: def);
        return _MockWidget(title: 'Balance', color: const Color(0xFF10B981));
      
      case 'focus_tasks':
        // return FocusTasksWidget(def: def);
        return _MockWidget(title: 'Focus Oggi', color: const Color(0xFF6366F1));
      
      case 'quick_expense':
        // return QuickExpenseWidget(def: def);
        return _MockWidget(title: 'Quick Spesa', color: const Color(0xFFF59E0B));
        
      case 'monthly_burn_rate':
        return _MockWidget(title: 'Burn Rate', color: const Color(0xFFE068F1));
        
      case 'unresolved_asterisks':
        return _MockWidget(title: 'Asterischi', color: const Color(0xFFEF4444));
        
      case 'habit_tracker':
        return _MockWidget(title: 'Routine Streak', color: const Color(0xFF3B82F6));
        
      default:
        return _MockWidget(title: 'Unknown: ${def.type}', color: Colors.grey);
    }
  }
}

class _MockWidget extends StatelessWidget {
  final String title;
  final Color color;

  const _MockWidget({
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return BentoWidgetContainer(
      child: Stack(
        children: [
          // Neon glow effect behind the text
          Center(
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.5),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
            ),
          ),
          Center(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
