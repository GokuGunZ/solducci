import 'package:flutter/material.dart';
import 'package:solducci/features/csv_importer/views/widgets/category_picker_sheet.dart';
import 'package:solducci/models/expense.dart';
import 'package:solducci/models/expense_form.dart';
import 'package:solducci/models/income.dart';
import 'package:solducci/models/income_category.dart';
import 'package:solducci/models/wallet.dart';
import 'package:solducci/models/wallet_transfer.dart';
import 'package:solducci/service/expense_service_cached.dart';
import 'package:solducci/service/income_service.dart';
import 'package:solducci/service/wallet_service.dart';
import 'package:solducci/service/wallet_transfer_service.dart';
import 'package:solducci/theme/app_theme.dart';

enum TransactionMode { expense, income, transfer }

class UnifiedTransactionModal extends StatefulWidget {
  final TransactionMode initialMode;

  const UnifiedTransactionModal({
    super.key,
    this.initialMode = TransactionMode.expense,
  });

  static Future<void> show(BuildContext context, {TransactionMode mode = TransactionMode.expense}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => UnifiedTransactionModal(initialMode: mode),
    );
  }

  @override
  State<UnifiedTransactionModal> createState() => _UnifiedTransactionModalState();
}

class _UnifiedTransactionModalState extends State<UnifiedTransactionModal> {
  late TransactionMode _mode;
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  DateTime _date = DateTime.now();

