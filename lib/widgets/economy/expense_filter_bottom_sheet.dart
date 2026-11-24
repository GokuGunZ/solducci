import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:solducci/models/expense.dart';
import 'package:solducci/models/expense_filter_criteria.dart';
import 'package:solducci/models/group.dart';
import 'package:solducci/utils/category_helpers.dart';
import 'package:solducci/utils/currency_input_helper.dart';

class ExpenseFilterBottomSheet extends StatefulWidget {
  final ExpenseFilterCriteria initialCriteria;
  final List<GroupMember> groupMembers;
  final ValueChanged<ExpenseFilterCriteria> onApply;

  const ExpenseFilterBottomSheet({
    super.key,
    required this.initialCriteria,
    this.groupMembers = const [],
    required this.onApply,
  });

  static Future<void> show(
    BuildContext context, {
    required ExpenseFilterCriteria currentCriteria,
    List<GroupMember> groupMembers = const [],
    required ValueChanged<ExpenseFilterCriteria> onApply,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ExpenseFilterBottomSheet(
        initialCriteria: currentCriteria,
        groupMembers: groupMembers,
        onApply: onApply,
      ),
    );
  }

  @override
  State<ExpenseFilterBottomSheet> createState() => _ExpenseFilterBottomSheetState();
}

class _ExpenseFilterBottomSheetState extends State<ExpenseFilterBottomSheet> {
  late Set<Tipologia> _selectedCategories;
  DateTimeRange? _selectedDateRange;
  String? _datePreset;
  String? _selectedPayerId;
  late TextEditingController _minAmountController;
  late TextEditingController _maxAmountController;

  @override
  void initState() {
    super.initState();
    _selectedCategories = Set.from(widget.initialCriteria.categories);
    _selectedDateRange = widget.initialCriteria.dateRange;
    _datePreset = widget.initialCriteria.datePreset;
    _selectedPayerId = widget.initialCriteria.paidByUserId;
    _minAmountController = TextEditingController(
      text: widget.initialCriteria.minAmount != null ? widget.initialCriteria.minAmount!.toStringAsFixed(0) : '',
    );
    _maxAmountController = TextEditingController(
      text: widget.initialCriteria.maxAmount != null ? widget.initialCriteria.maxAmount!.toStringAsFixed(0) : '',
    );
  }

  @override
  void dispose() {
    _minAmountController.dispose();
    _maxAmountController.dispose();
    super.dispose();
  }

  void _applyPreset(String preset) {
    final now = DateTime.now();
    DateTimeRange? range;

    if (preset == 'today') {
      range = DateTimeRange(start: now, end: now);
    } else if (preset == 'week') {
      range = DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now);
    } else if (preset == 'month') {
      range = DateTimeRange(start: DateTime(now.year, now.month, 1), end: now);
    } else if (preset == 'all') {
      range = null;
    }

