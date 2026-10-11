import 'package:flutter/material.dart';
import 'package:solducci/features/csv_importer/models/merchant_rule.dart';
import 'package:solducci/features/csv_importer/models/staging_transaction.dart';
import 'package:solducci/features/csv_importer/services/csv_import_committer.dart';
import 'package:solducci/features/csv_importer/services/csv_import_flow.dart';
import 'package:solducci/features/csv_importer/services/csv_parser_service.dart';
import 'package:solducci/features/csv_importer/services/csv_staging_service.dart';
import 'package:solducci/features/csv_importer/services/deduplication_service.dart';
import 'package:solducci/features/csv_importer/services/merchant_rule_service.dart';
import 'package:solducci/features/csv_importer/views/widgets/bulk_rule_sheet.dart';
import 'package:solducci/features/csv_importer/views/widgets/category_picker_sheet.dart';
import 'package:solducci/features/csv_importer/views/widgets/context_picker_sheet.dart';
import 'package:solducci/features/csv_importer/views/widgets/income_category_picker_sheet.dart';
import 'package:solducci/features/csv_importer/views/widgets/monthly_accordion_section.dart';
import 'package:solducci/features/csv_importer/views/widgets/staging_batch_toolbar.dart';
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
  final CsvParseResult? parseResult;
  final List<StagingTransaction>? initialTransactions;

  const CsvStagingInboxView({
    super.key,
    this.parseResult,
    this.initialTransactions,
  });

  @override
  State<CsvStagingInboxView> createState() => _CsvStagingInboxViewState();
}

class _CsvStagingInboxViewState extends State<CsvStagingInboxView> {
  List<StagingTransaction> _transactions = [];
  TransactionTypeFilter _typeFilter = TransactionTypeFilter.all;
  InboxFilter _statusFilter = InboxFilter.all;
  bool _isProcessing = true;
  bool _isCommitting = false;
  List<Wallet> _wallets = [];
  String? _selectedWalletId;
  List<ExpenseGroup> _groups = [];
  List<InvestmentPortfolio> _portfolios = [];
  String _currentUserId = '';

  // Set dei mesi attualmente espansi
  final Set<DateTime> _expandedMonths = {};

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    setState(() => _isProcessing = true);

    await Future.wait([
      _loadWallets(),
      _loadGroups(),
      _loadPortfolios(),
    ]);

    if (widget.parseResult != null) {
      _transactions = widget.parseResult!.transactions;
      await _runEnrichmentAndDeduplication();
      await CsvStagingService().saveStagedTransactions(
        _transactions,
        fileName: widget.parseResult!.matchedPreset?.name ?? 'Estratto Conto',
      );
    } else if (widget.initialTransactions != null) {
      _transactions = List.from(widget.initialTransactions!);
      await CsvStagingService().saveStagedTransactions(_transactions);
    } else {
      _transactions = await CsvStagingService().getStagedTransactions();
    }

    // Auto-espandi il primo mese (quello più recente)
    if (_groupedByMonth.isNotEmpty) {
      _expandedMonths.add(_groupedByMonth.keys.first);
    }

