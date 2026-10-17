import 'package:flutter/material.dart';
import 'package:solducci/models/dashboard_config.dart';
import 'package:solducci/widgets/common/view_group_picker_sheet.dart';
import 'package:solducci/widgets/dashboard/bento_widget_container.dart';
import 'package:solducci/widgets/dashboard/context/dashboard_context_scope.dart';
import 'package:solducci/widgets/quick_add/unified_transaction_modal.dart';
import 'package:solducci/service/context_manager.dart';
import 'package:solducci/service/expense_service_cached.dart';
import 'package:solducci/models/expense.dart';
import 'package:solducci/models/split_type.dart';
import 'package:solducci/models/expense_form.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:solducci/widgets/dashboard/widgets/radial_selectors.dart';

class QuickExpenseWidget extends StatefulWidget {
  final BentoWidgetDef def;

  const QuickExpenseWidget({super.key, required this.def});

  @override
  State<QuickExpenseWidget> createState() => _QuickExpenseWidgetState();
}

class _QuickExpenseWidgetState extends State<QuickExpenseWidget> {
  String _amount = '';
  Tipologia _selectedCategory = Tipologia.cibo;
  String? _selectedGroupId;
  bool _isSaving = false;
  String? _selectedPayerId;
  List<String> _selectedTargetUserIds = [];

  void _onKeyPress(String key) {
    setState(() {
      if (key == 'C') {
        _amount = '';
      } else if (key == '<') {
        if (_amount.isNotEmpty) {
          _amount = _amount.substring(0, _amount.length - 1);
        }
      } else {
        // Prevent multiple decimals
        if (key == '.' && _amount.contains('.')) return;
        _amount += key;
      }
    });
  }

