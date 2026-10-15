import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:solducci/models/recurring_transaction.dart';
import 'package:solducci/models/split_type.dart';
import 'package:solducci/models/wallet.dart';
import 'package:solducci/service/auth_service.dart';
import 'package:solducci/service/context_manager.dart';
import 'package:solducci/service/recurring_transaction_service.dart';
import 'package:solducci/service/wallet_service.dart';

class RecurringFormSheet extends StatefulWidget {
  final RecurringTransaction? existingItem;
  final bool? initialIsIncome;
  final String? initialTitle;
  final double? initialAmount;
  final String? initialCategory;
  final String? initialWalletId;

  const RecurringFormSheet({
    super.key,
    this.existingItem,
    this.initialIsIncome,
    this.initialTitle,
    this.initialAmount,
    this.initialCategory,
    this.initialWalletId,
  });

  static Future<void> show(
    BuildContext context, {
    RecurringTransaction? existingItem,
    bool? initialIsIncome,
    String? initialTitle,
    double? initialAmount,
    String? initialCategory,
    String? initialWalletId,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF131316),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => RecurringFormSheet(
        existingItem: existingItem,
        initialIsIncome: initialIsIncome,
        initialTitle: initialTitle,
        initialAmount: initialAmount,
        initialCategory: initialCategory,
        initialWalletId: initialWalletId,
      ),
    );
  }

  @override
  State<RecurringFormSheet> createState() => _RecurringFormSheetState();
}

class _RecurringFormSheetState extends State<RecurringFormSheet> {
  final _service = RecurringTransactionService();
  final _contextManager = ContextManager();

  late bool _isIncome;
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _notesController;
  late bool _isVariableAmount;
  late bool _requiresConfirmation;
  late RecurringFrequency _frequency;
  late DateTime _nextDueDate;
  DateTime? _endDate;
  String? _selectedWalletId;
  String _selectedCategory = 'casa';
  SplitType _splitType = SplitType.equal;

  List<Wallet> _wallets = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final item = widget.existingItem;

    _isIncome = item?.isIncome ?? widget.initialIsIncome ?? false;
    _titleController = TextEditingController(text: item?.title ?? widget.initialTitle ?? '');
    final initialAmt = item != null
        ? item.amount.toStringAsFixed(2)
        : (widget.initialAmount != null && widget.initialAmount! > 0 ? widget.initialAmount!.toStringAsFixed(2) : '');
    _amountController = TextEditingController(text: initialAmt);
    _notesController = TextEditingController(text: item?.notes ?? '');
    _isVariableAmount = item?.isVariableAmount ?? false;
    _requiresConfirmation = item?.requiresConfirmation ?? false;
    _frequency = item?.frequency ?? RecurringFrequency.monthly;
    _nextDueDate = item?.nextDueDate ?? DateTime.now();
    _endDate = item?.endDate;
    _selectedWalletId = item?.walletId ?? widget.initialWalletId;
    _selectedCategory = item?.category ?? widget.initialCategory ?? (_isIncome ? 'stipendio' : 'casa');
    _splitType = item?.splitType ?? SplitType.equal;

