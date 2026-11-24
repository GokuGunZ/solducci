import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:solducci/models/expense.dart';
import 'package:solducci/models/expense_form.dart';
import 'package:solducci/models/expense_filter_criteria.dart';
import 'package:solducci/models/group.dart';
import 'package:solducci/service/context_manager.dart';
import 'package:solducci/service/expense_service_cached.dart';
import 'package:solducci/service/group_service_cached.dart';
import 'package:solducci/theme/app_theme.dart';
import 'package:solducci/utils/category_helpers.dart';
import 'package:solducci/widgets/economy/expense_filter_bottom_sheet.dart';
import 'package:solducci/widgets/quick_add/unified_transaction_modal.dart';
import 'package:solducci/widgets/solducci_app_bar.dart';

class ExpenseList extends StatefulWidget {
  const ExpenseList({super.key});

  @override
  State<ExpenseList> createState() => _ExpenseListState();
}

class _ExpenseListState extends State<ExpenseList> {
  final ExpenseServiceCached _expenseService = ExpenseServiceCached();
  final _contextManager = ContextManager();
  final TextEditingController _searchController = TextEditingController();

  ExpenseFilterCriteria _criteria = const ExpenseFilterCriteria();
  List<GroupMember> _groupMembers = [];
  Map<int, double> _balances = {};

  @override
  void initState() {
    super.initState();
    _contextManager.addListener(_onContextChanged);
    _loadGroupMembers();
  }

