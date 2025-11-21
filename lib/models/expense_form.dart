import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:solducci/models/expense.dart';
import 'package:solducci/models/split_type.dart';
import 'package:solducci/models/group.dart';
import 'package:solducci/models/expense_view.dart';
import 'package:solducci/service/expense_service.dart';
import 'package:solducci/service/context_manager.dart';
import 'package:solducci/service/group_service.dart';
import 'package:solducci/widgets/group_expense_fields.dart';
import 'package:solducci/widgets/custom_split_editor.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  // Group expense fields state
  String? _paidBy;
  SplitType? _splitType = SplitType.equal;
  Map<String, double>? _customSplits;
  List<GroupMember> _groupMembers = [];
  bool _loadingMembers = false;

  @override
  void initState() {
    super.initState();

    // Initialize group fields from existing expense if in edit mode
    if (widget.expenseForm.isEditMode && widget.expenseForm._initialExpense != null) {
      final expense = widget.expenseForm._initialExpense!;
      _paidBy = expense.paidBy;
      _splitType = expense.splitType ?? SplitType.equal;
      _customSplits = expense.splitData;
    }

    if (widget.isGroupContext && widget.groupId != null) {
      _loadGroupMembers();
    }
  }

  Future<void> _loadGroupMembers() async {
    setState(() => _loadingMembers = true);

    try {
      final members = await GroupService()
          .getGroupMembers(widget.groupId!)
          .timeout(const Duration(seconds: 10));

      if (mounted) {
        setState(() {
          _groupMembers = members;
          _loadingMembers = false;
          // Auto-select current user as paidBy ONLY if not already set (new expense)
          if (_paidBy == null) {
            _paidBy = Supabase.instance.client.auth.currentUser?.id;
          }
        });
      }
    } catch (e, stackTrace) {
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

  @override
  Widget build(BuildContext context) {
    // Show loading indicator while loading members
    if (widget.isGroupContext && _loadingMembers) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Caricamento membri gruppo...'),
          ],
        ),
      );
    }

    // If in group context but no members loaded, show error
    if (widget.isGroupContext && _groupMembers.isEmpty && !_loadingMembers) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Impossibile caricare i membri del gruppo'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadGroupMembers,
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
          FieldWidget(expenseField: widget.expenseForm.moneyField),
          const SizedBox(height: 24),

          // Date picker - card style
          FieldWidget(expenseField: widget.expenseForm.dateField),
          const SizedBox(height: 16),

          // Category selector
          FieldWidget(expenseField: widget.expenseForm.typeField),
          const SizedBox(height: 16),

          // GROUP FIELDS - Show only in group context
          if (widget.isGroupContext && _groupMembers.isNotEmpty) ...[
            GroupExpenseFields(
              members: _groupMembers,
              initialPaidBy: _paidBy,
              initialSplitType: _splitType,
              onPaidByChanged: (value) {
                setState(() => _paidBy = value);
              },
              onSplitTypeChanged: (value) {
                setState(() => _splitType = value);
              },
            ),

            // Custom split editor - Show only if custom split selected
            if (_splitType == SplitType.custom) ...[
              const SizedBox(height: 16),
              CustomSplitEditor(
                members: _groupMembers,
                totalAmount: widget.expenseForm.moneyField.getFieldValue() as double? ?? 0.0,
                initialSplits: _customSplits,
                onSplitsChanged: (splits) {
                  setState(() => _customSplits = splits);
                },
              ),
            ],
          ],

          const SizedBox(height: 32),

          // Submit button - modern style
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: () async {
                // Validate custom splits if needed
                if (widget.isGroupContext &&
                    _splitType == SplitType.custom &&
                    _customSplits != null) {
                  final totalAmount = widget.expenseForm.moneyField.getFieldValue() as double? ?? 0.0;
                  final splitsTotal = _customSplits!.values.fold(0.0, (sum, amount) => sum + amount);

                  if ((splitsTotal - totalAmount).abs() > 0.01) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Gli importi custom devono sommare a ${totalAmount.toStringAsFixed(2)}€'),
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

                  if (widget.expenseForm.isEditMode && widget.expenseForm._initialExpense != null) {
                    // Update existing expense
                    final updatedExpense = Expense(
                      id: widget.expenseForm._initialExpense!.id,
                      description: widget.expenseForm.descriptionField.getFieldValue() as String,
                      amount: widget.expenseForm.moneyField.getFieldValue() as double,
                      // MoneyFlow: always use default (legacy field, no longer used)
                      moneyFlow: MoneyFlow.carlucci,
                      date: widget.expenseForm.dateField.getFieldValue() as DateTime,
                      type: widget.expenseForm.typeField.getFieldValue() as Tipologia,
                      userId: widget.expenseForm._initialExpense!.userId,
                      // FIX: Use current form values for group fields to allow updates
                      groupId: widget.expenseForm._initialExpense!.groupId,
                      paidBy: widget.isGroupContext ? _paidBy : widget.expenseForm._initialExpense!.paidBy,
                      splitType: widget.isGroupContext ? _splitType : widget.expenseForm._initialExpense!.splitType,
                      splitData: widget.isGroupContext && _splitType == SplitType.custom ? _customSplits : (widget.isGroupContext ? null : widget.expenseForm._initialExpense!.splitData),
                    );
                    await widget.expenseForm._expenseService.updateExpense(updatedExpense);
                  } else {
                    // Create new expense
                    final newExpense = Expense(
                      id: -1,
                      description: widget.expenseForm.descriptionField.getFieldValue() as String,
                      amount: widget.expenseForm.moneyField.getFieldValue() as double,
                      // MoneyFlow: always use default (legacy field, no longer used)
                      moneyFlow: MoneyFlow.carlucci,
                      date: widget.expenseForm.dateField.getFieldValue() as DateTime,
                      type: widget.expenseForm.typeField.getFieldValue() as Tipologia,
                      userId: userId,
                      // NEW: Add group fields if in group context
                      groupId: widget.isGroupContext ? widget.groupId : null,
                      paidBy: widget.isGroupContext ? _paidBy : null,
                      splitType: widget.isGroupContext ? _splitType : null,
                      splitData: widget.isGroupContext && _splitType == SplitType.custom ? _customSplits : null,
                    );
                    await widget.expenseForm._expenseService.createExpense(newExpense);
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
                widget.expenseForm.isEditMode ? 'Salva Modifiche' : 'Aggiungi Spesa',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
  const FieldWidget({super.key, required this.expenseField});

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
      _formatter = CurrencyTextInputFormatter.currency(locale: 'it', symbol: '€');
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
            widget.expenseField.setValue(_formatter!.getDouble());
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

enum MoneyFlow {
  carlToPit('Carl-->Pit'),
  pitToCarl('Pit-->Carl'),
  carlDiv2('Carl-->/2'),
  pitDiv2('Pit-->/2'),
  carlucci('Carlucci'),
  pit('Pitucci');

  final String label;
  const MoneyFlow(this.label);
}

enum Tipologia {
  affitto('Affitto'),
  cibo('Cibo'),
  utenze('Utenze'),
  prodottiCasa('Prodotti Casa'),
  ristorante('Ristorante'),
  tempoLibero('Tempo Libero'),
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
  // Gruppi selezionati (per creare la spesa)
  final Set<String> _selectedGroupIds = {};

  // Membri di tutti i gruppi della vista (caricati all'inizio)
  final Map<String, List<GroupMember>> _groupMembers = {};
  bool _loadingMembers = false;

  // Split fields (unificati per tutti i gruppi - FASE 1 semplificata)
  String? _paidBy;
  SplitType _splitType = SplitType.equal;

  @override
  void initState() {
    super.initState();
    _loadAllGroupMembers();
  }

  Future<void> _loadAllGroupMembers() async {
    setState(() => _loadingMembers = true);

    try {
      for (final group in widget.view.groups!) {
        final members = await GroupService()
            .getGroupMembers(group.id)
            .timeout(const Duration(seconds: 10));
        _groupMembers[group.id] = members;
      }

      if (mounted) {
        setState(() {
          _loadingMembers = false;
          // Auto-select current user as paidBy
          _paidBy = Supabase.instance.client.auth.currentUser?.id;
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

  /// Ottieni tutti i membri unici dai gruppi selezionati
  List<GroupMember> get _allSelectedMembers {
    final allMembers = <GroupMember>[];
    final seenUserIds = <String>{};

    for (final groupId in _selectedGroupIds) {
      final members = _groupMembers[groupId] ?? [];
      for (final member in members) {
        if (!seenUserIds.contains(member.userId)) {
          allMembers.add(member);
          seenUserIds.add(member.userId);
        }
      }
    }

    return allMembers;
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
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          // Campi base
          FieldWidget(expenseField: widget.expenseForm.descriptionField),
          const SizedBox(height: 16),
          FieldWidget(expenseField: widget.expenseForm.moneyField),
          const SizedBox(height: 16),
          FieldWidget(expenseField: widget.expenseForm.dateField),
          const SizedBox(height: 16),
          FieldWidget(expenseField: widget.expenseForm.typeField),
          const SizedBox(height: 24),

          // SEZIONE SELEZIONE GRUPPI
          Row(
            children: [
              Expanded(
                child: Divider(color: Colors.grey[400], thickness: 1),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'SELEZIONA GRUPPI',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Expanded(
                child: Divider(color: Colors.grey[400], thickness: 1),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Card selezionabili per ogni gruppo
          ...widget.view.groups!.map((group) {
            final isSelected = _selectedGroupIds.contains(group.id);
            final members = _groupMembers[group.id] ?? [];

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                elevation: isSelected ? 4 : 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected ? Colors.blue[700]! : Colors.grey[300]!,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedGroupIds.remove(group.id);
                      } else {
                        _selectedGroupIds.add(group.id);
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          color: isSelected ? Colors.blue[700] : Colors.grey,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                group.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: isSelected
                                      ? Colors.blue[700]
                                      : Colors.grey[800],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${members.length} membri',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),

          // SPLIT FIELDS (visibili solo se almeno 1 gruppo selezionato)
          if (_selectedGroupIds.isNotEmpty) ...[
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: Divider(color: Colors.grey[400], thickness: 1),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'SPLIT TRA MEMBRI',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                Expanded(
                  child: Divider(color: Colors.grey[400], thickness: 1),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Dropdown "Chi ha pagato?" (unificato per tutti i gruppi)
            Text(
              'Chi ha pagato? *',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _paidBy,
              decoration: InputDecoration(
                hintText: 'Seleziona chi ha pagato',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              items: _allSelectedMembers.map((member) {
                return DropdownMenuItem<String>(
                  value: member.userId,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.blue[200],
                        child: Text(
                          member.initials,
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          member.nickname ?? member.email ?? 'Unknown',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) => setState(() => _paidBy = value),
              validator: (value) =>
                  value == null ? 'Seleziona chi ha pagato' : null,
            ),

            const SizedBox(height: 16),

            // Split type selector
            Text(
              'Come dividere?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),

            ...SplitType.values.map((type) {
              return RadioListTile<SplitType>(
                value: type,
                groupValue: _splitType,
                onChanged: (value) => setState(() => _splitType = value!),
                title: Row(
                  children: [
                    Text(
                      type.icon,
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            type.label,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            type.description,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                dense: true,
              );
            }),
          ],

          const SizedBox(height: 32),

          // Submit button
          ElevatedButton.icon(
            onPressed: _selectedGroupIds.isEmpty ? null : _onSubmit,
            icon: const Icon(Icons.check),
            label: const Text('Crea Spesa'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey[300],
              disabledForegroundColor: Colors.grey[600],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    ),
  );
}

  Future<void> _onSubmit() async {
    if (!widget.formKey.currentState!.validate()) return;
    widget.formKey.currentState!.save();

    if (_selectedGroupIds.length == 1) {
      // CASO 1: Un solo gruppo selezionato → crea spesa normale
      await _createSingleGroupExpense(_selectedGroupIds.first);
    } else {
      // CASO 2: Più gruppi selezionati → mostra dialog scelta
      await _showMultiGroupChoiceDialog();
    }
  }

  Future<void> _createSingleGroupExpense(String groupId) async {
    final expense = Expense(
      id: -1,
      description: widget.expenseForm.descriptionField.getFieldValue() as String,
      amount: widget.expenseForm.moneyField.getFieldValue() as double,
      date: widget.expenseForm.dateField.getFieldValue() as DateTime,
      type: widget.expenseForm.typeField.getFieldValue() as Tipologia,
      moneyFlow: MoneyFlow.carlucci, // Legacy field
      userId: Supabase.instance.client.auth.currentUser?.id,
      groupId: groupId,
      paidBy: _paidBy,
      splitType: _splitType,
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
