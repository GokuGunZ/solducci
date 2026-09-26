import 'package:flutter/material.dart';
import 'package:solducci/models/wallet.dart';
import 'package:solducci/models/wallet_type.dart';
import 'package:solducci/service/wallet_service.dart';
import 'package:solducci/theme/app_theme.dart';
import 'package:solducci/widgets/solducci_app_bar.dart';

class WalletsManagementView extends StatefulWidget {
  const WalletsManagementView({super.key});

  @override
  State<WalletsManagementView> createState() => _WalletsManagementViewState();
}

class _WalletsManagementViewState extends State<WalletsManagementView> {
  final _walletService = WalletService();

  @override
  void initState() {
    super.initState();
    _walletService.fetchWallets();
  }

  void _openEditDialog(Wallet wallet) {
    final nameController = TextEditingController(text: wallet.name);
    final balanceController = TextEditingController(text: wallet.initialBalance.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Modifica ${wallet.name}', style: const TextStyle(color: Colors.white, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nome del conto', style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 6),
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF27272A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 14),
            const Text('Saldo Iniziale (€)', style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 6),
            TextField(
              controller: balanceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF27272A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
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
              final newName = nameController.text.trim();
              final cleanAmt = balanceController.text.replaceAll('.', '').replaceAll(',', '.');
              final newInitBal = double.tryParse(cleanAmt) ?? wallet.initialBalance;

              if (newName.isNotEmpty) {
                final updated = wallet.copyWith(name: newName, initialBalance: newInitBal);
                await _walletService.updateWallet(updated);
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.success,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Salva Modifiche'),
          ),
        ],
      ),
    );
  }

  void _showAddWalletDialog() {
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
                        decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text('Nuovo Portafoglio', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Nome del conto (es. Hype, Risparmi...)',
                        hintStyle: const TextStyle(color: Colors.white24),
                        filled: true,
                        fillColor: const Color(0xFF27272A),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 16),
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
                          labelStyle: TextStyle(color: isSel ? Colors.black : Colors.white70),
                          side: BorderSide(color: isSel ? AppTheme.success : Colors.white10),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: balanceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Saldo iniziale...',
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

                          await _walletService.createWallet(newWallet);
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
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: SolducciAppBar(
        title: const Text('I Miei Portafogli', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddWalletDialog,
        backgroundColor: AppTheme.success,
        child: const Icon(Icons.add_rounded, color: Colors.black, size: 28),
      ),
      body: StreamBuilder<List<Wallet>>(
        stream: _walletService.stream,
        builder: (context, snapshot) {
          final wallets = snapshot.data ?? _walletService.currentWallets;

          if (wallets.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.success));
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
            itemCount: wallets.length,
            itemBuilder: (ctx, idx) {
              final wallet = wallets[idx];

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF18181B),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: wallet.isDefault ? wallet.color : Colors.white12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: wallet.color.withOpacity(0.15),
                    child: Icon(wallet.type.icon, color: wallet.color, size: 22),
                  ),
                  title: Row(
                    children: [
                      Text(wallet.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      if (wallet.isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.warning.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.warning.withOpacity(0.4)),
                          ),
                          child: const Text('Predefinito', style: TextStyle(color: AppTheme.warning, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Saldo attuale: € ${wallet.currentBalance.toStringAsFixed(2)} • Iniziale: € ${wallet.initialBalance.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ),
                  trailing: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded, color: Colors.white54),
                    color: const Color(0xFF27272A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    onSelected: (val) async {
                      if (val == 'edit') _openEditDialog(wallet);
                      if (val == 'set_default') await _walletService.setDefaultWallet(wallet.id);
                      if (val == 'archive') await _walletService.archiveWallet(wallet.id);
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Modifica', style: TextStyle(color: Colors.white))),
                      if (!wallet.isDefault)
                        const PopupMenuItem(value: 'set_default', child: Text('Imposta come predefinito', style: TextStyle(color: Colors.white))),
                      if (wallets.length > 1)
                        const PopupMenuItem(value: 'archive', child: Text('Archivia', style: TextStyle(color: Colors.redAccent))),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
