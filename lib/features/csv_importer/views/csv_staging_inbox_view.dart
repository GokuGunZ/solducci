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
import 'package:solducci/models/income_category.dart';
import 'package:solducci/models/investment_portfolio.dart';
import 'package:solducci/models/split_type.dart';
import 'package:solducci/models/wallet.dart';
import 'package:solducci/service/group_service_cached.dart';
import 'package:solducci/service/investment_portfolio_service.dart';
import 'package:solducci/service/wallet_service.dart';
import 'package:solducci/theme/app_theme.dart';
import 'package:solducci/widgets/solducci_app_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum InboxFilter { all, ready, toReview, duplicates }
enum TransactionTypeFilter { all, expenses, incomes }

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
  TransactionTypeFilter _typeFilter = TransactionTypeFilter.all;
  InboxFilter _statusFilter = InboxFilter.all;
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
        // Auto-match portfolio sia per spese di tipo investimento che per entrate di tipo rendita
        for (final tx in _transactions) {
          final isInv = tx.category == Tipologia.investimento || tx.incomeCategory == IncomeCategory.rendita;
          if (isInv && tx.portfolioId == null && _portfolios.isNotEmpty) {
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
    return _transactions.where((t) {
      // 1. Filtro Tipo (Tutte / Spese / Entrate)
      if (_typeFilter == TransactionTypeFilter.expenses && t.isIncome) return false;
      if (_typeFilter == TransactionTypeFilter.incomes && !t.isIncome) return false;

      // 2. Filtro Stato Duplicati / Revisione
      switch (_statusFilter) {
        case InboxFilter.all:
          return true;
        case InboxFilter.ready:
          return t.duplicateStatus == DuplicateStatus.none;
        case InboxFilter.toReview:
          return t.duplicateStatus == DuplicateStatus.fuzzyMatch;
        case InboxFilter.duplicates:
          return t.duplicateStatus == DuplicateStatus.exactMatch;
      }
    }).toList();
  }

  int get _expensesCount => _transactions.where((t) => !t.isIncome).length;
  int get _incomesCount => _transactions.where((t) => t.isIncome).length;

  double get _totalExpensesAll => _transactions.where((t) => !t.isIncome).fold(0.0, (sum, t) => sum + t.amount);
  double get _totalIncomesAll => _transactions.where((t) => t.isIncome).fold(0.0, (sum, t) => sum + t.amount);

  int get _readyCount => _transactions.where((t) {
    if (_typeFilter == TransactionTypeFilter.expenses && t.isIncome) return false;
    if (_typeFilter == TransactionTypeFilter.incomes && !t.isIncome) return false;
    return t.duplicateStatus == DuplicateStatus.none;
  }).length;

  int get _toReviewCount => _transactions.where((t) {
    if (_typeFilter == TransactionTypeFilter.expenses && t.isIncome) return false;
    if (_typeFilter == TransactionTypeFilter.incomes && !t.isIncome) return false;
    return t.duplicateStatus == DuplicateStatus.fuzzyMatch;
  }).length;

  int get _duplicatesCount => _transactions.where((t) {
    if (_typeFilter == TransactionTypeFilter.expenses && t.isIncome) return false;
    if (_typeFilter == TransactionTypeFilter.incomes && !t.isIncome) return false;
    return t.duplicateStatus == DuplicateStatus.exactMatch;
  }).length;

  int get _selectedCount => _transactions.where((t) => t.isSelected).length;
  int get _selectedExpensesCount => _transactions.where((t) => t.isSelected && !t.isIncome).length;
  int get _selectedIncomesCount => _transactions.where((t) => t.isSelected && t.isIncome).length;

  double get _selectedExpensesTotal => _transactions
      .where((t) => t.isSelected && !t.isIncome)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get _selectedIncomesTotal => _transactions
      .where((t) => t.isSelected && t.isIncome)
      .fold(0.0, (sum, t) => sum + t.amount);

  void _toggleSelection(String mode) {
    setState(() {
      for (final t in _transactions) {
        if (mode == 'select_all') {
          t.isSelected = t.duplicateStatus != DuplicateStatus.exactMatch;
        } else if (mode == 'select_expenses') {
          t.isSelected = !t.isIncome && t.duplicateStatus != DuplicateStatus.exactMatch;
        } else if (mode == 'select_incomes') {
          t.isSelected = t.isIncome && t.duplicateStatus != DuplicateStatus.exactMatch;
        } else if (mode == 'deselect_all') {
          t.isSelected = false;
        }
      }
    });
  }

  // --- Modifica Categoria Spesa & Propagazione Batch ---
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

  // --- Modifica Categoria Entrata ---
  void _onIncomeCategoryChanged(StagingTransaction tx, IncomeCategory newCat) {
    setState(() {
      tx.incomeCategory = newCat;
      if (newCat == IncomeCategory.rendita && tx.portfolioId == null && _portfolios.isNotEmpty) {
        final match = _portfolios.firstWhere(
          (p) => p.brokerName != null && tx.cleanDescription.toLowerCase().contains(p.brokerName!.toLowerCase()),
          orElse: () => _portfolios.first,
        );
        tx.portfolioId = match.id;
      }
    });
  }

  void _onNameEdited(StagingTransaction tx, String newName) {
    setState(() {
      tx.cleanDescription = newName;
    });

    if (!tx.isIncome) {
      _checkForSimilarTransactions(tx, proposedName: newName);
    }
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
    final selectedExpenses = _transactions.where((t) => t.isSelected && !t.isIncome).toList();
    if (selectedExpenses.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => ContextPickerSheet(
        groups: _groups,
        currentGroupId: null,
        count: selectedExpenses.length,
        onContextSelected: (newGroupId) {
          setState(() {
            for (final tx in selectedExpenses) {
              tx.groupId = newGroupId;
              tx.splitType = SplitType.equal;
              tx.customSplitData = null;
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                newGroupId == null
                    ? 'Impostato contesto Personale per ${selectedExpenses.length} spese'
                    : 'Impostato gruppo per ${selectedExpenses.length} spese',
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

    final rawWords = tx.rawDescription
        .split(RegExp(r'[\s,-/]+'))
        .where((w) => w.length >= 4 && !RegExp(r'^\d+$').hasMatch(w))
        .toList();

    String pattern = cleanName;
    if (rawWords.isNotEmpty) {
      pattern = rawWords.first;
    }

    final similarCount = _transactions.where((t) {
      if (t.id == tx.id || t.isIncome) return false;
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
            final updated = MerchantRuleService().applyRuleToSimilarTransactions(
              transactions: _transactions,
              pattern: pattern,
              cleanName: cleanName,
              category: cat,
            );

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
          onApplyOnlyToCurrent: () {},
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
            onSelected: _toggleSelection,
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: 'select_all', child: Text('Seleziona Tutte (esclusi duplicati)', style: TextStyle(color: Colors.white))),
              PopupMenuItem(value: 'select_expenses', child: Text('Seleziona solo Spese', style: TextStyle(color: Colors.white))),
              PopupMenuItem(value: 'select_incomes', child: Text('Seleziona solo Entrate', style: TextStyle(color: Colors.white))),
              PopupMenuDivider(),
              PopupMenuItem(value: 'deselect_all', child: Text('Deseleziona Tutte', style: TextStyle(color: Colors.white70))),
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
                  Text('Analisi e categorizzazione in corso...', style: TextStyle(color: Colors.white70)),
                ],
              ),
            )
          : Column(
              children: [
                // 1. Hero Banner Riepilogo Importazione
                _buildHeroBanner(),

                // 2. Selettore Tipo: Tutte / Spese / Entrate
                _buildTypeSegmentSelector(),

                const SizedBox(height: 8),

                // 3. Filtro Stati: Pronte / Da Verificare / Duplicate
                _buildFilterTabs(),

                const SizedBox(height: 8),

                // 4. Lista Transazioni
                Expanded(
                  child: _filteredTransactions.isEmpty
                      ? const Center(
                          child: Text(
                            'Nessun movimento trovato per questo filtro',
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
                              onIncomeCategoryChanged: (cat) => _onIncomeCategoryChanged(tx, cat),
                              onNameEdited: (name) => _onNameEdited(tx, name),
                              onAlignWithExisting: () => _alignFuzzyMatch(tx),
                              onOpenContextPicker: () => _openContextPicker(tx),
                              onOpenVolumeSplit: tx.groupId != null ? () => _openVolumeSplit(tx) : null,
                              onPortfolioChanged: (pId) => setState(() => tx.portfolioId = pId),
                            );
                          },
                        ),
                ),

                // 5. Sticky Bottom Summary Bar
                StagingSummaryBar(
                  selectedCount: _selectedCount,
                  selectedExpensesCount: _selectedExpensesCount,
                  selectedIncomesCount: _selectedIncomesCount,
                  totalExpenses: _selectedExpensesTotal,
                  totalIncomes: _selectedIncomesTotal,
                  isLoading: _isCommitting,
                  onConfirm: _commitImport,
                  onBatchContext: _selectedExpensesCount > 0 ? _openBatchContextPicker : null,
                ),
              ],
            ),
    );
  }

  Widget _buildHeroBanner() {
    final netAll = _totalIncomesAll - _totalExpensesAll;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 10),
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
                  const Text('ESTRATTO CONTO BANCARIO', style: TextStyle(fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold, color: Colors.white38)),
                  const SizedBox(height: 4),
                  Text('${_transactions.length} movimenti rilevati', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
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

          const SizedBox(height: 12),

          // Mini Cashflow Banner (Spese vs Entrate vs Saldo Netto)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('USCITE', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(
                        '-€${_totalExpensesAll.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 26, color: Colors.white12),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ENTRATE', style: TextStyle(color: AppTheme.success, fontSize: 10, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(
                        '+€${_totalIncomesAll.toStringAsFixed(2)}',
                        style: const TextStyle(color: AppTheme.success, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 26, color: Colors.white12),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('SALDO NETTO', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(
                        '${netAll >= 0 ? '+' : '-'}€${netAll.abs().toStringAsFixed(2)}',
                        style: TextStyle(
                          color: netAll >= 0 ? AppTheme.success : Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (_wallets.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
        ],
      ),
    );
  }

  Widget _buildTypeSegmentSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFF18181B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            _buildTypeSegmentItem(
              label: 'Tutte (${_transactions.length})',
              filter: TransactionTypeFilter.all,
              activeColor: const Color(0xFF3B82F6),
            ),
            const SizedBox(width: 4),
            _buildTypeSegmentItem(
              label: 'Spese ($_expensesCount)',
              filter: TransactionTypeFilter.expenses,
              activeColor: const Color(0xFF6366F1),
              icon: Icons.arrow_upward_rounded,
            ),
            const SizedBox(width: 4),
            _buildTypeSegmentItem(
              label: 'Entrate ($_incomesCount)',
              filter: TransactionTypeFilter.incomes,
              activeColor: AppTheme.success,
              icon: Icons.arrow_downward_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSegmentItem({
    required String label,
    required TransactionTypeFilter filter,
    required Color activeColor,
    IconData? icon,
  }) {
    final isSelected = _typeFilter == filter;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _typeFilter = filter),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? activeColor.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? activeColor.withOpacity(0.5) : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: isSelected ? activeColor : Colors.white38),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white60,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
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
          _buildFilterChip('Tutti gli stati', InboxFilter.all),
          const SizedBox(width: 8),
          _buildFilterChip('🟢 Pronte ($_readyCount)', InboxFilter.ready),
          const SizedBox(width: 8),
          _buildFilterChip('🟡 Da Verificare ($_toReviewCount)', InboxFilter.toReview),
          const SizedBox(width: 8),
          _buildFilterChip('🟠 Duplicate ($_duplicatesCount)', InboxFilter.duplicates),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, InboxFilter filter) {
    final isSelected = _statusFilter == filter;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _statusFilter = filter);
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
