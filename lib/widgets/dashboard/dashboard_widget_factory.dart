import 'package:flutter/material.dart';
import 'package:solducci/models/dashboard_config.dart';
import 'package:solducci/widgets/dashboard/bento_widget_container.dart';

// Specific widgets
import 'package:solducci/widgets/dashboard/widgets/balance_pill_widget.dart';
import 'package:solducci/widgets/dashboard/widgets/focus_tasks_widget.dart';
import 'package:solducci/widgets/dashboard/widgets/quick_expense_widget.dart';
import 'package:solducci/widgets/dashboard/widgets/monthly_burn_rate_widget.dart';
import 'package:solducci/widgets/dashboard/widgets/daily_progress_widget.dart';
import 'package:solducci/widgets/dashboard/widgets/habit_tracker_widget.dart';
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
        
      case 'habit_tracker':
        return HabitTrackerWidget(def: def);
        
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

  static List<BentoWidgetDef> getAllAvailableWidgets() {
    return [
      BentoWidgetDef(id: 'w_bal', type: 'balance', size: const BentoWidgetSize(2, 1)),
      BentoWidgetDef(id: 'w_exp', type: 'quick_expense', size: const BentoWidgetSize(2, 3)),
      BentoWidgetDef(id: 'w_foc', type: 'focus_tasks', size: const BentoWidgetSize(2, 2)),
      BentoWidgetDef(id: 'w_brn', type: 'monthly_burn_rate', size: const BentoWidgetSize(2, 2)),
      BentoWidgetDef(id: 'w_dpr', type: 'daily_progress', size: const BentoWidgetSize(1, 1)),
      BentoWidgetDef(id: 'w_ast', type: 'unresolved_asterisks', size: const BentoWidgetSize(2, 2)),
      BentoWidgetDef(id: 'w_shp', type: 'shopping_quick_list', size: const BentoWidgetSize(1, 2)),
      BentoWidgetDef(id: 'w_hab', type: 'habit_tracker', size: const BentoWidgetSize(2, 1)),
    ];
  }

  static List<BentoWidgetSize> getAllowedSizes(String type) {
    switch (type) {
      case 'balance':
        return [const BentoWidgetSize(1, 1), const BentoWidgetSize(1, 2)];
      case 'quick_expense':
        return [const BentoWidgetSize(2, 3), const BentoWidgetSize(3, 3)];
      case 'focus_tasks':
        return [const BentoWidgetSize(2, 2), const BentoWidgetSize(2, 3), const BentoWidgetSize(3, 2), const BentoWidgetSize(3, 3), const BentoWidgetSize(2, 4), const BentoWidgetSize(3, 4)];
      case 'shopping_quick_list':
        return [const BentoWidgetSize(2, 2), const BentoWidgetSize(2, 3), const BentoWidgetSize(3, 2), const BentoWidgetSize(3, 3), const BentoWidgetSize(2, 4), const BentoWidgetSize(3, 4)];
      case 'unresolved_asterisks':
        return [const BentoWidgetSize(2, 2), const BentoWidgetSize(2, 3), const BentoWidgetSize(3, 2), const BentoWidgetSize(3, 3), const BentoWidgetSize(2, 4), const BentoWidgetSize(3, 4)];
      case 'monthly_burn_rate':
        return [const BentoWidgetSize(2, 2), const BentoWidgetSize(4, 2), const BentoWidgetSize(4, 4)];
      case 'daily_progress':
        return [const BentoWidgetSize(1, 1), const BentoWidgetSize(2, 1), const BentoWidgetSize(1, 2)];
      case 'habit_tracker':
        return [const BentoWidgetSize(2, 2), const BentoWidgetSize(4, 2), const BentoWidgetSize(4, 4)];
      default:
        return [const BentoWidgetSize(2, 2)]; // Default fallback
    }
  }

  static bool requiresInit(String type) {
    // Return true for widgets that need configuration before being added to the board
    switch (type) {
      case 'balance':
      case 'focus_tasks':
      case 'shopping_quick_list':
        return true;
      default:
        return false;
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
