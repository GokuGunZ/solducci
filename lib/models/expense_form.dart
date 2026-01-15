import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:solducci/models/expense.dart';
import 'package:solducci/models/split_type.dart';
import 'package:solducci/models/group.dart';
import 'package:solducci/models/expense_view.dart';
import 'package:solducci/models/expense_split_state.dart';
import 'package:solducci/service/expense_service.dart';
import 'package:solducci/service/context_manager.dart';
import 'package:solducci/service/group_service_cached.dart';
import 'package:solducci/widgets/expense_split/expense_type_switch.dart';
import 'package:solducci/widgets/expense_split/group_split_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive/hive.dart';

part 'expense_form.g.dart';

class ExpenseForm {
  final ExpenseService _expenseService = ExpenseService();
  final Expense? _initialExpense; // Store the original expense for updates

  final ExpenseField descriptionField;
  final ExpenseField moneyField;
  final ExpenseField flowField;
  final ExpenseField dateField;
  final ExpenseField typeField;

  // Private constructor
  ExpenseForm._internal({
    required this.descriptionField,
    required this.moneyField,
    required this.flowField,
    required this.dateField,
    required this.typeField,
    Expense? initialExpense,
  }) : _initialExpense = initialExpense;

  // Factory for creating an empty form
  factory ExpenseForm.empty() {
    return ExpenseForm._internal(
      descriptionField: ExpenseField(fieldName: 'Description', type: String),
      moneyField: ExpenseField(fieldName: "Money", type: double),
      flowField: ExpenseField(fieldName: "Flow", type: MoneyFlow),
      dateField: ExpenseField(
        fieldName: "Date",
        type: DateTime,
        value: DateTime.now(),
      ),
      typeField: ExpenseField(fieldName: "Tipologia", type: Tipologia),
    );
  }

  // Factory for creating a form from an existing expense (for edit/duplicate)
  factory ExpenseForm.fromExpense(Expense expense, {bool isEdit = false}) {
    return ExpenseForm._internal(
      descriptionField: ExpenseField(
        fieldName: 'Description',
        type: String,
        value: expense.description,
      ),
      moneyField: ExpenseField(
        fieldName: "Money",
        type: double,
        value: expense.amount,
      ),
      flowField: ExpenseField(
        fieldName: "Flow",
        type: MoneyFlow,
        value: expense.moneyFlow,
      ),
      dateField: ExpenseField(
        fieldName: "Date",
        type: DateTime,
        value: expense.date,
      ),
      typeField: ExpenseField(
        fieldName: "Tipologia",
        type: Tipologia,
        value: expense.type,
      ),
      initialExpense: isEdit ? expense : null, // Only store for edit mode
    );
  }

  bool get isEditMode => _initialExpense != null;

  List<dynamic> getFieldsNames() => [
    descriptionField.getFieldName(),
    moneyField.getFieldName(),
    flowField.getFieldName(),
    dateField.getFieldName(),
    typeField.getFieldName(),
  ];
  List<dynamic> getFieldValues() => [
    descriptionField.getFieldValue(),
    moneyField.getFieldValue(),
    flowField.getFieldValue(),
    dateField.getFieldValue(),
    typeField.getFieldValue(),
  ];
  Map<String, dynamic> getFieldsMap() => {
    descriptionField.getFieldName(): descriptionField.getFieldValue(),
    moneyField.getFieldName(): moneyField.getFieldValue(),
    flowField.getFieldName(): flowField.getFieldValue()?.label,
    dateField.getFieldName(): DateFormat(
      'dd/MM/yyyy',
    ).format(dateField.getFieldValue()),
    typeField.getFieldName(): typeField.getFieldValue()?.label,
  };
  final _formKey = GlobalKey<FormState>();