    if (mounted) {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _loadPortfolios() async {
    final portfolios = await InvestmentPortfolioService().fetchPortfolios();
    if (mounted) {
      setState(() {
        _portfolios = portfolios;
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
    await MerchantRuleService().enrichWithRules(_transactions);
    await DeduplicationService().runDeduplication(_transactions);
  }

  Future<void> _saveCurrentState() async {
    await CsvStagingService().saveStagedTransactions(_transactions);
  }

  // --- Raggruppamento e Filtri ---

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

  /// Mappa ordinata con raggruppamento per mese e anno (chiave: 1° del mese)
  Map<DateTime, List<StagingTransaction>> get _groupedByMonth {
    final filtered = _filteredTransactions;
    final map = <DateTime, List<StagingTransaction>>{};
    for (final t in filtered) {
      final monthKey = DateTime(t.date.year, t.date.month, 1);
      map.putIfAbsent(monthKey, () => []).add(t);
    }
    final sortedKeys = map.keys.toList()..sort((a, b) => b.compareTo(a));
    final sortedMap = <DateTime, List<StagingTransaction>>{};
    for (final k in sortedKeys) {
      sortedMap[k] = map[k]!;
    }
    return sortedMap;
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

  double get _selectedTotal => _transactions
      .where((t) => t.isSelected)
      .fold(0.0, (sum, t) => sum + t.amount);

  // --- Gestione Selezione ---

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
    _saveCurrentState();
  }

  void _toggleMonthSelection(DateTime monthKey, bool selectAll) {
    setState(() {
      final monthTxs = _groupedByMonth[monthKey] ?? [];
      for (final tx in monthTxs) {
        if (selectAll) {
          if (tx.duplicateStatus != DuplicateStatus.exactMatch) {
            tx.isSelected = true;
          }
        } else {
          tx.isSelected = false;
        }
      }
    });
    _saveCurrentState();
  }

  void _toggleMonthExpand(DateTime monthKey) {
    setState(() {
      if (_expandedMonths.contains(monthKey)) {
        _expandedMonths.remove(monthKey);
      } else {
        _expandedMonths.add(monthKey);
      }
    });
  }

  void _toggleAllMonthsExpand(bool expand) {
    setState(() {
      if (expand) {
        _expandedMonths.addAll(_groupedByMonth.keys);
      } else {
        _expandedMonths.clear();
      }
    });
  }

  // --- Modifiche Puntuali ---

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
    _saveCurrentState();
    _checkForSimilarTransactions(tx, proposedCategory: newCat);
  }

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
    _saveCurrentState();
  }

  void _onNameEdited(StagingTransaction tx, String newName) {
    setState(() {
      tx.cleanDescription = newName;
    });
    _saveCurrentState();
    if (!tx.isIncome) {
      _checkForSimilarTransactions(tx, proposedName: newName);
    }
  }

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
          _saveCurrentState();
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
        onSplitConfirmed: (newSplitType, newSplitData) {
          setState(() {
            tx.splitType = newSplitType;
            tx.customSplitData = newSplitData;
          });
          _saveCurrentState();
        },
      ),
    );
  }

  // --- Batch Actions ---

  void _openBatchContextPicker() {
    final selectedExpenses = _transactions.where((t) => t.isSelected && !t.isIncome).toList();
    if (selectedExpenses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleziona almeno una spesa per cambiare contesto')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => ContextPickerSheet(
        groups: _groups,
        currentGroupId: selectedExpenses.first.groupId,
        count: selectedExpenses.length,
        onContextSelected: (newGroupId) {
          setState(() {
            for (final tx in selectedExpenses) {
              tx.groupId = newGroupId;
              tx.splitType = SplitType.equal;
              tx.customSplitData = null;
            }
          });
          _saveCurrentState();
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

  void _openBatchCategoryPicker() {
    final selected = _transactions.where((t) => t.isSelected).toList();
    if (selected.isEmpty) return;

    final hasOnlyIncomes = selected.every((t) => t.isIncome);

    if (hasOnlyIncomes) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (ctx) => IncomeCategoryPickerSheet(
          currentCategory: selected.first.incomeCategory,
          onCategorySelected: (cat) {
            setState(() {
              for (final tx in selected) {
                tx.incomeCategory = cat;
              }
            });
            _saveCurrentState();
          },
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (ctx) => CategoryPickerSheet(
          currentCategory: selected.first.category,
          onCategorySelected: (cat) {
            setState(() {
              for (final tx in selected) {
                if (!tx.isIncome) {
                  tx.category = cat;
                }
              }
            });
            _saveCurrentState();
          },
        ),
      );
    }
  }

  void _openBatchWalletPicker() {
    final selected = _transactions.where((t) => t.isSelected).toList();
    if (selected.isEmpty || _wallets.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E22),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Assegna Conto di Addebito (${selected.length} selezionati)',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),
              ..._wallets.map((w) => ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(int.parse(w.colorHex.replaceFirst('#', '0xFF'))).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.account_balance_wallet_rounded, color: Color(int.parse(w.colorHex.replaceFirst('#', '0xFF'))), size: 18),
                ),
                title: Text(w.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text('Saldo: € ${w.initialBalance.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    for (final tx in selected) {
                      tx.walletId = w.id;
                    }
                  });
                  _saveCurrentState();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Assegnato conto "${w.name}" a ${selected.length} movimenti'),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                },
              )),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _discardSingleTransaction(StagingTransaction tx) async {
    setState(() {
      _transactions.removeWhere((t) => t.id == tx.id);
    });
    await CsvStagingService().removeTransactions([tx.id]);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Movimento scartato dalla bozza')),
      );
    }
  }

  Future<void> _discardSelectedTransactions() async {
    final selectedIds = _transactions.where((t) => t.isSelected).map((t) => t.id).toList();
    if (selectedIds.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Scarta Movimenti', style: TextStyle(color: Colors.white, fontSize: 18)),
        content: Text(
          'Vuoi davvero rimuovere i ${selectedIds.length} movimenti selezionati dalla bozza senza registrarli?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annulla', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Scarta'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _transactions.removeWhere((t) => selectedIds.contains(t.id));
      });
      await CsvStagingService().removeTransactions(selectedIds);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${selectedIds.length} movimenti rimossi dalla bozza'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _clearEntireDraft() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Svuota Intera Staging Inbox', style: TextStyle(color: Colors.white, fontSize: 18)),
        content: const Text(
          'Tutti i movimenti non ancora importati verranno eliminati dalla bozza locale. Sei sicuro?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annulla', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Svuota Tutto'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await CsvStagingService().clearStaging();
      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  // --- Inserimento In-Place ---

  Future<void> _commitSelected() async {
    final selected = _transactions.where((t) => t.isSelected).toList();
    if (selected.isEmpty) return;

    setState(() => _isCommitting = true);

    try {
      final insertedCount = await CsvImportCommitter().commitTransactions(
        selected,
        walletId: _selectedWalletId,
      );

      final committedIds = selected.map((t) => t.id).toList();
      await CsvStagingService().removeTransactions(committedIds);

      if (mounted) {
        setState(() {
          _transactions.removeWhere((t) => committedIds.contains(t.id));
          _isCommitting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _transactions.isEmpty
                  ? '🎉 Tutti i movimenti sono stati registrati con successo!'
                  : '🎉 $insertedCount movimenti registrati! Rimangono ${_transactions.length} movimenti in sospeso.',
            ),
            backgroundColor: AppTheme.success,
            duration: const Duration(seconds: 4),
          ),
        );
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
            MerchantRuleService().applyRuleToSimilarTransactions(
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

            setState(() {});
            _saveCurrentState();

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Applicata regola e aggiornate $similarCount transazioni simili!'),
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
      _saveCurrentState();

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
              if (val == 'expand_all') {
                _toggleAllMonthsExpand(true);
              } else if (val == 'collapse_all') {
                _toggleAllMonthsExpand(false);
              } else if (val == 'add_another_csv') {
                CsvImportFlow.startImport(context);
              } else if (val == 'clear_draft') {
                _clearEntireDraft();
              } else {
                _toggleSelection(val);
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'select_all', child: Text('Seleziona Tutte (esclusi duplicati)', style: TextStyle(color: Colors.white))),
              const PopupMenuItem(value: 'select_expenses', child: Text('Seleziona solo Spese', style: TextStyle(color: Colors.white))),
              const PopupMenuItem(value: 'select_incomes', child: Text('Seleziona solo Entrate', style: TextStyle(color: Colors.white))),
              const PopupMenuItem(value: 'deselect_all', child: Text('Deseleziona Tutte', style: TextStyle(color: Colors.white70))),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'expand_all', child: Text('Espandi tutti i mesi', style: TextStyle(color: Colors.white))),
              const PopupMenuItem(value: 'collapse_all', child: Text('Comprimi tutti i mesi', style: TextStyle(color: Colors.white70))),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'add_another_csv', child: Text('➕ Aggiungi altro file CSV', style: TextStyle(color: AppTheme.success))),
              const PopupMenuItem(value: 'clear_draft', child: Text('🗑️ Svuota Staging Inbox', style: TextStyle(color: Color(0xFFEF4444)))),
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
          : _transactions.isEmpty
              ? _buildCelebrationView()
              : Stack(
                  children: [
                    Column(
                      children: [
                        // 1. Hero Banner Riepilogo
                        _buildHeroBanner(),

                        // 2. Selettore Tipo: Tutte / Spese / Entrate
                        _buildTypeSegmentSelector(),

                        const SizedBox(height: 8),

                        // 3. Filtro Stati: Pronte / Da Verificare / Duplicate
                        _buildFilterTabs(),

                        const SizedBox(height: 10),

                        // 4. Lista Mesi ad Accordion
                        Expanded(
                          child: _groupedByMonth.isEmpty
                              ? const Center(
                                  child: Text(
                                    'Nessun movimento trovato per questo filtro',
                                    style: TextStyle(color: Colors.white38),
                                  ),
                                )
                              : ListView.builder(
                                  padding: EdgeInsets.only(
                                    left: 14,
                                    right: 14,
                                    top: 4,
                                    bottom: _selectedCount > 0 ? 150 : 30,
                                  ),
                                  itemCount: _groupedByMonth.length,
                                  itemBuilder: (ctx, idx) {
                                    final monthKey = _groupedByMonth.keys.elementAt(idx);
                                    final monthTxs = _groupedByMonth[monthKey]!;
                                    final isExp = _expandedMonths.contains(monthKey);

                                    return MonthlyAccordionSection(
                                      key: ValueKey(monthKey.toIso8601String()),
                                      monthDate: monthKey,
                                      transactions: monthTxs,
                                      isExpanded: isExp,
                                      onToggleExpand: () => _toggleMonthExpand(monthKey),
                                      onSelectAllMonth: (selectAll) => _toggleMonthSelection(monthKey, selectAll),
                                      availableGroups: _groups,
                                      availablePortfolios: _portfolios,
                                      onToggleCardSelection: (tx) {
                                        setState(() => tx.isSelected = !tx.isSelected);
                                        _saveCurrentState();
                                      },
                                      onCategoryChanged: _onCategoryChanged,
                                      onIncomeCategoryChanged: _onIncomeCategoryChanged,
                                      onNameEdited: _onNameEdited,
                                      onAlignWithExisting: _alignFuzzyMatch,
                                      onOpenContextPicker: _openContextPicker,
                                      onOpenVolumeSplit: _openVolumeSplit,
                                      onPortfolioChanged: (tx, pId) {
                                        setState(() => tx.portfolioId = pId);
                                        _saveCurrentState();
                                      },
                                      onDismissTransaction: _discardSingleTransaction,
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),

                    // 5. Barra Azioni Batch Flottante (visibile se selezionati > 0)
                    StagingBatchToolbar(
                      selectedCount: _selectedCount,
                      selectedTotal: _selectedTotal,
                      isCommitting: _isCommitting,
                      onDeselectAll: () => _toggleSelection('deselect_all'),
                      onContextPressed: _openBatchContextPicker,
                      onCategoryPressed: _openBatchCategoryPicker,
                      onWalletPressed: _openBatchWalletPicker,
                      onDiscardPressed: _discardSelectedTransactions,
                      onCommitPressed: _commitSelected,
                    ),
                  ],
                ),
    );
  }

  Widget _buildCelebrationView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.success.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.done_all_rounded, color: AppTheme.success, size: 54),
            ),
            const SizedBox(height: 24),
            const Text(
              'Inbox Completata! 🎉',
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Tutti i movimenti del tuo estratto conto sono stati registrati con successo in Solducci.',
              style: TextStyle(color: Colors.white60, fontSize: 14, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.success,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Torna all\'App', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroBanner() {
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
                  Text('${_transactions.length} movimenti in bozza', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
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
                      widget.parseResult?.matchedPreset?.name ?? CsvStagingService().activeFileName ?? 'Estratto Conto',
                      style: const TextStyle(color: AppTheme.success, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

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
              ],
            ),
          ),
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
          color: const Color(0xFF1E1E22),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            _buildTypeSegmentItem(
              label: 'Tutte (${_transactions.length})',
              filter: TransactionTypeFilter.all,
              activeColor: Colors.white,
            ),
            const SizedBox(width: 4),
            _buildTypeSegmentItem(
              label: 'Spese ($_expensesCount)',
              filter: TransactionTypeFilter.expenses,
              activeColor: const Color(0xFFEF4444),
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
