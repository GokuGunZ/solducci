import 'package:flutter/material.dart';
import 'package:solducci/models/dashboard_config.dart';
import 'package:solducci/widgets/dashboard/bento_widget_container.dart';
import 'package:solducci/service/context_manager.dart';
import 'package:solducci/service/expense_service_cached.dart';
import 'package:solducci/models/expense.dart';
import 'package:solducci/models/expense_form.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  bool _isSaving = false;

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
      final currentContext = ContextManager().currentContext;
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('Utente non autenticato');

      final newExpense = Expense(
        id: 0,
        description: 'Spesa Rapida',
        amount: parsedAmount,
        date: DateTime.now(),
        type: _selectedCategory,
        userId: userId,
        groupId: currentContext.isGroup ? currentContext.groupId : null,
      );

      await ExpenseServiceCached().insert(newExpense);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Spesa di €${parsedAmount.toStringAsFixed(2)} registrata!'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
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
    return BentoWidgetContainer(
      child: Column(
        children: [
          // Payment Info Bar
          ListenableBuilder(
            listenable: ContextManager(),
            builder: (context, _) {
              final contextManager = ContextManager();
              final isView = contextManager.currentContext.isView;
              
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.white10)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (isView) ...[
                      const RadialGroupSelector(label: 'Gruppi:'),
                      Container(
                        height: 24,
                        width: 2,
                        color: Colors.white24,
                      ),
                    ],
                    const RadialUserSelector(label: 'Paga:'),
                    Container(
                      height: 24,
                      width: 1,
                      color: Colors.white10,
                    ),
                    const RadialUserSelector(label: 'Per:', isDefaultAll: true),
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