  Widget getExpenseView(BuildContext context) {
    // Check current context type
    final currentContext = ContextManager().currentContext;

    if (currentContext.isView) {
      // CASO VISTA: mostra selettore gruppi
      return _ViewExpenseFormWidget(
        formKey: _formKey,
        expenseForm: this,
        view: currentContext.view!,
      );
    } else {
      // CASO NORMALE (Personal o Group singolo)
      final isGroupContext = currentContext.isGroup;
      return _ExpenseFormWidget(
        formKey: _formKey,
        expenseForm: this,
        isGroupContext: isGroupContext,
        groupId: currentContext.groupId,
      );
    }
  }
}

/// Stateful wrapper for expense form to handle group fields
class _ExpenseFormWidget extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final ExpenseForm expenseForm;
  final bool isGroupContext;
  final String? groupId;

  const _ExpenseFormWidget({
    required this.formKey,
    required this.expenseForm,
    required this.isGroupContext,
    this.groupId,
  });

  @override
  State<_ExpenseFormWidget> createState() => _ExpenseFormWidgetState();
}

class _ExpenseFormWidgetState extends State<_ExpenseFormWidget> {
  // Expense type state (Personal vs Group)
  ExpenseType _expenseType = ExpenseType.personal;

  // Group expense fields state
  ExpenseSplitState? _splitState;
  ExpenseGroup? _currentGroup;
  bool _loadingMembers = false;

  @override
  void initState() {
    super.initState();

    // Determine initial expense type
    if (widget.isGroupContext && widget.groupId != null) {
      _expenseType = ExpenseType.group;
      _loadGroupData();
    } else if (widget.expenseForm.isEditMode &&
        widget.expenseForm._initialExpense != null &&
        widget.expenseForm._initialExpense!.groupId != null) {
      // Edit mode with group expense
      _expenseType = ExpenseType.group;
      _loadGroupData();
    } else {
      _expenseType = ExpenseType.personal;
    }
  }

