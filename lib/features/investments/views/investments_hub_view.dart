import 'package:flutter/material.dart';
import 'package:solducci/features/investments/views/asset_detail_view.dart';
import 'package:solducci/models/asset_class.dart';
import 'package:solducci/service/investment_asset_service.dart';
import 'package:solducci/service/investment_portfolio_service.dart';
import 'package:solducci/theme/app_theme.dart';
import 'package:solducci/widgets/solducci_app_bar.dart';

class InvestmentsHubView extends StatefulWidget {
  const InvestmentsHubView({super.key});

  @override
  State<InvestmentsHubView> createState() => _InvestmentsHubViewState();
}

class _InvestmentsHubViewState extends State<InvestmentsHubView> {
  final _portfolioService = InvestmentPortfolioService();
  final _assetService = InvestmentAssetService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _portfolioService.fetchPortfolios();
    await _assetService.fetchAllAssets();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _showCreatePortfolioDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final brokerCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Nuovo Portafoglio Investimenti', style: TextStyle(color: Colors.white, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Nome (es. PAC ETF, Crypto Ledger...)',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF27272A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: brokerCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Broker / Piattaforma (es. Degiro, Binance...)',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF27272A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annulla', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(ctx);
                await _portfolioService.createPortfolio(
                  name: name,
                  brokerName: brokerCtrl.text.trim().isNotEmpty ? brokerCtrl.text.trim() : null,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Crea', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showCreateAssetDialog(BuildContext context, String portfolioId) {
    final nameCtrl = TextEditingController();
    final tickerCtrl = TextEditingController();
    AssetClass selectedClass = AssetClass.etf;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E22),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Nuovo Asset nel Portafoglio', style: TextStyle(color: Colors.white, fontSize: 18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Nome (es. Vanguard All-World, Bitcoin...)',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: const Color(0xFF27272A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: tickerCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Ticker / Simbolo opzionale (es. VWCE, BTC...)',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: const Color(0xFF27272A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonHideUnderline(
                child: DropdownButton<AssetClass>(
                  value: selectedClass,
                  dropdownColor: const Color(0xFF27272A),
                  isExpanded: true,
                  items: AssetClass.values.map((ac) {
                    return DropdownMenuItem<AssetClass>(
                      value: ac,
                      child: Row(
                        children: [
                          Icon(ac.icon, size: 16, color: ac.color),
                          const SizedBox(width: 8),
                          Text(ac.label, style: const TextStyle(color: Colors.white, fontSize: 13)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (newClass) {
                    if (newClass != null) {
                      setDialogState(() => selectedClass = newClass);
                    }
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annulla', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isNotEmpty) {
                  Navigator.pop(ctx);
                  await _assetService.createAsset(
                    portfolioId: portfolioId,
                    name: name,
                    ticker: tickerCtrl.text.trim().isNotEmpty ? tickerCtrl.text.trim() : null,
                    assetClass: selectedClass,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Aggiungi', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_portfolioService, _assetService]),
      builder: (context, _) {
        final portfolios = _portfolioService.currentPortfolios;
        final totalValue = _portfolioService.getTotalCurrentValue();
        final investedCapital = _portfolioService.getTotalInvestedCapital();
        final pnl = _portfolioService.getTotalUnrealizedPnl();
        final roi = _portfolioService.getTotalRoiPercent();
        final isProfitable = pnl >= 0;
        final pnlColor = isProfitable ? AppTheme.success : AppTheme.error;

        // Ripartizione per Asset Class per l'Allocation bar
        final allAssets = _assetService.currentAssets;
        final allocationMap = <AssetClass, double>{};
        for (final a in allAssets) {
          allocationMap[a.assetClass] = (allocationMap[a.assetClass] ?? 0.0) + a.currentValue;
        }

        return Scaffold(
          backgroundColor: const Color(0xFF0F0F12),
          appBar: SolducciAppBar(
            titleText: 'Investimenti & Asset',
            actions: [
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF818CF8)),
                tooltip: 'Nuovo Portafoglio',
                onPressed: () => _showCreatePortfolioDialog(context),
              ),
            ],
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: const Color(0xFF6366F1),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Hero Card Patrimonio Investito
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF18181B),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'CONTROVALORE TOTALE INVESTITO',
                                    style: TextStyle(
                                      color: Colors.white38,
                                      fontSize: 11,
                                      letterSpacing: 1.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: pnlColor.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: pnlColor.withOpacity(0.3)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(isProfitable ? Icons.trending_up_rounded : Icons.trending_down_rounded, size: 14, color: pnlColor),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${isProfitable ? '+' : ''}${roi.toStringAsFixed(1)}%',
                                          style: TextStyle(color: pnlColor, fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '€ ${totalValue.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Capitale Versato', style: TextStyle(color: Colors.white38, fontSize: 11)),
                                      const SizedBox(height: 2),
                                      Text('€ ${investedCapital.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  const SizedBox(width: 24),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Plusvalenza Netta', style: TextStyle(color: Colors.white38, fontSize: 11)),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${isProfitable ? '+' : ''}€ ${pnl.toStringAsFixed(2)}',
                                        style: TextStyle(color: pnlColor, fontSize: 14, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // 2. Asset Allocation Breakdown Bar
                        if (totalValue > 0 && allocationMap.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF18181B),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'ASSET ALLOCATION',
                                  style: TextStyle(color: Colors.white38, fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 12),

                                // Barra segmentata
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: SizedBox(
                                    height: 12,
                                    child: Row(
                                      children: allocationMap.entries.map((entry) {
                                        final fraction = entry.value / totalValue;
                                        return Flexible(
                                          flex: (fraction * 100).round().clamp(1, 100),
                                          child: Container(color: entry.key.color),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 12),

                                // Legenda
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 8,
                                  children: allocationMap.entries.map((entry) {
                                    final pct = (entry.value / totalValue) * 100;
                                    return Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(width: 8, height: 8, decoration: BoxDecoration(color: entry.key.color, shape: BoxShape.circle)),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${entry.key.label} (${pct.toStringAsFixed(0)}%)',
                                          style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        // 3. Intestazione Sezione Portafogli
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'I TUOI PORTAFOGLI',
                              style: TextStyle(fontSize: 12, letterSpacing: 1.2, fontWeight: FontWeight.bold, color: Colors.white38),
                            ),
                            InkWell(
                              onTap: () => _showCreatePortfolioDialog(context),
                              borderRadius: BorderRadius.circular(8),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                child: Text('+ Portafoglio', style: TextStyle(color: Color(0xFF818CF8), fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // 4. Lista dei Portafogli ed Asset
                        if (portfolios.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: const Color(0xFF18181B),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white10),
                            ),
                            alignment: Alignment.center,
                            child: Column(
                              children: [
                                const Icon(Icons.account_balance_wallet_outlined, size: 36, color: Colors.white24),
                                const SizedBox(height: 10),
                                const Text('Nessun portafoglio investimenti creato.', style: TextStyle(color: Colors.white54, fontSize: 14)),
                                const SizedBox(height: 14),
                                ElevatedButton.icon(
                                  onPressed: () => _showCreatePortfolioDialog(context),
                                  icon: const Icon(Icons.add, size: 16),
                                  label: const Text('Crea Primo Portafoglio'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF6366F1),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ...portfolios.map((portfolio) {
                            final assets = _assetService.getAssetsForPortfolio(portfolio.id);
                            final portValue = assets.fold(0.0, (s, a) => s + a.currentValue);
                            final portCapital = assets.fold(0.0, (s, a) => s + a.investedCapital);
                            final portPnl = portValue - portCapital;
                            final portProfitable = portPnl >= 0;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF18181B),
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(color: Colors.white10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Intestazione Portafoglio
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: portfolio.color.withOpacity(0.18),
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                          child: Icon(portfolio.iconData, size: 20, color: portfolio.color),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                portfolio.name,
                                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                portfolio.brokerName ?? (portfolio.isShared ? 'Condiviso' : 'Personale'),
                                                style: const TextStyle(color: Colors.white38, fontSize: 12),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              '€ ${portValue.toStringAsFixed(2)}',
                                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                                            ),
                                            if (portCapital > 0)
                                              Text(
                                                '${portProfitable ? '+' : ''}€${portPnl.toStringAsFixed(0)}',
                                                style: TextStyle(
                                                  color: portProfitable ? AppTheme.success : AppTheme.error,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Lista Asset all'interno del Portafoglio
                                  if (assets.isNotEmpty) ...[
                                    const Divider(color: Colors.white10, height: 1),
                                    ...assets.map((asset) {
                                      final aProfit = asset.isProfitable;
                                      return InkWell(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => AssetDetailView(asset: asset),
                                            ),
                                          );
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          child: Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 14,
                                                backgroundColor: asset.assetClass.color.withOpacity(0.15),
                                                child: Icon(asset.assetClass.icon, size: 14, color: asset.assetClass.color),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      asset.name,
                                                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      '${asset.totalQuantity} quote • €${asset.currentPrice.toStringAsFixed(2)}',
                                                      style: const TextStyle(color: Colors.white38, fontSize: 11),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    '€ ${asset.currentValue.toStringAsFixed(2)}',
                                                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                                  ),
                                                  if (asset.investedCapital > 0)
                                                    Text(
                                                      '${aProfit ? '+' : ''}${asset.roiPercent.toStringAsFixed(1)}%',
                                                      style: TextStyle(
                                                        color: aProfit ? AppTheme.success : AppTheme.error,
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(width: 4),
                                              const Icon(Icons.chevron_right_rounded, color: Colors.white24, size: 18),
                                            ],
                                          ),
                                        ),
                                      );
                                    }),
                                  ],

                                  // Tasto rapido aggiungi asset al portafoglio
                                  const Divider(color: Colors.white10, height: 1),
                                  InkWell(
                                    onTap: () => _showCreateAssetDialog(context, portfolio.id),
                                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(22)),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      alignment: Alignment.center,
                                      child: const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.add, size: 15, color: Color(0xFF818CF8)),
                                          SizedBox(width: 6),
                                          Text(
                                            'Aggiungi Asset al Portafoglio',
                                            style: TextStyle(color: Color(0xFF818CF8), fontSize: 13, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }
}
