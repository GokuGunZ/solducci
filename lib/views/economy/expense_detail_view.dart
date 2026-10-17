import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:solducci/models/expense.dart';
import 'package:solducci/models/expense_form.dart';
import 'package:solducci/models/group.dart';
import 'package:solducci/models/split_type.dart';
import 'package:solducci/service/expense_service_cached.dart';
import 'package:solducci/service/group_service_cached.dart';
import 'package:solducci/service/wallet_service.dart';
import 'package:solducci/models/wallet.dart';
import 'package:solducci/utils/category_helpers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ExpenseDetailView extends StatefulWidget {
  final int expenseId;
  final Expense? initialExpense;

  const ExpenseDetailView({
    super.key,
    required this.expenseId,
    this.initialExpense,
  });

  @override
  State<ExpenseDetailView> createState() => _ExpenseDetailViewState();
}

class _ExpenseDetailViewState extends State<ExpenseDetailView> {
  final _expenseService = ExpenseServiceCached();
  final _groupService = GroupServiceCached();
  final _walletService = WalletService();

  Expense? _expense;
  bool _isLoading = true;
  String? _errorMessage;

  ExpenseGroup? _group;
  List<GroupMember> _groupMembers = [];
  Map<String, double> _resolvedSplits = {};
  Wallet? _wallet;

  @override
  void initState() {
    super.initState();
    _expense = widget.initialExpense;
    _loadExpenseData();
  }

