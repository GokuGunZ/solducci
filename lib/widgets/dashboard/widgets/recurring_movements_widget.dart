import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:solducci/models/dashboard_config.dart';
import 'package:solducci/models/recurring_transaction.dart';
import 'package:solducci/service/context_manager.dart';
import 'package:solducci/service/recurring_transaction_service.dart';
import 'package:solducci/theme/app_theme.dart';
import 'package:solducci/utils/category_helpers.dart';
import 'package:solducci/widgets/dashboard/bento_widget_container.dart';
import 'package:solducci/widgets/economy/recurring_form_sheet.dart';
import 'package:solducci/widgets/economy/recurring_inbox_sheet.dart';

/// Bento Widget "Spese e Movimenti Ricorrenti"
class RecurringMovementsWidget extends StatefulWidget {
  final BentoWidgetDef def;

  const RecurringMovementsWidget({super.key, required this.def});

  @override
  State<RecurringMovementsWidget> createState() => _RecurringMovementsWidgetState();
}

class _RecurringMovementsWidgetState extends State<RecurringMovementsWidget> {
  final _service = RecurringTransactionService();
  final _contextManager = ContextManager();

  StreamSubscription? _sub;
  List<RecurringTransaction> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _contextManager.addListener(_onContextChanged);
    _sub = _service.stream.listen((items) {
      if (mounted) {
        setState(() {
          _items = items;
          _isLoading = false;
        });
      }
    });
    _loadItems();
  }

  @override
  void dispose() {
    _contextManager.removeListener(_onContextChanged);
    _sub?.cancel();
    super.dispose();
  }

  void _onContextChanged() {
    if (mounted) {
      _loadItems();
    }
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    final items = await _service.fetchRecurringTransactions();
    if (mounted) {
      setState(() {
        _items = items;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.def.size;
    final isHeight1 = size.mainAxisCellCount <= 1;

    return BentoWidgetContainer(
      heroTag: widget.def.id,
      size: size,
      isLoading: _isLoading,
      onTap: () => context.push('/economy/recurring'),
      child: Padding(
        padding: isHeight1
            ? const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0)
            : const EdgeInsets.all(14.0),
        child: isHeight1 ? _buildMiniBanner() : (size.mainAxisCellCount <= 2 ? _buildCompactView() : _buildExpandedView()),
      ),
    );
  }

  Widget _buildMiniBanner() {
    final activeItems = _items.where((i) => i.isActive).toList();
    final pendingCount = _items.where((i) => i.isActive && i.requiresConfirmation && i.isDueTodayOrOverdue).length;

    double monthlyExpenses = 0.0;
    for (final item in activeItems) {
      if (!item.isIncome) {
        monthlyExpenses += item.monthlyEquivalentAmount;
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withOpacity(0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.repeat_rounded, size: 13, color: Color(0xFFA78BFA)),
            ),
            const SizedBox(width: 8),
            const Text(
              'RICORRENTI',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
            if (pendingCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.warning.withOpacity(0.5)),
                ),
                child: Text(
                  '$pendingCount!',
                  style: const TextStyle(
                    color: AppTheme.warning,
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        Text(
          '€ ${monthlyExpenses.toStringAsFixed(0)}/m',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactView() {
    final activeItems = _items.where((i) => i.isActive).toList();
    final pendingCount = _items.where((i) => i.isActive && i.requiresConfirmation && i.isDueTodayOrOverdue).length;

    double monthlyExpenses = 0.0;
    for (final item in activeItems) {
      if (!item.isIncome) {
        monthlyExpenses += item.monthlyEquivalentAmount;
      }
    }

    final upcoming = [...activeItems]..sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));
    final nextItem = upcoming.isNotEmpty ? upcoming.first : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withOpacity(0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.repeat_rounded, size: 14, color: Color(0xFFA78BFA)),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Ricorrenti',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (pendingCount > 0) ...[
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => RecurringInboxSheet.show(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.warning.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.warning.withOpacity(0.5)),
                      ),
                      child: Text(
                        '$pendingCount!',
                        style: const TextStyle(
                          color: AppTheme.warning,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            Text(
              '€ ${monthlyExpenses.toStringAsFixed(0)}/m',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        if (nextItem != null)
          Row(
            children: [
              Expanded(
                child: Text(
                  nextItem.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              _buildCountdownChip(nextItem),
              const SizedBox(width: 6),
              Text(
                '€ ${nextItem.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  color: nextItem.isIncome ? AppTheme.success : Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          )
        else
          const Text(
            'Nessuna ricorrenza attiva',
            style: TextStyle(color: Colors.white38, fontSize: 11),
          ),
      ],
    );
  }

  Widget _buildExpandedView() {
    final activeItems = _items.where((i) => i.isActive).toList();
    final pendingCount = _items.where((i) => i.isActive && i.requiresConfirmation && i.isDueTodayOrOverdue).length;

    double monthlyExpenses = 0.0;
    double monthlyIncomes = 0.0;
    for (final item in activeItems) {
      if (item.isIncome) {
        monthlyIncomes += item.monthlyEquivalentAmount;
      } else {
        monthlyExpenses += item.monthlyEquivalentAmount;
      }
    }

    final upcoming = [...activeItems]..sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withOpacity(0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.repeat_rounded, size: 16, color: Color(0xFFA78BFA)),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Movimenti Ricorrenti',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (pendingCount > 0)
              GestureDetector(
                onTap: () => RecurringInboxSheet.show(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.warning.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.inbox_rounded, size: 12, color: AppTheme.warning),
                      const SizedBox(width: 4),
                      Text(
                        '$pendingCount da confermare',
                        style: const TextStyle(
                          color: AppTheme.warning,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              const Icon(Icons.chevron_right_rounded, size: 18, color: Colors.white38),
          ],
        ),

        const SizedBox(height: 10),

        // Monthly Summary Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF27272A).withOpacity(0.6),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('Uscite: ', style: TextStyle(color: Colors.white38, fontSize: 11)),
                  Text(
                    '€ ${monthlyExpenses.toStringAsFixed(0)}/m',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              if (monthlyIncomes > 0)
                Row(
                  children: [
                    const Text('Entrate: ', style: TextStyle(color: Colors.white38, fontSize: 11)),
                    Text(
                      '+€ ${monthlyIncomes.toStringAsFixed(0)}/m',
                      style: const TextStyle(color: AppTheme.success, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Upcoming List
        Expanded(
          child: upcoming.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Nessun movimento attivo',
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                      const SizedBox(height: 6),
                      TextButton.icon(
                        onPressed: () => RecurringFormSheet.show(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: const Icon(Icons.add, size: 14, color: Color(0xFFA78BFA)),
                        label: const Text(
                          'Aggiungi ricorrenza',
                          style: TextStyle(color: Color(0xFFA78BFA), fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: upcoming.length > 3 ? 3 : upcoming.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = upcoming[index];
                    return _buildItemRow(item);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildItemRow(RecurringTransaction item) {
    final icon = CategoryHelpers.getIconForCategory(item.category);
    final color = CategoryHelpers.getColorForCategory(item.category);

    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: color.withOpacity(0.18),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 13, color: color),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                item.frequency.label,
                style: const TextStyle(color: Colors.white38, fontSize: 10),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        _buildCountdownChip(item),
        const SizedBox(width: 8),
        Text(
          '${item.isIncome ? '+' : '-'}€ ${item.amount.toStringAsFixed(2)}',
          style: TextStyle(
            color: item.isIncome ? AppTheme.success : Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCountdownChip(RecurringTransaction item) {
    final days = item.daysUntilNextDue;
    final isDue = item.isDueTodayOrOverdue;

    Color bg;
    Color fg;
    String label;

    if (isDue) {
      bg = AppTheme.warning.withOpacity(0.2);
      fg = AppTheme.warning;
      label = days < 0 ? 'Scaduto' : 'Oggi';
    } else if (days == 1) {
      bg = Colors.blue.withOpacity(0.18);
      fg = Colors.lightBlueAccent;
      label = 'Domani';
    } else if (days <= 7) {
      bg = Colors.white.withOpacity(0.08);
      fg = Colors.white70;
      label = 'tra ${days}gg';
    } else {
      bg = Colors.white.withOpacity(0.05);
      fg = Colors.white54;
      label = DateFormat('d MMM', 'it').format(item.nextDueDate);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 9.5, fontWeight: FontWeight.w600),
      ),
    );
  }
}
