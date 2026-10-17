import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:solducci/models/dashboard_config.dart';
import 'package:solducci/models/wallet.dart';
import 'package:solducci/widgets/dashboard/bento_empty_state.dart';
import 'package:solducci/widgets/dashboard/bento_widget_container.dart';
import 'package:solducci/widgets/dashboard/bento_skeleton.dart';
import 'package:solducci/widgets/dashboard/cache/bento_data_cache.dart';
import 'package:solducci/service/expense_service_cached.dart';
import 'package:solducci/service/wallet_service.dart';
import 'package:solducci/service/context_manager.dart';
import 'package:intl/intl.dart';
import 'package:solducci/widgets/dashboard/context/dashboard_context_scope.dart';
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
  ExpenseContext? _lastContext;

  String _cacheKey(ExpenseContext ctx) => 'balance_${ctx.contextKey}_${widget.def.id}';

  @override
  void initState() {
    super.initState();
    _walletSub = WalletService().stream.listen((wallets) {
      final currentContext = _lastContext ?? ContextManager().currentContext;
      if (currentContext.isPersonal) {
        _updateFromWallets(wallets, currentContext);
      }
    });
    _expenseSub = ExpenseServiceCached().stream.listen((_) {
      final currentContext = _lastContext ?? ContextManager().currentContext;
      if (currentContext.isGroup) {
        _loadGroupBalance(currentContext);
      } else if (currentContext.isView) {
        _loadViewBalance(currentContext);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentContext = DashboardContextScope.of(context);
    if (_lastContext != currentContext) {
      _lastContext = currentContext;
      _loadFromCacheFirst(currentContext);
      _loadBalance(currentContext);
    }
  }

  void _loadFromCacheFirst(ExpenseContext ctx) {
    // 0 ms: lettura immediata sincrona da memoria o disco
    final fast = BentoDataCache.getFastMemorySnapshot(_cacheKey(ctx));
    if (fast != null && fast['items'] is List) {
      _applyCachedJson(fast);
      return;
    }

    // Lettura asincrona disco rapida
    BentoDataCache.getSnapshot(_cacheKey(ctx)).then((disk) {
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
      final ctx = _lastContext ?? DashboardContextScope.of(context);
      _loadBalance(ctx);
    }
  }

  @override
  void dispose() {
    _walletSub?.cancel();
    _expenseSub?.cancel();
    super.dispose();
  }

  void _updateFromWallets(List<Wallet> wallets, ExpenseContext ctx) {
    if (!mounted) return;
    final customProps = widget.def.customProps;
    final specificWalletId = customProps?['walletId'] as String?;

    List<MapEntry<String, double>> freshBalances = [];

    if (specificWalletId != null) {
      final match = wallets.where((w) => w.id == specificWalletId).firstOrNull;
      if (match != null) {
        freshBalances = [MapEntry(match.name, match.currentBalance)];
      } else {
        freshBalances = [const MapEntry('Conto non trovato', 0.0)];
      }
    } else {
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

    setState(() {
      _balancesList = freshBalances;
      _isLoading = false;
      _isStale = false;
    });

    BentoDataCache.saveSnapshot(_cacheKey(ctx), {
      'items': freshBalances.map((e) => {'k': e.key, 'v': e.value}).toList(),
    });
  }

  Future<void> _loadGroupBalance(ExpenseContext ctx) async {
    if (!ctx.isGroup || ctx.groupId == null) return;

    try {
      final balances = await ExpenseServiceCached()
          .calculateGroupBalance(ctx.groupId!)
          .timeout(const Duration(seconds: 4));

      List<MapEntry<String, double>> freshBalances = [];
      if (balances.isNotEmpty) {
        freshBalances = balances.entries.toList();
      } else {
        freshBalances = [const MapEntry('Nessun saldo', 0.0)];
      }

      if (mounted) {
        setState(() {
          _balancesList = freshBalances;
          _isLoading = false;
          _isStale = false;
        });

        BentoDataCache.saveSnapshot(_cacheKey(ctx), {
          'items': freshBalances.map((e) => {'k': e.key, 'v': e.value}).toList(),
        });
      }
    } catch (e) {
      debugPrint('[BalancePillWidget] Errore fetch group balance: $e');
    }
  }

  Future<void> _loadViewBalance(ExpenseContext ctx) async {
    try {
      final groupIds = ctx.groupIds;
      final Map<String, double> aggregated = {};
      for (final gid in groupIds) {
        final gBalances = await ExpenseServiceCached()
            .calculateGroupBalance(gid)
            .timeout(const Duration(seconds: 4));
        for (final entry in gBalances.entries) {
          aggregated[entry.key] = (aggregated[entry.key] ?? 0.0) + entry.value;
        }
      }

      List<MapEntry<String, double>> freshBalances = aggregated.isNotEmpty
          ? aggregated.entries.toList()
          : [const MapEntry('Nessun saldo', 0.0)];

      if (mounted) {
        setState(() {
          _balancesList = freshBalances;
          _isLoading = false;
          _isStale = false;
        });

        BentoDataCache.saveSnapshot(_cacheKey(ctx), {
          'items': freshBalances.map((e) => {'k': e.key, 'v': e.value}).toList(),
        });
      }
    } catch (e) {
      debugPrint('[BalancePillWidget] Errore fetch view balance: $e');
    }
  }

  Future<void> _loadBalance(ExpenseContext ctx) async {
    try {
      if (ctx.isGroup && ctx.groupId != null) {
        await _loadGroupBalance(ctx);
      } else if (ctx.isView) {
        await _loadViewBalance(ctx);
      } else {
        final wallets = await WalletService()
            .fetchWallets(context: ctx)
            .timeout(const Duration(seconds: 4));
        _updateFromWallets(wallets, ctx);
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
    final currentContext = DashboardContextScope.of(context);
    final size = widget.def.size;
    final is1x1 = size.crossAxisCellCount <= 1 && size.mainAxisCellCount <= 1;
    final is2x1 = size.crossAxisCellCount >= 2 && size.mainAxisCellCount <= 1;
    final isHeight3 = size.mainAxisCellCount >= 3;
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
      onRetry: () => _loadBalance(currentContext),
      onTap: () {
        GoRouter.of(context).push('/economy', extra: {'heroTag': widget.def.id});
      },
      child: !hasValidAccounts && !_isLoading
          ? BentoEmptyState(
              icon: Icons.account_balance_wallet_rounded,
              title: 'Nessun conto',
              subtitle: 'Aggiungi un portafoglio per monitorare il saldo',
              color: const Color(0xFF10B981),
              actionLabel: 'Aggiungi',
              onAction: () => GoRouter.of(context).push('/wallets'),
              isCompact: is1x1 || is2x1,
            )
          : SwipeableBentoStack<MapEntry<String, double>>(
              items: _balancesList.isEmpty ? [const MapEntry('', 0.0)] : _balancesList,
              builder: (context, item, index) {
                if (is2x1) {
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
                                color: const Color(0xFF10B981).withOpacity(0.18),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF10B981), size: 13),
                            ),
                            const SizedBox(width: 8),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 85),
                              child: Text(
                                item.key.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10.5,
                                  letterSpacing: 0.8,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        _buildBalanceAmount(item.value, is1x1: false, isLarge: false, customFontSize: 16.0),
                      ],
                    ),
                  );
                }

                if (isHeight3) {
                  final now = DateTime.now();
                  final allExp = ExpenseServiceCached().getAllCachedExpenses();
                  double mSpent = 0.0;
                  for (final e in allExp) {
                    if (e.date.year == now.year && e.date.month == now.month) {
                      mSpent += e.amount;
                    }
                  }
                  final totalLiquidity = _balancesList.isNotEmpty ? _balancesList.first.value : 1.0;
                  final otherWallets = _balancesList.skip(1).toList();

                  return Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Livello 1: Saldo attivo + Indicatore Swipe + Mese
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.swipe_rounded, size: 9, color: Colors.white38),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${index + 1}/${_balancesList.length}',
                                    style: const TextStyle(color: Colors.white38, fontSize: 9.5),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        _buildBalanceAmount(item.value, isLarge: true, customFontSize: 24.0),
                        const SizedBox(height: 4),
                        if (mSpent > 0)
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.arrow_downward_rounded, size: 9, color: Color(0xFFEF4444)),
                                    const SizedBox(width: 2),
                                    Text(
                                      '-€${mSpent.toStringAsFixed(0)} questo mese',
                                      style: const TextStyle(color: Color(0xFFEF4444), fontSize: 9.5, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 8),
                        Container(height: 0.8, color: Colors.white.withOpacity(0.08)),
                        const SizedBox(height: 6),

                        // Livello 2: Ripartizione conti o quota patrimonio
                        Expanded(
                          child: (index == 0 && otherWallets.isNotEmpty)
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    const Text(
                                      'CONTI ATTIVI',
                                      style: TextStyle(
                                        color: Colors.white38,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    ...otherWallets.take(2).map((w) => Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              width: 6,
                                              height: 6,
                                              decoration: const BoxDecoration(
                                                color: Color(0xFF10B981),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            ConstrainedBox(
                                              constraints: const BoxConstraints(maxWidth: 85),
                                              child: Text(
                                                w.key,
                                                style: const TextStyle(color: Colors.white70, fontSize: 11),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          '€${w.value.toStringAsFixed(0)}',
                                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    )),
                                  ],
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'QUOTA SUL TOTALE',
                                          style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                                        ),
                                        Text(
                                          totalLiquidity > 0 ? '${((item.value / totalLiquidity) * 100).clamp(0, 100).toStringAsFixed(1)}%' : '0%',
                                          style: const TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(3),
                                      child: LinearProgressIndicator(
                                        value: totalLiquidity > 0 ? (item.value / totalLiquidity).clamp(0.0, 1.0) : 0.0,
                                        backgroundColor: Colors.white10,
                                        color: const Color(0xFF10B981),
                                        minHeight: 4,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  );
                }

                if (is1x1) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item.key.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 9.0,
                              letterSpacing: 0.8,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          _buildBalanceAmount(item.value, is1x1: true, isLarge: false, customFontSize: 16.0),
                        ],
                      ),
                    ),
                  );
                }

                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                        _buildBalanceAmount(item.value, is1x1: false, isLarge: is2x2OrLarger),
                        if (is2x2OrLarger) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Builder(
                                builder: (context) {
                                  final now = DateTime.now();
                                  final allExp = ExpenseServiceCached().getAllCachedExpenses();
                                  double mSpent = 0.0;
                                  for (final e in allExp) {
                                    if (e.date.year == now.year && e.date.month == now.month) {
                                      mSpent += e.amount;
                                    }
                                  }
                                  if (mSpent <= 0) return const SizedBox.shrink();
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 6.0),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEF4444).withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(7),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.arrow_downward_rounded, size: 10, color: Color(0xFFEF4444)),
                                          const SizedBox(width: 3),
                                          Text(
                                            '-€${mSpent.toStringAsFixed(0)}',
                                            style: const TextStyle(
                                              color: Color(0xFFEF4444),
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(7),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.swipe_rounded, size: 10, color: Colors.white38),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${index + 1} di ${_balancesList.length}',
                                      style: const TextStyle(color: Colors.white38, fontSize: 9.5),
                                    ),
                                  ],
                                ),
                              ),
                            ],
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

  Widget _buildBalanceAmount(double balance, {bool is1x1 = false, bool isLarge = false, double? customFontSize}) {
    final formatter = NumberFormat.currency(locale: 'it_IT', symbol: '€');
    final isPositive = balance >= 0;
    final color = isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final sign = isPositive ? '+' : '';

    final double fontSize = customFontSize ?? (is1x1 ? 16.0 : (isLarge ? 26.0 : 21.0));

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
