import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:solducci/features/csv_importer/services/csv_import_flow.dart';
import 'package:solducci/features/csv_importer/services/csv_staging_service.dart';
import 'package:solducci/features/csv_importer/views/widgets/category_picker_sheet.dart';
import 'package:solducci/features/investments/views/investments_hub_view.dart';
import 'package:solducci/features/wallets/views/wallets_management_view.dart';
import 'package:solducci/models/expense.dart';
import 'package:solducci/service/auth_service.dart';
import 'package:solducci/service/context_manager.dart';
import 'package:solducci/service/expense_service_cached.dart';
import 'package:solducci/service/group_service_cached.dart';
import 'package:solducci/theme/app_theme.dart';
import 'package:solducci/widgets/economy/category_breakdown_deck.dart';
import 'package:solducci/widgets/economy/group_debts_section.dart';
import 'package:solducci/widgets/economy/real_cashflow_timeline_graph.dart';
import 'package:solducci/widgets/quick_add/unified_transaction_modal.dart';
import 'package:solducci/service/recurring_transaction_service.dart';
import 'package:solducci/service/wallet_service.dart';
import 'package:solducci/widgets/economy/recurring_inbox_sheet.dart';
import 'package:solducci/widgets/wallets/cashflow_hero_card.dart';
import 'package:solducci/widgets/wallets/investments_carousel.dart';
import 'package:solducci/widgets/wallets/wallets_carousel.dart';

class EconomyHubView extends StatefulWidget {
  const EconomyHubView({super.key});

  @override
  State<EconomyHubView> createState() => _EconomyHubViewState();
}

class _EconomyHubViewState extends State<EconomyHubView> {
  final _contextManager = ContextManager();
  final _expenseService = ExpenseServiceCached();
  String? _selectedWalletId;
  Map<int, double> _cachedBalances = {};

  @override
  void initState() {
    super.initState();
    CsvStagingService().init();
    _contextManager.addListener(_onContextChanged);
  }

  @override
  void dispose() {
    _contextManager.removeListener(_onContextChanged);
    super.dispose();
  }

  void _onContextChanged() {
    if (mounted) {
      setState(() {
        _selectedWalletId = null;
        _cachedBalances = {};
      });
    }
  }

  Future<void> _updateBalances(List<Expense> expenses) async {
    final groupExpenses = expenses.where((e) => e.isGroup).take(10).toList();
    if (groupExpenses.isEmpty) return;
    try {
      final balances = await _expenseService.calculateBulkUserBalances(groupExpenses);
      if (mounted) {
        setState(() {
          _cachedBalances = balances;
        });
      }
    } catch (_) {}
  }

  void _openExpenseDetails(Expense expense) {
    GoRouter.of(context).push('/expense/${expense.id}', extra: expense);
  }

  @override
  Widget build(BuildContext context) {
    final isGroupContext = _contextManager.isGroupContext;

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        title: Text(
          isGroupContext ? 'Economy Hub • ${_contextManager.contextDisplayName}' : 'Economy Hub',
          style: const TextStyle(color: Color(0xFFE0E0E0), fontWeight: FontWeight.bold),
        ),
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
          ValueListenableBuilder<int>(
            valueListenable: RecurringTransactionService().pendingInboxCountNotifier,
            builder: (context, pendingCount, child) {
              if (pendingCount > 0) {
                return Badge.count(
                  count: pendingCount,
                  backgroundColor: Colors.amber,
                  textColor: Colors.black,
                  alignment: const Alignment(0.6, -0.6),
                  child: child!,
                );
              }
              return child!;
            },
            child: IconButton(
              icon: const Icon(Icons.repeat_rounded, color: Color(0xFF10B981)),
              tooltip: 'Spese Fisse & Ricorrenze',
              onPressed: () => context.push('/economy/recurring'),
            ),
          ),
          ValueListenableBuilder<int>(
            valueListenable: CsvStagingService().pendingCountNotifier,
            builder: (context, pendingCount, child) {
              if (pendingCount > 0) {
                return Badge.count(
                  count: pendingCount,
                  backgroundColor: AppTheme.success,
                  textColor: Colors.black,
                  alignment: const Alignment(0.6, -0.6),
                  child: child!,
                );
              }
              return child!;
            },
            child: IconButton(
              icon: const Icon(Icons.upload_file_rounded, color: Color(0xFF10B981)),
              tooltip: 'Importa Estratto Conto (CSV)',
              onPressed: () => CsvImportFlow.startImport(context),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.pie_chart_rounded, color: Color(0xFF10B981)),
            tooltip: 'Grafici Analitici',
            onPressed: () => context.push('/economy/charts'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'economy_hub_fab',
        onPressed: () => UnifiedTransactionModal.show(context),
        backgroundColor: isGroupContext ? const Color(0xFF8B5CF6) : AppTheme.success,
        child: const Icon(Icons.add_rounded, color: Colors.black, size: 28),
      ),
      body: StreamBuilder<List<Expense>>(
        stream: _expenseService.stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.success));
          }