  Future<void> _loadGroupData() async {
    setState(() => _loadingMembers = true);

    try {
      final groupId = widget.groupId ?? widget.expenseForm._initialExpense?.groupId;
      if (groupId == null) {
        throw Exception('No group ID available');
      }

      // Use cached service for performance
      final groupService = GroupServiceCached();
      final members = await groupService
          .getGroupMembers(groupId)
          .timeout(const Duration(seconds: 10));

      // Get group info
      final group = await groupService.getGroupById(groupId);

      if (mounted) {
        final totalAmount = widget.expenseForm.moneyField.getFieldValue() as double? ?? 0.0;

        // Initialize split state
        if (widget.expenseForm.isEditMode &&
            widget.expenseForm._initialExpense != null) {
          // Edit mode: load existing split data
          final expense = widget.expenseForm._initialExpense!;
          _splitState = ExpenseSplitState(
            members: members,
            totalAmount: totalAmount,
            initialPayer: expense.paidBy,
            initialSplitters: expense.splitData?.keys.toSet(),
            initialSplits: expense.splitData,
            initialIsEqualSplit: expense.splitType == SplitType.equal,
          );
        } else {
          // New expense: preselect all members with equal split
          _splitState = ExpenseSplitState(
            members: members,
            totalAmount: totalAmount,
          );

          // Preselect current user as payer and all members for split
          final currentUserId = Supabase.instance.client.auth.currentUser?.id;
          _splitState!.preselectAllMembers(payerId: currentUserId);
        }

        setState(() {
          _currentGroup = group;
          _loadingMembers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingMembers = false);

        // Show error to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore caricamento membri: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onExpenseTypeChanged(ExpenseType newType) {
    if (newType == _expenseType) return;

    setState(() {
      _expenseType = newType;

      if (newType == ExpenseType.group && widget.groupId != null) {
        // Switching to group: load group data if not already loaded
        if (_splitState == null) {
          _loadGroupData();
        }
      } else if (newType == ExpenseType.personal) {
        // Switching to personal: keep splitState but don't use it in submission
        // No need to clear, just ignore it during save
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator while loading members
    if (_loadingMembers) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Caricamento dati gruppo...'),
          ],
        ),
      );
    }

    // If in group context but no members loaded, show error
    if (_expenseType == ExpenseType.group &&
        _splitState == null &&
        !_loadingMembers) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Impossibile caricare i dati del gruppo'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadGroupData,
              icon: const Icon(Icons.refresh),
              label: const Text('Riprova'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annulla'),
            ),
          ],
        ),
      );
    }

    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Description field - full width
          FieldWidget(expenseField: widget.expenseForm.descriptionField),
          const SizedBox(height: 16),

          // Amount field - full width
          FieldWidget(
            expenseField: widget.expenseForm.moneyField,
            onAmountChanged: (newAmount) {
              // Update split state when amount changes
              if (_splitState != null && newAmount > 0) {
                _splitState!.updateTotalAmount(newAmount);
              }
            },
          ),
          const SizedBox(height: 24),

          // Date picker - card style
          FieldWidget(expenseField: widget.expenseForm.dateField),
          const SizedBox(height: 16),

          // Category selector
          FieldWidget(expenseField: widget.expenseForm.typeField),
          const SizedBox(height: 24),

          // NEW: Expense Type Switch (always visible, preselected based on context)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ExpenseTypeSwitch(
              initialType: _expenseType,
              onTypeChanged: _onExpenseTypeChanged,
            ),
          ),
          const SizedBox(height: 16),

          // NEW: Group Split Card (show when group type selected with slide animation)
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (Widget child, Animation<double> animation) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, -0.3),
                    end: Offset.zero,
                  ).animate(animation),
                  child: FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                );
              },
              child: _expenseType == ExpenseType.group &&
                      _splitState != null &&
                      _currentGroup != null
                  ? Padding(
                      key: const ValueKey('group_split_card'),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GroupSplitCard(
                        group: _currentGroup!,
                        splitState: _splitState!,
                        isSelected: true,
                        allowCollapse: false, // Always expanded in single group context
                      ),
                    )
                  : const SizedBox.shrink(key: ValueKey('empty')),
            ),
          ),

          const SizedBox(height: 32),

          // Submit button - modern style
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: () async {
                // Validate split state if in group mode
                if (_expenseType == ExpenseType.group && _splitState != null) {
                  if (!_splitState!.isValid) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          _splitState!.selectedSplitters.isEmpty
                              ? 'Seleziona almeno un utente per la divisione'
                              : 'Gli importi devono sommare a ${_splitState!.totalAmount.toStringAsFixed(2)}€',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  if (_splitState!.selectedPayer == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Seleziona chi ha pagato la spesa'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                }

                if (widget.formKey.currentState!.validate()) {
                  widget.formKey.currentState!.save();

                  // Get current user ID from Supabase
                  final userId = Supabase.instance.client.auth.currentUser?.id;

                  // Determine split type based on state
                  SplitType? splitType;
                  Map<String, double>? splitData;

                  if (_expenseType == ExpenseType.group && _splitState != null) {
                    if (_splitState!.isEqualSplit) {
                      splitType = SplitType.equal;
                      // FIX: Save splitData even in equal mode to track selected members
                      splitData = _splitState!.splits;
                    } else {
                      splitType = SplitType.custom;
                      splitData = _splitState!.splits;
                    }
                  }

                  if (widget.expenseForm.isEditMode &&
                      widget.expenseForm._initialExpense != null) {
                    // Update existing expense
                    final updatedExpense = Expense(
                      id: widget.expenseForm._initialExpense!.id,
                      description:
                          widget.expenseForm.descriptionField.getFieldValue()
                              as String,
                      amount:
                          widget.expenseForm.moneyField.getFieldValue()
                              as double,
                      // MoneyFlow: always use default (legacy field, no longer used)
                      moneyFlow: MoneyFlow.carlucci,
                      date:
                          widget.expenseForm.dateField.getFieldValue()
                              as DateTime,
                      type:
                          widget.expenseForm.typeField.getFieldValue()
                              as Tipologia,
                      userId: widget.expenseForm._initialExpense!.userId,
                      // Use new split state if in group mode
                      groupId: _expenseType == ExpenseType.group
                          ? (widget.groupId ?? widget.expenseForm._initialExpense!.groupId)
                          : null,
                      paidBy: _expenseType == ExpenseType.group
                          ? _splitState?.selectedPayer
                          : null,
                      splitType: splitType,
                      splitData: splitData,
                    );
                    await widget.expenseForm._expenseService.updateExpense(
                      updatedExpense,
                    );
                  } else {
                    // Create new expense
                    final newExpense = Expense(
                      id: -1,
                      description:
                          widget.expenseForm.descriptionField.getFieldValue()
                              as String,
                      amount:
                          widget.expenseForm.moneyField.getFieldValue()
                              as double,
                      // MoneyFlow: always use default (legacy field, no longer used)
                      moneyFlow: MoneyFlow.carlucci,
                      date:
                          widget.expenseForm.dateField.getFieldValue()
                              as DateTime,
                      type:
                          widget.expenseForm.typeField.getFieldValue()
                              as Tipologia,
                      userId: userId,
                      // Add group fields if in group mode
                      groupId: _expenseType == ExpenseType.group ? widget.groupId : null,
                      paidBy: _expenseType == ExpenseType.group
                          ? _splitState?.selectedPayer
                          : null,
                      splitType: splitType,
                      splitData: splitData,
                    );
                    await widget.expenseForm._expenseService.createExpense(
                      newExpense,
                    );
                  }

                  widget.formKey.currentState!.reset();
                  // Reset date field to current date
                  widget.expenseForm.dateField.setValue(DateTime.now());
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                }
              },
              icon: const Icon(Icons.check),
              label: Text(
                widget.expenseForm.isEditMode
                    ? 'Salva Modifiche'
                    : 'Aggiungi Spesa',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class ExpenseField {
  String fieldName;
  Type type;
  dynamic value;

  ExpenseField({required this.fieldName, required this.type, this.value});

  String getFieldName() => fieldName;
  dynamic getFieldValue() => value;
  Type? getFieldType() => type;
  void setValue(dynamic val) {
    value = val;
  }
}

class FieldWidget extends StatefulWidget {
  final ExpenseField expenseField;
  final ValueChanged<double>? onAmountChanged;

  const FieldWidget({
    super.key,
    required this.expenseField,
    this.onAmountChanged,
  });

  @override
  State<FieldWidget> createState() => _FieldWidgetState();
}

class _FieldWidgetState extends State<FieldWidget> {
  TextEditingController? _amountController;
  CurrencyTextInputFormatter? _formatter;

  @override
  void initState() {
    super.initState();
    // Initialize controller only for double type
    if (widget.expenseField.getFieldType() == double) {
      _formatter = CurrencyTextInputFormatter.currency(
        locale: 'it',
        symbol: '€',
      );
      final initialAmount = widget.expenseField.getFieldValue() as double?;
      _amountController = TextEditingController(
        text: _formatter!.formatDouble(initialAmount ?? 0),
      );
    }
  }

  @override
  void dispose() {
    _amountController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.expenseField.getFieldType();

    if (type == String) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: TextFormField(
          initialValue: widget.expenseField.getFieldValue()?.toString(),
          decoration: InputDecoration(
            labelText: widget.expenseField.getFieldName(),
            hintText: 'Es. Spesa supermercato',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey[50],
            prefixIcon: Icon(Icons.description),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          keyboardType: TextInputType.text,
          style: TextStyle(fontSize: 16),
          onSaved: (newValue) => widget.expenseField.setValue(newValue),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Inserisci una descrizione';
            }
            return null;
          },
        ),
      );
    } else if (type == double) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: TextFormField(
          controller: _amountController,
          inputFormatters: <TextInputFormatter>[_formatter!],
          decoration: InputDecoration(
            labelText: widget.expenseField.getFieldName(),
            hintText: '0,00 €',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey[50],
            prefixIcon: Icon(Icons.euro, color: Colors.green[700]),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            errorMaxLines: 2,
          ),
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          onChanged: (value) {
            final newAmount = _formatter!.getDouble();
            widget.expenseField.setValue(newAmount);
            widget.onAmountChanged?.call(newAmount);
          },
          onSaved: (newValue) {
            widget.expenseField.setValue(_formatter!.getDouble());
          },
          validator: (value) {
            final currentAmount = _formatter!.getDouble();
            if (currentAmount <= 0) {
              return 'Inserisci un importo valido';
            }
            return null;
          },
        ),
      );
    } else if (type == DateTime) {
      final dateValue = widget.expenseField.getFieldValue() as DateTime;
      final formattedDate = DateFormat('dd/MM/yyyy').format(dateValue);

      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: dateValue,
                firstDate: DateTime(1950),
                lastDate: DateTime(2050),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(
                        primary: Colors.blue[700]!,
                        onPrimary: Colors.white,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null && picked != dateValue) {
                setState(() {
                  widget.expenseField.setValue(picked);
                });
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: Colors.blue[700], size: 24),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Data',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          formattedDate,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey[400]),
                ],
              ),
            ),
          ),
        ),
      );
    } else if (enumTypeValues.containsKey(type)) {
      final values = enumTypeValues[type]!;
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: EnumFormField<Enum>(
              title: values[0].getTypeTitle(),
              options: values,
              initialValue: widget.expenseField.getFieldValue() as Enum?,
              onChanged: (selected) {
                setState(() {
                  widget.expenseField.setValue(selected);
                });
              },
              onSaved: (newValue) {
                widget.expenseField.setValue(newValue);
              },
              validator: (value) {
                if (value == null) {
                  return 'Seleziona un\'opzione';
                }
                return null;
              },
            ),
          ),
        ),
      );
    }

    return const Placeholder(); // default fallback
  }
}

