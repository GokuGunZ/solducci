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
import 'package:solducci/widgets/dashboard/widgets/recent_markdown_widget.dart';
import 'package:solducci/widgets/dashboard/widgets/markdown_stack_widget.dart';
import 'package:solducci/widgets/dashboard/widgets/hero_countdown_widget.dart';
import 'package:solducci/widgets/dashboard/widgets/pantry_alert_widget.dart';
import 'package:solducci/widgets/dashboard/widgets/investment_summary_widget.dart';
import 'package:solducci/widgets/dashboard/widgets/note_stack_widget.dart';
import 'package:solducci/widgets/dashboard/widgets/recent_notes_widget.dart';
import 'package:solducci/widgets/dashboard/widgets/peer_debts_widget.dart';
import 'package:solducci/widgets/dashboard/widgets/category_expenses_widget.dart';
import 'package:solducci/widgets/dashboard/widgets/recurring_movements_widget.dart';
import 'package:solducci/widgets/dashboard/widgets/quick_transfer_widget.dart';
import 'package:solducci/widgets/dashboard/widgets/cashflow_forecast_widget.dart';
import 'package:solducci/widgets/dashboard/widgets/quick_scratchpad_widget.dart';
import 'package:solducci/widgets/dashboard/widgets/life_os/life_os_capture_widget.dart';
import 'package:solducci/widgets/dashboard/widgets/life_os/life_os_recent_seeds_widget.dart';
import 'package:solducci/widgets/dashboard/widgets/life_os/life_os_active_entities_widget.dart';
import 'package:solducci/widgets/dashboard/widgets/life_os/life_os_pinned_entity_widget.dart';

import 'package:solducci/service/context_manager.dart';
import 'package:solducci/widgets/dashboard/context/dashboard_context_scope.dart';

class DashboardWidgetFactory {
  /// Maps a widget definition string to its actual Flutter Widget wrapped in [DashboardContextScope]
  static Widget buildWidget(
    BuildContext context,
    BentoWidgetDef def, {
    ExpenseContext? tabContext,
  }) {
    final effectiveContext = tabContext ?? ContextManager().currentContext;
    final widget = _instantiateWidget(context, def);
    return DashboardContextScope(
      tabContext: effectiveContext,
      child: widget,
    );
  }

  static Widget _instantiateWidget(BuildContext context, BentoWidgetDef def) {
    switch (def.type) {
      case 'recurring_movements':
        return RecurringMovementsWidget(def: def);

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
        
      case 'recent_markdown':
        return RecentMarkdownWidget(def: def);

      case 'markdown_stack':
        return MarkdownStackWidget(def: def);

      case 'hero_countdown':
        return HeroCountdownWidget(def: def);

      case 'pantry_alert':
        return PantryAlertWidget(def: def);

      case 'investment_summary':
        return InvestmentSummaryWidget(def: def);

      case 'note_stack':
        return NoteStackWidget(def: def);

      case 'recent_notes':
        return RecentNotesWidget(def: def);

      case 'peer_debts':
        return PeerDebtsWidget(def: def);

      case 'category_expenses':
        return CategoryExpensesWidget(def: def);

      case 'quick_transfer':
        return QuickTransferWidget(def: def);

      case 'cashflow_forecast':
        return CashflowForecastWidget(def: def);

      case 'quick_scratchpad':
        return QuickScratchpadWidget(def: def);

      case 'life_os_capture':
        return LifeOsCaptureWidget(def: def);

      case 'life_os_recent_seeds':
        return LifeOsRecentSeedsWidget(def: def);

      case 'life_os_active_entities':
        return LifeOsActiveEntitiesWidget(def: def);

      case 'life_os_pinned_entity':
        return LifeOsPinnedEntityWidget(def: def);
        
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
      BentoWidgetDef(id: 'w_cnt', type: 'hero_countdown', size: const BentoWidgetSize(2, 1)),
      BentoWidgetDef(id: 'w_pnt', type: 'pantry_alert', size: const BentoWidgetSize(1, 1)),
      BentoWidgetDef(id: 'w_inv', type: 'investment_summary', size: const BentoWidgetSize(2, 1)),
      BentoWidgetDef(id: 'w_ast', type: 'unresolved_asterisks', size: const BentoWidgetSize(2, 2)),
      BentoWidgetDef(id: 'w_shp', type: 'shopping_quick_list', size: const BentoWidgetSize(1, 2)),
      BentoWidgetDef(id: 'w_hab', type: 'habit_tracker', size: const BentoWidgetSize(2, 1)),
      BentoWidgetDef(id: 'w_rmd', type: 'recent_markdown', size: const BentoWidgetSize(2, 2)),
      BentoWidgetDef(id: 'w_mds', type: 'markdown_stack', size: const BentoWidgetSize(2, 2)),
      BentoWidgetDef(id: 'w_nst', type: 'note_stack', size: const BentoWidgetSize(2, 2)),
      BentoWidgetDef(id: 'w_not', type: 'recent_notes', size: const BentoWidgetSize(2, 2)),
      BentoWidgetDef(id: 'w_deb', type: 'peer_debts', size: const BentoWidgetSize(2, 2)),
      BentoWidgetDef(id: 'w_cat', type: 'category_expenses', size: const BentoWidgetSize(2, 2)),
      BentoWidgetDef(id: 'w_rec', type: 'recurring_movements', size: const BentoWidgetSize(2, 2)),
      BentoWidgetDef(id: 'w_los_cap', type: 'life_os_capture', size: const BentoWidgetSize(2, 1)),
      BentoWidgetDef(id: 'w_los_rec', type: 'life_os_recent_seeds', size: const BentoWidgetSize(2, 2)),
      BentoWidgetDef(id: 'w_los_act', type: 'life_os_active_entities', size: const BentoWidgetSize(2, 2)),
      BentoWidgetDef(id: 'w_los_pin', type: 'life_os_pinned_entity', size: const BentoWidgetSize(2, 2)),
      BentoWidgetDef(id: 'w_trf', type: 'quick_transfer', size: const BentoWidgetSize(2, 2)),
      BentoWidgetDef(id: 'w_csf', type: 'cashflow_forecast', size: const BentoWidgetSize(2, 3)),
      BentoWidgetDef(id: 'w_pad', type: 'quick_scratchpad', size: const BentoWidgetSize(2, 2)),
    ];
  }