    _loadWallets();
  }

  Future<void> _loadWallets() async {
    try {
      final wallets = await WalletService().fetchWallets();
      if (mounted) {
        setState(() {
          _wallets = wallets;
          if (_selectedWalletId == null && wallets.isNotEmpty) {
            _selectedWalletId = wallets.firstWhere((w) => w.isDefault, orElse: () => wallets.first).id;
          }
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final amountText = _amountController.text.trim().replaceAll(',', '.');
    final amount = double.tryParse(amountText);

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inserisci un titolo per la ricorrenza'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    if (amount == null || amount < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inserisci un importo valido'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    setState(() => _isSaving = true);
    HapticFeedback.selectionClick();

    final currentContext = _contextManager.currentContext;
    final currentUserId = AuthService().currentUserId ?? '';

    try {
      final item = RecurringTransaction(
        id: widget.existingItem?.id ?? '',
        userId: widget.existingItem?.userId ?? currentUserId,
        isIncome: _isIncome,
        title: title,
        amount: amount,
        isVariableAmount: _isVariableAmount,
        category: _selectedCategory,
        walletId: _selectedWalletId,
        groupId: currentContext.isGroup ? currentContext.groupId : null,
        paidBy: currentContext.isGroup ? currentUserId : null,
        splitType: _splitType,
        frequency: _frequency,
        intervalCount: 1,
        dayOfMonth: _nextDueDate.day,
        dayOfWeek: _nextDueDate.weekday % 7,
        startDate: widget.existingItem?.startDate ?? DateTime.now(),
        endDate: _endDate,
        nextDueDate: _nextDueDate,
        requiresConfirmation: _requiresConfirmation || _isVariableAmount,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        createdAt: widget.existingItem?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.existingItem != null) {
        await _service.updateRecurringTransaction(item);
      } else {
        await _service.createRecurringTransaction(item);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existingItem != null ? 'Ricorrenza aggiornata!' : 'Nuova ricorrenza creata!',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving recurring transaction: $e');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = _isIncome ? const Color(0xFF10B981) : const Color(0xFF6366F1);

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),

          // Header with Income/Expense toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.existingItem != null ? 'Modifica Ricorrenza' : 'Nuova Ricorrenza',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              // Segmented Toggle Spesa / Entrata
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF27272A),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(2),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => setState(() {
                        _isIncome = false;
                        _selectedCategory = 'casa';
                      }),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: !_isIncome ? const Color(0xFF6366F1) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Uscita',
                          style: TextStyle(
                            color: !_isIncome ? Colors.white : Colors.white60,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => setState(() {
                        _isIncome = true;
                        _selectedCategory = 'stipendio';
                      }),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _isIncome ? const Color(0xFF10B981) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Entrata',
                          style: TextStyle(
                            color: _isIncome ? Colors.black : Colors.white60,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Form Fields (Scrollable)
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                // Title Field
                TextField(
                  controller: _titleController,
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: 'Titolo *',
                    labelStyle: const TextStyle(color: Colors.white60),
                    hintText: _isIncome ? 'es. Stipendio, Rendita affitto' : 'es. Netflix, Affitto, Bolletta Luce',
                    hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                    filled: true,
                    fillColor: const Color(0xFF1C1C21),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: themeColor, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),

                // Amount & Variable Toggle Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          labelText: _isVariableAmount ? 'Importo stimato (€) *' : 'Importo fisso (€) *',
                          labelStyle: const TextStyle(color: Colors.white60),
                          prefixText: '€ ',
                          prefixStyle: TextStyle(color: themeColor, fontWeight: FontWeight.bold),
                          filled: true,
                          fillColor: const Color(0xFF1C1C21),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: themeColor, width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Variable chip button
                    Expanded(
                      flex: 2,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _isVariableAmount = !_isVariableAmount;
                            if (_isVariableAmount) {
                              _requiresConfirmation = true;
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: _isVariableAmount ? Colors.amber.withOpacity(0.18) : const Color(0xFF1C1C21),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _isVariableAmount ? Colors.amber : Colors.white12,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.tune_rounded,
                                size: 16,
                                color: _isVariableAmount ? Colors.amber : Colors.white54,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Variabile',
                                style: TextStyle(
                                  color: _isVariableAmount ? Colors.amber : Colors.white60,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Frequency Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C21),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 16, color: Colors.white54),
                      const SizedBox(width: 10),
                      const Text('Frequenza:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<RecurringFrequency>(
                            value: _frequency,
                            dropdownColor: const Color(0xFF27272A),
                            borderRadius: BorderRadius.circular(12),
                            items: RecurringFrequency.values.map((f) {
                              return DropdownMenuItem(
                                value: f,
                                child: Text(f.label, style: const TextStyle(color: Colors.white, fontSize: 13)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _frequency = val);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Next Due Date Picker
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _nextDueDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                      builder: (ctx, child) => Theme(
                        data: ThemeData.dark().copyWith(colorScheme: ColorScheme.dark(primary: themeColor)),
                        child: child!,
                      ),
                    );
                    if (picked != null) {
                      setState(() => _nextDueDate = picked);
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C21),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.event_available_rounded, size: 16, color: themeColor),
                        const SizedBox(width: 10),
                        const Text('Prossimo addebito:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        const Spacer(),
                        Text(
                          DateFormat('dd/MM/yyyy').format(_nextDueDate),
                          style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down, color: Colors.white54, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Wallet Selector (if wallets available)
                if (_wallets.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C21),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.account_balance_wallet_rounded, size: 16, color: Colors.white54),
                        const SizedBox(width: 10),
                        const Text('Portafoglio:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedWalletId,
                              dropdownColor: const Color(0xFF27272A),
                              borderRadius: BorderRadius.circular(12),
                              items: _wallets.map((w) {
                                return DropdownMenuItem(
                                  value: w.id,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        margin: const EdgeInsets.only(right: 6),
                                        decoration: BoxDecoration(
                                          color: Color(int.parse(w.colorHex.replaceFirst('#', '0xFF'))),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      Text(w.name, style: const TextStyle(color: Colors.white, fontSize: 13)),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) => setState(() => _selectedWalletId = val),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Auto-confirm vs Ask in Inbox Toggle
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C21),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _requiresConfirmation ? Icons.mark_email_unread_rounded : Icons.flash_auto_rounded,
                        size: 18,
                        color: _requiresConfirmation ? Colors.amber : const Color(0xFF10B981),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _requiresConfirmation ? 'Richiedi conferma (Inbox)' : 'Addebita in automatico',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              _requiresConfirmation
                                  ? 'Apparirà nell\'Inbox per confermare o modificare l\'importo prima di scalare'
                                  : 'Verrà registrato automaticamente sul portafoglio alla data di scadenza',
                              style: const TextStyle(color: Colors.white38, fontSize: 10.5),
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: _requiresConfirmation,
                        activeColor: Colors.amber,
                        onChanged: _isVariableAmount
                            ? null // Variable amounts ALWAYS require confirmation
                            : (val) => setState(() => _requiresConfirmation = val),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Notes Field
                TextField(
                  controller: _notesController,
                  maxLines: 2,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Note aggiuntive (opzionali)',
                    labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
                    hintText: 'es. Codice abbonamento, IBAN o dettagli rinnovo',
                    hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
                    filled: true,
                    fillColor: const Color(0xFF1C1C21),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _isSaving ? null : () => Navigator.pop(context),
                child: const Text('Annulla', style: TextStyle(color: Colors.white54)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  foregroundColor: _isIncome ? Colors.black : Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(widget.existingItem != null ? 'Salva Modifiche' : 'Crea Ricorrenza', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