          final allExpenses = snapshot.data ?? [];

          // Filtra per portafoglio se selezionato nel carosello (solo in personale)
          final expenses = (!isGroupContext && _selectedWalletId != null)
              ? allExpenses.where((e) => e.walletId == _selectedWalletId).toList()
              : allExpenses;

          // Aggiorna asincronamente i bilanci debitori per le prime spese se necessario
          if (expenses.isNotEmpty && _cachedBalances.isEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _updateBalances(expenses);
            });
          }

          return RefreshIndicator(
            color: const Color(0xFF10B981),
            backgroundColor: const Color(0xFF18181B),
            onRefresh: () async {
              _expenseService.refresh();
              await Future.wait([
                WalletService().fetchWallets(forceRefresh: true),
                RecurringTransactionService().fetchRecurringTransactions(),
              ]);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 80),
              children: [
              // Banner Movimenti Ricorrenti in Sospeso
              ValueListenableBuilder<int>(
                valueListenable: RecurringTransactionService().pendingInboxCountNotifier,
                builder: (context, pendingCount, _) {
                  if (pendingCount == 0) return const SizedBox.shrink();
                  return Container(
                    margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.amber.withOpacity(0.35)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.mark_email_unread_rounded, color: Colors.amber, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$pendingCount ${pendingCount == 1 ? "movimento in scadenza" : "movimenti in scadenza"}',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const Text(
                                'Verifica o modifica l\'importo prima di scalare',
                                style: TextStyle(color: Colors.white70, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => RecurringInboxSheet.show(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Rivedi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                  );
                },
              ),

              // Banner Bozza CSV in Sospeso (reattivo)
              ValueListenableBuilder<int>(
                valueListenable: CsvStagingService().pendingCountNotifier,
                builder: (context, pendingCount, _) {
                  if (pendingCount == 0) return const SizedBox.shrink();
                  return Container(
                    margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF10B981).withOpacity(0.35)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.inbox_rounded, color: AppTheme.success, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Staging Inbox CSV in Sospeso',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              Text(
                                '$pendingCount movimenti pronti da importare',
                                style: const TextStyle(color: Colors.white70, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => CsvImportFlow.openPendingDraft(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.success,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Riprendi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                  );
                },
              ),

              // ==========================================
              // HERO CARD PATRIMONIO
              // (Personale: verde classico | Gruppo: risaltato viola con badge 'PERSONALE')
              // ==========================================
              CashflowHeroCard(isGroupContext: isGroupContext),

              // ==========================================
              // SEZIONE SPECIFICA PER GRUPPO / VISTA: Debiti & Crediti
              // ==========================================
              if (isGroupContext) ...[
                const GroupDebtsSection(),
                const SizedBox(height: 12),
              ],

              // ==========================================
              // SEZIONE PORTAFOGLI (Solo in Personale)
              // ==========================================
              if (!isGroupContext) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'I MIEI PORTAFOGLI',
                        style: TextStyle(color: Colors.white54, fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.bold),
                      ),
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
                WalletsCarousel(
                  selectedWalletId: _selectedWalletId,
                  onWalletSelected: (id) => setState(() => _selectedWalletId = id),
                ),
                const SizedBox(height: 20),
              ],

              // ==========================================
              // GRAFICO FLUSSO SPESE RECENTI
              // (Posizionato sotto i portafogli in Personale, o dopo i debiti in Gruppo)
              // ==========================================
              RealCashflowTimelineGraph(expenses: expenses),
              const SizedBox(height: 20),

              // ==========================================
              // I MIEI ASSET DI INVESTIMENTO (Solo in Personale)
              // ==========================================
              if (!isGroupContext) ...[
                const InvestmentsCarousel(),
                const SizedBox(height: 20),
              ],

              // ==========================================
              // SPESE PER CATEGORIA (Deck esplorabile orizzontale)
              // ==========================================
              CategoryBreakdownDeck(expenses: expenses),
              const SizedBox(height: 24),

              // ==========================================
              // SEZIONE TRANSAZIONI (Ultime 5 con "Visualizza tutte")
              // ==========================================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          isGroupContext ? 'Transazioni Gruppo' : 'Transazioni',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        if (_selectedWalletId != null) ...[
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () => setState(() => _selectedWalletId = null),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white10,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                children: [
                                  Text('Filtro attivo', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                  SizedBox(width: 4),
                                  Icon(Icons.close_rounded, size: 12, color: Colors.white70),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    TextButton(
                      onPressed: () => context.push('/expense_list'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Visualizza tutte',
                            style: TextStyle(
                              color: isGroupContext ? const Color(0xFFA78BFA) : const Color(0xFF10B981),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 12,
                            color: isGroupContext ? const Color(0xFFA78BFA) : const Color(0xFF10B981),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              if (expenses.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Center(
                    child: Text(
                      _selectedWalletId != null
                          ? 'Nessuna spesa associata a questo portafoglio'
                          : (isGroupContext ? 'Nessuna spesa registrata in questo gruppo' : 'Nessuna spesa trovata'),
                      style: const TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                  ),
                )
              else
                ...expenses.take(5).map((e) => _buildTransactionCard(e)),

              const SizedBox(height: 24),
              Center(
                child: TextButton.icon(
                  icon: const Icon(Icons.analytics_rounded, color: Color(0xFF10B981)),
                  label: const Text('Grafici e Analisi', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                  onPressed: () => context.push('/economy/charts'),
                ),
              ),
            ],
          ),
        );
      },
    ),
    );
  }

  Widget _buildTransactionCard(Expense e) {
    final color = CategoryPickerSheet.getColor(e.type);
    final icon = CategoryPickerSheet.getIcon(e.type);
    final currentUserId = AuthService().currentUserId;
    final isPayer = e.paidBy == currentUserId;
    final bal = _cachedBalances[e.id];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openExpenseDetails(e),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Icona Tipologia di Spesa con Badge Tipologia Contesto (Gruppo/Personale)
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: color.withOpacity(0.3), width: 1.2),
                      ),
                      child: Icon(icon, color: color, size: 21),
                    ),
                    Positioned(
                      right: -3,
                      bottom: -3,
                      child: Container(
                        padding: const EdgeInsets.all(2.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF18181B),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Icon(
                          e.isGroup ? Icons.group_rounded : Icons.person_rounded,
                          size: 10,
                          color: e.isGroup ? const Color(0xFFA78BFA) : const Color(0xFF10B981),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),

                // Testi e Metadati Spesa
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              e.description,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (e.isGroup) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF8B5CF6).withOpacity(0.18),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.4)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.group_rounded, size: 10, color: Color(0xFFDDD6FE)),
                                  const SizedBox(width: 3),
                                  Text(
                                    GroupServiceCached().getGroupName(e.groupId!) ?? 'Gruppo',
                                    style: const TextStyle(color: Color(0xFFDDD6FE), fontSize: 9, fontWeight: FontWeight.bold),
                                  ),
                                  if (e.splitType != null) ...[
                                    const SizedBox(width: 3),
                                    Text(e.splitType!.icon, style: const TextStyle(fontSize: 9)),
                                  ],
                                ],
                              ),
                            ),
                          ] else ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.person_rounded, size: 10, color: Colors.white60),
                                  SizedBox(width: 3),
                                  Text(
                                    'Personale',
                                    style: TextStyle(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(
                            DateFormat('dd MMM yyyy').format(e.date),
                            style: const TextStyle(color: Colors.white38, fontSize: 11),
                          ),
                          const SizedBox(width: 6),
                          Text('•', style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 10)),
                          const SizedBox(width: 6),
                          // Chip Tipologia Categoria con Icona Dedicata
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: color.withOpacity(0.25)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(icon, size: 11, color: color),
                                const SizedBox(width: 4),
                                Text(
                                  e.type.label,
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (e.isGroup && e.paidBy != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              isPayer ? '💰 Hai pagato tu' : '💰 Pagato da altri',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isPayer ? const Color(0xFF10B981) : const Color(0xFF818CF8),
                              ),
                            ),
                            if (bal != null && bal.abs() >= 0.01) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: (bal > 0 ? const Color(0xFF10B981) : const Color(0xFFF59E0B)).withOpacity(0.14),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      bal > 0 ? Icons.north_east_rounded : Icons.south_west_rounded,
                                      size: 10,
                                      color: bal > 0 ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      bal > 0 ? '+€${bal.toStringAsFixed(2)} ti spettano' : '€${bal.abs().toStringAsFixed(2)} devi',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: bal > 0 ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // Importo
                Text(
                  '€${e.amount.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
