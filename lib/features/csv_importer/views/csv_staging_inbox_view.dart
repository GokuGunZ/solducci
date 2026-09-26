import 'package:flutter/material.dart';
import 'package:solducci/features/csv_importer/models/merchant_rule.dart';
import 'package:solducci/features/csv_importer/models/staging_transaction.dart';
import 'package:solducci/features/csv_importer/services/csv_import_committer.dart';
import 'package:solducci/features/csv_importer/services/csv_parser_service.dart';
import 'package:solducci/features/csv_importer/services/deduplication_service.dart';
import 'package:solducci/features/csv_importer/services/merchant_rule_service.dart';
import 'package:solducci/features/csv_importer/views/widgets/bulk_rule_sheet.dart';
import 'package:solducci/features/csv_importer/views/widgets/context_picker_sheet.dart';
import 'package:solducci/features/csv_importer/views/widgets/staging_card.dart';
import 'package:solducci/features/csv_importer/views/widgets/staging_summary_bar.dart';
import 'package:solducci/features/csv_importer/views/widgets/volume_split_sheet.dart';
import 'package:solducci/models/expense_form.dart';
import 'package:solducci/models/group.dart';
import 'package:solducci/models/split_type.dart';
import 'package:solducci/models/wallet.dart';
import 'package:solducci/service/group_service_cached.dart';
import 'package:solducci/service/wallet_service.dart';
import 'package:solducci/models/investment_portfolio.dart';
import 'package:solducci/service/investment_portfolio_service.dart';
import 'package:solducci/theme/app_theme.dart';
import 'package:solducci/widgets/solducci_app_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum InboxFilter { all, toReview, ready, duplicates }

class CsvStagingInboxView extends StatefulWidget {
  final CsvParseResult parseResult;

  const CsvStagingInboxView({
    super.key,
    required this.parseResult,
  });

  @override
  State<CsvStagingInboxView> createState() => _CsvStagingInboxViewState();
}

class _CsvStagingInboxViewState extends State<CsvStagingInboxView> {
  late List<StagingTransaction> _transactions;
  InboxFilter _activeFilter = InboxFilter.all;
  bool _isProcessing = true;
  bool _isCommitting = false;
  List<Wallet> _wallets = [];
  String? _selectedWalletId;
  List<ExpenseGroup> _groups = [];
  List<InvestmentPortfolio> _portfolios = [];
  String _currentUserId = '';

  @override
  void initState() {
    super.initState();
    _transactions = widget.parseResult.transactions;
    _runEnrichmentAndDeduplication();
    _loadWallets();
    _loadGroups();
    _loadPortfolios();
  }

  Future<void> _loadPortfolios() async {
    final portfolios = await InvestmentPortfolioService().fetchPortfolios();
    if (mounted) {
      setState(() {
        _portfolios = portfolios;
        // Auto-match portfolio se ci sono transazioni di tipo investimento
        for (final tx in _transactions) {
          if (tx.category == Tipologia.investimento && tx.portfolioId == null && _portfolios.isNotEmpty) {
            final match = _portfolios.firstWhere(
              (p) => p.brokerName != null && tx.cleanDescription.toLowerCase().contains(p.brokerName!.toLowerCase()),
              orElse: () => _portfolios.first,
            );
            tx.portfolioId = match.id;
          }
        }
      });
    }
  }

  Future<void> _loadGroups() async {
    final currentId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final groups = await GroupServiceCached().getUserGroups();
    if (mounted) {
      setState(() {
        _groups = groups;
        _currentUserId = currentId;
      });
    }
  }

  Future<void> _loadWallets() async {
    final wallets = await WalletService().fetchWallets();
    if (mounted && wallets.isNotEmpty) {
      setState(() {
        _wallets = wallets;
        _selectedWalletId = WalletService().getDefaultWallet()?.id ?? wallets.first.id;
      });
    }
  }

  Future<void> _runEnrichmentAndDeduplication() async {
    setState(() => _isProcessing = true);

    // 1. Applica le regole note per pulire i nomi ed assegnare le categorie
    await MerchantRuleService().enrichWithRules(_transactions);

    // 2. Esegue la deduplicazione intelligente a 3 livelli (+-2 giorni, +-0.09 €)
    await DeduplicationService().runDeduplication(_transactions);

    if (mounted) {
      setState(() => _isProcessing = false);
    }
  }

