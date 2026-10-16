import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:solducci/models/dashboard_config.dart';
import 'package:solducci/models/dashboard_data.dart';
import 'package:solducci/service/context_manager.dart';
import 'package:solducci/service/expense_service_cached.dart';
import 'package:solducci/widgets/dashboard/bento_empty_state.dart';
import 'package:solducci/widgets/dashboard/bento_skeleton.dart';
import 'package:solducci/widgets/dashboard/bento_widget_container.dart';

/// Bento Widget "Saldo e Debiti": visualizza i debiti e crediti reciproci nel gruppo o nella vista
class PeerDebtsWidget extends StatefulWidget {
  final BentoWidgetDef def;

  const PeerDebtsWidget({super.key, required this.def});

  @override
  State<PeerDebtsWidget> createState() => _PeerDebtsWidgetState();
}

class _PeerDebtsWidgetState extends State<PeerDebtsWidget> {
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
    if (ctx.isPersonal) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isViewMode = false;
          _balances = [];
          _groupedBalances = [];
        });
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (ctx.isGroup && ctx.groupId != null) {
        final raw = await _expenseService.calculateGroupBalanceMultiPerson(ctx.groupId!);
        final list = raw.entries.map((entry) {
          final data = entry.value;
          return PairwiseDebtBalance.fromBalanceEntry(
            userId: entry.key,
            userName: data['name'] as String? ?? 'Utente',
            balance: (data['balance'] as num?)?.toDouble() ?? 0.0,
          );
        }).toList();

        // Sort: debiti per primi, poi crediti
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
      } else if (ctx.isView && ctx.groupIds.isNotEmpty) {
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
      } else {
        if (mounted) {
          setState(() {
            _isViewMode = false;
            _balances = [];
            _groupedBalances = [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('[PeerDebtsWidget] Error loading debts: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctx = _contextManager.currentContext;
    final is1x1 = widget.def.size.crossAxisCellCount == 1 && widget.def.size.mainAxisCellCount == 1;
    final is2x1 = widget.def.size.crossAxisCellCount >= 2 && widget.def.size.mainAxisCellCount <= 1;

    void navigateToDebts() {
      GoRouter.of(context).push('/expenses_dashboard', extra: {'heroTag': widget.def.id});
    }

    // Se siamo nel contesto personale, il widget non è applicabile
    if (ctx.isPersonal) {
      return BentoWidgetContainer(
        heroTag: widget.def.id,
        size: widget.def.size,
        onTap: navigateToDebts,
        onExpand: navigateToDebts,
        child: BentoEmptyState(
          icon: Icons.group_off_rounded,
          title: 'Solo nei Gruppi',
          subtitle: 'Seleziona un gruppo o una vista per visualizzare i saldi e i debiti',
          color: const Color(0xFF8B5CF6),
          isCompact: is1x1 || is2x1,
        ),
      );
    }

    final hasData = _isViewMode ? _groupedBalances.isNotEmpty : _balances.isNotEmpty;

    return BentoWidgetContainer(
      heroTag: widget.def.id,
      size: widget.def.size,
      skeletonType: BentoSkeletonType.list,
      isLoading: _isLoading && !hasData,
      onRetry: _loadDebts,
      onTap: navigateToDebts,
      onExpand: navigateToDebts,
      child: !hasData && !_isLoading
          ? _buildAllBalancedState(is1x1 || is2x1)
          : (_isViewMode ? _buildViewGroupedContent(is1x1) : _buildBalancesContent(is1x1: is1x1, is2x1: is2x1)),
    );
  }

  Widget _buildAllBalancedState(bool is1x1) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 24),
            ),
            const SizedBox(height: 6),
            Text(
              _isViewMode ? 'Saldi in pareggio' : 'Tutti in pari',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            if (!is1x1) ...[
              const SizedBox(height: 2),
              Text(
                _isViewMode ? 'Nessun debito aperto nei gruppi' : 'Nessun debito nel gruppo',
                style: const TextStyle(color: Colors.white54, fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Visualizzazione per singolo gruppo (compatta o a lista)
  Widget _buildBalancesContent({required bool is1x1, required bool is2x1}) {
    if (is1x1) {
      final top = _balances.first;
      final isDebtor = top.youOwe;
      final color = isDebtor ? const Color(0xFFF59E0B) : const Color(0xFF10B981);
      final icon = isDebtor ? Icons.south_west_rounded : Icons.north_east_rounded;

      return Center(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 10, color: color),
                  const SizedBox(width: 3),
                  Text(
                    isDebtor ? 'DEVI' : 'TI SPETTA',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 9,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '€${top.amount.abs().toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                top.userName,
                style: const TextStyle(color: Colors.white54, fontSize: 10),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );
    }

    if (is2x1) {
      final top = _balances.first;
      final isDebtor = top.youOwe;
      final color = isDebtor ? const Color(0xFFF59E0B) : const Color(0xFF10B981);
      final icon = isDebtor ? Icons.south_west_rounded : Icons.north_east_rounded;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
        child: Row(
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
                  child: const Icon(Icons.compare_arrows_rounded, size: 13, color: Color(0xFF8B5CF6)),
                ),
                const SizedBox(width: 8),
                const Text(
                  'SALDO & DEBITI',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 11, color: color),
                  const SizedBox(width: 4),
                  Text(
                    '${isDebtor ? "Devi" : "Ti spetta"} €${top.amount.abs().toStringAsFixed(2)}',
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.compare_arrows_rounded, size: 14, color: Color(0xFF8B5CF6)),
                  SizedBox(width: 6),
                  Text(
                    'SALDO & DEBITI',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${_balances.length}',
                  style: const TextStyle(color: Color(0xFF8B5CF6), fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),

        // List
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            itemCount: _balances.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final b = _balances[index];
              final isDebtor = b.youOwe;
              // Crediti in su (verde), Debiti in giù (ambra)
              final color = isDebtor ? const Color(0xFFF59E0B) : const Color(0xFF10B981);
              final icon = isDebtor ? Icons.south_west_rounded : Icons.north_east_rounded;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF18181D),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 13,
                      backgroundColor: color.withOpacity(0.18),
                      child: Text(
                        b.userInitial,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            b.userName,
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            isDebtor ? 'Devi rimborsare' : 'Ti deve rimborsare',
                            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          size: 13,
                          color: color,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '€${b.amount.abs().toStringAsFixed(2)}',
                          style: TextStyle(
                            color: color,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
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
    );
  }

  /// Visualizzazione per Viste con più gruppi
  Widget _buildViewGroupedContent(bool is1x1) {
    if (is1x1) {
      final top = _groupedBalances.first;
      final net = top.totalTheyOweYou - top.totalYouOwe;
      final isDebtor = net < 0;
      final color = isDebtor ? const Color(0xFFF59E0B) : const Color(0xFF10B981);
      final icon = isDebtor ? Icons.south_west_rounded : Icons.north_east_rounded;

      return Center(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 10, color: color),
                  const SizedBox(width: 3),
                  Text(
                    isDebtor ? 'DEBITO NETTO' : 'CREDITO NETTO',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 8,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '€${net.abs().toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                top.groupName,
                style: const TextStyle(color: Colors.white54, fontSize: 10),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.compare_arrows_rounded, size: 14, color: Color(0xFF8B5CF6)),
                  SizedBox(width: 6),
                  Text(
                    'SALDO PER GRUPPO',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${_groupedBalances.length}',
                  style: const TextStyle(color: Color(0xFF8B5CF6), fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),

        // List
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            itemCount: _groupedBalances.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final g = _groupedBalances[index];
              final net = g.totalTheyOweYou - g.totalYouOwe;
              final isNetPositive = net > 0.01;
              final isNetNegative = net < -0.01;
              final netColor = isNetPositive
                  ? const Color(0xFF10B981)
                  : (isNetNegative ? const Color(0xFFF59E0B) : Colors.white54);

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF18181D),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            g.groupName,
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          isNetPositive
                              ? '+€${net.toStringAsFixed(2)}'
                              : (isNetNegative ? '-€${net.abs().toStringAsFixed(2)}' : '0.00 €'),
                          style: TextStyle(
                            color: netColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (g.hasCredits) ...[
                          const Icon(Icons.north_east_rounded, size: 10, color: Color(0xFF10B981)),
                          const SizedBox(width: 2),
                          Text(
                            '€${g.totalTheyOweYouLabel}',
                            style: const TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (g.hasDebts) ...[
                          const Icon(Icons.south_west_rounded, size: 10, color: Color(0xFFF59E0B)),
                          const SizedBox(width: 2),
                          Text(
                            '€${g.totalYouOweLabel}',
                            style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 10, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
