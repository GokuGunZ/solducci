import 'package:flutter/material.dart';
import 'package:solducci/models/dashboard_config.dart';
import 'package:solducci/widgets/dashboard/bento_widget_container.dart';
import 'package:solducci/service/expense_service_cached.dart';
import 'package:solducci/service/context_manager.dart';
import 'package:intl/intl.dart';

class BalancePillWidget extends StatefulWidget {
  final BentoWidgetDef def;

  const BalancePillWidget({super.key, required this.def});

  @override
  State<BalancePillWidget> createState() => _BalancePillWidgetState();
}

class _BalancePillWidgetState extends State<BalancePillWidget> {
  bool _isLoading = true;
  double _balance = 0.0;
  String _targetName = '';

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
          // Simplify logic: sum of balances or just take the first one
          _balance = balances.values.first;
          _targetName = balances.keys.first;
        }
      }
    } catch (e) {
      print('Error loading balance: $e');
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
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'SALDO',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 10,
                letterSpacing: 1.2,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            _buildBalanceAmount(),
            if (_targetName.isNotEmpty && _targetName != 'Unknown') ...[
              const SizedBox(height: 4),
              Text(
                _balance >= 0 ? 'da $_targetName' : 'a $_targetName',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceAmount() {
    final formatter = NumberFormat.currency(locale: 'it_IT', symbol: '€');
    final isPositive = _balance >= 0;
    final color = isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final sign = isPositive ? '+' : '';

    return Stack(
      alignment: Alignment.center,
      children: [
        // Neon Glow
        Text(
          '$sign${formatter.format(_balance)}',
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
          '$sign${formatter.format(_balance)}',
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