  // --- Filtri e Statistiche ---
  List<StagingTransaction> get _filteredTransactions {
    switch (_activeFilter) {
      case InboxFilter.all:
        return _transactions;
      case InboxFilter.toReview:
        return _transactions.where((t) => t.duplicateStatus == DuplicateStatus.fuzzyMatch).toList();
      case InboxFilter.ready:
        return _transactions.where((t) => t.duplicateStatus == DuplicateStatus.none).toList();
      case InboxFilter.duplicates:
        return _transactions.where((t) => t.duplicateStatus == DuplicateStatus.exactMatch).toList();
    }
  }

  int get _readyCount => _transactions.where((t) => t.duplicateStatus == DuplicateStatus.none).length;
  int get _toReviewCount => _transactions.where((t) => t.duplicateStatus == DuplicateStatus.fuzzyMatch).length;
  int get _duplicatesCount => _transactions.where((t) => t.duplicateStatus == DuplicateStatus.exactMatch).length;

  int get _selectedCount => _transactions.where((t) => t.isSelected).length;
  double get _selectedTotal => _transactions
      .where((t) => t.isSelected && !t.isIncome)
      .fold(0.0, (sum, t) => sum + t.amount);

  void _toggleSelectAll(bool selectAll) {
    setState(() {
      for (final t in _transactions) {
        // Se si seleziona tutto, non riattivare i duplicati esatti per sicurezza
        if (selectAll && t.duplicateStatus == DuplicateStatus.exactMatch) {
          t.isSelected = false;
        } else {
          t.isSelected = selectAll;
        }
      }
    });
  }

  // --- Modifica Categoria & Propagazione Batch ---
  void _onCategoryChanged(StagingTransaction tx, Tipologia newCat) {
    setState(() {
      tx.category = newCat;
      if (newCat == Tipologia.investimento && tx.portfolioId == null && _portfolios.isNotEmpty) {
        final match = _portfolios.firstWhere(
          (p) => p.brokerName != null && tx.cleanDescription.toLowerCase().contains(p.brokerName!.toLowerCase()),
          orElse: () => _portfolios.first,
        );
        tx.portfolioId = match.id;
      }
    });

    _checkForSimilarTransactions(tx, proposedCategory: newCat);
  }

  void _onNameEdited(StagingTransaction tx, String newName) {
    setState(() {
      tx.cleanDescription = newName;
    });

    _checkForSimilarTransactions(tx, proposedName: newName);
  }