  @override
  void dispose() {
    _contextManager.removeListener(_onContextChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onContextChanged() {
    if (mounted) {
      _loadGroupMembers();
      setState(() {
        _balances = {};
      });
    }
  }

  Future<void> _loadGroupMembers() async {
    final ctx = _contextManager.currentContext;
    if (ctx.isGroup && ctx.groupId != null) {
      try {
        final members = await GroupServiceCached().getGroupMembers(ctx.groupId!);
        if (mounted) setState(() => _groupMembers = members);
      } catch (_) {}
    } else {
      if (mounted) setState(() => _groupMembers = []);
    }
  }

  void _openFilters() {
    ExpenseFilterBottomSheet.show(
      context,
      currentCriteria: _criteria,
      groupMembers: _groupMembers,
      onApply: (newCriteria) {
        setState(() {
          _criteria = newCriteria;
        });
      },
    );
  }

  void _openExpenseDetails(Expense expense) {
    GoRouter.of(context).push('/expense/${expense.id}', extra: expense);
  }

  @override
  Widget build(BuildContext context) {
    final isGroup = _contextManager.isGroupContext;
    final primaryColor = isGroup ? const Color(0xFF8B5CF6) : AppTheme.success;

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: SolducciAppBar(
        titleText: 'Lista Spese',
        showContextSwitcher: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Bottone Filtri con Badge se attivi
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(
                  Icons.tune_rounded,
                  color: _criteria.activeFilterCount > 0 ? primaryColor : Colors.white70,
                ),
                tooltip: 'Filtra spese',
                onPressed: _openFilters,
              ),
              if (_criteria.activeFilterCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '${_criteria.activeFilterCount}',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'expense_list_fab',
        onPressed: () => UnifiedTransactionModal.show(context),
        backgroundColor: primaryColor,
        child: const Icon(Icons.add_rounded, color: Colors.black, size: 28),
      ),
      body: StreamBuilder<List<Expense>>(
        stream: _expenseService.stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: primaryColor, strokeWidth: 2));
          }

          final allExpenses = snapshot.data ?? [];

          // Applica i filtri (ricerca testuale e criteri)
          final filteredExpenses = allExpenses.where((e) {
            return _criteria.matches(e);
          }).toList();

          // Assicura ordinamento decrescente per data
          filteredExpenses.sort((a, b) => b.date.compareTo(a.date));

          // Calcolo ottimizzato saldi debito in background
          if (filteredExpenses.isNotEmpty && _balances.isEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              try {
                final bulk = await _expenseService.calculateBulkUserBalances(filteredExpenses);
                if (mounted) setState(() => _balances = bulk);
              } catch (_) {}
            });
          }

          return Column(
            children: [
              // 1. Barra di Ricerca moderna
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() {
                      _criteria = _criteria.copyWith(searchQuery: val);
                    });
                  },
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Cerca per nome o descrizione...',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded, color: Colors.white38, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, color: Colors.white38, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _criteria = _criteria.copyWith(searchQuery: '');
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFF141418),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: primaryColor, width: 1.5),
                    ),
                  ),
                ),
              ),

              // 2. Tray dei Filtri Attivi (Chips rimovibili con un tap)
              if (!_criteria.isEmpty)
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      // Categorie
                      ..._criteria.categories.map((cat) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InputChip(
                            label: Text(CategoryHelpers.getCategoryLabel(cat)),
                            avatar: Icon(CategoryHelpers.getCategoryIcon(cat), size: 14, color: CategoryHelpers.getCategoryColor(cat)),
                            onDeleted: () {
                              final updated = Set<Tipologia>.from(_criteria.categories)..remove(cat);
                              setState(() => _criteria = _criteria.copyWith(categories: updated));
                            },
                            backgroundColor: const Color(0xFF1C1C22),
                            deleteIconColor: Colors.white54,
                            labelStyle: const TextStyle(color: Colors.white, fontSize: 11),
                            side: BorderSide(color: CategoryHelpers.getCategoryColor(cat).withOpacity(0.4)),
                          ),
                        );
                      }),

                      // Data
                      if (_criteria.dateRange != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InputChip(
                            label: Text(
                              _criteria.datePreset == 'today'
                                  ? 'Oggi'
                                  : (_criteria.datePreset == 'week'
                                      ? 'Ultimi 7 gg'
                                      : (_criteria.datePreset == 'month'
                                          ? 'Questo Mese'
                                          : '${DateFormat('dd/MM').format(_criteria.dateRange!.start)} - ${DateFormat('dd/MM').format(_criteria.dateRange!.end)}')),
                            ),
                            avatar: const Icon(Icons.calendar_today_rounded, size: 13, color: Color(0xFF10B981)),
                            onDeleted: () {
                              setState(() => _criteria = _criteria.copyWith(clearDateRange: true));
                            },
                            backgroundColor: const Color(0xFF1C1C22),
                            deleteIconColor: Colors.white54,
                            labelStyle: const TextStyle(color: Colors.white, fontSize: 11),
                            side: BorderSide(color: const Color(0xFF10B981).withOpacity(0.4)),
                          ),
                        ),

                      // Chi ha pagato
                      if (_criteria.paidByUserId != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InputChip(
                            label: Text('Pagato da: ${_getMemberName(_criteria.paidByUserId!)}'),
                            avatar: const Icon(Icons.person_rounded, size: 13, color: Color(0xFF8B5CF6)),
                            onDeleted: () {
                              setState(() => _criteria = _criteria.copyWith(clearPaidBy: true));
                            },
                            backgroundColor: const Color(0xFF1C1C22),
                            deleteIconColor: Colors.white54,
                            labelStyle: const TextStyle(color: Colors.white, fontSize: 11),
                            side: BorderSide(color: const Color(0xFF8B5CF6).withOpacity(0.4)),
                          ),
                        ),

                      // Importo
                      if (_criteria.minAmount != null || _criteria.maxAmount != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InputChip(
                            label: Text(
                              '€ ${_criteria.minAmount?.toStringAsFixed(0) ?? '0'} - ${_criteria.maxAmount?.toStringAsFixed(0) ?? '∞'}',
                            ),
                            avatar: const Icon(Icons.euro_rounded, size: 13, color: Colors.amber),
                            onDeleted: () {
                              setState(() => _criteria = _criteria.copyWith(minAmount: null, maxAmount: null));
                            },
                            backgroundColor: const Color(0xFF1C1C22),
                            deleteIconColor: Colors.white54,
                            labelStyle: const TextStyle(color: Colors.white, fontSize: 11),
                            side: BorderSide(color: Colors.amber.withOpacity(0.4)),
                          ),
                        ),

                      // Resetta tutto
                      ActionChip(
                        label: const Text('Cancella filtri'),
                        onPressed: () {
                          setState(() {
                            _criteria = const ExpenseFilterCriteria();
                            _searchController.clear();
                          });
                        },
                        backgroundColor: Colors.white10,
                        labelStyle: const TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),

              // 3. Conteggio risultati
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${filteredExpenses.length} ${filteredExpenses.length == 1 ? "spesa trovata" : "spese trovate"}',
                      style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    if (filteredExpenses.isNotEmpty)
                      Text(
                        'Totale: € ${filteredExpenses.fold<double>(0, (sum, e) => sum + e.amount).toStringAsFixed(2)}',
                        style: TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
              ),

              // 4. Lista Spese con design unificato Tab Economia
              Expanded(
                child: filteredExpenses.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.04),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.receipt_long_rounded, size: 48, color: Colors.white24),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Nessuna spesa corrisponde ai filtri',
                              style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Prova a modificare o resettare i filtri attivi',
                              style: TextStyle(color: Colors.white38, fontSize: 12),
                            ),
                            if (!_criteria.isEmpty) ...[
                              const SizedBox(height: 14),
                              TextButton.icon(
                                icon: const Icon(Icons.restart_alt_rounded, size: 16),
                                label: const Text('Resetta Filtri'),
                                style: TextButton.styleFrom(foregroundColor: primaryColor),
                                onPressed: () {
                                  setState(() {
                                    _criteria = const ExpenseFilterCriteria();
                                    _searchController.clear();
                                  });
                                },
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 80),
                        itemCount: filteredExpenses.length,
                        itemBuilder: (context, index) {
                          final expense = filteredExpenses[index];
                          return _buildUnifiedExpenseCard(expense, primaryColor);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _getMemberName(String userId) {
    final member = _groupMembers.where((m) => m.userId == userId).firstOrNull;
    return member?.nickname ?? member?.email?.split('@').first ?? 'Utente';
  }

  Widget _buildUnifiedExpenseCard(Expense expense, Color themeColor) {
    final catColor = CategoryHelpers.getCategoryColor(expense.type);
    final catIcon = CategoryHelpers.getCategoryIcon(expense.type);
    final userBalance = _balances[expense.id];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF141418),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: InkWell(
        onTap: () => _openExpenseDetails(expense),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Icona Categoria con cerchio colorato
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: catColor.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(catIcon, color: catColor, size: 22),
              ),
              const SizedBox(width: 14),

              // Dati Spesa
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.description,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          DateFormat('d MMM yyyy', 'it_IT').format(expense.date),
                          style: const TextStyle(color: Colors.white38, fontSize: 11),
                        ),
                        if (expense.isGroup && expense.paidBy != null) ...[
                          const Text(' • ', style: TextStyle(color: Colors.white24, fontSize: 11)),
                          Text(
                            'Da ${_getMemberName(expense.paidBy!)}',
                            style: const TextStyle(color: Color(0xFFA78BFA), fontSize: 11, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Importo e Bilancio Debito
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '€ ${expense.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  if (userBalance != null && userBalance.abs() > 0.01) ...[
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: userBalance > 0
                            ? const Color(0xFF10B981).withOpacity(0.18)
                            : const Color(0xFFF59E0B).withOpacity(0.18),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        userBalance > 0
                            ? '+${userBalance.toStringAsFixed(2)} €'
                            : '${userBalance.toStringAsFixed(2)} €',
                        style: TextStyle(
                          color: userBalance > 0 ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded, color: Colors.white24, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
