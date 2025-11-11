import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:solducci/models/expense.dart';
import 'package:solducci/service/expense_service.dart';
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
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Description field - full width
          FieldWidget(expenseField: descriptionField),
          SizedBox(height: 16),

          // Amount field - full width
          FieldWidget(expenseField: moneyField),
          SizedBox(height: 24),

          // Date picker - card style
          FieldWidget(expenseField: dateField),
          SizedBox(height: 16),

          // Category selector
          FieldWidget(expenseField: typeField),
          SizedBox(height: 16),

          // Money flow selector
          FieldWidget(expenseField: flowField),
          SizedBox(height: 32),

          // Submit button - modern style
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();

                  // Get current user ID from Supabase
                  final userId = Supabase.instance.client.auth.currentUser?.id;

                  if (isEditMode && _initialExpense != null) {
                    // Update existing expense
                    final updatedExpense = Expense(
                      id: _initialExpense.id,
                      description: descriptionField.getFieldValue() as String,
                      amount: moneyField.getFieldValue() as double,
                      moneyFlow: flowField.getFieldValue() as MoneyFlow,
                      date: dateField.getFieldValue() as DateTime,
                      type: typeField.getFieldValue() as Tipologia,
                      userId: _initialExpense.userId,
                    );
                    await _expenseService.updateExpense(updatedExpense);
                  } else {
                    // Create new expense
                    final newExpense = Expense(
                      id: -1, // Use -1 to signal new record (won't be sent to DB)
                      description: descriptionField.getFieldValue() as String,
                      amount: moneyField.getFieldValue() as double,
                      moneyFlow: flowField.getFieldValue() as MoneyFlow,
                      date: dateField.getFieldValue() as DateTime,
                      type: typeField.getFieldValue() as Tipologia,
                      userId: userId, // Assign current user
                    );
                    await _expenseService.createExpense(newExpense);
                  }

                  _formKey.currentState!.reset();
                  // Reset date field to current date
                  dateField.setValue(DateTime.now());
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                }
              },
              icon: Icon(Icons.check),
              label: Text(
                isEditMode ? 'Salva Modifiche' : 'Aggiungi Spesa',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          SizedBox(height: 16),
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
      CurrencyTextInputFormatter formatter =
          CurrencyTextInputFormatter.currency(locale: 'it', symbol: '€');
      final initialAmount = widget.expenseField.getFieldValue() as double?;
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: TextFormField(
          inputFormatters: <TextInputFormatter>[formatter],
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
          initialValue: formatter.formatDouble(initialAmount ?? 0),
          onChanged: (value) {
            // Update the field value as the user types
            widget.expenseField.setValue(formatter.getDouble());
          },
          onSaved: (newValue) {
            widget.expenseField.setValue(formatter.getDouble());
          },
          validator: (value) {
            // Check the current value from the formatter
            final currentAmount = formatter.getDouble();
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
