import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:solducci/features/csv_importer/services/csv_import_flow.dart';
import 'package:solducci/features/investments/views/investments_hub_view.dart';
import 'package:solducci/features/wallets/views/wallets_management_view.dart';
import 'package:solducci/models/expense.dart';
import 'package:solducci/service/expense_service_cached.dart';
import 'package:solducci/theme/app_theme.dart';
import 'package:solducci/widgets/neon_wave_graph.dart';
import 'package:solducci/widgets/quick_add/unified_transaction_modal.dart';
import 'package:solducci/widgets/solducci_app_bar.dart';
import 'package:solducci/widgets/wallets/cashflow_hero_card.dart';
import 'package:solducci/widgets/wallets/wallets_carousel.dart';

class EconomyHubView extends StatefulWidget {
  const EconomyHubView({super.key});

  @override
  State<EconomyHubView> createState() => _EconomyHubViewState();
}

class _EconomyHubViewState extends State<EconomyHubView> {
  String? _selectedWalletId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: SolducciAppBar(
        title: const Text('Economy Hub', style: TextStyle(color: Color(0xFFE0E0E0), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.trending_up_rounded, color: Color(0xFF10B981)),
            tooltip: 'Portafogli & Asset Investiti',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (ctx) => const InvestmentsHubView()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF10B981)),
            tooltip: 'Gestisci Portafogli',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (ctx) => const WalletsManagementView()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.upload_file_rounded, color: Color(0xFF10B981)),
            tooltip: 'Importa Estratto Conto (CSV)',
            onPressed: () => CsvImportFlow.startImport(context),
          ),
          IconButton(
            icon: const Icon(Icons.dashboard, color: Color(0xFF10B981)),
            tooltip: 'Dashboard Analitica',
            onPressed: () => context.push('/expenses_dashboard'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => UnifiedTransactionModal.show(context),
        backgroundColor: AppTheme.success,
        child: const Icon(Icons.add_rounded, color: Colors.black, size: 28),
      ),
      body: StreamBuilder<List<Expense>>(
        stream: ExpenseServiceCached().stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.success));
          }

          final allExpenses = snapshot.data ?? [];

          // Filtra per portafoglio se selezionato nel carosello
          final expenses = _selectedWalletId != null
              ? allExpenses.where((e) => e.walletId == _selectedWalletId).toList()
              : allExpenses;

          List<double> waveData;
          if (expenses.isEmpty) {
            waveData = [10.0, 30.0, 15.0, 45.0, 20.0, 60.0, 30.0, 55.0];
          } else {
            waveData = expenses.take(15).toList().reversed.map((e) => e.amount).toList();
            if (waveData.length < 2) waveData.add(waveData.first);
          }

          final totalRecent = expenses.take(15).fold(0.0, (sum, e) => sum + e.amount);

          return ListView(
            padding: const EdgeInsets.only(bottom: 80),
            children: [
              // 1. Hero Card: Patrimonio Netto & Cashflow Mese
              const CashflowHeroCard(),

              // 2. Data Stream Animato (Grafico Neon Wave)
              Container(
                height: 200,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E).withOpacity(0.4),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withOpacity(0.05),
                      blurRadius: 20,
                      spreadRadius: 5,
                    )
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: NeonWaveGraph(
                          color: const Color(0xFF10B981),
                          dataPoints: waveData,
                          height: 200,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 20,
                      left: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('FLUSSO SPESE RECENTI', style: TextStyle(color: Colors.white54, fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text('€${totalRecent.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 3. Sezione: I MIEI PORTAFOGLI
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('I MIEI PORTAFOGLI', style: TextStyle(color: Colors.white54, fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (ctx) => const WalletsManagementView()),
                        );
                      },
                      child: const Text('Gestisci', style: TextStyle(color: AppTheme.success, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Carosello Orizzontale Portafogli
              WalletsCarousel(
                selectedWalletId: _selectedWalletId,
                onWalletSelected: (id) => setState(() => _selectedWalletId = id),
              ),

              const SizedBox(height: 20),

              // 4. Card Rapida: Portafogli & Investimenti
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF18181B),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF10B981).withOpacity(0.25)),
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (ctx) => const InvestmentsHubView()),
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.trending_up_rounded, color: Color(0xFF10B981), size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text('Portafogli & Asset Investiti', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                                SizedBox(height: 2),
                                Text('Gestisci asset, quote, storico prezzi e rendimenti', style: TextStyle(color: Colors.white54, fontSize: 12)),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 14),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 5. Card Rapida: Importa Estratto Conto (CSV)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF18181B),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF10B981).withOpacity(0.25)),
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    onTap: () => CsvImportFlow.startImport(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.upload_file_rounded, color: Color(0xFF10B981), size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text('Importa Estratto Conto', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                                SizedBox(height: 2),
                                Text('Carica CSV BNL o altra banca con deduplicazione', style: TextStyle(color: Colors.white54, fontSize: 12)),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 14),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // 5. Sezione Transazioni (con filtro conto attivo se presente)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Transazioni', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                    if (_selectedWalletId != null)
                      InkWell(
                        onTap: () => setState(() => _selectedWalletId = null),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: const [
                              Text('Rimuovi filtro', style: TextStyle(color: Colors.white70, fontSize: 11)),
                              SizedBox(width: 4),
                              Icon(Icons.close_rounded, size: 12, color: Colors.white70),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              if (expenses.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Text(
                    _selectedWalletId != null
                        ? 'Nessuna spesa associata a questo portafoglio'
                        : 'Nessuna spesa trovata',
                    style: const TextStyle(color: Colors.white54),
                  ),
                )
              else
                ...expenses.take(15).map((e) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF10B981).withOpacity(0.15)),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF10B981).withOpacity(0.1),
                      child: const Icon(Icons.attach_money, color: Color(0xFF10B981)),
                    ),
                    title: Text(e.description, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    subtitle: Text(DateFormat('dd MMM yyyy').format(e.date), style: const TextStyle(color: Colors.white54)),
                    trailing: Text('€${e.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFE0E0E0))),
                  ),
                )),

              const SizedBox(height: 24),
              Center(
                child: TextButton.icon(
                  icon: const Icon(Icons.analytics, color: Color(0xFF10B981)),
                  label: const Text('Dashboard Analitica', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                  onPressed: () => context.push('/expenses_dashboard'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
