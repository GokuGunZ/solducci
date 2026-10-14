import 'package:flutter/material.dart';
import 'package:solducci/models/dashboard_data.dart';
import 'package:solducci/service/context_manager.dart';
import 'package:solducci/service/expense_service_cached.dart';

class GroupDebtsSection extends StatefulWidget {
  final String? groupId;
  const GroupDebtsSection({super.key, this.groupId});

  @override
  State<GroupDebtsSection> createState() => _GroupDebtsSectionState();
}

class _GroupDebtsSectionState extends State<GroupDebtsSection> {
  final _contextManager = ContextManager();
  final _expenseService = ExpenseServiceCached();

  bool _isLoading = true;
  List<PairwiseDebtBalance> _balances = [];

  @override
  void initState() {
    super.initState();
    _loadDebts();
  }

  Future<void> _loadDebts() async {
    final targetGroupId = widget.groupId ?? _contextManager.currentGroupId;
    if (targetGroupId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final raw = await _expenseService.calculateGroupBalanceMultiPerson(targetGroupId);
      final list = raw.entries.map((entry) {
        final data = entry.value;
        return PairwiseDebtBalance.fromBalanceEntry(
          userId: entry.key,
          userName: data['name'] as String? ?? 'Utente',
          balance: (data['balance'] as num?)?.toDouble() ?? 0.0,
        );
      }).toList();

      list.sort((a, b) {
        if (a.youOwe && !b.youOwe) return -1;
        if (!a.youOwe && b.youOwe) return 1;
        return b.amount.abs().compareTo(a.amount.abs());
      });

      if (mounted) {
        setState(() {
          _balances = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[GroupDebtsSection] Error loading debts: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 60,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF8B5CF6))),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141418),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.3), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.compare_arrows_rounded, size: 18, color: Color(0xFF8B5CF6)),
                  SizedBox(width: 8),
                  Text(
                    'Saldo Debiti & Crediti',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              if (_balances.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_balances.length} posizioni',
                    style: const TextStyle(color: Color(0xFF8B5CF6), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          if (_balances.isEmpty)
            // Stato tutti in pari
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF10B981).withOpacity(0.25)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Tutti i saldi in pareggio',
                    style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            )
          else
            // Elenco dei debiti
            ..._balances.map((b) {
              final isDebtor = b.youOwe;
              final color = isDebtor ? const Color(0xFFF59E0B) : const Color(0xFF10B981);

              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C22),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.06)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: color.withOpacity(0.18),
                        child: Text(
                          b.userInitial,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              b.userName,
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              isDebtor ? 'Devi rimborsare' : 'Ti deve rimborsare',
                              style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isDebtor ? Icons.arrow_outward_rounded : Icons.south_west_rounded,
                            size: 15,
                            color: color,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '€ ${b.amount.abs().toStringAsFixed(2)}',
                            style: TextStyle(
                              color: color,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