  Wallet? _selectedWallet;
  Wallet? _toWallet; // Per giroconto
  Tipologia _expenseCategory = Tipologia.cibo;
  IncomeCategory _incomeCategory = IncomeCategory.stipendio;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    _initWallets();
  }

  Future<void> _initWallets() async {
    final wallets = await WalletService().fetchWallets();
    if (mounted && wallets.isNotEmpty) {
      setState(() {
        _selectedWallet = WalletService().getDefaultWallet() ?? wallets.first;
        if (wallets.length > 1) {
          _toWallet = wallets.firstWhere((w) => w.id != _selectedWallet?.id, orElse: () => wallets.last);
        }
      });
    }
  }

  Color get _accentColor {
    switch (_mode) {
      case TransactionMode.expense:
        return const Color(0xFF6366F1); // Indigo
      case TransactionMode.income:
        return AppTheme.success; // Emerald
      case TransactionMode.transfer:
        return AppTheme.warning; // Amber
    }
  }

  Future<void> _submit() async {
    final cleanAmt = _amountController.text.replaceAll('.', '').replaceAll(',', '.').trim();
    final amount = double.tryParse(cleanAmt);

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inserisci un importo valido maggiore di 0'), backgroundColor: AppTheme.error),
      );
      return;
    }

    final desc = _descController.text.trim();
    if (desc.isEmpty && _mode != TransactionMode.transfer) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inserisci una descrizione'), backgroundColor: AppTheme.error),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_mode == TransactionMode.expense) {
        final newExp = Expense(
          id: -1,
          description: desc,
          amount: amount,
          date: _date,
          type: _expenseCategory,
          walletId: _selectedWallet?.id,
        );
        await ExpenseServiceCached().createExpense(newExp);
      } else if (_mode == TransactionMode.income) {
        final newInc = Income(
          id: '',
          userId: '',
          walletId: _selectedWallet?.id,
          amount: amount,
          description: desc,
          date: _date,
          category: _incomeCategory,
        );
        await IncomeService().createIncome(newInc);
      } else if (_mode == TransactionMode.transfer) {
        if (_selectedWallet == null || _toWallet == null || _selectedWallet?.id == _toWallet?.id) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Seleziona due portafogli diversi per il giroconto'), backgroundColor: AppTheme.error),
          );
          setState(() => _isLoading = false);
          return;
        }

        final newTrf = WalletTransfer(
          id: '',
          userId: '',
          fromWalletId: _selectedWallet!.id,
          toWalletId: _toWallet!.id,
          amount: amount,
          date: _date,
          notes: desc.isNotEmpty ? desc : 'Giroconto interno',
        );
        await WalletTransferService().createTransfer(newTrf);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_mode == TransactionMode.expense
                ? 'Spesa salvata!'
                : (_mode == TransactionMode.income ? 'Entrata registrata!' : 'Giroconto completato!')),
            backgroundColor: _accentColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final wallets = WalletService().currentWallets;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
              const SizedBox(height: 16),

              // Segmented Pill: Spesa / Entrata / Giroconto
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF141417),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    _buildPillTab('🔴 Spesa', TransactionMode.expense),
                    _buildPillTab('🟢 Entrata', TransactionMode.income),
                    _buildPillTab('🔄 Giro', TransactionMode.transfer),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Campo Importo Gigante
              Center(
                child: IntrinsicWidth(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '€',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: _accentColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 170,
                        child: TextField(
                          controller: _amountController,
                          autofocus: true,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          decoration: InputDecoration(
                            hintText: '0,00',
                            hintStyle: TextStyle(color: Colors.white24, fontSize: 34),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Campo Descrizione
              TextField(
                controller: _descController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: _mode == TransactionMode.transfer ? 'Note opzionali...' : 'Descrizione...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: const Color(0xFF27272A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),

              const SizedBox(height: 14),

              // Riga Selettori: Portafoglio + Categoria
              if (_mode != TransactionMode.transfer)
                Row(
                  children: [
                    // Selettore Wallet
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF27272A),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<Wallet>(
                            value: wallets.any((w) => w.id == _selectedWallet?.id) ? _selectedWallet : null,
                            dropdownColor: const Color(0xFF27272A),
                            hint: const Text('Portafoglio', style: TextStyle(color: Colors.white38, fontSize: 13)),
                            isExpanded: true,
                            items: wallets.map((w) {
                              return DropdownMenuItem<Wallet>(
                                value: w,
                                child: Row(
                                  children: [
                                    Icon(w.type.icon, size: 16, color: w.color),
                                    const SizedBox(width: 8),
                                    Flexible(child: Text(w.name, style: const TextStyle(color: Colors.white, fontSize: 13), overflow: TextOverflow.ellipsis)),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (val) => setState(() => _selectedWallet = val),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    // Selettore Categoria
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          if (_mode == TransactionMode.expense) {
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.transparent,
                              isScrollControlled: true,
                              builder: (ctx) => CategoryPickerSheet(
                                currentCategory: _expenseCategory,
                                onCategorySelected: (cat) => setState(() => _expenseCategory = cat),
                              ),
                            );
                          } else {
                            // Selettore Categoria Entrata
                            _showIncomeCategoryPicker(context);
                          }
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF27272A),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _mode == TransactionMode.expense
                                    ? CategoryPickerSheet.getIcon(_expenseCategory)
                                    : _incomeCategory.icon,
                                size: 16,
                                color: _mode == TransactionMode.expense
                                    ? CategoryPickerSheet.getColor(_expenseCategory)
                                    : _incomeCategory.color,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _mode == TransactionMode.expense ? _expenseCategory.label : _incomeCategory.label,
                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(Icons.arrow_drop_down, color: Colors.white54, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              else
                // Giroconto: Da Wallet -> A Wallet
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF27272A),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<Wallet>(
                            value: wallets.any((w) => w.id == _selectedWallet?.id) ? _selectedWallet : null,
                            dropdownColor: const Color(0xFF27272A),
                            hint: const Text('Da Conto', style: TextStyle(color: Colors.white38, fontSize: 13)),
                            isExpanded: true,
                            items: wallets.map((w) => DropdownMenuItem(value: w, child: Text(w.name, style: const TextStyle(color: Colors.white, fontSize: 13), overflow: TextOverflow.ellipsis))).toList(),
                            onChanged: (val) => setState(() => _selectedWallet = val),
                          ),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.arrow_forward_rounded, color: AppTheme.warning, size: 18),
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF27272A),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<Wallet>(
                            value: wallets.any((w) => w.id == _toWallet?.id) ? _toWallet : null,
                            dropdownColor: const Color(0xFF27272A),
                            hint: const Text('A Conto', style: TextStyle(color: Colors.white38, fontSize: 13)),
                            isExpanded: true,
                            items: wallets.map((w) => DropdownMenuItem(value: w, child: Text(w.name, style: const TextStyle(color: Colors.white, fontSize: 13), overflow: TextOverflow.ellipsis))).toList(),
                            onChanged: (val) => setState(() => _toWallet = val),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 24),

              // Pulsante Salva
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentColor,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : Text(
                          _mode == TransactionMode.expense
                              ? 'Salva Spesa'
                              : (_mode == TransactionMode.income ? 'Registra Entrata' : 'Esegui Giroconto'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPillTab(String title, TransactionMode mode) {
    final isSel = _mode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _mode = mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSel ? _accentColor.withOpacity(0.25) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSel ? Border.all(color: _accentColor, width: 1.2) : null,
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              color: isSel ? Colors.white : Colors.white54,
              fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  void _showIncomeCategoryPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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
              const Text('Categoria Entrata', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: IncomeCategory.values.map((cat) {
                  final isSel = cat == _incomeCategory;
                  return InkWell(
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() => _incomeCategory = cat);
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSel ? cat.color.withOpacity(0.25) : const Color(0xFF27272A),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: isSel ? cat.color : Colors.white10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(cat.icon, size: 18, color: cat.color),
                          const SizedBox(width: 8),
                          Text(cat.label, style: TextStyle(color: isSel ? Colors.white : Colors.white70, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
