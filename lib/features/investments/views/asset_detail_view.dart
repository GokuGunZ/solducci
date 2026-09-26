import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:solducci/models/investment_asset.dart';
import 'package:solducci/models/asset_price_snapshot.dart';
import 'package:solducci/service/investment_asset_service.dart';
import 'package:solducci/theme/app_theme.dart';
import 'package:solducci/widgets/solducci_app_bar.dart';

class AssetDetailView extends StatefulWidget {
  final InvestmentAsset asset;

  const AssetDetailView({
    super.key,
    required this.asset,
  });

  @override
  State<AssetDetailView> createState() => _AssetDetailViewState();
}

class _AssetDetailViewState extends State<AssetDetailView> {
  late InvestmentAsset _asset;
  List<AssetPriceSnapshot> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _asset = widget.asset;
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final list = await InvestmentAssetService().fetchPriceHistory(_asset.id);
    if (mounted) {
      setState(() {
        _history = list;
        _isLoading = false;
      });
    }
  }

  void _showUpdatePriceDialog() {
    final priceCtrl = TextEditingController(text: _asset.currentPrice > 0 ? _asset.currentPrice.toStringAsFixed(2) : '');
    final noteCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Aggiorna Quotazione', style: TextStyle(color: Colors.white, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Prezzo attuale di 1 quota di ${_asset.name}:',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceCtrl,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                prefixText: '€ ',
                prefixStyle: const TextStyle(color: Color(0xFF818CF8), fontSize: 18, fontWeight: FontWeight.bold),
                hintText: '0.00',
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: const Color(0xFF27272A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: noteCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Nota opzionale (es. Rilevazione fine mese)...',
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
              final clean = priceCtrl.text.replaceAll(',', '.').trim();
              final p = double.tryParse(clean);
              if (p != null && p > 0) {
                Navigator.pop(ctx);
                await InvestmentAssetService().updateAssetPrice(
                  assetId: _asset.id,
                  newPrice: p,
                  note: noteCtrl.text.trim().isNotEmpty ? noteCtrl.text.trim() : null,
                  source: 'manual',
                );
                setState(() {
                  _asset = _asset.copyWith(
                    currentPrice: p,
                    lastPriceUpdate: DateTime.now(),
                  );
                });
                _loadHistory();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Salva', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isProfitable = _asset.isProfitable;
    final pnlColor = isProfitable ? AppTheme.success : AppTheme.error;
    final lastUpdateStr = DateFormat('dd MMM yyyy, HH:mm', 'it_IT').format(_asset.lastPriceUpdate);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F12),
      appBar: SolducciAppBar(
        titleText: _asset.name,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_calendar_rounded, color: Color(0xFF818CF8)),
            tooltip: 'Aggiorna Prezzo',
            onPressed: _showUpdatePriceDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Hero Card Asset
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _asset.assetClass.color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _asset.assetClass.color.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_asset.assetClass.icon, size: 14, color: _asset.assetClass.color),
                            const SizedBox(width: 6),
                            Text(
                              _asset.assetClass.label,
                              style: TextStyle(color: _asset.assetClass.color, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      if (_asset.ticker != null)
                        Text(
                          _asset.ticker!,
                          style: const TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  const Text('CONTROVALORE TOTALE', style: TextStyle(color: Colors.white38, fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    '€ ${_asset.currentValue.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
                  ),

                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: pnlColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: pnlColor.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(isProfitable ? Icons.trending_up_rounded : Icons.trending_down_rounded, size: 14, color: pnlColor),
                            const SizedBox(width: 4),
                            Text(
                              '${isProfitable ? '+' : ''}€ ${_asset.unrealizedPnl.toStringAsFixed(2)} (${isProfitable ? '+' : ''}${_asset.roiPercent.toStringAsFixed(1)}%)',
                              style: TextStyle(color: pnlColor, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Agg: $lastUpdateStr',
                        style: const TextStyle(color: Colors.white30, fontSize: 11),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),
                  const Divider(color: Colors.white10, height: 1),
                  const SizedBox(height: 14),

                  // Statistiche Quote e Prezzo Medio
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Quote possedute', style: TextStyle(color: Colors.white38, fontSize: 11)),
                          const SizedBox(height: 2),
                          Text('${_asset.totalQuantity}', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Prezzo medio carico', style: TextStyle(color: Colors.white38, fontSize: 11)),
                          const SizedBox(height: 2),
                          Text('€ ${_asset.averageBuyPrice.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Quotazione attuale', style: TextStyle(color: Colors.white38, fontSize: 11)),
                          const SizedBox(height: 2),
                          Text('€ ${_asset.currentPrice.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFF818CF8), fontSize: 14, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 2. Storico Prezzi & Rilevazioni
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.history_rounded, size: 18, color: Color(0xFF818CF8)),
                    SizedBox(width: 8),
                    Text(
                      'STORICO QUOTAZIONI',
                      style: TextStyle(fontSize: 12, letterSpacing: 1.2, fontWeight: FontWeight.bold, color: Colors.white38),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: _showUpdatePriceDialog,
                  icon: const Icon(Icons.add, size: 16, color: Color(0xFF818CF8)),
                  label: const Text('Rilevazione', style: TextStyle(color: Color(0xFF818CF8), fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (_isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: Color(0xFF6366F1))))
            else if (_history.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF18181B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                alignment: Alignment.center,
                child: const Text('Nessun punto storico registrato per questo asset.', style: TextStyle(color: Colors.white38, fontSize: 13)),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _history.length,
                itemBuilder: (ctx, idx) {
                  final snap = _history[_history.length - 1 - idx]; // Più recenti prima
                  final dateFormatted = DateFormat('dd MMMM yyyy, HH:mm', 'it_IT').format(snap.timestamp);
                  final isPurchase = snap.source == 'purchase';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF18181B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isPurchase ? AppTheme.success.withOpacity(0.15) : const Color(0xFF6366F1).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                isPurchase ? Icons.shopping_cart_checkout_rounded : Icons.price_change_rounded,
                                color: isPurchase ? AppTheme.success : const Color(0xFF818CF8),
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '€ ${snap.price.toStringAsFixed(2)}',
                                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  dateFormatted,
                                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (snap.note != null && snap.note!.isNotEmpty)
                          Flexible(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Text(
                                snap.note!,
                                style: const TextStyle(color: Colors.white54, fontSize: 11, fontStyle: FontStyle.italic),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