@HiveType(typeId: 2)
enum MoneyFlow {
  @HiveField(0)
  carlToPit('Carl-->Pit'),
  @HiveField(1)
  pitToCarl('Pit-->Carl'),
  @HiveField(2)
  carlDiv2('Carl-->/2'),
  @HiveField(3)
  pitDiv2('Pit-->/2'),
  @HiveField(4)
  carlucci('Carlucci'),
  @HiveField(5)
  pit('Pitucci');

  final String label;
  const MoneyFlow(this.label);
}

@HiveType(typeId: 3)
enum Tipologia {
  @HiveField(0)
  affitto('Affitto'),
  @HiveField(1)
  cibo('Cibo'),
  @HiveField(2)
  utenze('Utenze'),
  @HiveField(3)
  prodottiCasa('Prodotti Casa'),
  @HiveField(4)
  ristorante('Ristorante'),
  @HiveField(5)
  tempoLibero('Tempo Libero'),
  @HiveField(6)
  altro('Altro');

  final String label;
  const Tipologia(this.label);
}

extension EnumLabel on Enum {
  String getLabel() {
    switch (runtimeType) {
      case MoneyFlow:
        return (this as MoneyFlow).label;
      case Tipologia:
        return (this as Tipologia).label;
      default:
        return toString().split('.').last;
    }
  }

