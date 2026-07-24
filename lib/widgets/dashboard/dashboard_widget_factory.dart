import 'package:flutter/material.dart';
import 'package:solducci/models/dashboard_config.dart';
import 'package:solducci/widgets/dashboard/bento_widget_container.dart';

// Specific widgets
import 'package:solducci/widgets/dashboard/widgets/balance_pill_widget.dart';
import 'package:solducci/widgets/dashboard/widgets/focus_tasks_widget.dart';
import 'package:solducci/widgets/dashboard/widgets/quick_expense_widget.dart';
import 'package:solducci/widgets/dashboard/widgets/monthly_burn_rate_widget.dart';
import 'package:solducci/widgets/dashboard/widgets/daily_progress_widget.dart';
import 'package:solducci/widgets/dashboard/widgets/unresolved_asterisks_widget.dart';
import 'package:solducci/widgets/dashboard/widgets/shopping_quick_list_widget.dart';

class DashboardWidgetFactory {
  /// Maps a widget definition string to its actual Flutter Widget
  static Widget buildWidget(BuildContext context, BentoWidgetDef def) {
    switch (def.type) {
      case 'balance':
        return BalancePillWidget(def: def);
      
      case 'focus_tasks':
        return FocusTasksWidget(def: def);
      
      case 'quick_expense':
        return QuickExpenseWidget(def: def);
        
      case 'monthly_burn_rate':
        return MonthlyBurnRateWidget(def: def);
        
      case 'daily_progress':
        return DailyProgressWidget(def: def);
        
      case 'unresolved_asterisks':
        return UnresolvedAsterisksWidget(def: def);
        
      case 'shopping_quick_list':
        return ShoppingQuickListWidget(def: def);
        
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
