import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:solducci/models/dashboard_config.dart';
import 'package:solducci/service/context_manager.dart';
import 'package:solducci/service/investment_portfolio_service.dart';
import 'package:solducci/service/investment_asset_service.dart';
import 'package:solducci/widgets/dashboard/bento_widget_container.dart';

class InvestmentSummaryWidget extends StatefulWidget {
  final BentoWidgetDef def;

  const InvestmentSummaryWidget({super.key, required this.def});

  @override
  State<InvestmentSummaryWidget> createState() => _InvestmentSummaryWidgetState();
}

class _InvestmentSummaryWidgetState extends State<InvestmentSummaryWidget> {
  final _portfolioService = InvestmentPortfolioService();
  final _assetService = InvestmentAssetService();
  final _contextManager = ContextManager();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final context = _contextManager.currentContext;
    try {
      await _portfolioService.fetchPortfolios(groupId: context.isGroup ? context.groupId : null);
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
    final currencyFormatter = NumberFormat.currency(locale: 'it_IT', symbol: '€');

    return AnimatedBuilder(
      animation: Listenable.merge([_portfolioService, _assetService]),
      builder: (context, _) {
        final totalValue = _portfolioService.getTotalCurrentValue();
        final unrealizedPnl = _portfolioService.getTotalUnrealizedPnl();
        final roiPercent = _portfolioService.getTotalRoiPercent();
        final isPositive = unrealizedPnl >= 0;
        final pnlColor = isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444);

        return BentoWidgetContainer(
          heroTag: widget.def.id,
          isLoading: _isLoading,
          onExpand: () {
            GoRouter.of(context).push('/investments');
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  // Subtle ambient glow in bottom right
                  Positioned(
                    bottom: -30,
                    right: -30,
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: pnlColor.withOpacity(0.12),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
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
                                const Text(
                                  'PORTAFOGLIO',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.8,
                                  ),
                                ),
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

                        // Mini progress/footer info
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${_portfolioService.currentPortfolios.length} ${_portfolioService.currentPortfolios.length == 1 ? 'conto' : 'conti'} attivi',
                              style: const TextStyle(color: Colors.white38, fontSize: 10),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 10),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
