import 'package:flutter/material.dart';
import 'package:solducci/features/investments/views/asset_detail_view.dart';
import 'package:solducci/models/asset_class.dart';
import 'package:solducci/service/income_service.dart';
import 'package:solducci/service/investment_asset_service.dart';
import 'package:solducci/service/investment_portfolio_service.dart';
import 'package:solducci/theme/app_theme.dart';
import 'package:solducci/widgets/neon_wave_graph.dart';
import 'package:solducci/widgets/solducci_app_bar.dart';

class InvestmentsHubView extends StatefulWidget {
  const InvestmentsHubView({super.key});

  @override
  State<InvestmentsHubView> createState() => _InvestmentsHubViewState();
}

class _InvestmentsHubViewState extends State<InvestmentsHubView> {
  final _portfolioService = InvestmentPortfolioService();
  final _assetService = InvestmentAssetService();
  Map<AssetClass, double> _targetAllocation = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _portfolioService.fetchPortfolios();
    await _assetService.fetchAllAssets();
    _targetAllocation = await _portfolioService.getTargetAllocation();
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
    final editionCtrl = TextEditingController();
    final gradingCtrl = TextEditingController();
    final storageCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    final buyPriceCtrl = TextEditingController();
    final currentPriceCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    AssetClass selectedClass = AssetClass.etf;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final isPhys = selectedClass.isPhysical;