  String getTypeTitle() {
    switch (runtimeType) {
      case MoneyFlow:
        return "Inserisci la direzione del flusso";
      case Tipologia:
        return "Inserisci la tipologia della spesa";
      default:
        return "title";
    }
  }
}

final enumTypeValues = <Type, List<Enum>>{
  MoneyFlow: MoneyFlow.values,
  Tipologia: Tipologia.values,
};

class EnumFormField<T extends Enum> extends FormField<T> {
  final String title;
  final List<T> options;
  final ValueChanged<T?>?
  onChanged; // Callback for when a radio button is selected

  EnumFormField({
    super.key,
    required this.title,
    required this.options,
    this.onChanged,
    super.initialValue,
    super.onSaved,
    super.validator,
    super.autovalidateMode = AutovalidateMode.onUserInteraction,
  }) : super(
         builder: (FormFieldState<T> state) {
           return Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Text(
                 title,
                 style: TextStyle(
                   fontSize: 16,
                   fontWeight: FontWeight.bold,
                   color: Colors.grey[800],
                 ),
               ),
               SizedBox(height: 12),
               Wrap(
                 spacing: 8,
                 runSpacing: 8,
                 children: options.map((val) {
                   final isSelected = state.value == val;
                   return InkWell(
                     onTap: () {
                       state.didChange(val);
                       onChanged?.call(val);
                     },
                     borderRadius: BorderRadius.circular(12),
                     child: Container(
                       padding: EdgeInsets.symmetric(
                         horizontal: 16,
                         vertical: 12,
                       ),
                       decoration: BoxDecoration(
                         color: isSelected
                             ? Colors.blue[700]
                             : Colors.grey[100],
                         borderRadius: BorderRadius.circular(12),
                         border: Border.all(
                           color: isSelected
                               ? Colors.blue[700]!
                               : Colors.grey[300]!,
                           width: 2,
                         ),
                       ),
                       child: Text(
                         (val as dynamic).label,
                         style: TextStyle(
                           fontSize: 14,
                           fontWeight: isSelected
                               ? FontWeight.bold
                               : FontWeight.normal,
                           color: isSelected ? Colors.white : Colors.grey[800],
                         ),
                       ),
                     ),
                   );
                 }).toList(),
               ),
               if (state.hasError)
                 Padding(
                   padding: const EdgeInsets.only(top: 8),
                   child: Text(
                     state.errorText!,
                     style: TextStyle(
                       color: Theme.of(state.context).colorScheme.error,
                       fontSize: 12,
                     ),
                   ),
                 ),
             ],
           );
         },
       );
}