  Future<void> _loadExpenseData() async {
    try {
      Expense? exp = _expense;
      exp ??= await _expenseService.getById(widget.expenseId) ??
          await _expenseService.fetchById(widget.expenseId);

      if (exp == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Spesa non trovata o rimossa.';
          });
        }
        return;
      }

      _expense = exp;

      // Load group & members if group expense
      if (exp.groupId != null) {
        final g = await _groupService.getGroupById(exp.groupId!);
        final members = await _groupService.getGroupMembers(exp.groupId!);
        _group = g;
        _groupMembers = members;
        _computeSplits(exp, members);
      }

      // Load wallet if present
      if (exp.walletId != null) {
        final wallets = await _walletService.fetchWallets();
        _wallet = wallets.where((w) => w.id == exp?.walletId).firstOrNull;
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Errore nel caricamento: $e';
        });
      }
    }
  }

  void _computeSplits(Expense exp, List<GroupMember> members) {
    final Map<String, double> splits = {};
    if (exp.splitType == SplitType.custom && exp.splitData != null) {
      splits.addAll(exp.splitData!);
    } else if (exp.splitType == SplitType.equal && members.isNotEmpty) {
      final perPerson = exp.amount / members.length;
      final rounded = double.parse(perPerson.toStringAsFixed(2));
      for (final m in members) {
        splits[m.userId] = rounded;
      }
    }
    _resolvedSplits = splits;
  }

  String _getPayerName(String? payerId) {
    if (payerId == null) return 'Non specificato';
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (payerId == currentUserId) return 'Tu';
    for (final m in _groupMembers) {
      if (m.userId == payerId) {
        return m.nickname ?? m.email?.split('@').first ?? 'Utente';
      }
    }
    return 'Utente';
  }

  String _getUserName(String userId) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == currentUserId) return 'Tu';
    for (final m in _groupMembers) {
      if (m.userId == userId) {
        return m.nickname ?? m.email?.split('@').first ?? 'Utente';
      }
    }
    return 'Utente';
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 24),
            SizedBox(width: 10),
            Text(
              'Elimina Spesa',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'Sei sicuro di voler eliminare questa spesa? Questa azione non può essere annullata.',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annulla', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Elimina', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await _expenseService.delete(widget.expenseId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Spesa eliminata con successo'),
              backgroundColor: Color(0xFF18181B),
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Errore durante l\'eliminazione: $e'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _openEditModal() async {
    if (_expense == null) return;

    final updated = await showModalBottomSheet<Expense>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EditExpenseSheet(
        expense: _expense!,
        groupMembers: _groupMembers,
      ),
    );

    if (updated != null && mounted) {
      setState(() {
        _expense = updated;
        if (updated.groupId != null && _groupMembers.isNotEmpty) {
          _computeSplits(updated, _groupMembers);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF09090B),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF10B981)),
        ),
      );
    }

    if (_errorMessage != null || _expense == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF09090B),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 48),
                const SizedBox(height: 16),
                Text(
                  _errorMessage ?? 'Spesa non trovata',
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF18181B),
                    side: BorderSide(color: Colors.white.withOpacity(0.1)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Torna Indietro', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final expense = _expense!;
    final categoryColor = CategoryHelpers.getCategoryColor(expense.type);
    final categoryIcon = CategoryHelpers.getCategoryIcon(expense.type);
    final categoryLabel = CategoryHelpers.getCategoryLabel(expense.type);
    final dateFormat = DateFormat('EEEE, d MMMM yyyy', 'it_IT');
    final timeFormat = DateFormat('HH:mm');

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Dettaglio Spesa',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.white70, size: 20),
            onPressed: _openEditModal,
            tooltip: 'Modifica',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 21),
            onPressed: _confirmDelete,
            tooltip: 'Elimina',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero Card
            _buildHeroCard(expense, categoryColor, categoryIcon, categoryLabel, dateFormat, timeFormat),
            const SizedBox(height: 20),

            // Payer & Group Info
            _buildPayerCard(expense),
            const SizedBox(height: 16),

            // Splits Breakdown if Group Expense
            if (expense.isGroup) ...[
              _buildSplitsCard(expense),
              const SizedBox(height: 16),
            ],

            // Wallet Info if linked
            if (_wallet != null) ...[
              _buildWalletCard(_wallet!),
              const SizedBox(height: 16),
            ],

            // Technical Meta Card
            _buildMetaCard(expense),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(
    Expense expense,
    Color categoryColor,
    IconData categoryIcon,
    String categoryLabel,
    DateFormat dateFormat,
    DateFormat timeFormat,
  ) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF141416),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: categoryColor.withOpacity(0.08),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Category Icon badge
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: categoryColor.withOpacity(0.14),
              shape: BoxShape.circle,
              border: Border.all(color: categoryColor.withOpacity(0.35), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: categoryColor.withOpacity(0.25),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(categoryIcon, color: categoryColor, size: 30),
          ),
          const SizedBox(height: 16),

          // Amount
          Text(
            '-€${expense.amount.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.2,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 6),

          // Description
          Text(
            expense.description.isNotEmpty ? expense.description : 'Spesa senza titolo',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Tags row
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              // Category tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: categoryColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(categoryIcon, size: 13, color: categoryColor),
                    const SizedBox(width: 5),
                    Text(
                      categoryLabel,
                      style: TextStyle(
                        color: categoryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // Date Tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.access_time_rounded, size: 13, color: Colors.white60),
                    const SizedBox(width: 5),
                    Text(
                      '${timeFormat.format(expense.date)} • ${dateFormat.format(expense.date)}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPayerCard(Expense expense) {
    final isGroup = expense.isGroup;
    final payerName = _getPayerName(expense.paidBy);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF141416),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isGroup ? Icons.group_rounded : Icons.person_rounded,
                color: const Color(0xFF6366F1),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                isGroup ? 'SPESA DI GRUPPO' : 'SPESA PERSONALE',
                style: const TextStyle(
                  color: Color(0xFF818CF8),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF27272A),
                child: Text(
                  payerName.isNotEmpty ? payerName[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payerName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isGroup
                          ? 'Ha anticipato l\'intero importo di €${expense.amount.toStringAsFixed(2)}'
                          : 'Spesa addebitata sul tuo profilo personale',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (isGroup && _group != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Text(
                    _group!.name,
                    style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSplitsCard(Expense expense) {
    String splitMethodLabel = 'Divisione Equa';
    if (expense.splitType == SplitType.custom) {
      splitMethodLabel = 'Quote Personalizzate';
    } else if (expense.splitType == SplitType.offer) {
      splitMethodLabel = 'Offerto interamente';
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF141416),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.pie_chart_outline_rounded, color: Color(0xFF10B981), size: 18),
                  SizedBox(width: 8),
                  Text(
                    'RIPARTIZIONE SPESA',
                    style: TextStyle(
                      color: Color(0xFF34D399),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  splitMethodLabel,
                  style: const TextStyle(
                    color: Color(0xFF34D399),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_resolvedSplits.isEmpty)
            const Text(
              'Nessuna quota registrata.',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            )
          else
            ..._resolvedSplits.entries.map((entry) {
              final userName = _getUserName(entry.key);
              final isPayer = entry.key == expense.paidBy;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: isPayer
                          ? const Color(0xFF10B981).withOpacity(0.2)
                          : Colors.white.withOpacity(0.08),
                      child: Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: isPayer ? const Color(0xFF10B981) : Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        userName,
                        style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w500),
                      ),
                    ),
                    if (isPayer)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Payer',
                          style: TextStyle(color: Color(0xFF34D399), fontSize: 9.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                    Text(
                      '€${entry.value.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildWalletCard(Wallet wallet) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF141416),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.14),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF60A5FA), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PORTAFOGLIO ADDEBITATO',
                  style: TextStyle(
                    color: Color(0xFF60A5FA),
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  wallet.name,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Text(
            '€${wallet.currentBalance.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaCard(Expense expense) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF141416),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DETTAGLI TRANSAZIONE',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          _buildMetaRow('ID Spesa', '#${expense.id}'),
          const Divider(color: Colors.white10, height: 16),
          _buildMetaRow(
            'Stato Sincronizzazione',
            'Sincronizzato Cloud',
            trailingIcon: Icons.cloud_done_rounded,
            trailingColor: const Color(0xFF10B981),
          ),
          if (expense.recurringTransactionId != null) ...[
            const Divider(color: Colors.white10, height: 16),
            _buildMetaRow('Da Ricorrente', 'Sì (Template collegato)'),
          ],
        ],
      ),
    );
  }

  Widget _buildMetaRow(String label, String value, {IconData? trailingIcon, Color? trailingColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12.5)),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trailingIcon != null) ...[
              Icon(trailingIcon, size: 14, color: trailingColor ?? Colors.white70),
              const SizedBox(width: 4),
            ],
            Text(
              value,
              style: TextStyle(
                color: trailingColor ?? Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _EditExpenseSheet extends StatefulWidget {
  final Expense expense;
  final List<GroupMember> groupMembers;

  const _EditExpenseSheet({
    required this.expense,
    required this.groupMembers,
  });

  @override
  State<_EditExpenseSheet> createState() => _EditExpenseSheetState();
}

class _EditExpenseSheetState extends State<_EditExpenseSheet> {
  late TextEditingController _descController;
  late TextEditingController _amountController;
  late Tipologia _selectedCategory;
  late DateTime _selectedDate;
  String? _selectedPayerId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _descController = TextEditingController(text: widget.expense.description);
    _amountController = TextEditingController(text: widget.expense.amount.toStringAsFixed(2));
    _selectedCategory = widget.expense.type;
    _selectedDate = widget.expense.date;
    _selectedPayerId = widget.expense.paidBy;
  }

  @override
  void dispose() {
    _descController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF10B981),
              surface: Color(0xFF18181B),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDate.hour,
          _selectedDate.minute,
        );
      });
    }
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountController.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inserisci un importo valido.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final updated = widget.expense.copyWith(
        description: _descController.text.trim(),
        amount: amount,
        type: _selectedCategory,
        date: _selectedDate,
        paidBy: _selectedPayerId,
      );

      final result = await ExpenseServiceCached().update(updated);

      if (mounted) {
        Navigator.pop(context, result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore salvataggio: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF18181B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Modifica Spesa',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 18),

            // Description
            TextField(
              controller: _descController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Descrizione',
                labelStyle: const TextStyle(color: Colors.white60),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF10B981)),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Amount
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Importo (€)',
                labelStyle: const TextStyle(color: Colors.white60),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF10B981)),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Date selector
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              tileColor: Colors.white.withOpacity(0.05),
              leading: const Icon(Icons.calendar_today_rounded, color: Color(0xFF10B981), size: 20),
              title: const Text('Data', style: TextStyle(color: Colors.white70, fontSize: 13)),
              trailing: Text(
                DateFormat('dd/MM/yyyy').format(_selectedDate),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              onTap: _pickDate,
            ),
            const SizedBox(height: 16),

            // Category Selector
            const Text(
              'Categoria',
              style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: Tipologia.values.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = Tipologia.values[index];
                  final isSelected = _selectedCategory == cat;
                  final catColor = CategoryHelpers.getCategoryColor(cat);
                  final catIcon = CategoryHelpers.getCategoryIcon(cat);

                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? catColor.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? catColor : Colors.white10,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(catIcon, color: isSelected ? catColor : Colors.white60, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            CategoryHelpers.getCategoryLabel(cat),
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                      )
                    : const Text(
                        'Salva Modifiche',
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
