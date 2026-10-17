import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:solducci/models/dashboard_config.dart';
import 'package:solducci/service/investment_portfolio_service.dart';
import 'package:solducci/service/investment_asset_service.dart';
import 'package:solducci/widgets/dashboard/bento_widget_container.dart';
import 'package:solducci/widgets/dashboard/context/dashboard_context_scope.dart';

class InvestmentSummaryWidget extends StatefulWidget {
  final BentoWidgetDef def;

  const InvestmentSummaryWidget({super.key, required this.def});

  @override
  State<InvestmentSummaryWidget> createState() => _InvestmentSummaryWidgetState();
}

class _InvestmentSource {
  final String title;
  final String? portfolioId;
  final Color? color;
  _InvestmentSource({required this.title, this.portfolioId, this.color});
}

class _InvestmentSummaryWidgetState extends State<InvestmentSummaryWidget> {
  final _portfolioService = InvestmentPortfolioService();
  final _assetService = InvestmentAssetService();

  bool _isLoading = true;
  ExpenseContext? _lastContext;
  int _currentPortfolioIndex = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentContext = DashboardContextScope.of(context);
    if (_lastContext != currentContext) {
      _lastContext = currentContext;
      _fetchData(currentContext);
    }
  }

  Future<void> _fetchData(ExpenseContext ctx) async {
    try {
      await _portfolioService.fetchPortfoliosForContext(ctx);
      await _assetService.fetchAllAssets();
    } catch (_) {}

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentContext = DashboardContextScope.of(context);
    final currencyFormatter = NumberFormat.currency(locale: 'it_IT', symbol: '€');

    return AnimatedBuilder(
      animation: Listenable.merge([_portfolioService, _assetService]),
      builder: (context, _) {
        final selectedSourceIds = (widget.def.customProps?['selectedSourceIds'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toSet() ??
            {};
        final targetPortfolioId = widget.def.customProps?['portfolioId'] as String?;

        final List<_InvestmentSource> sources = [];
        final portfolios = _portfolioService.currentPortfolios;

        if (selectedSourceIds.isNotEmpty) {
          if (selectedSourceIds.contains('all')) {
            sources.add(_InvestmentSource(title: 'Patrimonio', portfolioId: null));
          }
          for (final p in portfolios) {
            if (selectedSourceIds.contains('portfolio_${p.id}') || selectedSourceIds.contains(p.id)) {
              sources.add(_InvestmentSource(title: p.name, portfolioId: p.id, color: p.color));
            }
          }
        } else if (targetPortfolioId != null) {
          final match = portfolios.where((p) => p.id == targetPortfolioId).firstOrNull;
          sources.add(_InvestmentSource(
            title: match?.name ?? 'Portafoglio',
            portfolioId: targetPortfolioId,
            color: match?.color,
          ));
        } else {
          sources.add(_InvestmentSource(title: 'Patrimonio', portfolioId: null));
          for (final p in portfolios) {
            sources.add(_InvestmentSource(title: p.name, portfolioId: p.id, color: p.color));
          }
        }

        if (sources.isEmpty) {
          sources.add(_InvestmentSource(title: 'Patrimonio', portfolioId: null));
        }

        final safeIndex = _currentPortfolioIndex.clamp(0, sources.length - 1);
        final activeSource = sources[safeIndex];

        void nextPortfolio() {
          if (sources.length <= 1) return;
          setState(() {
            _currentPortfolioIndex = (_currentPortfolioIndex + 1) % sources.length;
          });
        }

        void previousPortfolio() {
          if (sources.length <= 1) return;
          setState(() {
            _currentPortfolioIndex = (_currentPortfolioIndex - 1 + sources.length) % sources.length;
          });
        }

        double totalValue;
        double unrealizedPnl;
        double roiPercent;

        if (activeSource.portfolioId != null) {
          final assets = _assetService.getAssetsForPortfolio(activeSource.portfolioId!);
          totalValue = assets.fold(0.0, (sum, a) => sum + a.currentValue);
          final invested = assets.fold(0.0, (sum, a) => sum + a.investedCapital);
          unrealizedPnl = totalValue - invested;
          roiPercent = invested > 0 ? (unrealizedPnl / invested) * 100 : 0.0;
        } else {
          final contextAssets = _assetService.getAssetsForContext(currentContext);
          totalValue = contextAssets.fold(0.0, (sum, a) => sum + a.currentValue);
          final invested = contextAssets.fold(0.0, (sum, a) => sum + a.investedCapital);
          unrealizedPnl = totalValue - invested;
          roiPercent = invested > 0 ? (unrealizedPnl / invested) * 100 : 0.0;
        }

        final isPositive = unrealizedPnl >= 0;
        final pnlColor = isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444);

        final isHeight1 = widget.def.size.mainAxisCellCount <= 1;

        return BentoWidgetContainer(
          heroTag: widget.def.id,
          size: widget.def.size,
          isLoading: _isLoading,
          onTap: () {
            GoRouter.of(context).push('/investments');
          },
          onExpand: () {
            GoRouter.of(context).push('/investments');
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity != null) {
                if (details.primaryVelocity! < -150) {
                  nextPortfolio();
                } else if (details.primaryVelocity! > 150) {
                  previousPortfolio();
                }
              }
            },
            child: isHeight1
                ? Padding(
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
                                color: (activeSource.color ?? const Color(0xFF6366F1)).withOpacity(0.18),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.trending_up_rounded,
                                color: activeSource.color ?? const Color(0xFF818CF8),
                                size: 13,
                              ),
                            ),
                            const SizedBox(width: 8),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 110),
                              child: Text(
                                activeSource.title.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.6,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (sources.length > 1) ...[
                              const SizedBox(width: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${safeIndex + 1}/${sources.length}',
                                  style: TextStyle(
                                    color: activeSource.color ?? const Color(0xFF818CF8),
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              currencyFormatter.format(totalValue),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: pnlColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              '${roiPercent >= 0 ? '+' : ''}${roiPercent.toStringAsFixed(1)}%',
                              style: TextStyle(
                                color: pnlColor,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final isH3 = widget.def.size.mainAxisCellCount == 3;
                    if (isH3) {
                      return Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: _buildH3View(
                          title: activeSource.title,
                          currentIndex: safeIndex,
                          totalSources: sources.length,
                          totalValue: totalValue,
                          unrealizedPnl: unrealizedPnl,
                          roiPercent: roiPercent,
                          isPositive: isPositive,
                          pnlColor: pnlColor,
                          currencyFormatter: currencyFormatter,
                        ),
                      );
                    }

                    final isWide = constraints.maxWidth > 240;

                    return Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: isWide
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // Left: Values & Header
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF6366F1).withOpacity(0.15),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: const Icon(
                                                  Icons.trending_up_rounded,
                                                  color: Color(0xFF818CF8),
                                                  size: 13,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              ConstrainedBox(
                                                constraints: const BoxConstraints(maxWidth: 110),
                                                child: Text(
                                                  activeSource.title.toUpperCase(),
                                                  style: const TextStyle(
                                                    color: Colors.white54,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 0.8,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (sources.length > 1) ...[
                                                const SizedBox(width: 5),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white.withOpacity(0.08),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    '${safeIndex + 1}/${sources.length}',
                                                    style: TextStyle(
                                                      color: activeSource.color ?? const Color(0xFF818CF8),
                                                      fontSize: 8.5,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            currencyFormatter.format(totalValue),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 24,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: -0.5,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              Text(
                                                '${isPositive ? '+' : ''}${currencyFormatter.format(unrealizedPnl)}',
                                                style: TextStyle(
                                                  color: pnlColor,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              const Text(
                                                'non realizzato',
                                                style: TextStyle(color: Colors.white38, fontSize: 10),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    // Right: Performance & Action pill
                                    Expanded(
                                      flex: 2,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                            decoration: BoxDecoration(
                                              color: pnlColor.withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: pnlColor.withOpacity(0.3), width: 1),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  isPositive ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded,
                                                  color: pnlColor,
                                                  size: 16,
                                                ),
                                                Text(
                                                  '${roiPercent >= 0 ? '+' : ''}${roiPercent.toStringAsFixed(1)}% ROI',
                                                  style: TextStyle(
                                                    color: pnlColor,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          GestureDetector(
                                            onTap: () => GoRouter.of(context).push('/investments'),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.06),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    targetPortfolioId != null
                                                        ? 'Conto selezionato'
                                                        : '${_portfolioService.currentPortfolios.length} ${_portfolioService.currentPortfolios.length == 1 ? "conto" : "conti"}',
                                                    style: const TextStyle(color: Colors.white70, fontSize: 10.5),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 9),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Header
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF6366F1).withOpacity(0.15),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Icon(
                                                Icons.trending_up_rounded,
                                                color: Color(0xFF818CF8),
                                                size: 14,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            ConstrainedBox(
                                              constraints: const BoxConstraints(maxWidth: 80),
                                              child: Text(
                                                activeSource.title.toUpperCase(),
                                                style: const TextStyle(
                                                  color: Colors.white54,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 0.8,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (sources.length > 1) ...[
                                              const SizedBox(width: 4),
                                              Text(
                                                '${safeIndex + 1}/${sources.length}',
                                                style: TextStyle(
                                                  color: activeSource.color ?? const Color(0xFF818CF8),
                                                  fontSize: 8.5,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),

                                        // Mini ROI pill
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: pnlColor.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: pnlColor.withOpacity(0.3), width: 1),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                isPositive ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded,
                                                color: pnlColor,
                                                size: 14,
                                              ),
                                              Text(
                                                '${roiPercent >= 0 ? '+' : ''}${roiPercent.toStringAsFixed(1)}%',
                                                style: TextStyle(
                                                  color: pnlColor,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),

                                    // Main Value
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          currencyFormatter.format(totalValue),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 24,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Text(
                                              '${isPositive ? '+' : ''}${currencyFormatter.format(unrealizedPnl)}',
                                              style: TextStyle(
                                                color: pnlColor,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            const Text(
                                              'non realizzato',
                                              style: TextStyle(color: Colors.white38, fontSize: 10),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),

                                    // Mini progress/footer info navigabile
                                    GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () => GoRouter.of(context).push('/investments'),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            targetPortfolioId != null
                                                ? 'Conto singolo selezionato'
                                                : '${_portfolioService.currentPortfolios.length} ${_portfolioService.currentPortfolios.length == 1 ? 'conto' : 'conti'} attivi',
                                            style: const TextStyle(color: Colors.white38, fontSize: 10),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.06),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 10),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            );
          },
        );
  }

  Widget _buildH3View({
    required String title,
    required int currentIndex,
    required int totalSources,
    required double totalValue,
    required double unrealizedPnl,
    required double roiPercent,
    required bool isPositive,
    required Color pnlColor,
    required NumberFormat currencyFormatter,
  }) {
    final portfolios = _portfolioService.currentPortfolios;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.trending_up_rounded,
                    color: Color(0xFF818CF8),
                    size: 14,
                  ),
                ),
                const SizedBox(width: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 120),
                  child: Text(
                    title.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (totalSources > 1) ...[
                  const SizedBox(width: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${currentIndex + 1}/$totalSources',
                      style: const TextStyle(
                        color: Color(0xFF818CF8),
                        fontSize: 8.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: pnlColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: pnlColor.withOpacity(0.3), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPositive ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded,
                    color: pnlColor,
                    size: 14,
                  ),
                  Text(
                    '${roiPercent >= 0 ? '+' : ''}${roiPercent.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: pnlColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Livello 1: Valore Complessivo & PnL
        Text(
          currencyFormatter.format(totalValue),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Text(
              '${isPositive ? '+' : ''}${currencyFormatter.format(unrealizedPnl)}',
              style: TextStyle(
                color: pnlColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              'non realizzato',
              style: TextStyle(color: Colors.white38, fontSize: 10),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Livello 2: Portafogli Attivi a Confronto
        Expanded(
          child: portfolios.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF27272A).withOpacity(0.4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: const Text('Nessun portafoglio attivo', style: TextStyle(color: Colors.white38, fontSize: 10.5)),
                )
              : ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: portfolios.length > 2 ? 2 : portfolios.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 5),
                  itemBuilder: (context, index) {
                    final p = portfolios[index];
                    final pAssets = _assetService.getAssetsForPortfolio(p.id);
                    final pVal = pAssets.fold(0.0, (s, a) => s + a.currentValue);
                    final share = totalValue > 0 ? (pVal / totalValue).clamp(0.0, 1.0) : 0.0;

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF27272A).withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.name,
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${(share * 100).toInt()}% del totale',
                                  style: const TextStyle(color: Colors.white38, fontSize: 9),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            currencyFormatter.format(pVal),
                            style: const TextStyle(color: Colors.white70, fontSize: 11.5, fontWeight: FontWeight.bold),
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