/// Widget form per creare spese da contesto Vista
/// Mostra selettore di gruppi (Card) e permette multi-select
class _ViewExpenseFormWidget extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final ExpenseForm expenseForm;
  final ExpenseView view;

  const _ViewExpenseFormWidget({
    required this.formKey,
    required this.expenseForm,
    required this.view,
  });

  @override
  State<_ViewExpenseFormWidget> createState() => _ViewExpenseFormWidgetState();
}

class _ViewExpenseFormWidgetState extends State<_ViewExpenseFormWidget> {
  // Expense type state (always starts as Group in View context)
  ExpenseType _expenseType = ExpenseType.group;

  // Split state per each group
  final Map<String, ExpenseSplitState> _groupSplitStates = {};
  final Map<String, ExpenseGroup> _groups = {};
  bool _loadingMembers = false;

  // Gruppi selezionati (per creare la spesa)
  final Set<String> _selectedGroupIds = {};

  @override
  void initState() {
    super.initState();
    _loadAllGroupMembers();
  }

  Future<void> _loadAllGroupMembers() async {
    setState(() => _loadingMembers = true);

    try {
      // Use cached service for performance
      final groupService = GroupServiceCached();
      final totalAmount = widget.expenseForm.moneyField.getFieldValue() as double? ?? 0.0;

      // Load all groups in parallel
      final futures = widget.view.groups!.map((group) async {
        final members = await groupService
            .getGroupMembers(group.id)
            .timeout(const Duration(seconds: 10));
        final groupInfo = await groupService.getGroupById(group.id);
        return MapEntry(
          group.id,
          {
            'members': members,
            'group': groupInfo,
          },
        );
      });

      final results = await Future.wait(futures);

      for (final entry in results) {
        final members = entry.value['members'] as List<GroupMember>;
        final groupInfo = entry.value['group'] as ExpenseGroup;

        _groups[entry.key] = groupInfo;

        // Create split state for each group
        _groupSplitStates[entry.key] = ExpenseSplitState(
          members: members,
          totalAmount: totalAmount,
        );

        // Preselect all members with current user as payer
        final currentUserId = Supabase.instance.client.auth.currentUser?.id;
        _groupSplitStates[entry.key]!.preselectAllMembers(payerId: currentUserId);
      }

      if (mounted) {
        setState(() {
          _loadingMembers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingMembers = false);
        // Show error in next frame to avoid calling inherited widget in initState
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Errore caricamento membri: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        });
      }
    }
  }

  void _onExpenseTypeChanged(ExpenseType newType) {
    if (newType == _expenseType) return;

    setState(() {
      _expenseType = newType;

      if (newType == ExpenseType.personal) {
        // Deselect all groups
        _selectedGroupIds.clear();
      }
    });
  }

  void _toggleGroupSelection(String groupId) {
    setState(() {
      if (_selectedGroupIds.contains(groupId)) {
        _selectedGroupIds.remove(groupId);
      } else {
        _selectedGroupIds.add(groupId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Loading state
    if (_loadingMembers) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Caricamento membri gruppi...'),
          ],
        ),
      );
    }

    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Description field
          FieldWidget(expenseField: widget.expenseForm.descriptionField),
          const SizedBox(height: 16),

          // Amount field with reactive update
          FieldWidget(
            expenseField: widget.expenseForm.moneyField,
            onAmountChanged: (newAmount) {
              // Update all split states when amount changes
              for (final splitState in _groupSplitStates.values) {
                if (newAmount > 0) {
                  splitState.updateTotalAmount(newAmount);
                }
              }
            },
          ),
          const SizedBox(height: 24),

          // Date picker
          FieldWidget(expenseField: widget.expenseForm.dateField),
          const SizedBox(height: 16),

          // Category selector
          FieldWidget(expenseField: widget.expenseForm.typeField),
          const SizedBox(height: 24),

          // Expense Type Switch (always visible, preselected to Group)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ExpenseTypeSwitch(
              initialType: _expenseType,
              onTypeChanged: _onExpenseTypeChanged,
            ),
          ),
          const SizedBox(height: 16),

          // Group Split Cards (show when group type selected with slide animation)
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (Widget child, Animation<double> animation) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, -0.3),
                    end: Offset.zero,
                  ).animate(animation),
                  child: FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                );
              },
              child: _expenseType == ExpenseType.group
                  ? Column(
                      key: const ValueKey('group_cards'),
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: widget.view.groups!.map((group) {
                        final splitState = _groupSplitStates[group.id];
                        final groupInfo = _groups[group.id];
                        final isSelected = _selectedGroupIds.contains(group.id);

                        if (splitState == null || groupInfo == null) {
                          return const SizedBox.shrink();
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          child: GroupSplitCard(
                            group: groupInfo,
                            splitState: splitState,
                            isSelected: isSelected,
                            allowCollapse: true, // Allow collapse in view context
                            showExpandIcon: false, // Hide expand icon in view context
                            onSelectionChanged: (selected) {
                              _toggleGroupSelection(group.id);
                            },
                          ),
                        );
                      }).toList(),
                    )
                  : const SizedBox.shrink(key: ValueKey('empty')),
            ),
          ),

          const SizedBox(height: 32),

          // Submit button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: _expenseType == ExpenseType.personal ||
                      _selectedGroupIds.isEmpty
                  ? null
                  : _onSubmit,
              icon: const Icon(Icons.check),
              label: Text(
                _expenseType == ExpenseType.personal
                    ? 'Crea Spesa Personale'
                    : 'Crea Spesa Di Gruppo',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[300],
                disabledForegroundColor: Colors.grey[600],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _onSubmit() async {
    if (!widget.formKey.currentState!.validate()) return;

    // If personal expense, create without group
    if (_expenseType == ExpenseType.personal) {
      await _createPersonalExpense();
      return;
    }

    // Validate all selected group split states
    for (final groupId in _selectedGroupIds) {
      final splitState = _groupSplitStates[groupId];
      if (splitState == null) continue;

      if (!splitState.isValid) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                splitState.selectedSplitters.isEmpty
                    ? 'Seleziona almeno un utente per ${_groups[groupId]?.name}'
                    : 'Gli importi per ${_groups[groupId]?.name} devono sommare a ${splitState.totalAmount.toStringAsFixed(2)}€',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (splitState.selectedPayer == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Seleziona chi ha pagato per ${_groups[groupId]?.name}'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    widget.formKey.currentState!.save();

    if (_selectedGroupIds.length == 1) {
      // CASO 1: Un solo gruppo selezionato → crea spesa normale
      await _createSingleGroupExpense(_selectedGroupIds.first);
    } else {
      // CASO 2: Più gruppi selezionati → mostra dialog scelta
      await _showMultiGroupChoiceDialog();
    }
  }

  Future<void> _createPersonalExpense() async {
    widget.formKey.currentState!.save();

    final expense = Expense(
      id: -1,
      description: widget.expenseForm.descriptionField.getFieldValue() as String,
      amount: widget.expenseForm.moneyField.getFieldValue() as double,
      date: widget.expenseForm.dateField.getFieldValue() as DateTime,
      type: widget.expenseForm.typeField.getFieldValue() as Tipologia,
      moneyFlow: MoneyFlow.carlucci,
      userId: Supabase.instance.client.auth.currentUser?.id,
      groupId: null,
      paidBy: null,
      splitType: null,
      splitData: null,
    );

    await ExpenseService().createExpense(expense);

    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _createSingleGroupExpense(String groupId) async {
    final splitState = _groupSplitStates[groupId]!;

    // Determine split type based on state
    SplitType splitType;
    Map<String, double>? splitData;

    if (splitState.isEqualSplit) {
      splitType = SplitType.equal;
      // FIX: Save splitData even in equal mode to track selected members
      splitData = splitState.splits;
    } else {
      splitType = SplitType.custom;
      splitData = splitState.splits;
    }

    final expense = Expense(
      id: -1,
      description: widget.expenseForm.descriptionField.getFieldValue() as String,
      amount: widget.expenseForm.moneyField.getFieldValue() as double,
      date: widget.expenseForm.dateField.getFieldValue() as DateTime,
      type: widget.expenseForm.typeField.getFieldValue() as Tipologia,
      moneyFlow: MoneyFlow.carlucci,
      userId: Supabase.instance.client.auth.currentUser?.id,
      groupId: groupId,
      paidBy: splitState.selectedPayer,
      splitType: splitType,
      splitData: splitData,
    );

    await ExpenseService().createExpense(expense);

    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _showMultiGroupChoiceDialog() async {
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hai selezionato ${_selectedGroupIds.length} gruppi'),
        content: const Text(
          'Come vuoi procedere con questa spesa?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'individual'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
            ),
            child: const Text('Spese Individuali'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'new_group'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
            ),
            child: const Text('Crea Nuovo Gruppo'),
          ),
        ],
      ),
    );

    if (choice == 'individual') {
      await _createIndividualExpenses();
    } else if (choice == 'new_group') {
      await _createNewGroupAndExpense();
    }
  }

  Future<void> _createIndividualExpenses() async {
    // Crea N spese separate, una per ogni gruppo
    for (final groupId in _selectedGroupIds) {
      await _createSingleGroupExpense(groupId);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_selectedGroupIds.length} spese create con successo',
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _createNewGroupAndExpense() async {
    // TODO: Implementare creazione gruppo con membri unificati
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Funzionalità "Crea Nuovo Gruppo" in sviluppo'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
}
