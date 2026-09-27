import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:solducci/models/asset_price_snapshot.dart';
import 'package:solducci/models/investment_asset.dart';
import 'package:solducci/service/income_service.dart';
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
    final freshAsset = InvestmentAssetService().getAssetById(_asset.id) ?? _asset;
    if (mounted) {
      setState(() {
        _asset = freshAsset;
        _history = list;
        _isLoading = false;
      });
    }
  }

  // ===========================================================================
  // AZIONI: Compra, Vendi, Rettifica, Rileva Valore, Modifica
  // ===========================================================================

  void _showBuySheet() {
    final qtyCtrl = TextEditingController(text: '1');
    final totalSpentCtrl = TextEditingController();
    final unitPriceCtrl = TextEditingController(text: _asset.currentPrice > 0 ? _asset.currentPrice.toStringAsFixed(2) : '');
    final noteCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final isPhys = _asset.isPhysical;

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
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.add_shopping_cart_rounded, color: AppTheme.success, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isPhys ? 'Acquisto / Aggiungi Esemplari' : 'Acquisto / Incremento Quote',
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _asset.name,
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Quantità e Prezzi
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: qtyCtrl,
                          autofocus: true,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            labelText: isPhys ? 'Qtà (Pezzi)' : 'Qtà (Quote)',
                            labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
                            filled: true,
                            fillColor: const Color(0xFF27272A),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                          ),
                          onChanged: (val) {
                            final q = double.tryParse(val.replaceAll(',', '.')) ?? 0.0;
                            final u = double.tryParse(unitPriceCtrl.text.replaceAll(',', '.')) ?? 0.0;
                            if (q > 0 && u > 0) {
                              totalSpentCtrl.text = (q * u).toStringAsFixed(2);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: totalSpentCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            labelText: 'Spesa Totale (€)',
                            labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
                            hintText: '0.00',
                            filled: true,
                            fillColor: const Color(0xFF27272A),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: noteCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Nota acquisto (opzionale)',
                      labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
                      hintText: isPhys ? 'Es. Comprata su Cardmarket, mercatino...' : 'Es. Acquisto PAC mensile...',
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
                        final qty = double.tryParse(qtyCtrl.text.replaceAll(',', '.').trim()) ?? 0.0;
                        final total = double.tryParse(totalSpentCtrl.text.replaceAll(',', '.').trim()) ?? 0.0;
                        if (qty <= 0 || total <= 0) return;

                        Navigator.pop(ctx);
                        await InvestmentAssetService().recordBuyTransaction(
                          assetId: _asset.id,
                          quantityAdded: qty,
                          totalSpent: total,
                          note: noteCtrl.text.trim().isNotEmpty ? noteCtrl.text.trim() : null,
                        );
                        _loadHistory();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.success,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Registra Acquisto', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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

  void _showSellSheet() {
    final qtyCtrl = TextEditingController(text: '1');
    final totalRealizedCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final isPhys = _asset.isPhysical;
          final qty = double.tryParse(qtyCtrl.text.replaceAll(',', '.').trim()) ?? 0.0;
          final totalRealized = double.tryParse(totalRealizedCtrl.text.replaceAll(',', '.').trim()) ?? 0.0;
          final costBasis = _asset.averageBuyPrice * qty;
          final previewPnl = totalRealized - costBasis;

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
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.error.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.sell_rounded, color: AppTheme.error, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isPhys ? 'Vendita / Cessione Bene' : 'Vendita / Liquidazione Quote',
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Disponibili: ${_asset.formattedQuantity} ${_asset.quantityUnitLabel}',
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: qtyCtrl,
                          autofocus: true,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            labelText: isPhys ? 'Qtà Venduta' : 'Quote Vendute',
                            labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
                            filled: true,
                            fillColor: const Color(0xFF27272A),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                          ),
                          onChanged: (_) => setSheetState(() {}),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: totalRealizedCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            labelText: 'Incasso Totale (€)',
                            labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
                            hintText: '0.00',
                            filled: true,
                            fillColor: const Color(0xFF27272A),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                          ),
                          onChanged: (_) => setSheetState(() {}),
                        ),
                      ),
                    ],
                  ),

                  // Anteprima Guadagno / Perdita
                  if (qty > 0 && totalRealized > 0) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: (previewPnl >= 0 ? AppTheme.success : AppTheme.error).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: (previewPnl >= 0 ? AppTheme.success : AppTheme.error).withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Plusvalenza Realizzata:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                          Text(
                            '${previewPnl >= 0 ? '+' : ''}€ ${previewPnl.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: previewPnl >= 0 ? AppTheme.success : AppTheme.error,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),
                  TextField(
                    controller: noteCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Nota vendita (opzionale)',
                      labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
                      hintText: 'Es. Venduta su eBay, realizzo...',
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
                        final q = double.tryParse(qtyCtrl.text.replaceAll(',', '.').trim()) ?? 0.0;
                        final total = double.tryParse(totalRealizedCtrl.text.replaceAll(',', '.').trim()) ?? 0.0;
                        if (q <= 0 || total <= 0) return;
                        if (q > _asset.totalQuantity) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Non puoi vendere più pezzi di quanti ne possiedi!'), backgroundColor: AppTheme.error),
                          );
                          return;
                        }

                        Navigator.pop(ctx);
                        final pnl = await InvestmentAssetService().recordSellTransaction(
                          assetId: _asset.id,
                          quantitySold: q,
                          totalRealized: total,
                          note: noteCtrl.text.trim().isNotEmpty ? noteCtrl.text.trim() : null,
                        );
                        _loadHistory();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Vendita registrata! Plusvalenza: ${pnl >= 0 ? '+' : ''}€${pnl.toStringAsFixed(2)}'),
                              backgroundColor: pnl >= 0 ? AppTheme.success : AppTheme.warning,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.error,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Conferma Vendita', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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

  void _showAdjustQuantityDialog() {
    final qtyCtrl = TextEditingController(text: _asset.formattedQuantity);
    final reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Rettifica Quantità Inventario', style: TextStyle(color: Colors.white, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Imposta direttamente il numero effettivo di ${_asset.quantityUnitLabel} attualmente posseduti:',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: qtyCtrl,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF27272A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: reasonCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Motivo rettifica (es. Conteggio inventario)...',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF27272A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annulla', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            onPressed: () async {
              final newQ = double.tryParse(qtyCtrl.text.replaceAll(',', '.').trim());
              if (newQ != null && newQ >= 0) {
                Navigator.pop(ctx);
                await InvestmentAssetService().adjustQuantity(
                  assetId: _asset.id,
                  newQuantity: newQ,
                  reason: reasonCtrl.text.trim().isNotEmpty ? reasonCtrl.text.trim() : null,
                );
                _loadHistory();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1), foregroundColor: Colors.white),
            child: const Text('Aggiorna Quantità', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showUpdatePriceDialog() {
    final priceCtrl = TextEditingController(text: _asset.currentPrice > 0 ? _asset.currentPrice.toStringAsFixed(2) : '');
    final noteCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          _asset.isPhysical ? 'Rileva Valore di Mercato' : 'Aggiorna Quotazione',
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _asset.isPhysical
                  ? 'Stima attuale di 1 esemplare di ${_asset.name}:'
                  : 'Prezzo attuale di 1 quota di ${_asset.name}:',
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
                hintText: _asset.isPhysical ? 'Fonte stima (es. Cardmarket, vendita eBay)...' : 'Nota (es. Chiusura mese)...',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF27272A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annulla', style: TextStyle(color: Colors.white54))),
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
                _loadHistory();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1), foregroundColor: Colors.white),
            child: const Text('Salva Stima', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showEditAssetDialog() {
    final nameCtrl = TextEditingController(text: _asset.name);
    final tickerCtrl = TextEditingController(text: _asset.ticker ?? '');
    final editionCtrl = TextEditingController(text: _asset.editionOrSet ?? '');
    final gradingCtrl = TextEditingController(text: _asset.conditionOrGrading ?? '');
    final storageCtrl = TextEditingController(text: _asset.storageLocation ?? '');
    final noteCtrl = TextEditingController(text: _asset.note ?? '');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
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
              const Text('Modifica Informazioni Asset', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),

              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Nome',
                  labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFF27272A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 10),

              if (_asset.isPhysical) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: editionCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Set / Edizione / Anno',
                          labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
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
                          filled: true,
                          fillColor: const Color(0xFF27272A),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: storageCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Luogo di Custodia',
                    labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
                    filled: true,
                    fillColor: const Color(0xFF27272A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                ),
              ] else ...[
                TextField(
                  controller: tickerCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Ticker / Simbolo',
                    labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
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
                  labelText: 'Note generali',
                  labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFF27272A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),

              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final bottomSheetNav = Navigator.of(ctx);
                        final rootNav = Navigator.of(context);
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (c) => AlertDialog(
                            backgroundColor: const Color(0xFF1E1E22),
                            title: const Text('Elimina Asset', style: TextStyle(color: Colors.white)),
                            content: Text('Sei sicuro di voler eliminare definitivamente "${_asset.name}" dal portafoglio?', style: const TextStyle(color: Colors.white70)),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Annulla', style: TextStyle(color: Colors.white54))),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(c, true),
                                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error, foregroundColor: Colors.white),
                                child: const Text('Elimina'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          bottomSheetNav.pop();
                          await InvestmentAssetService().deleteAsset(_asset.id);
                          rootNav.pop();
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.error,
                        side: const BorderSide(color: AppTheme.error),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Elimina Asset'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () async {
                        final name = nameCtrl.text.trim();
                        if (name.isEmpty) return;

                        final updated = _asset.copyWith(
                          name: name,
                          ticker: tickerCtrl.text.trim().isNotEmpty ? tickerCtrl.text.trim() : null,
                          clearTicker: tickerCtrl.text.trim().isEmpty,
                          editionOrSet: editionCtrl.text.trim().isNotEmpty ? editionCtrl.text.trim() : null,
                          clearEditionOrSet: editionCtrl.text.trim().isEmpty,
                          conditionOrGrading: gradingCtrl.text.trim().isNotEmpty ? gradingCtrl.text.trim() : null,
                          clearConditionOrGrading: gradingCtrl.text.trim().isEmpty,
                          storageLocation: storageCtrl.text.trim().isNotEmpty ? storageCtrl.text.trim() : null,
                          clearStorageLocation: storageCtrl.text.trim().isEmpty,
                          note: noteCtrl.text.trim().isNotEmpty ? noteCtrl.text.trim() : null,
                        );

                        Navigator.pop(ctx);
                        await InvestmentAssetService().updateAsset(updated);
                        _loadHistory();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Salva Modifiche', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // BUILD PRINCIPALE
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final isProfitable = _asset.isProfitable;
    final pnlColor = isProfitable ? AppTheme.success : AppTheme.error;
    final lastUpdateStr = DateFormat('dd MMM yyyy, HH:mm', 'it_IT').format(_asset.lastPriceUpdate);
    final totalDividends = IncomeService().getTotalDividendsForAsset(_asset.id);
    final totalReturn = _asset.unrealizedPnl + totalDividends;
    final totalReturnPercent = _asset.investedCapital > 0 ? (totalReturn / _asset.investedCapital) * 100 : 0.0;
    final isTotalReturnProfitable = totalReturn >= 0;
    final isPhys = _asset.isPhysical;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F12),
      appBar: SolducciAppBar(
        titleText: _asset.name,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: Colors.white70),
            tooltip: 'Rettifica Quantità',
            onPressed: _showAdjustQuantityDialog,
          ),
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: Color(0xFF818CF8)),
            tooltip: 'Modifica Dettagli',
            onPressed: _showEditAssetDialog,
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
                  // Badges: Classe, Condizione PSA, Edizione, Ticker
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
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
                      if (_asset.conditionOrGrading != null && _asset.conditionOrGrading!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.4)),
                          ),
                          child: Text(
                            _asset.conditionOrGrading!,
                            style: const TextStyle(color: Color(0xFFFBBF24), fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      if (_asset.editionOrSet != null && _asset.editionOrSet!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3)),
                          ),
                          child: Text(
                            _asset.editionOrSet!,
                            style: const TextStyle(color: Color(0xFF818CF8), fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      if (_asset.ticker != null && _asset.ticker!.isNotEmpty)
                        Text(
                          _asset.ticker!,
                          style: const TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                      if (_asset.storageLocation != null && _asset.storageLocation!.isNotEmpty)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.inventory_2_outlined, size: 12, color: Colors.white38),
                            const SizedBox(width: 4),
                            Text(_asset.storageLocation!, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Text(
                    isPhys ? 'VALORE STIMATO TOTALE' : 'CONTROVALORE TOTALE',
                    style: const TextStyle(color: Colors.white38, fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.bold),
                  ),
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

                  // Total Return & Dividendi (se presenti)
                  if (totalDividends > 0) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF27272A).withOpacity(0.7),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppTheme.success.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.savings_outlined, size: 16, color: AppTheme.success),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'TOTAL RETURN (Plusv. + Rendite)',
                                  style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${isTotalReturnProfitable ? '+' : ''}€ ${totalReturn.toStringAsFixed(2)} (${isTotalReturnProfitable ? '+' : ''}${totalReturnPercent.toStringAsFixed(1)}%)',
                                  style: TextStyle(
                                    color: isTotalReturnProfitable ? AppTheme.success : AppTheme.error,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Cedole/Rendite', style: TextStyle(color: Colors.white38, fontSize: 10)),
                              const SizedBox(height: 2),
                              Text(
                                '+€ ${totalDividends.toStringAsFixed(2)}',
                                style: const TextStyle(color: AppTheme.success, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 18),
                  const Divider(color: Colors.white10, height: 1),
                  const SizedBox(height: 14),

                  // Griglia Parametri: Quantità, PMC, Valore Unitario, Capitale Versato
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(isPhys ? 'Pezzi posseduti' : 'Quote possedute', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                          const SizedBox(height: 2),
                          Text('${_asset.formattedQuantity} ${_asset.quantityUnitLabel}', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(isPhys ? 'Prezzo medio d\'acquisto' : 'Prezzo medio carico', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                          const SizedBox(height: 2),
                          Text('€ ${_asset.averageBuyPrice.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(isPhys ? 'Valore stimato unitario' : 'Quotazione attuale', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                          const SizedBox(height: 2),
                          Text('€ ${_asset.currentPrice.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFF818CF8), fontSize: 14, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 2. Action Bar (Pulsantiera Operativa: Compra, Vendi, Rileva Valore)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showBuySheet,
                    icon: const Icon(Icons.add, size: 16),
                    label: Text(isPhys ? 'Aggiungi' : 'Compra'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.success.withOpacity(0.18),
                      foregroundColor: AppTheme.success,
                      elevation: 0,
                      side: BorderSide(color: AppTheme.success.withOpacity(0.35)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showSellSheet,
                    icon: const Icon(Icons.remove, size: 16),
                    label: Text(isPhys ? 'Cedi / Vendi' : 'Vendi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.error.withOpacity(0.18),
                      foregroundColor: AppTheme.error,
                      elevation: 0,
                      side: BorderSide(color: AppTheme.error.withOpacity(0.35)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showUpdatePriceDialog,
                    icon: const Icon(Icons.price_change_outlined, size: 16),
                    label: const Text('Stima'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1).withOpacity(0.18),
                      foregroundColor: const Color(0xFF818CF8),
                      elevation: 0,
                      side: BorderSide(color: const Color(0xFF6366F1).withOpacity(0.35)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 3. Timeline Storica & Movimenti
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.history_rounded, size: 18, color: Color(0xFF818CF8)),
                    SizedBox(width: 8),
                    Text(
                      'TIMELINE & STORICO DEL BENE',
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
                child: const Text('Nessun movimento o rilevazione storica registrata.', style: TextStyle(color: Colors.white38, fontSize: 13)),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _history.length,
                itemBuilder: (ctx, idx) {
                  final snap = _history[_history.length - 1 - idx]; // Più recenti prima
                  final dateFormatted = DateFormat('dd MMMM yyyy, HH:mm', 'it_IT').format(snap.timestamp);
                  final isPurchase = snap.isPurchase;
                  final isSale = snap.isSale;
                  final isAdjustment = snap.isAdjustment;

                  Color badgeColor = const Color(0xFF6366F1);
                  IconData badgeIcon = Icons.trending_up_rounded;
                  String title = 'Rilevazione Valore';

                  if (isPurchase) {
                    badgeColor = AppTheme.success;
                    badgeIcon = Icons.shopping_cart_rounded;
                    title = 'Acquisto / Carico';
                  } else if (isSale) {
                    badgeColor = AppTheme.error;
                    badgeIcon = Icons.sell_rounded;
                    title = 'Vendita / Cessione';
                  } else if (isAdjustment) {
                    badgeColor = const Color(0xFF3B82F6);
                    badgeIcon = Icons.tune_rounded;
                    title = 'Rettifica Quantità';
                  }

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
                                color: badgeColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(badgeIcon, color: badgeColor, size: 16),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      title,
                                      style: TextStyle(color: badgeColor, fontSize: 13, fontWeight: FontWeight.bold),
                                    ),
                                    if (snap.quantityDelta != null && snap.quantityDelta != 0) ...[
                                      const SizedBox(width: 6),
                                      Text(
                                        '(${snap.quantityDelta! > 0 ? '+' : ''}${snap.quantityDelta!.toStringAsFixed(snap.quantityDelta! == snap.quantityDelta!.roundToDouble() ? 0 : 2)} ${_asset.quantityUnitLabel})',
                                        style: TextStyle(
                                          color: badgeColor.withOpacity(0.85),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ],
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '€ ${snap.price.toStringAsFixed(2)}',
                              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            if (snap.note != null && snap.note!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  snap.note!,
                                  style: const TextStyle(color: Colors.white54, fontSize: 11, fontStyle: FontStyle.italic),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
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
