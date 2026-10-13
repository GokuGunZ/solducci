import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:solducci/models/dashboard_config.dart';
import 'package:solducci/widgets/dashboard/bento_empty_state.dart';
import 'package:solducci/widgets/dashboard/bento_widget_container.dart';
import 'package:solducci/widgets/dashboard/bento_skeleton.dart';
import 'package:solducci/widgets/dashboard/cache/bento_data_cache.dart';
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
  bool _isStale = false;
  List<MapEntry<String, double>> _balancesList = [];
  StreamSubscription? _walletSub;
  StreamSubscription? _expenseSub;

  String get _cacheKey => 'balance_${widget.def.id}';

  @override
  void initState() {
    super.initState();
    _loadFromCacheFirst();
    _loadBalance();
    _walletSub = WalletService().stream.listen((_) => _loadBalance());
    _expenseSub = ExpenseServiceCached().stream.listen((_) => _loadBalance());
  }

  void _loadFromCacheFirst() {
    // 0 ms: lettura immediata sincrona da memoria o disco
    final fast = BentoDataCache.getFastMemorySnapshot(_cacheKey);
    if (fast != null && fast['items'] is List) {
      _applyCachedJson(fast);
      return;
    }

    // Lettura asincrona disco rapida
    BentoDataCache.getSnapshot(_cacheKey).then((disk) {
      if (disk != null && disk['items'] is List && mounted && _balancesList.isEmpty) {
        setState(() {
          _applyCachedJson(disk);
        });
      }
    });
  }

  void _applyCachedJson(Map<String, dynamic> json) {
    try {
      final items = (json['items'] as List)
          .map((e) => MapEntry<String, double>(e['k'] as String, (e['v'] as num).toDouble()))
          .toList();
      if (items.isNotEmpty) {
        _balancesList = items;
        _isLoading = false;
      }
    } catch (_) {}
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

      List<MapEntry<String, double>> freshBalances = [];

      if (specificWalletId != null) {
        final wallets = await WalletService().fetchWallets().timeout(const Duration(seconds: 4));
        final match = wallets.where((w) => w.id == specificWalletId).firstOrNull;
        if (match != null) {
          freshBalances = [MapEntry(match.name, match.currentBalance)];
        } else {
          freshBalances = [const MapEntry('Conto non trovato', 0.0)];
        }
      } else if (currentContext.isGroup && currentContext.groupId != null) {
        final balances = await ExpenseServiceCached()
            .calculateGroupBalance(currentContext.groupId!)
            .timeout(const Duration(seconds: 4));
        if (balances.isNotEmpty) {
          freshBalances = balances.entries.toList();
        } else {
          freshBalances = [const MapEntry('Nessun saldo', 0.0)];
        }
      } else {
        final wallets = await WalletService().fetchWallets().timeout(const Duration(seconds: 4));
        if (wallets.isNotEmpty) {
          final double totalBalance = wallets.fold(0.0, (sum, w) => sum + w.currentBalance);
          freshBalances = [
            MapEntry('Totale', totalBalance),
            ...wallets.map((w) => MapEntry(w.name, w.currentBalance)),
          ];
        } else {
          freshBalances = [const MapEntry('Nessun conto', 0.0)];
        }
      }

      if (mounted) {
        setState(() {
          _balancesList = freshBalances;
          _isLoading = false;
          _isStale = false;
        });

        // Persistiamo lo snapshot valido
        BentoDataCache.saveSnapshot(_cacheKey, {
          'items': freshBalances.map((e) => {'k': e.key, 'v': e.value}).toList(),
        });
      }
    } catch (e) {
      debugPrint('[BalancePillWidget] Errore o timeout fetch balance: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          // Se avevamo già dati (cache), non li distruggiamo ma attiviamo lo status offline
          if (_balancesList.isNotEmpty) {
            _isStale = true;
          } else {
            _balancesList = [const MapEntry('Non disponibile', 0.0)];
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.def.size;
    final is1x1 = size.crossAxisCellCount <= 1 && size.mainAxisCellCount <= 1;
    final is2x2OrLarger = size.mainAxisCellCount >= 2;

    final hasValidAccounts = _balancesList.isNotEmpty &&
        !(_balancesList.length == 1 &&
            (_balancesList.first.key == 'Nessun conto' ||
                _balancesList.first.key == 'Non disponibile'));

    return BentoWidgetContainer(
      heroTag: widget.def.id,
      size: widget.def.size,
      skeletonType: BentoSkeletonType.metric,
      isLoading: _isLoading && _balancesList.isEmpty,
      isStale: _isStale,
      onRetry: _loadBalance,
      onExpand: () {
        GoRouter.of(context).push('/economy/charts', extra: {'heroTag': widget.def.id});
      },
      child: !hasValidAccounts && !_isLoading
          ? BentoEmptyState(
              icon: Icons.account_balance_wallet_rounded,
              title: 'Nessun conto',
              subtitle: 'Aggiungi un portafoglio per monitorare il saldo',
              color: const Color(0xFF10B981),
              actionLabel: 'Aggiungi',
              onAction: () => GoRouter.of(context).push('/wallets'),
              isCompact: is1x1,
            )
          : SwipeableBentoStack<MapEntry<String, double>>(
              items: _balancesList.isEmpty ? [const MapEntry('', 0.0)] : _balancesList,
              builder: (context, item, index) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: is1x1 ? 8.0 : 16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item.key.toUpperCase(),
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: is1x1 ? 9 : 10,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: is1x1 ? 2 : 4),
                        _buildBalanceAmount(item.value, is1x1: is1x1, isLarge: is2x2OrLarger),
                        if (is2x2OrLarger) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.swipe_rounded, size: 11, color: Colors.white38),
                                const SizedBox(width: 4),
                                Text(
                                  'Conto ${index + 1} di ${_balancesList.length}',
                                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildBalanceAmount(double balance, {bool is1x1 = false, bool isLarge = false}) {
    final formatter = NumberFormat.currency(locale: 'it_IT', symbol: '€');
    final isPositive = balance >= 0;
    final color = isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final sign = isPositive ? '+' : '';

    final double fontSize = is1x1 ? 16.0 : (isLarge ? 26.0 : 21.0);

    return Stack(
      alignment: Alignment.center,
      children: [
        // Neon Glow
        Text(
          '$sign${formatter.format(balance)}',
          style: TextStyle(
            color: color.withOpacity(0.3),
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        // Sharp Foreground
        Text(
          '$sign${formatter.format(balance)}',
          style: TextStyle(
            color: color,
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