  // --- Gestione Contesto (Personale vs Gruppo) & Volume Split ---
  void _openContextPicker(StagingTransaction tx) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => ContextPickerSheet(
        groups: _groups,
        currentGroupId: tx.groupId,
        count: 1,
        onContextSelected: (newGroupId) {
          setState(() {
            tx.groupId = newGroupId;
            tx.splitType = SplitType.equal;
            tx.customSplitData = null;
          });
        },
      ),
    );
  }

  Future<void> _openVolumeSplit(StagingTransaction tx) async {
    if (tx.groupId == null) return;
    final group = _groups.where((g) => g.id == tx.groupId).firstOrNull;
    if (group == null) return;

    // Carica membri aggiornati
    final members = await GroupServiceCached().getGroupMembers(group.id);
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => VolumeSplitSheet(
        transaction: tx,
        group: group,
        members: members,
        currentUserId: _currentUserId,
        onSplitConfirmed: (splitType, splitData) {
          setState(() {
            tx.splitType = splitType;
            tx.customSplitData = splitData;
          });
        },
      ),
    );
  }

  void _openBatchContextPicker() {
    final selected = _transactions.where((t) => t.isSelected).toList();
    if (selected.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => ContextPickerSheet(
        groups: _groups,
        currentGroupId: null,
        count: selected.length,
        onContextSelected: (newGroupId) {
          setState(() {
            for (final tx in selected) {
              tx.groupId = newGroupId;
              tx.splitType = SplitType.equal;
              tx.customSplitData = null;
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                newGroupId == null
                    ? 'Impostato contesto Personale per ${selected.length} spese'
                    : 'Impostato gruppo per ${selected.length} spese',
              ),
              backgroundColor: AppTheme.success,
            ),
          );
        },
      ),
    );
  }

  void _checkForSimilarTransactions(
    StagingTransaction tx, {
    String? proposedName,
    Tipologia? proposedCategory,
  }) {
    final cleanName = proposedName ?? tx.cleanDescription;
    final cat = proposedCategory ?? tx.category;

    // Cerca una parola chiave significativa (almeno 4 caratteri) nella descrizione originale
    final rawWords = tx.rawDescription
        .split(RegExp(r'[\s,-/]+'))
        .where((w) => w.length >= 4 && !RegExp(r'^\d+$').hasMatch(w))
        .toList();

    String pattern = cleanName;
    if (rawWords.isNotEmpty) {
      pattern = rawWords.first;
    }

    // Conta le altre transazioni simili nel file corrente
    final similarCount = _transactions.where((t) {
      if (t.id == tx.id) return false;
      return t.rawDescription.toLowerCase().contains(pattern.toLowerCase()) ||
          t.cleanDescription.toLowerCase().contains(cleanName.toLowerCase());
    }).length;

    if (similarCount > 0) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (ctx) => BulkRuleSheet(
          detectedPattern: pattern,
          proposedName: cleanName,
          proposedCategory: cat,
          similarCount: similarCount,
          onApplyToAllAndSaveRule: () async {
            // 1. Aggiorna in blocco tutte le transazioni simili nel file corrente
            final updated = MerchantRuleService().applyRuleToSimilarTransactions(
              transactions: _transactions,
              pattern: pattern,
              cleanName: cleanName,
              category: cat,
            );

            // 2. Persiste la regola per i prossimi CSV
            await MerchantRuleService().saveRule(
              MerchantRule(
                id: 'rule_${DateTime.now().millisecondsSinceEpoch}',
                pattern: pattern,
                cleanName: cleanName,
                defaultCategory: cat,
              ),
            );

            if (mounted) {
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('⚡ Regola salvata e applicata a $updated transazioni simili!'),
                  backgroundColor: AppTheme.success,
                ),
              );
            }
          },
          onApplyOnlyToCurrent: () {
            // Lascia modificata solo la transazione corrente
          },
        ),
      );
    }
  }

  // --- Allineamento Fuzzy con Spesa Esistente ---
  Future<void> _alignFuzzyMatch(StagingTransaction tx) async {
    final diff = tx.amountDifference ?? 0.0;
    final diffStr = diff >= 0 ? '+€${diff.toStringAsFixed(2)}' : '-€${(-diff).toStringAsFixed(2)}';

    final shouldAlign = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Allinea con Spesa Esistente', style: TextStyle(color: Colors.white, fontSize: 18)),
        content: Text(
          'Spesa esistente in Solducci: €${tx.matchedExistingExpense?.amount.toStringAsFixed(2)}\n'
          'Importo ufficiale banca: €${tx.amount.toStringAsFixed(2)} ($diffStr)\n\n'
          'Vuoi correggere la spesa esistente con l\'importo esatto al centesimo della banca ed escludere questa riga dall\'importazione?',
          style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annulla', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.success,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Allinea Importo', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (shouldAlign == true) {
      await CsvImportCommitter().alignExistingExpense(tx);
      setState(() {
        tx.duplicateStatus = DuplicateStatus.exactMatch;
        tx.isSelected = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Spesa esistente allineata al centesimo!'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    }
  }

  // --- Inserimento Finale ---
  Future<void> _commitImport() async {
    setState(() => _isCommitting = true);

    try {
      final insertedCount = await CsvImportCommitter().commitTransactions(
        _transactions,
        walletId: _selectedWalletId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 $insertedCount movimenti importati con successo in Solducci!'),
            backgroundColor: AppTheme.success,
            duration: const Duration(seconds: 3),
          ),
        );

        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCommitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore durante l\'importazione: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: SolducciAppBar(
        title: const Text('Staging Inbox', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
            color: const Color(0xFF27272A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onSelected: (val) {
              if (val == 'select_all') _toggleSelectAll(true);
              if (val == 'deselect_all') _toggleSelectAll(false);
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: 'select_all', child: Text('Seleziona Tutte (esclusi duplicati)', style: TextStyle(color: Colors.white))),
              PopupMenuItem(value: 'deselect_all', child: Text('Deseleziona Tutte', style: TextStyle(color: Colors.white))),
            ],
          ),
        ],
      ),
      body: _isProcessing
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppTheme.success),
                  SizedBox(height: 16),
                  Text('Analisi e deduplicazione in corso...', style: TextStyle(color: Colors.white70)),
                ],
              ),
            )
          : Column(
              children: [
                // 1. Hero Card Riepilogo Importazione
                _buildHeroBanner(),

                // 2. Filtro a schede
                _buildFilterTabs(),

                const SizedBox(height: 8),

                // 3. Lista Transazioni
                Expanded(
                  child: _filteredTransactions.isEmpty
                      ? Center(
                          child: Text(
                            'Nessuna transazione in questo filtro',
                            style: TextStyle(color: Colors.white38),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 24),
                          itemCount: _filteredTransactions.length,
                          itemBuilder: (ctx, idx) {
                            final tx = _filteredTransactions[idx];
                            return StagingCard(
                              key: ValueKey(tx.id),
                              transaction: tx,
                              availableGroups: _groups,
                              availablePortfolios: _portfolios,
                              onToggleSelection: (val) => setState(() => tx.isSelected = val),
                              onCategoryChanged: (cat) => _onCategoryChanged(tx, cat),
                              onNameEdited: (name) => _onNameEdited(tx, name),
                              onAlignWithExisting: () => _alignFuzzyMatch(tx),
                              onOpenContextPicker: () => _openContextPicker(tx),
                              onOpenVolumeSplit: tx.groupId != null ? () => _openVolumeSplit(tx) : null,
                              onPortfolioChanged: (pId) => setState(() => tx.portfolioId = pId),
                            );
                          },
                        ),
                ),

                // 4. Sticky Bottom Summary Bar
                StagingSummaryBar(
                  selectedCount: _selectedCount,
                  selectedTotal: _selectedTotal,
                  isLoading: _isCommitting,
                  onConfirm: _commitImport,
                  onBatchContext: _selectedCount > 0 ? _openBatchContextPicker : null,
                ),
              ],
            ),
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('TRANSAZIONI RILEVATE', style: TextStyle(fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.bold, color: Colors.white38)),
                  const SizedBox(height: 4),
                  Text('${_transactions.length} movimenti trovati', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.success.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.account_balance_rounded, size: 14, color: AppTheme.success),
                    const SizedBox(width: 6),
                    Text(
                      widget.parseResult.matchedPreset?.name ?? 'Estratto Conto',
                      style: const TextStyle(color: AppTheme.success, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_wallets.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black38,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_wallet_rounded, size: 16, color: Color(0xFF6366F1)),
                  const SizedBox(width: 8),
                  const Text('Conto:', style: TextStyle(color: Colors.white60, fontSize: 12)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedWalletId,
                        dropdownColor: const Color(0xFF27272A),
                        isDense: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70, size: 18),
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        items: _wallets.map((w) {
                          return DropdownMenuItem<String>(
                            value: w.id,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(w.type.icon, size: 14, color: w.type.color),
                                const SizedBox(width: 6),
                                Text(w.name),
                                if (w.isDefault)
                                  const Text(' (Predefinito)', style: TextStyle(color: Colors.white38, fontSize: 11)),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (newId) {
                          if (newId != null) {
                            setState(() => _selectedWalletId = newId);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatPill('🟢 Pronte', _readyCount, AppTheme.success),
              const SizedBox(width: 8),
              _buildStatPill('🟡 Da verificare', _toReviewCount, AppTheme.warning),
              const SizedBox(width: 8),
              _buildStatPill('🟠 Duplicate', _duplicatesCount, AppTheme.error),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text('$count', style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildFilterChip('Tutte (${_transactions.length})', InboxFilter.all),
          const SizedBox(width: 8),
          _buildFilterChip('Pronte ($_readyCount)', InboxFilter.ready),
          const SizedBox(width: 8),
          _buildFilterChip('Da Verificare ($_toReviewCount)', InboxFilter.toReview),
          const SizedBox(width: 8),
          _buildFilterChip('Duplicate ($_duplicatesCount)', InboxFilter.duplicates),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, InboxFilter filter) {
    final isSelected = _activeFilter == filter;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _activeFilter = filter);
      },
      selectedColor: AppTheme.success,
      backgroundColor: const Color(0xFF1E1E22),
      labelStyle: TextStyle(
        color: isSelected ? Colors.black : Colors.white70,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      side: BorderSide(color: isSelected ? AppTheme.success : Colors.white10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
