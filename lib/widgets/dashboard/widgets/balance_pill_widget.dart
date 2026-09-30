import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:solducci/models/dashboard_config.dart';
import 'package:solducci/widgets/dashboard/bento_widget_container.dart';
import 'package:solducci/service/expense_service_cached.dart';
import 'package:solducci/service/wallet_service.dart';
import 'package:solducci/service/context_manager.dart';
import 'package:intl/intl.dart';

import 'package:solducci/widgets/dashboard/swipeable_bento_stack.dart';

class BalancePillWidget extends StatefulWidget {
  final BentoWidgetDef def;

  const BalancePillWidget({super.key, required this.def});

  @override
  State<BalancePillWidget> createState() => _BalancePillWidgetState();
}

class _BalancePillWidgetState extends State<BalancePillWidget> {
  bool _isLoading = true;
  List<MapEntry<String, double>> _balancesList = [];
  StreamSubscription? _walletSub;
  StreamSubscription? _expenseSub;

  @override
  void initState() {
    super.initState();
    _loadBalance();
    _walletSub = WalletService().stream.listen((_) => _loadBalance());
    _expenseSub = ExpenseServiceCached().stream.listen((_) => _loadBalance());
  }

  @override
  void didUpdateWidget(BalancePillWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.def.customProps != widget.def.customProps) {
      _loadBalance();
    }
  }

  @override
  void dispose() {
    _walletSub?.cancel();
    _expenseSub?.cancel();
    super.dispose();
  }

  Future<void> _loadBalance() async {
    try {
      final contextManager = ContextManager();
      final currentContext = contextManager.currentContext;
      final customProps = widget.def.customProps;
      final specificWalletId = customProps?['walletId'] as String?;

      if (specificWalletId != null) {
        final wallets = await WalletService().fetchWallets();
        final match = wallets.where((w) => w.id == specificWalletId).firstOrNull;
        if (match != null) {
          _balancesList = [MapEntry(match.name, match.currentBalance)];
        } else {
          _balancesList = [const MapEntry('Conto non trovato', 0.0)];
        }
      } else if (currentContext.isGroup && currentContext.groupId != null) {
        final balances = await ExpenseServiceCached().calculateGroupBalance(currentContext.groupId!);
        if (balances.isNotEmpty) {
          _balancesList = balances.entries.toList();
        } else {
          _balancesList = [const MapEntry('Nessun saldo', 0.0)];
        }
      } else {
        final wallets = await WalletService().fetchWallets();
        if (wallets.isNotEmpty) {
          final double totalBalance = wallets.fold(0.0, (sum, w) => sum + w.currentBalance);
          _balancesList = [
            MapEntry('Totale', totalBalance),
            ...wallets.map((w) => MapEntry(w.name, w.currentBalance)),
          ];
        } else {
          _balancesList = [const MapEntry('Nessun conto', 0.0)];
        }
      }
    } catch (e) {
      debugPrint('Error loading balance: $e');
      _balancesList = [const MapEntry('Errore', 0.0)];
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BentoWidgetContainer(
      heroTag: widget.def.id,
      isLoading: _isLoading,
      onExpand: () {
        GoRouter.of(context).push('/expenses_dashboard', extra: {'heroTag': widget.def.id});
      },
      child: SwipeableBentoStack<MapEntry<String, double>>(
        items: _balancesList.isEmpty ? [const MapEntry('', 0.0)] : _balancesList,
        builder: (context, item, index) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.key.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                _buildBalanceAmount(item.value),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBalanceAmount(double balance) {
    final formatter = NumberFormat.currency(locale: 'it_IT', symbol: '€');
    final isPositive = balance >= 0;
    final color = isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final sign = isPositive ? '+' : '';

    return Stack(
      alignment: Alignment.center,
      children: [
        // Neon Glow
        Text(
          '$sign${formatter.format(balance)}',
          style: TextStyle(
            color: Colors.transparent,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            fontFamily: 'Inter',
            shadows: [
              Shadow(
                color: color.withOpacity(0.5),
                blurRadius: 15,
              ),
            ],
          ),
        ),
        // Actual Text
        Text(
          '$sign${formatter.format(balance)}',
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            fontFamily: 'Inter',
          ),
        ),
      ],
    );
  }
}
