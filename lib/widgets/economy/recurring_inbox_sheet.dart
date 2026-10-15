import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:solducci/models/recurring_transaction.dart';
import 'package:solducci/service/recurring_transaction_service.dart';
import 'package:solducci/utils/category_helpers.dart';

class RecurringInboxSheet extends StatefulWidget {
  const RecurringInboxSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF131316),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => const RecurringInboxSheet(),
    );
  }

  @override
  State<RecurringInboxSheet> createState() => _RecurringInboxSheetState();
}

class _RecurringInboxSheetState extends State<RecurringInboxSheet> {
  final _service = RecurringTransactionService();
  final Map<String, TextEditingController> _amountControllers = {};
  final Set<String> _processingIds = {};

  @override
  void dispose() {
    for (final ctrl in _amountControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  TextEditingController _getController(RecurringTransaction item) {
    return _amountControllers.putIfAbsent(
      item.id,
      () => TextEditingController(text: item.amount.toStringAsFixed(2)),
    );
  }

  Future<void> _confirmItem(RecurringTransaction item) async {
    final ctrl = _getController(item);
    final parsed = double.tryParse(ctrl.text.replaceAll(',', '.')) ?? item.amount;

    setState(() => _processingIds.add(item.id));
    HapticFeedback.mediumImpact();

    try {
      await _service.confirmOccurrence(item, customAmount: parsed);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  item.isIncome ? Icons.trending_up_rounded : Icons.check_circle_rounded,
                  color: item.isIncome ? const Color(0xFF10B981) : const Color(0xFF6366F1),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${item.title}: registrato con successo (${NumberFormat.currency(locale: 'it_IT', symbol: '€').format(parsed)})',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF18181B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: item.isIncome ? const Color(0xFF10B981) : const Color(0xFF6366F1)),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error confirming recurring item: $e');
    } finally {
      if (mounted) {
        setState(() => _processingIds.remove(item.id));
        if (_service.getPendingInboxItems().isEmpty) {
          Navigator.pop(context);
        }
      }
    }
  }

  Future<void> _skipItem(RecurringTransaction item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        title: const Text('Salta questo ciclo?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'La transazione per "${item.title}" non verrà registrata sul portafoglio e la scadenza passerà al ciclo successivo.',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annulla', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Salta'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _processingIds.add(item.id));
      HapticFeedback.lightImpact();
      await _service.skipCycle(item);
      if (mounted) {
        setState(() => _processingIds.remove(item.id));
        if (_service.getPendingInboxItems().isEmpty) {
          Navigator.pop(context);
        }
      }
    }
  }

  Future<void> _postponeItem(RecurringTransaction item, {int days = 3}) async {
    setState(() => _processingIds.add(item.id));
    HapticFeedback.lightImpact();
    await _service.postponeOccurrence(item, days: days);
    if (mounted) {
      setState(() => _processingIds.remove(item.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.title} posticipato di $days giorni'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (_service.getPendingInboxItems().isEmpty) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _service.pendingInboxCountNotifier,
      builder: (context, _) {
        final pendingItems = _service.getPendingInboxItems();

        return Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 14,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Sheet Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.repeat_rounded, color: Color(0xFF818CF8), size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Movimenti in Scadenza',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Verifica gli importi e conferma le uscite/entrate',
                          style: TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  if (pendingItems.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.4)),
                      ),
                      child: Text(
                        '${pendingItems.length}',
                        style: const TextStyle(
                          color: Color(0xFF818CF8),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Items List or Empty
              if (pendingItems.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.04),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_circle_outline_rounded, size: 36, color: Color(0xFF10B981)),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Tutto in pari! 🎉',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Nessun movimento ricorrente in attesa di conferma.',
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    ],
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: pendingItems.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = pendingItems[index];
                      final isProcessing = _processingIds.contains(item.id);
                      final ctrl = _getController(item);

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1C21),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: item.isIncome
                                ? const Color(0xFF10B981).withOpacity(0.3)
                                : const Color(0xFF6366F1).withOpacity(0.3),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top Row: Icon, Title, and Variable badge
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: (item.isIncome ? const Color(0xFF10B981) : const Color(0xFF6366F1)).withOpacity(0.18),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    item.isIncome ? Icons.arrow_downward_rounded : CategoryHelpers.getIconForCategory(item.category),
                                    size: 16,
                                    color: item.isIncome ? const Color(0xFF10B981) : const Color(0xFF818CF8),
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
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (item.isVariableAmount) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                              decoration: BoxDecoration(
                                                color: Colors.amber.withOpacity(0.18),
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: Colors.amber.withOpacity(0.4), width: 0.8),
                                              ),
                                              child: const Text(
                                                'Variabile',
                                                style: TextStyle(color: Colors.amber, fontSize: 9, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Frequenza: ${item.frequency.label} • Scadenza: ${DateFormat('dd/MM/yyyy').format(item.nextDueDate)}',
                                        style: const TextStyle(color: Colors.white38, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Middle: Amount Editor
                            Row(
                              children: [
                                const Text(
                                  'Importo effettivo:',
                                  style: TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Container(
                                    height: 38,
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF27272A),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.white12),
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          '€',
                                          style: TextStyle(
                                            color: item.isIncome ? const Color(0xFF10B981) : const Color(0xFF818CF8),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: TextField(
                                            controller: ctrl,
                                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            decoration: const InputDecoration(
                                              border: InputBorder.none,
                                              isDense: true,
                                              contentPadding: EdgeInsets.zero,
                                            ),
                                          ),
                                        ),
                                        const Icon(Icons.edit, size: 13, color: Colors.white30),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Bottom Actions
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                // Postpone menu
                                PopupMenuButton<int>(
                                  color: const Color(0xFF27272A),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  icon: const Icon(Icons.more_horiz_rounded, color: Colors.white38, size: 20),
                                  itemBuilder: (ctx) => [
                                    const PopupMenuItem(value: 3, child: Text('Postponi di 3 giorni', style: TextStyle(color: Colors.white, fontSize: 13))),
                                    const PopupMenuItem(value: 7, child: Text('Postponi di 1 settimana', style: TextStyle(color: Colors.white, fontSize: 13))),
                                  ],
                                  onSelected: (days) => _postponeItem(item, days: days),
                                ),
                                const Spacer(),
                                TextButton(
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFFEF4444),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  onPressed: isProcessing ? null : () => _skipItem(item),
                                  child: const Text('Salta Ciclo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                ),
                                const SizedBox(width: 6),
                                ElevatedButton.icon(
                                  icon: isProcessing
                                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                                      : const Icon(Icons.check, size: 16),
                                  label: const Text('Conferma', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: item.isIncome ? const Color(0xFF10B981) : const Color(0xFF6366F1),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: isProcessing ? null : () => _confirmItem(item),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
