import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:solducci/models/dashboard_config.dart';
import 'package:solducci/widgets/dashboard/bento_widget_container.dart';
import 'package:solducci/service/expense_service_cached.dart';
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

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    try {
      final contextManager = ContextManager();
      final currentContext = contextManager.currentContext;
      
      if (currentContext.isGroup && currentContext.groupId != null) {
        final balances = await ExpenseServiceCached().calculateGroupBalance(currentContext.groupId!);
        if (balances.isNotEmpty) {
          _balancesList = balances.entries.toList();
        } else {
           _balancesList = [const MapEntry('Nessun saldo', 0.0)];
        }
      } else {
        // For personal context, mock multiple wallets to demonstrate the swipe stack
        _balancesList = const [
          MapEntry('Totale', 1250.00),
          MapEntry('Intesa SP', 800.00),
          MapEntry('Revolut', 450.00),
        ];
      }
    } catch (e) {
      print('Error loading balance: $e');
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
      isLoading: _isLoading,
      onExpand: () {
        GoRouter.of(context).push('/expenses_dashboard');
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
                color: color.withValues(alpha: 0.5),
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
