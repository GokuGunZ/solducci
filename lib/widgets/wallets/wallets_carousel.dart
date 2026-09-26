import 'package:flutter/material.dart';
import 'package:solducci/models/wallet.dart';
import 'package:solducci/models/wallet_type.dart';
import 'package:solducci/service/wallet_service.dart';
import 'package:solducci/theme/app_theme.dart';

class WalletsCarousel extends StatelessWidget {
  final String? selectedWalletId;
  final ValueChanged<String?> onWalletSelected;

  const WalletsCarousel({
    super.key,
    required this.selectedWalletId,
    required this.onWalletSelected,
  });

  void _showAddWalletDialog(BuildContext context) {
    final nameController = TextEditingController();
    final balanceController = TextEditingController(text: '0,00');
    var selectedType = WalletType.bank;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              decoration: const BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Nuovo Portafoglio / Conto',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    const Text('Nome del conto', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Es. Conto BNL, Revolut, Contanti...',
                        hintStyle: const TextStyle(color: Colors.white24),
                        filled: true,
                        fillColor: const Color(0xFF27272A),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Tipologia', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: WalletType.values.map((t) {
                        final isSel = t == selectedType;
                        return ChoiceChip(
                          avatar: Icon(t.icon, size: 16, color: isSel ? Colors.black : Colors.white70),
                          label: Text(t.label),
                          selected: isSel,
                          onSelected: (val) {
                            if (val) setSheetState(() => selectedType = t);
                          },
                          selectedColor: AppTheme.success,
                          backgroundColor: const Color(0xFF27272A),
                          labelStyle: TextStyle(
                            color: isSel ? Colors.black : Colors.white70,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                          ),
                          side: BorderSide(color: isSel ? AppTheme.success : Colors.white10),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    const Text('Saldo Iniziale (€)', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: balanceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: '0,00',
                        hintStyle: const TextStyle(color: Colors.white24),
                        filled: true,
                        fillColor: const Color(0xFF27272A),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () async {
                          final name = nameController.text.trim();
                          if (name.isEmpty) return;

                          final cleanAmt = balanceController.text.replaceAll('.', '').replaceAll(',', '.');
                          final initBal = double.tryParse(cleanAmt) ?? 0.0;

                          final newWallet = Wallet(
                            id: '',
                            userId: '',
                            name: name,
                            type: selectedType,
                            initialBalance: initBal,
                            colorHex: selectedType == WalletType.cash ? '#F59E0B' : '#10B981',
                          );

                          await WalletService().createWallet(newWallet);
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.success,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Crea Portafoglio', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Wallet>>(
      stream: WalletService().stream,
      builder: (context, snapshot) {
        final wallets = snapshot.data ?? WalletService().currentWallets;

        if (wallets.isEmpty) {
          WalletService().fetchWallets();
          return const SizedBox(height: 105);
        }

        return SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: wallets.length + 1, // +1 per card "Aggiungi"
            itemBuilder: (ctx, idx) {
              if (idx == wallets.length) {
                // Card Aggiungi Nuovo Conto
                return Container(
                  width: 120,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141417),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: InkWell(
                    onTap: () => _showAddWalletDialog(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.add_circle_outline_rounded, color: Colors.white54, size: 28),
                        SizedBox(height: 6),
                        Text('Nuovo', style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                );
              }

              final wallet = wallets[idx];
              final isSelected = selectedWalletId == wallet.id;

              return Container(
                width: 175,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF1E1E24) : const Color(0xFF141417),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? wallet.color : Colors.white12,
                    width: isSelected ? 1.8 : 1.0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: wallet.color.withOpacity(0.15),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    onTap: () {
                      if (isSelected) {
                        onWalletSelected(null); // Deseleziona per mostrare tutti i conti
                      } else {
                        onWalletSelected(wallet.id);
                      }
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: wallet.color.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(wallet.type.icon, size: 16, color: wallet.color),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  wallet.name,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.white70,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (wallet.isDefault)
                                const Icon(Icons.star_rounded, size: 14, color: AppTheme.warning),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '€ ${wallet.currentBalance.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: wallet.currentBalance >= 0 ? Colors.white : AppTheme.error,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              Text(
                                isSelected ? 'Filtro attivo' : wallet.type.label,
                                style: TextStyle(
                                  color: isSelected ? wallet.color : Colors.white38,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
