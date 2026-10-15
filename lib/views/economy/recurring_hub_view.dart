import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:solducci/models/recurring_transaction.dart';
import 'package:solducci/service/context_manager.dart';
import 'package:solducci/service/recurring_transaction_service.dart';
import 'package:solducci/utils/category_helpers.dart';
import 'package:solducci/widgets/economy/recurring_form_sheet.dart';
import 'package:solducci/widgets/economy/recurring_inbox_sheet.dart';
import 'package:solducci/widgets/solducci_app_bar.dart';

class RecurringHubView extends StatefulWidget {
  const RecurringHubView({super.key});

  @override
  State<RecurringHubView> createState() => _RecurringHubViewState();
}

enum _RecurringFilter { all, expenses, incomes, paused }

class _RecurringHubViewState extends State<RecurringHubView> {
  final _service = RecurringTransactionService();
  final _contextManager = ContextManager();
  _RecurringFilter _filter = _RecurringFilter.all;

  @override
  void initState() {
    super.initState();
    _service.fetchRecurringTransactions();
  }

  Future<void> _deleteItem(RecurringTransaction item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        title: const Text('Elimina Ricorrenza', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('Vuoi eliminare definitivamente "${item.title}"? Le transazioni già generate in passato rimarranno memorizzate.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annulla', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      HapticFeedback.lightImpact();
      await _service.deleteRecurringTransaction(item.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ricorrenza eliminata'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'it_IT', symbol: '€');

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: SolducciAppBar(
        title: Text(
          _contextManager.isGroupContext ? 'Spese Fisse • ${_contextManager.contextDisplayName}' : 'Spese Fisse & Ricorrenze',
          style: const TextStyle(color: Color(0xFFE0E0E0), fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Inbox Icon with pending badge
          ValueListenableBuilder<int>(
            valueListenable: _service.pendingInboxCountNotifier,
            builder: (context, pendingCount, child) {
              if (pendingCount > 0) {
                return Badge.count(
                  count: pendingCount,
                  backgroundColor: Colors.amber,
                  textColor: Colors.black,
                  alignment: const Alignment(0.6, -0.6),
                  child: child!,
                );
              }
              return child!;
            },
            child: IconButton(
              icon: const Icon(Icons.move_to_inbox_rounded, color: Colors.white70),
              tooltip: 'Inbox Movimenti in Scadenza',
              onPressed: () => RecurringInboxSheet.show(context),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_recurring_fab',
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nuova Ricorrenza', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => RecurringFormSheet.show(context),
      ),
      body: StreamBuilder<List<RecurringTransaction>>(
        stream: _service.stream,
        builder: (context, snapshot) {
          final allItems = snapshot.data ?? _service.currentItems;

          // Metrics calculation (normalized monthly)
          double totalExpensesMonthly = 0.0;
          double totalIncomesMonthly = 0.0;

          for (final item in allItems) {
            if (!item.isActive) continue;
            if (item.isIncome) {
              totalIncomesMonthly += item.monthlyEquivalentAmount;
            } else {
              totalExpensesMonthly += item.monthlyEquivalentAmount;
            }
          }

          // Filter items
          final filteredItems = allItems.where((item) {
            switch (_filter) {
              case _RecurringFilter.all:
                return true;
              case _RecurringFilter.expenses:
                return !item.isIncome && item.isActive;
              case _RecurringFilter.incomes:
                return item.isIncome && item.isActive;
              case _RecurringFilter.paused:
                return !item.isActive;
            }
          }).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
            children: [
              // Pending Inbox Banner if items available
              ValueListenableBuilder<int>(
                valueListenable: _service.pendingInboxCountNotifier,
                builder: (context, pendingCount, _) {
                  if (pendingCount == 0) return const SizedBox.shrink();
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.amber.withOpacity(0.35)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.mark_email_unread_rounded, color: Colors.amber, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$pendingCount ${pendingCount == 1 ? "movimento in scadenza" : "movimenti in scadenza"}',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const Text(
                                'Da confermare o verificare importo',
                                style: TextStyle(color: Colors.white60, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => RecurringInboxSheet.show(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Rivedi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                  );
                },
              ),

              // Hero Metric Cards Summary
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF141417),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'IMPEGNO MENSILE RICORRENTE',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 10,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${allItems.where((i) => i.isActive).length} attive',
                            style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        // Uscite fisse
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.arrow_upward_rounded, size: 13, color: Color(0xFFEF4444)),
                                  SizedBox(width: 4),
                                  Text('Uscite / mese', style: TextStyle(color: Colors.white54, fontSize: 11)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                currencyFormatter.format(totalExpensesMonthly),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 36, color: Colors.white12),
                        const SizedBox(width: 14),
                        // Entrate fisse
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.arrow_downward_rounded, size: 13, color: Color(0xFF10B981)),
                                  SizedBox(width: 4),
                                  Text('Entrate / mese', style: TextStyle(color: Colors.white54, fontSize: 11)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                currencyFormatter.format(totalIncomesMonthly),
                                style: const TextStyle(
                                  color: Color(0xFF10B981),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('Tutti', _RecurringFilter.all, allItems.length),
                    const SizedBox(width: 8),
                    _buildFilterChip('Uscite', _RecurringFilter.expenses, allItems.where((i) => !i.isIncome && i.isActive).length),
                    const SizedBox(width: 8),
                    _buildFilterChip('Entrate', _RecurringFilter.incomes, allItems.where((i) => i.isIncome && i.isActive).length),
                    const SizedBox(width: 8),
                    _buildFilterChip('In Pausa', _RecurringFilter.paused, allItems.where((i) => !i.isActive).length),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // List of Recurring Items
              if (filteredItems.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Icon(Icons.repeat_rounded, size: 40, color: Colors.white.withOpacity(0.15)),
                      const SizedBox(height: 12),
                      const Text(
                        'Nessun movimento ricorrente',
                        style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Tocca "+ Nuova Ricorrenza" per registrare abbonamenti o spese fisse.',
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    ],
                  ),
                )
              else
                ...filteredItems.map((item) => _buildRecurringCard(item, currencyFormatter)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, _RecurringFilter filter, int count) {
    final isSelected = _filter == filter;
    return InkWell(
      onTap: () => setState(() => _filter = filter),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1).withOpacity(0.2) : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF6366F1) : Colors.white10,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white60,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF6366F1) : Colors.white10,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white54,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecurringCard(RecurringTransaction item, NumberFormat formatter) {
    final daysUntil = item.daysUntilNextDue;
    String countdownLabel;
    Color countdownColor;

    if (daysUntil < 0) {
      countdownLabel = 'Scaduta da ${-daysUntil}gg';
      countdownColor = const Color(0xFFEF4444);
    } else if (daysUntil == 0) {
      countdownLabel = 'Oggi';
      countdownColor = Colors.amber;
    } else if (daysUntil == 1) {
      countdownLabel = 'Domani';
      countdownColor = Colors.amber;
    } else {
      countdownLabel = 'tra ${daysUntil}gg (${DateFormat('dd/MM').format(item.nextDueDate)})';
      countdownColor = Colors.white54;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF141417),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: item.isActive
              ? (item.isIncome ? const Color(0xFF10B981).withOpacity(0.25) : const Color(0xFF6366F1).withOpacity(0.25))
              : Colors.white10,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => RecurringFormSheet.show(context, existingItem: item),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Category icon, Title, Amount & Active switch
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: item.isActive
                          ? (item.isIncome ? const Color(0xFF10B981) : const Color(0xFF6366F1)).withOpacity(0.18)
                          : Colors.white.withOpacity(0.06),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      item.isIncome ? Icons.arrow_downward_rounded : CategoryHelpers.getIconForCategory(item.category),
                      size: 16,
                      color: item.isActive
                          ? (item.isIncome ? const Color(0xFF10B981) : const Color(0xFF818CF8))
                          : Colors.white38,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                item.title,
                                style: TextStyle(
                                  color: item.isActive ? Colors.white : Colors.white38,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  decoration: item.isActive ? null : TextDecoration.lineThrough,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (item.isVariableAmount) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Variabile',
                                  style: TextStyle(color: Colors.amber, fontSize: 8.5, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${item.frequency.label} • ${item.category.toUpperCase()}',
                          style: const TextStyle(color: Colors.white38, fontSize: 10.5),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${item.isIncome ? "+" : "-"}${formatter.format(item.amount)}',
                        style: TextStyle(
                          color: item.isActive
                              ? (item.isIncome ? const Color(0xFF10B981) : Colors.white)
                              : Colors.white38,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          fontFamily: 'Inter',
                        ),
                      ),
                      if (item.frequency != RecurringFrequency.monthly)
                        Text(
                          '≈ ${formatter.format(item.monthlyEquivalentAmount)}/m',
                          style: const TextStyle(color: Colors.white30, fontSize: 9.5),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Bottom details row & switch
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: countdownColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.schedule_rounded, size: 10, color: countdownColor),
                            const SizedBox(width: 4),
                            Text(
                              countdownLabel,
                              style: TextStyle(color: countdownColor, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (item.requiresConfirmation)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.mark_email_unread_rounded, size: 10, color: Colors.amber),
                              SizedBox(width: 3),
                              Text('Richiede conferma', style: TextStyle(color: Colors.amber, fontSize: 9.5)),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.flash_auto_rounded, size: 10, color: Color(0xFF10B981)),
                              SizedBox(width: 3),
                              Text('Auto-addebito', style: TextStyle(color: Color(0xFF10B981), fontSize: 9.5)),
                            ],
                          ),
                        ),
                    ],
                  ),

                  // Actions: Delete & Active Switch
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.white24),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Elimina',
                        onPressed: () => _deleteItem(item),
                      ),
                      const SizedBox(width: 12),
                      Switch.adaptive(
                        value: item.isActive,
                        activeColor: item.isIncome ? const Color(0xFF10B981) : const Color(0xFF6366F1),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        onChanged: (val) => _service.toggleActive(item.id, val),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