          return Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF18181B),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isPhys ? 'Nuovo Bene / Oggetto da Collezione' : 'Nuovo Asset nel Portafoglio',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Icon(isPhys ? Icons.style_rounded : Icons.trending_up_rounded, color: const Color(0xFF818CF8)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isPhys
                        ? 'Registra una carta, orologio o bene materiale con quantità e stima'
                        : 'Aggiungi quote di ETF, azioni o crypto al tuo portafoglio',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 16),

                  // Selettore Classe Asset
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF27272A),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<AssetClass>(
                        value: selectedClass,
                        dropdownColor: const Color(0xFF27272A),
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70),
                        items: AssetClass.values.map((ac) {
                          return DropdownMenuItem<AssetClass>(
                            value: ac,
                            child: Row(
                              children: [
                                Icon(ac.icon, size: 16, color: ac.color),
                                const SizedBox(width: 8),
                                Text(ac.label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (newClass) {
                          if (newClass != null) {
                            setSheetState(() => selectedClass = newClass);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Nome Asset
                  TextField(
                    controller: nameCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: isPhys ? 'Nome Oggetto / Carta' : 'Nome Asset / Titolo',
                      labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
                      hintText: isPhys ? 'Es. Charizard 1st Edition, Rolex Submariner...' : 'Es. Vanguard All-World, Bitcoin...',
                      hintStyle: const TextStyle(color: Colors.white24),
                      filled: true,
                      fillColor: const Color(0xFF27272A),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                  ),

                  if (isPhys) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: editionCtrl,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Edizione / Set / Anno',
                              labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
                              hintText: 'Es. Set Base 1999',
                              hintStyle: const TextStyle(color: Colors.white24),
                              filled: true,
                              fillColor: const Color(0xFF27272A),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: gradingCtrl,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Grado / Condizione',
                              labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
                              hintText: 'Es. PSA 10, Raw NM',
                              hintStyle: const TextStyle(color: Colors.white24),
                              filled: true,
                              fillColor: const Color(0xFF27272A),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['PSA 10', 'PSA 9', 'BGS 9.5', 'Near Mint', 'Mint', 'Raw', 'Full Set'].map((chip) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ActionChip(
                              label: Text(chip, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                              backgroundColor: const Color(0xFF27272A),
                              side: const BorderSide(color: Colors.white10),
                              padding: EdgeInsets.zero,
                              onPressed: () {
                                setSheetState(() => gradingCtrl.text = chip);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 10),
                    TextField(
                      controller: tickerCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Ticker / Simbolo (opzionale)',
                        labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
                        hintText: 'Es. VWCE, BTC, AAPL...',
                        hintStyle: const TextStyle(color: Colors.white24),
                        filled: true,
                        fillColor: const Color(0xFF27272A),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),
                  // Quantità, Prezzo d'acquisto e Stima Valore Attuale
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: qtyCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: isPhys ? 'Pezzi / Qtà' : 'Quote / Qtà',
                            labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
                            hintText: '1',
                            hintStyle: const TextStyle(color: Colors.white24),
                            filled: true,
                            fillColor: const Color(0xFF27272A),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: buyPriceCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Costo Totale (€)',
                            labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
                            hintText: '0.00',
                            hintStyle: const TextStyle(color: Colors.white24),
                            filled: true,
                            fillColor: const Color(0xFF27272A),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: currentPriceCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Stima Unitaria (€)',
                            labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
                            hintText: '0.00',
                            hintStyle: const TextStyle(color: Colors.white24),
                            filled: true,
                            fillColor: const Color(0xFF27272A),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (isPhys) ...[
                    const SizedBox(height: 10),
                    TextField(
                      controller: storageCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Luogo di Custodia (opzionale)',
                        labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
                        hintText: 'Es. Raccoglitore Toploader, Cassaforte...',
                        hintStyle: const TextStyle(color: Colors.white24),
                        filled: true,
                        fillColor: const Color(0xFF27272A),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      ),
                    ),
                  ],

                  const SizedBox(height: 10),
                  TextField(
                    controller: noteCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Note aggiuntive (opzionale)',
                      labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
                      hintText: 'Es. Acquistata da privato, numero certificato...',
                      hintStyle: const TextStyle(color: Colors.white24),
                      filled: true,
                      fillColor: const Color(0xFF27272A),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                  ),

                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        final name = nameCtrl.text.trim();
                        if (name.isEmpty) return;

                        final qty = double.tryParse(qtyCtrl.text.replaceAll(',', '.').trim()) ?? (isPhys ? 1.0 : 0.0);
                        final capital = double.tryParse(buyPriceCtrl.text.replaceAll(',', '.').trim()) ?? 0.0;
                        final currentP = double.tryParse(currentPriceCtrl.text.replaceAll(',', '.').trim()) ?? (qty > 0 && capital > 0 ? capital / qty : 0.0);

                        Navigator.pop(ctx);
                        await _assetService.createAsset(
                          portfolioId: portfolioId,
                          name: name,
                          ticker: tickerCtrl.text.trim().isNotEmpty ? tickerCtrl.text.trim() : null,
                          assetClass: selectedClass,
                          initialQuantity: qty,
                          initialCapital: capital,
                          currentPrice: currentP,
                          editionOrSet: editionCtrl.text.trim().isNotEmpty ? editionCtrl.text.trim() : null,
                          conditionOrGrading: gradingCtrl.text.trim().isNotEmpty ? gradingCtrl.text.trim() : null,
                          storageLocation: storageCtrl.text.trim().isNotEmpty ? storageCtrl.text.trim() : null,
                          note: noteCtrl.text.trim().isNotEmpty ? noteCtrl.text.trim() : null,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Salva Asset nel Portafoglio', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showTargetAllocationSheet(BuildContext context) {
    final tempTargets = Map<AssetClass, double>.from(_targetAllocation);
    for (final ac in AssetClass.values) {
      tempTargets.putIfAbsent(ac, () => 0.0);
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final totalTarget = tempTargets.values.fold<double>(0.0, (s, v) => s + v);
          final isValid = (totalTarget - 100.0).abs() <= 1.0;

          return Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF18181B),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Target Asset Allocation',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isValid ? AppTheme.success.withOpacity(0.15) : AppTheme.error.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isValid ? AppTheme.success.withOpacity(0.4) : AppTheme.error.withOpacity(0.4)),
                        ),
                        child: Text(
                          'Totale: ${totalTarget.toStringAsFixed(0)}%',
                          style: TextStyle(
                            color: isValid ? AppTheme.success : AppTheme.error,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Imposta le percentuali obiettivo del tuo portafoglio. Solducci ti suggerirà come riequilibrare gli asset nei prossimi acquisti o PAC.',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 14),

                  // Presets veloci
                  Row(
                    children: [
                      ActionChip(
                        label: const Text('Bilanciato (60/20/10/10)', style: TextStyle(fontSize: 11)),
                        backgroundColor: const Color(0xFF27272A),
                        side: BorderSide.none,
                        onPressed: () {
                          setSheetState(() {
                            for (final ac in AssetClass.values) {
                              tempTargets[ac] = 0.0;
                            }
                            tempTargets[AssetClass.etf] = 60.0;
                            tempTargets[AssetClass.bond] = 20.0;
                            tempTargets[AssetClass.stock] = 10.0;
                            tempTargets[AssetClass.crypto] = 10.0;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      ActionChip(
                        label: const Text('100% ETF', style: TextStyle(fontSize: 11)),
                        backgroundColor: const Color(0xFF27272A),
                        side: BorderSide.none,
                        onPressed: () {
                          setSheetState(() {
                            for (final ac in AssetClass.values) {
                              tempTargets[ac] = 0.0;
                            }
                            tempTargets[AssetClass.etf] = 100.0;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Sliders per ogni classe
                  ...AssetClass.values.map((ac) {
                    final val = tempTargets[ac] ?? 0.0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(ac.icon, size: 16, color: ac.color),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 100,
                            child: Text(
                              ac.label,
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Expanded(
                            child: Slider(
                              value: val.clamp(0.0, 100.0),
                              min: 0,
                              max: 100,
                              divisions: 20,
                              activeColor: ac.color,
                              inactiveColor: Colors.white12,
                              onChanged: (newVal) {
                                setSheetState(() {
                                  tempTargets[ac] = newVal;
                                });
                              },
                            ),
                          ),
                          SizedBox(
                            width: 44,
                            child: Text(
                              '${val.toStringAsFixed(0)}%',
                              textAlign: TextAlign.end,
                              style: TextStyle(color: ac.color, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await _portfolioService.saveTargetAllocation(tempTargets);
                        setState(() {
                          _targetAllocation = tempTargets;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Salva Obiettivi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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

        // Storico e dividendi
        final wavePoints = _portfolioService.getHistoricalPerformancePoints();
        final totalDividends = IncomeService().cachedIncomes
            .where((i) => i.portfolioId != null || i.assetId != null)
            .fold<double>(0.0, (sum, i) => sum + i.amount);
        final totalReturn = pnl + totalDividends;
        final totalReturnRoi = investedCapital > 0 ? (totalReturn / investedCapital) * 100 : 0.0;
        final rebalanceMsg = _portfolioService.getRebalancingSuggestion(_targetAllocation);

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
                icon: const Icon(Icons.tune_rounded, color: Color(0xFF818CF8)),
                tooltip: 'Target Allocation',
                onPressed: () => _showTargetAllocationSheet(context),
              ),
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
                        // 1. Hero Card Patrimonio Investito con NeonWaveGraph
                        Container(
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: const Color(0xFF18181B),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: Opacity(
                                  opacity: 0.5,
                                  child: NeonWaveGraph(
                                    color: pnlColor,
                                    dataPoints: wavePoints,
                                    height: 220,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(20),
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
                                            color: pnlColor.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: pnlColor.withOpacity(0.4)),
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
                                    if (totalDividends > 0) ...[
                                      const SizedBox(height: 12),
                                      const Divider(color: Colors.white10, height: 1),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text('Cedole / Dividendi', style: TextStyle(color: Colors.white38, fontSize: 11)),
                                              const SizedBox(height: 2),
                                              Text('+€ ${totalDividends.toStringAsFixed(2)}', style: const TextStyle(color: AppTheme.success, fontSize: 13, fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                          const SizedBox(width: 24),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text('Total Return', style: TextStyle(color: Colors.white38, fontSize: 11)),
                                              const SizedBox(height: 2),
                                              Text(
                                                '${totalReturn >= 0 ? '+' : ''}€ ${totalReturn.toStringAsFixed(2)} (${totalReturnRoi >= 0 ? '+' : ''}${totalReturnRoi.toStringAsFixed(1)}%)',
                                                style: TextStyle(color: totalReturn >= 0 ? AppTheme.success : AppTheme.error, fontSize: 13, fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
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
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'ASSET ALLOCATION',
                                      style: TextStyle(color: Colors.white38, fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.bold),
                                    ),
                                    InkWell(
                                      onTap: () => _showTargetAllocationSheet(context),
                                      borderRadius: BorderRadius.circular(8),
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        child: Row(
                                          children: [
                                            Icon(Icons.tune_rounded, size: 13, color: Color(0xFF818CF8)),
                                            SizedBox(width: 4),
                                            Text('Obiettivi Target', style: TextStyle(color: Color(0xFF818CF8), fontSize: 11, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
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

                                // Legenda con confronto Target
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 8,
                                  children: allocationMap.entries.map((entry) {
                                    final pct = (entry.value / totalValue) * 100;
                                    final targetPct = _targetAllocation[entry.key];
                                    final targetStr = targetPct != null && targetPct > 0 ? ' (tgt ${targetPct.toStringAsFixed(0)}%)' : '';
                                    return Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(width: 8, height: 8, decoration: BoxDecoration(color: entry.key.color, shape: BoxShape.circle)),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${entry.key.label} ${pct.toStringAsFixed(0)}%$targetStr',
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

                        // Rebalancing Guidance Banner (se presente)
                        if (rebalanceMsg != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF6366F1).withOpacity(0.15),
                                  const Color(0xFF10B981).withOpacity(0.08),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6366F1).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.auto_graph_rounded, color: Color(0xFF818CF8), size: 16),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'CONSIGLIO RIBILANCIAMENTO',
                                        style: TextStyle(color: Color(0xFF818CF8), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        rebalanceMsg,
                                        style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.3),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                TextButton(
                                  onPressed: () => _showTargetAllocationSheet(context),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text('Target', style: TextStyle(color: Color(0xFF818CF8), fontSize: 11, fontWeight: FontWeight.bold)),
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
                                                      '${asset.conditionOrGrading != null && asset.conditionOrGrading!.isNotEmpty ? "${asset.conditionOrGrading} • " : ""}${asset.formattedQuantity} ${asset.quantityUnitLabel} • €${asset.currentPrice.toStringAsFixed(2)}',
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