  Future<void> _saveExpense() async {
    if (_amount.isEmpty || _isSaving) return;
    final double? parsedAmount = double.tryParse(_amount);
    if (parsedAmount == null || parsedAmount <= 0) return;

    setState(() => _isSaving = true);

    try {
      final currentContext = DashboardContextScope.of(context);
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('Utente non autenticato');

      String? targetGroupId;
      if (currentContext.isGroup) {
        targetGroupId = currentContext.groupId;
      } else if (currentContext.isView) {
        if (_selectedGroupId != null) {
          targetGroupId = _selectedGroupId;
        } else {
          final choice = await ViewGroupPickerSheet.show(
            context,
            title: 'Spesa Rapida',
            subtitle: 'Scegli in quale contesto salvare la spesa',
          );
          if (choice == null) {
            if (mounted) setState(() => _isSaving = false);
            return;
          }
          targetGroupId = choice.isPersonal ? null : choice.groupId;
        }
      }

      final isGroupOrView = targetGroupId != null;
      final payerId = isGroupOrView ? (_selectedPayerId ?? userId) : null;

      SplitType? splitType;
      Map<String, double>? splitData;

      if (isGroupOrView) {
        if (_selectedTargetUserIds.isNotEmpty) {
          splitType = SplitType.custom;
          final perPerson = parsedAmount / _selectedTargetUserIds.length;
          final rounded = double.parse(perPerson.toStringAsFixed(2));
          splitData = {
            for (final uid in _selectedTargetUserIds) uid: rounded,
          };
        } else {
          splitType = SplitType.equal;
        }
      }

      final newExpense = Expense(
        id: 0,
        description: 'Spesa Rapida',
        amount: parsedAmount,
        date: DateTime.now(),
        type: _selectedCategory,
        userId: userId,
        groupId: targetGroupId,
        paidBy: payerId,
        splitType: splitType,
        splitData: splitData,
      );

      final createdExpense = await ExpenseServiceCached().insert(newExpense);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                GoRouter.of(context).push('/expense/${createdExpense.id}');
              },
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Spesa di €${parsedAmount.toStringAsFixed(2)} registrata!',
                      style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            backgroundColor: const Color(0xFF18181B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: const Color(0xFF10B981).withOpacity(0.5)),
            ),
            action: SnackBarAction(
              label: 'DETTAGLI',
              textColor: const Color(0xFF10B981),
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                GoRouter.of(context).push('/expense/${createdExpense.id}');
              },
            ),
          ),
        );
        setState(() {
          _amount = '';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
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
    final isCompact = widget.def.size.mainAxisCellCount <= 2;

    return BentoWidgetContainer(
      heroTag: widget.def.id,
      size: widget.def.size,
      child: isCompact
          ? _buildCompactLauncher(context)
          : Column(
              children: [
          // Payment Info Bar
          ListenableBuilder(
            listenable: ContextManager(),
            builder: (context, _) {
              final contextManager = ContextManager();
              final isView = contextManager.currentContext.isView;
              
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.white10)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (isView) ...[
                      RadialGroupSelector(
                        label: 'Gruppi:',
                        selectedGroupId: _selectedGroupId,
                        onGroupChanged: (gid) => setState(() => _selectedGroupId = gid),
                      ),
                      Container(
                        height: 24,
                        width: 1,
                        color: Colors.white10,
                      ),
                    ],
                    RadialUserSelector(
                      label: 'Paga:',
                      isDefaultAll: false,
                      onPayerChanged: (userId) => setState(() => _selectedPayerId = userId),
                    ),
                    Container(
                      height: 24,
                      width: 1,
                      color: Colors.white10,
                    ),
                    RadialUserSelector(
                      label: 'Per:',
                      isDefaultAll: true,
                      onSplitMembersChanged: (userIds) => setState(() => _selectedTargetUserIds = userIds),
                    ),
                    Container(
                      height: 24,
                      width: 1,
                      color: Colors.white10,
                    ),
                    RadialCategorySelector(
                      selectedCategory: _selectedCategory,
                      onCategoryChanged: (cat) => setState(() => _selectedCategory = cat),
                    ),
                  ],
                ),
              );
            }
          ),
          // Display Area
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              alignment: Alignment.centerRight,
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.white10)),
              ),
              child: Text(
                _amount.isEmpty ? '0.00 €' : '$_amount €',
                style: TextStyle(
                  color: _amount.isEmpty ? Colors.white24 : const Color(0xFF6366F1),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Inter',
                  shadows: _amount.isNotEmpty ? [
                    Shadow(
                      color: const Color(0xFF6366F1).withOpacity(0.5),
                      blurRadius: 10,
                    ),
                  ] : [],
                ),
              ),
            ),
          ),
          // Keypad Area
          Expanded(
            flex: 9,
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      _buildRow(['1', '2', '3']),
                      _buildRow(['4', '5', '6']),
                      _buildRow(['7', '8', '9']),
                      _buildRow(['.', '0', '<']),
                    ],
                  ),
                ),
                // Action Buttons
                Expanded(
                  flex: 1,
                  child: Container(
                    decoration: const BoxDecoration(
                      border: Border(left: BorderSide(color: Colors.white10)),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: _KeypadButton(
                            text: 'C',
                            color: Colors.white54,
                            onTap: () => _onKeyPress('C'),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: GestureDetector(
                            onTap: _saveExpense,
                            child: Container(
                              color: const Color(0xFF6366F1).withOpacity(0.1),
                              child: Center(
                                child: _isSaving
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Color(0xFF6366F1),
                                        ),
                                      )
                                    : Icon(
                                        Icons.check_circle,
                                        color: _amount.isNotEmpty ? const Color(0xFF6366F1) : Colors.white24,
                                        size: 32,
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _recordQuickPreset(String description, double amount, Tipologia category) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final currentContext = DashboardContextScope.of(context);
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('Utente non autenticato');

      String? targetGroupId;
      if (currentContext.isGroup) {
        targetGroupId = currentContext.groupId;
      } else if (currentContext.isView) {
        if (_selectedGroupId != null) {
          targetGroupId = _selectedGroupId;
        } else {
          final choice = await ViewGroupPickerSheet.show(
            context,
            title: 'Spesa Rapida',
            subtitle: 'Scegli in quale contesto salvare la spesa',
          );
          if (choice == null) {
            if (mounted) setState(() => _isSaving = false);
            return;
          }
          targetGroupId = choice.isPersonal ? null : choice.groupId;
        }
      }

      final newExpense = Expense(
        id: 0,
        description: description,
        amount: amount,
        date: DateTime.now(),
        type: category,
        userId: userId,
        groupId: targetGroupId,
        paidBy: targetGroupId != null ? userId : null,
        splitType: targetGroupId != null ? SplitType.equal : null,
      );

      final createdExpense = await ExpenseServiceCached().insert(newExpense);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                GoRouter.of(context).push('/expense/${createdExpense.id}');
              },
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$description: registrata spesa di €${amount.toStringAsFixed(2)}!',
                      style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            backgroundColor: const Color(0xFF18181B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: const Color(0xFF10B981).withOpacity(0.5)),
            ),
            action: SnackBarAction(
              label: 'DETTAGLI',
              textColor: const Color(0xFF10B981),
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                GoRouter.of(context).push('/expense/${createdExpense.id}');
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _buildCompactLauncher(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.bolt_rounded, color: Color(0xFFEF4444), size: 13),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'SPESA RAPIDA',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              RadialCategorySelector(
                selectedCategory: _selectedCategory,
                onCategoryChanged: (cat) => setState(() => _selectedCategory = cat),
              ),
            ],
          ),
          // 4 Quick Presets in 2x2
          Row(
            children: [
              Expanded(
                child: _buildPresetButton('☕ Caffè', '1.50€', () => _recordQuickPreset('Caffè', 1.50, Tipologia.cibo)),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildPresetButton('🍕 Pranzo', '12€', () => _recordQuickPreset('Pranzo', 12.0, Tipologia.ristorante)),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: _buildPresetButton('🛒 Spesa', '25€', () => _recordQuickPreset('Spesa', 25.0, Tipologia.cibo)),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: GestureDetector(
                  onTap: () => UnifiedTransactionModal.show(context),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.4)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_rounded, color: Color(0xFF818CF8), size: 13),
                        SizedBox(width: 4),
                        Text(
                          'Altro...',
                          style: TextStyle(
                            color: Color(0xFF818CF8),
                            fontSize: 10.5,
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
        ],
      ),
    );
  }

  Widget _buildPresetButton(String label, String price, VoidCallback onTap) {
    return GestureDetector(
      onTap: _isSaving ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              price,
              style: const TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(List<String> keys) {
    return Expanded(
      child: Row(
        children: keys.map((k) => Expanded(
          child: _KeypadButton(
            text: k,
            onTap: () => _onKeyPress(k),
          ),
        )).toList(),
      ),
    );
  }
}

class _KeypadButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final Color? color;

  const _KeypadButton({required this.text, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white10, width: 0.5),
        ),
        child: Center(
          child: text == '<' 
            ? Icon(Icons.backspace_outlined, color: color ?? Colors.white70, size: 18)
            : Text(
                text,
                style: TextStyle(
                  color: color ?? Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Inter',
                ),
              ),
        ),
      ),
    );
  }
}
