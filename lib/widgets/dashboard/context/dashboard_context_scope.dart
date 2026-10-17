import 'package:flutter/widgets.dart';
import 'package:solducci/service/context_manager.dart';

export 'package:solducci/service/context_manager.dart' show ExpenseContext;

/// InheritedWidget that provides the active [ExpenseContext] down the dashboard
/// widget sub-tree. Ensures that every Bento widget accurately consumes and
/// isolates its data according to the tab's contextual scope.
class DashboardContextScope extends InheritedWidget {
  final ExpenseContext tabContext;

  const DashboardContextScope({
    super.key,
    required this.tabContext,
    required super.child,
  });

  /// Retrieves the [ExpenseContext] from the nearest [DashboardContextScope] ancestor.
  /// Falls back to [ContextManager().currentContext] if no scope is found.
  static ExpenseContext of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<DashboardContextScope>();
    return scope?.tabContext ?? ContextManager().currentContext;
  }

  @override
  bool updateShouldNotify(DashboardContextScope oldWidget) {
    return tabContext != oldWidget.tabContext;
  }
}