  static List<BentoWidgetSize> getSupportedSizes(String type) => getAllowedSizes(type);

  static List<BentoWidgetSize> getAllowedSizes(String type) {
    switch (type) {
      case 'quick_transfer':
        return [const BentoWidgetSize(2, 1), const BentoWidgetSize(2, 2), const BentoWidgetSize(2, 3)];
      case 'cashflow_forecast':
        return [const BentoWidgetSize(2, 3), const BentoWidgetSize(4, 2)];
      case 'quick_scratchpad':
        return [const BentoWidgetSize(2, 1), const BentoWidgetSize(4, 1), const BentoWidgetSize(2, 2)];
      case 'recurring_movements':
        return [const BentoWidgetSize(2, 1), const BentoWidgetSize(2, 2), const BentoWidgetSize(2, 3), const BentoWidgetSize(2, 4), const BentoWidgetSize(4, 1)];
      case 'balance':
        return [const BentoWidgetSize(1, 1), const BentoWidgetSize(2, 1), const BentoWidgetSize(2, 2), const BentoWidgetSize(2, 3), const BentoWidgetSize(4, 1)];
      case 'quick_expense':
        return [const BentoWidgetSize(2, 4), const BentoWidgetSize(3, 4), const BentoWidgetSize(2, 2)];
      case 'focus_tasks':
        return [const BentoWidgetSize(2, 4), const BentoWidgetSize(2, 1), const BentoWidgetSize(2, 2), const BentoWidgetSize(2, 3), const BentoWidgetSize(3, 4)];
      case 'shopping_quick_list':
        return [const BentoWidgetSize(2, 4), const BentoWidgetSize(2, 1), const BentoWidgetSize(2, 2), const BentoWidgetSize(2, 3), const BentoWidgetSize(3, 4)];
      case 'unresolved_asterisks':
        return [const BentoWidgetSize(2, 2), const BentoWidgetSize(2, 3), const BentoWidgetSize(3, 2), const BentoWidgetSize(2, 4), const BentoWidgetSize(3, 4)];
      case 'monthly_burn_rate':
        return [const BentoWidgetSize(2, 2), const BentoWidgetSize(4, 2), const BentoWidgetSize(2, 3)];
      case 'daily_progress':
        return [const BentoWidgetSize(1, 1), const BentoWidgetSize(2, 1), const BentoWidgetSize(1, 2)];
      case 'habit_tracker':
        return [const BentoWidgetSize(2, 1), const BentoWidgetSize(2, 2), const BentoWidgetSize(2, 3), const BentoWidgetSize(4, 2)];
      case 'hero_countdown':
        return [const BentoWidgetSize(2, 1), const BentoWidgetSize(2, 2), const BentoWidgetSize(4, 2)];
      case 'pantry_alert':
        return [const BentoWidgetSize(1, 1), const BentoWidgetSize(2, 1), const BentoWidgetSize(2, 2), const BentoWidgetSize(2, 3)];
      case 'investment_summary':
        return [const BentoWidgetSize(2, 1), const BentoWidgetSize(2, 2), const BentoWidgetSize(2, 3), const BentoWidgetSize(4, 2)];
      case 'recent_markdown':
        return [const BentoWidgetSize(2, 3), const BentoWidgetSize(2, 4), const BentoWidgetSize(2, 2), const BentoWidgetSize(3, 2)];
      case 'markdown_stack':
        return [const BentoWidgetSize(2, 2), const BentoWidgetSize(2, 3), const BentoWidgetSize(2, 4), const BentoWidgetSize(4, 2)];
      case 'note_stack':
        return [const BentoWidgetSize(2, 3), const BentoWidgetSize(2, 4), const BentoWidgetSize(2, 2), const BentoWidgetSize(4, 2)];
      case 'peer_debts':
        return [const BentoWidgetSize(1, 1), const BentoWidgetSize(2, 1), const BentoWidgetSize(2, 2), const BentoWidgetSize(2, 3), const BentoWidgetSize(2, 4), const BentoWidgetSize(3, 2)];
      case 'category_expenses':
        return [const BentoWidgetSize(1, 1), const BentoWidgetSize(2, 1), const BentoWidgetSize(2, 2), const BentoWidgetSize(2, 3), const BentoWidgetSize(4, 2), const BentoWidgetSize(2, 4)];
      case 'recent_notes':
        return [const BentoWidgetSize(2, 4), const BentoWidgetSize(2, 2), const BentoWidgetSize(2, 3), const BentoWidgetSize(3, 4)];
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
      case 'habit_tracker':
      case 'monthly_burn_rate':
      case 'hero_countdown':
      case 'pantry_alert':
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
                    color: color.withOpacity(0.5),
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
