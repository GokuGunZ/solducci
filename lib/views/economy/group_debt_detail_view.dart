import 'package:flutter/material.dart';
import 'package:solducci/models/expense.dart';
import 'package:solducci/service/context_manager.dart';
import 'package:solducci/service/expense_service_cached.dart';
import 'package:solducci/widgets/economy/group_debts_section.dart';
import 'package:solducci/widgets/economy/observable_debt_timeline_chart.dart';
import 'package:solducci/widgets/solducci_app_bar.dart';

class GroupDebtDetailView extends StatefulWidget {
  final String? groupId;

  const GroupDebtDetailView({super.key, this.groupId});

  @override
  State<GroupDebtDetailView> createState() => _GroupDebtDetailViewState();
}

class _GroupDebtDetailViewState extends State<GroupDebtDetailView> {
  final _expenseService = ExpenseServiceCached();
  final _contextManager = ContextManager();

  @override
  Widget build(BuildContext context) {
    final ctx = _contextManager.currentContext;
    final effectiveGroupId = widget.groupId ?? (ctx.isGroup ? ctx.groupId : null);

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: const SolducciAppBar(
        titleText: 'Dettaglio Debiti & Crediti',
        showContextSwitcher: true,
      ),
      body: StreamBuilder<List<Expense>>(
        stream: _expenseService.stream,
        builder: (context, snapshot) {
          final allExpenses = snapshot.data ?? [];
          final groupExpenses = effectiveGroupId != null
              ? allExpenses.where((e) => e.groupId == effectiveGroupId).toList()
              : allExpenses.where((e) => e.groupId != null).toList();

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 12),
            children: [
              // In cima si ripropone lo stesso widget da cui si è entrati (in detail mode non naviga)
              GroupDebtsSection(
                groupId: effectiveGroupId,
                isDetailMode: true,
              ),

              const SizedBox(height: 12),

              // Grafico osservabile e navigabile dell'andamento del debito nel tempo
              ObservableDebtTimelineChart(
                expenses: groupExpenses,
                groupId: effectiveGroupId,
              ),

              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }
}
