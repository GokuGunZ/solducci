import 'dart:async';
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
  bool _isViewMode = false;
  List<PairwiseDebtBalance> _balances = [];
  List<GroupedDebtBalance> _groupedBalances = [];
  StreamSubscription? _expenseSub;

  @override
  void initState() {
    super.initState();
    _contextManager.addListener(_onContextChanged);
    _expenseSub = _expenseService.stream.listen((_) => _loadDebts());
    _loadDebts();
  }

  @override
  void dispose() {
    _contextManager.removeListener(_onContextChanged);
    _expenseSub?.cancel();
    super.dispose();
  }

  void _onContextChanged() {
    if (mounted) {
      _loadDebts();
    }
  }

  Future<void> _loadDebts() async {
    final ctx = _contextManager.currentContext;

    // Single group explicitly passed or single group context
    final singleGroupId = widget.groupId ?? (ctx.isGroup ? ctx.groupId : null);

    if (singleGroupId != null) {
      try {
        final raw = await _expenseService.calculateGroupBalanceMultiPerson(singleGroupId);
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
            _isViewMode = false;
            _balances = list;
            _groupedBalances = [];
            _isLoading = false;
          });
        }
      } catch (e) {
        debugPrint('[GroupDebtsSection] Error loading group debts: $e');
        if (mounted) setState(() => _isLoading = false);
      }
      return;
    }

    // View context with multiple groups
    if (ctx.isView && ctx.groupIds.isNotEmpty) {
      try {
        final raw = await _expenseService.calculateViewBalanceGrouped(ctx.groupIds);
        final list = raw.entries.map((entry) {
          final data = entry.value;
          return GroupedDebtBalance(
            groupId: entry.key,
            groupName: data['groupName'] as String? ?? 'Gruppo',
            peopleYouOwe: (data['peopleYouOwe'] as num?)?.toInt() ?? 0,
            peopleWhoOweYou: (data['peopleWhoOweYou'] as num?)?.toInt() ?? 0,
            totalYouOwe: (data['totalYouOwe'] as num?)?.toDouble() ?? 0.0,
            totalTheyOweYou: (data['totalTheyOweYou'] as num?)?.toDouble() ?? 0.0,
          );
        }).toList();

        list.sort((a, b) => b.netBalance.abs().compareTo(a.netBalance.abs()));

        if (mounted) {
          setState(() {
            _isViewMode = true;
            _groupedBalances = list;
            _balances = [];
            _isLoading = false;
          });
        }
      } catch (e) {
        debugPrint('[GroupDebtsSection] Error loading view grouped debts: $e');
        if (mounted) setState(() => _isLoading = false);
      }
      return;
    }

    // Personal or empty
    if (mounted) {
      setState(() {
        _isViewMode = false;
        _balances = [];
        _groupedBalances = [];
        _isLoading = false;
      });
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

    final hasData = _isViewMode ? _groupedBalances.isNotEmpty : _balances.isNotEmpty;

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
              Row(
                children: [
                  const Icon(Icons.compare_arrows_rounded, size: 18, color: Color(0xFF8B5CF6)),
                  const SizedBox(width: 8),
                  Text(
                    _isViewMode ? 'Saldo Debiti per Gruppo' : 'Saldo Debiti & Crediti',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              if (hasData)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _isViewMode
                        ? '${_groupedBalances.length} ${_groupedBalances.length == 1 ? 'gruppo' : 'gruppi'}'
                        : '${_balances.length} posizioni',
                    style: const TextStyle(color: Color(0xFF8B5CF6), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          if (!hasData)
            // Stato in pareggio
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF10B981).withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
                  const SizedBox(width: 10),
                  Text(
                    _isViewMode ? 'Tutti i saldi in pareggio in questa vista' : 'Tutti i saldi in pareggio',
                    style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            )
          else if (_isViewMode)
            // Visualizzazione raggruppata per Viste
            ..._groupedBalances.map((g) => _buildViewGroupCard(g))
          else
            // Elenco dei debiti per singolo Gruppo
            ..._balances.map((b) => _buildPairwiseDebtRow(b)),
        ],
      ),
    );
  }

  /// Riga per singolo debito/credito tra persone
  Widget _buildPairwiseDebtRow(PairwiseDebtBalance b) {
    final isDebtor = b.youOwe;
    // Debito verso altri -> down-arrow (diminuisce patrimonio, ambra)
    // Credito da altri -> up-arrow (aumenta patrimonio, verde)
    final color = isDebtor ? const Color(0xFFF59E0B) : const Color(0xFF10B981);
    final icon = isDebtor ? Icons.south_west_rounded : Icons.north_east_rounded;

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
                  icon,
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
  }

  /// Card per ciascun gruppo nella vista aggregata
  Widget _buildViewGroupCard(GroupedDebtBalance g) {
    final net = g.totalTheyOweYou - g.totalYouOwe;
    final isNetPositive = net > 0.01;
    final isNetNegative = net < -0.01;
    final netColor = isNetPositive
        ? const Color(0xFF10B981)
        : (isNetNegative ? const Color(0xFFF59E0B) : Colors.white54);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C22),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Intestazione Gruppo + Net balance badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.group_work_rounded, size: 14, color: Color(0xFF8B5CF6)),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      g.groupName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: netColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: netColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    isNetPositive
                        ? 'Netto: +€${net.toStringAsFixed(2)}'
                        : (isNetNegative
                            ? 'Netto: -€${net.abs().toStringAsFixed(2)}'
                            : 'In pareggio'),
                    style: TextStyle(
                      color: netColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Crediti nel gruppo (persone che ti devono rimborsare)
            if (g.hasCredits)
              Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.north_east_rounded, size: 12, color: Color(0xFF10B981)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${g.peopleWhoOweYou} ${g.peopleWhoOweYou == 1 ? 'persona ti deve' : 'persone ti devono'} rimborsare',
                        style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                      ),
                    ),
                    Text(
                      '+ €${g.totalTheyOweYouLabel}',
                      style: const TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

            // Debiti nel gruppo (persone a cui devi rimborsare)
            if (g.hasDebts)
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.south_west_rounded, size: 12, color: Color(0xFFF59E0B)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Devi rimborsare a ${g.peopleYouOwe} ${g.peopleYouOwe == 1 ? 'persona' : 'persone'}',
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                    ),
                  ),
                  Text(
                    '- €${g.totalYouOweLabel}',
                    style: const TextStyle(
                      color: Color(0xFFF59E0B),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
