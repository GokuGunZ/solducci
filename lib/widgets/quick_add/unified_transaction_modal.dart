import 'package:flutter/material.dart';
import 'package:solducci/features/csv_importer/views/widgets/category_picker_sheet.dart';
import 'package:solducci/models/asset_class.dart';
import 'package:solducci/models/expense.dart';
import 'package:solducci/models/expense_asset_allocation.dart';
import 'package:solducci/models/expense_form.dart';
import 'package:solducci/models/income.dart';
import 'package:solducci/models/income_category.dart';
import 'package:solducci/models/investment_asset.dart';
import 'package:solducci/models/investment_portfolio.dart';
import 'package:solducci/models/wallet.dart';
import 'package:solducci/models/wallet_transfer.dart';
import 'package:solducci/service/expense_service_cached.dart';
import 'package:solducci/service/income_service.dart';
import 'package:solducci/service/investment_asset_service.dart';
import 'package:solducci/service/investment_portfolio_service.dart';
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
  final _quantityController = TextEditingController();
  final DateTime _date = DateTime.now();

  Wallet? _selectedWallet;
  Wallet? _toWallet; // Per giroconto
  Tipologia _expenseCategory = Tipologia.cibo;
  IncomeCategory _incomeCategory = IncomeCategory.stipendio;
  bool _isLoading = false;

  // Stato per Spese Investimento
  List<InvestmentPortfolio> _portfolios = [];
  InvestmentPortfolio? _selectedPortfolio;
  List<InvestmentAsset> _portfolioAssets = [];
  InvestmentAsset? _selectedAsset;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    _initWallets();
    _initInvestments();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _initInvestments() async {
    final portfolios = await InvestmentPortfolioService().fetchPortfolios();
    await InvestmentAssetService().fetchAllAssets();
    if (mounted && portfolios.isNotEmpty) {
      setState(() {
        _portfolios = portfolios;
        _selectedPortfolio = portfolios.first;
        _loadPortfolioAssets();
      });
    }
  }

  void _loadPortfolioAssets() {
    if (_selectedPortfolio == null) {
      setState(() {
        _portfolioAssets = [];
        _selectedAsset = null;
      });
      return;
    }
    final assets = InvestmentAssetService().getAssetsForPortfolio(_selectedPortfolio!.id);
    setState(() {
      _portfolioAssets = assets;
      _selectedAsset = assets.isNotEmpty ? assets.first : null;
    });
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
          portfolioId: _expenseCategory == Tipologia.investimento ? _selectedPortfolio?.id : null,
        );
        final created = await ExpenseServiceCached().createExpense(newExp);

        // Se è un investimento ed è stato selezionato un asset, registriamo l'allocazione
        if (_expenseCategory == Tipologia.investimento && _selectedAsset != null) {
          final cleanQty = _quantityController.text.replaceAll(',', '.').trim();
          final qty = double.tryParse(cleanQty) ?? 1.0;
          final unitPrice = qty > 0 ? (amount / qty) : amount;

          await InvestmentAssetService().recordExpenseAllocations(
            expenseId: created.id,
            allocations: [
              ExpenseAssetAllocation(
                id: '',
                expenseId: created.id,
                assetId: _selectedAsset!.id,
                amount: amount,
                quantity: qty > 0 ? qty : 1.0,
                pricePerUnit: unitPrice > 0 ? unitPrice : amount,
              ),
            ],
          );
        }
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
                ),

              // Sezione Dettaglio Investimento
              if (_mode == TransactionMode.expense && _expenseCategory == Tipologia.investimento) ...[
                const SizedBox(height: 14),
                _buildInvestmentAllocationSection(),
              ] else if (_mode == TransactionMode.transfer)
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

  Widget _buildInvestmentAllocationSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1).withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.trending_up_rounded, color: Color(0xFF818CF8), size: 16),
                  SizedBox(width: 6),
                  Text(
                    'DESTINAZIONE INVESTIMENTO',
                    style: TextStyle(
                      color: Color(0xFF818CF8),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => _showCreatePortfolioDialog(context),
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    children: [
                      Icon(Icons.add, size: 14, color: Color(0xFF818CF8)),
                      SizedBox(width: 4),
                      Text('+ Portafoglio', style: TextStyle(color: Color(0xFF818CF8), fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Selettore Portafoglio
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E22),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<InvestmentPortfolio>(
                value: _portfolios.any((p) => p.id == _selectedPortfolio?.id) ? _selectedPortfolio : null,
                dropdownColor: const Color(0xFF27272A),
                hint: const Text('Seleziona Portafoglio...', style: TextStyle(color: Colors.white38, fontSize: 13)),
                isExpanded: true,
                items: _portfolios.map((p) {
                  return DropdownMenuItem<InvestmentPortfolio>(
                    value: p,
                    child: Row(
                      children: [
                        Icon(p.iconData, size: 15, color: p.color),
                        const SizedBox(width: 8),
                        Expanded(child: Text(p.name, style: const TextStyle(color: Colors.white, fontSize: 13), overflow: TextOverflow.ellipsis)),
                        if (p.brokerName != null)
                          Text('(${p.brokerName})', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (newP) {
                  if (newP != null) {
                    setState(() {
                      _selectedPortfolio = newP;
                      _loadPortfolioAssets();
                    });
                  }
                },
              ),
            ),
          ),

          if (_selectedPortfolio != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                // Selettore Asset
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E22),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<InvestmentAsset>(
                        value: _portfolioAssets.any((a) => a.id == _selectedAsset?.id) ? _selectedAsset : null,
                        dropdownColor: const Color(0xFF27272A),
                        hint: const Text('Asset (opzionale)', style: TextStyle(color: Colors.white38, fontSize: 13)),
                        isExpanded: true,
                        items: _portfolioAssets.map((a) {
                          return DropdownMenuItem<InvestmentAsset>(
                            value: a,
                            child: Row(
                              children: [
                                Icon(a.assetClass.icon, size: 14, color: a.assetClass.color),
                                const SizedBox(width: 6),
                                Expanded(child: Text(a.name, style: const TextStyle(color: Colors.white, fontSize: 13), overflow: TextOverflow.ellipsis)),
                                if (a.ticker != null)
                                  Text(a.ticker!, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (newA) => setState(() => _selectedAsset = newA),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => _showCreateAssetDialog(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF27272A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.add, size: 14, color: Colors.white70),
                        SizedBox(width: 4),
                        Text('Asset', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            if (_selectedAsset != null) ...[
              const SizedBox(height: 10),
              TextField(
                controller: _quantityController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Quantità / Quote acquistate (es. 2.50)...',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFF1E1E22),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  void _showCreatePortfolioDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final brokerCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Nuovo Portafoglio Investimenti', style: TextStyle(color: Colors.white, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Nome (es. PAC ETF, Crypto...)',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF27272A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: brokerCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Broker / Piattaforma (es. Degiro, Binance...)',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF27272A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
              final name = nameCtrl.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(ctx);
                final created = await InvestmentPortfolioService().createPortfolio(
                  name: name,
                  brokerName: brokerCtrl.text.trim().isNotEmpty ? brokerCtrl.text.trim() : null,
                );
                setState(() {
                  _portfolios = InvestmentPortfolioService().currentPortfolios;
                  _selectedPortfolio = created;
                  _loadPortfolioAssets();
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Crea', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showCreateAssetDialog(BuildContext context) {
    if (_selectedPortfolio == null) return;
    final nameCtrl = TextEditingController();
    final tickerCtrl = TextEditingController();
    AssetClass selectedClass = AssetClass.etf;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E22),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Nuovo Asset nel Portafoglio', style: TextStyle(color: Colors.white, fontSize: 18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Nome (es. Vanguard All-World, Bitcoin...)',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: const Color(0xFF27272A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: tickerCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Ticker / Simbolo opzionale (es. VWCE, BTC...)',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: const Color(0xFF27272A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonHideUnderline(
                child: DropdownButton<AssetClass>(
                  value: selectedClass,
                  dropdownColor: const Color(0xFF27272A),
                  isExpanded: true,
                  items: AssetClass.values.map((ac) {
                    return DropdownMenuItem<AssetClass>(
                      value: ac,
                      child: Row(
                        children: [
                          Icon(ac.icon, size: 16, color: ac.color),
                          const SizedBox(width: 8),
                          Text(ac.label, style: const TextStyle(color: Colors.white, fontSize: 13)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (newClass) {
                    if (newClass != null) {
                      setDialogState(() => selectedClass = newClass);
                    }
                  },
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
                final name = nameCtrl.text.trim();
                if (name.isNotEmpty) {
                  Navigator.pop(ctx);
                  final created = await InvestmentAssetService().createAsset(
                    portfolioId: _selectedPortfolio!.id,
                    name: name,
                    ticker: tickerCtrl.text.trim().isNotEmpty ? tickerCtrl.text.trim() : null,
                    assetClass: selectedClass,
                  );
                  setState(() {
                    _loadPortfolioAssets();
                    _selectedAsset = created;
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Aggiungi', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