    setState(() {
      _datePreset = preset == 'all' ? null : preset;
      _selectedDateRange = range;
    });
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: _selectedDateRange ?? DateTimeRange(
        start: now.subtract(const Duration(days: 30)),
        end: now,
      ),
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
        _selectedDateRange = picked;
        _datePreset = 'custom';
      });
    }
  }

  void _reset() {
    setState(() {
      _selectedCategories.clear();
      _selectedDateRange = null;
      _datePreset = null;
      _selectedPayerId = null;
      _minAmountController.clear();
      _maxAmountController.clear();
    });
  }

  void _submit() {
    final minAmt = CurrencyInputHelper.parse(_minAmountController.text);
    final maxAmt = CurrencyInputHelper.parse(_maxAmountController.text);

    final criteria = widget.initialCriteria.copyWith(
      categories: _selectedCategories,
      dateRange: _selectedDateRange,
      datePreset: _datePreset,
      paidByUserId: _selectedPayerId,
      minAmount: minAmt,
      maxAmount: maxAmt,
      clearDateRange: _selectedDateRange == null,
      clearPaidBy: _selectedPayerId == null,
    );

    widget.onApply(criteria);
    Navigator.pop(context);
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),

            // Header con Resetta
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.tune_rounded, color: Color(0xFF10B981), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Filtra Spese',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: _reset,
                  child: const Text('Resetta', style: TextStyle(color: Colors.white54, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 1. Tipologia / Categoria (Selezione Multipla)
            const Text(
              'Categoria (seleziona più tipologie)',
              style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: Tipologia.values.map((cat) {
                final isSelected = _selectedCategories.contains(cat);
                final catColor = CategoryHelpers.getCategoryColor(cat);

                return FilterChip(
                  label: Text(CategoryHelpers.getCategoryLabel(cat)),
                  avatar: Icon(
                    CategoryHelpers.getCategoryIcon(cat),
                    size: 15,
                    color: isSelected ? catColor : Colors.white60,
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedCategories.add(cat);
                      } else {
                        _selectedCategories.remove(cat);
                      }
                    });
                  },
                  selectedColor: catColor.withOpacity(0.2),
                  backgroundColor: Colors.white.withOpacity(0.05),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                  side: BorderSide(color: isSelected ? catColor : Colors.white10),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // 2. Data / Finestra Temporale
            const Text(
              'Finestra Temporale',
              style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Tutto'),
                  selected: _datePreset == null && _selectedDateRange == null,
                  onSelected: (_) => _applyPreset('all'),
                  selectedColor: const Color(0xFF10B981).withOpacity(0.2),
                  backgroundColor: Colors.white.withOpacity(0.05),
                  labelStyle: TextStyle(
                    color: (_datePreset == null && _selectedDateRange == null) ? const Color(0xFF10B981) : Colors.white70,
                    fontSize: 12,
                  ),
                ),
                ChoiceChip(
                  label: const Text('Oggi'),
                  selected: _datePreset == 'today',
                  onSelected: (_) => _applyPreset('today'),
                  selectedColor: const Color(0xFF10B981).withOpacity(0.2),
                  backgroundColor: Colors.white.withOpacity(0.05),
                  labelStyle: TextStyle(
                    color: _datePreset == 'today' ? const Color(0xFF10B981) : Colors.white70,
                    fontSize: 12,
                  ),
                ),
                ChoiceChip(
                  label: const Text('Ultimi 7 gg'),
                  selected: _datePreset == 'week',
                  onSelected: (_) => _applyPreset('week'),
                  selectedColor: const Color(0xFF10B981).withOpacity(0.2),
                  backgroundColor: Colors.white.withOpacity(0.05),
                  labelStyle: TextStyle(
                    color: _datePreset == 'week' ? const Color(0xFF10B981) : Colors.white70,
                    fontSize: 12,
                  ),
                ),
                ChoiceChip(
                  label: const Text('Questo Mese'),
                  selected: _datePreset == 'month',
                  onSelected: (_) => _applyPreset('month'),
                  selectedColor: const Color(0xFF10B981).withOpacity(0.2),
                  backgroundColor: Colors.white.withOpacity(0.05),
                  labelStyle: TextStyle(
                    color: _datePreset == 'month' ? const Color(0xFF10B981) : Colors.white70,
                    fontSize: 12,
                  ),
                ),
                ActionChip(
                  avatar: const Icon(Icons.date_range_rounded, size: 15, color: Color(0xFF10B981)),
                  label: Text(_datePreset == 'custom' && _selectedDateRange != null
                      ? '${DateFormat('dd/MM').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM').format(_selectedDateRange!.end)}'
                      : 'Personalizzato'),
                  onPressed: _pickCustomRange,
                  backgroundColor: _datePreset == 'custom'
                      ? const Color(0xFF10B981).withOpacity(0.2)
                      : Colors.white.withOpacity(0.05),
                  labelStyle: TextStyle(
                    color: _datePreset == 'custom' ? const Color(0xFF10B981) : Colors.white70,
                    fontSize: 12,
                  ),
                  side: BorderSide(
                    color: _datePreset == 'custom' ? const Color(0xFF10B981) : Colors.white10,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 3. Chi ha pagato (Se presenti membri gruppo)
            if (widget.groupMembers.isNotEmpty) ...[
              const Text(
                'Chi ha pagato',
                style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.groupMembers.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      final isSelected = _selectedPayerId == null;
                      return ChoiceChip(
                        label: const Text('Tutti'),
                        selected: isSelected,
                        onSelected: (_) => setState(() => _selectedPayerId = null),
                        selectedColor: const Color(0xFF8B5CF6).withOpacity(0.2),
                        backgroundColor: Colors.white.withOpacity(0.05),
                        labelStyle: TextStyle(
                          color: isSelected ? const Color(0xFFA78BFA) : Colors.white70,
                          fontSize: 12,
                        ),
                      );
                    }

                    final member = widget.groupMembers[index - 1];
                    final isSelected = _selectedPayerId == member.userId;
                    final name = member.nickname ?? member.email?.split('@').first ?? 'Membro';

                    return ChoiceChip(
                      label: Text(name),
                      selected: isSelected,
                      onSelected: (val) => setState(() => _selectedPayerId = val ? member.userId : null),
                      selectedColor: const Color(0xFF8B5CF6).withOpacity(0.2),
                      backgroundColor: Colors.white.withOpacity(0.05),
                      labelStyle: TextStyle(
                        color: isSelected ? const Color(0xFFA78BFA) : Colors.white70,
                        fontSize: 12,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],

            // 4. Range di Importo (€)
            const Text(
              'Importo (€)',
              style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minAmountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Min (€)',
                      labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _maxAmountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Max (€)',
                      labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Pulsante Applica
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _submit,
                child: const Text(
                  'Applica Filtri',
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
