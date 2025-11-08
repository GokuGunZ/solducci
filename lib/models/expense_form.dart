import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:solducci/models/expense.dart';
import 'package:solducci/service/expense_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ExpenseForm {
  final ExpenseService _expenseService = ExpenseService();

  final ExpenseField descriptionField = ExpenseField(
    fieldName: 'Description',
    type: String,
  );
  final ExpenseField moneyField = ExpenseField(
    fieldName: "Money",
    type: double,
  );
  final ExpenseField flowField = ExpenseField(
    fieldName: "Flow",
    type: MoneyFlow,
  );
  final ExpenseField dateField = ExpenseField(
    fieldName: "Date",
    type: DateTime,
    value: DateTime.now(),
  );
  final ExpenseField typeField = ExpenseField(
    fieldName: "Tipologia",
    type: Tipologia,
  );

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

  Widget getExpenseView() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                flex: 5,
                child: FieldWidget(expenseField: descriptionField),
              ),
              Flexible(flex: 2, child: FieldWidget(expenseField: moneyField)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              flowField,
              dateField,
              typeField,
            ].map((el) => FieldWidget(expenseField: el)).toList(),
          ),
          IconButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();

                // Get current user ID from Supabase
                final userId = Supabase.instance.client.auth.currentUser?.id;

                // Create expense object from form data
                final newExpense = Expense(
                  id: 0, // Let Supabase auto-generate ID
                  description: descriptionField.getFieldValue() as String,
                  amount: moneyField.getFieldValue() as double,
                  moneyFlow: flowField.getFieldValue() as MoneyFlow,
                  date: dateField.getFieldValue() as DateTime,
                  type: typeField.getFieldValue() as Tipologia,
                  userId: userId, // Assign current user
                );

                // Save to Supabase
                await _expenseService.createExpense(newExpense);

                _formKey.currentState!.reset();
                // Reset date field to current date
                dateField.setValue(DateTime.now());
              }
            },
            icon: const Icon(Icons.send),
          ),
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
      return Container(
        margin: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
        child: TextFormField(
          decoration: InputDecoration(
            hintText: widget.expenseField.getFieldName(),
            labelText: widget.expenseField.getFieldName(),
          ),
          keyboardType: TextInputType.text,
          onSaved: (newValue) => widget.expenseField.setValue(newValue),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '${widget.expenseField.getFieldName()} cannot be empty';
            }
            return null;
          },
        ),
      );
    } else if (type == double) {
      CurrencyTextInputFormatter formatter =
          CurrencyTextInputFormatter.currency(locale: 'it', symbol: '€');
      return Container(
        margin: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: TextFormField(
          inputFormatters: <TextInputFormatter>[formatter],
          decoration: InputDecoration(
            hintText: widget.expenseField.getFieldName(),
            labelText: widget.expenseField.getFieldName(),
            errorMaxLines: 2,
          ),
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          initialValue: formatter.formatDouble(0),
          onSaved: (newValue) {
            widget.expenseField.setValue(formatter.getDouble());
            formatter.formatDouble(0);
          },
          validator: (value) {
            if (formatter.getDouble() == 0 || value == null || value.isEmpty) {
              return '${widget.expenseField.getFieldName()} cannot be empty';
            }
            return null;
          },
        ),
      );
    } else if (enumTypeValues.containsKey(type)) {
      final values = enumTypeValues[type]!;
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Color.fromRGBO(0, 185, 160, 0.2),
        ),
        margin: EdgeInsets.symmetric(vertical: 15, horizontal: 50),
        child: EnumFormField<Enum>(
          // Use Enum as the generic type or a more specific base if possible
          title: values[0]
              .getTypeTitle(), // Access getTypeTitle from EnumLabel extension
          options: values,
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
              return 'Please select a ${widget.expenseField.getFieldName()}';
            }
            return null;
          },
        ),
      );
    } else if (type == DateTime) {
      return Container(
        margin: EdgeInsetsGeometry.symmetric(vertical: 15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            const SizedBox(width: 16),
            Text("${widget.expenseField.getFieldValue()}".split(' ')[0]),
            const SizedBox(width: 16),
            IconButton(
              onPressed: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: widget.expenseField.getFieldValue(),
                  firstDate: DateTime(1950),
                  lastDate: DateTime(2050),
                );
                if (picked != null &&
                    picked != widget.expenseField.getFieldValue()) {
                  setState(() {
                    widget.expenseField.setValue(picked);
                  });
                }
              },
              icon: Icon(Icons.today),
            ),
            const SizedBox(width: 16),
          ],
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
      case MoneyFlow _:
        return (this as MoneyFlow).label;
      case Tipologia _:
        return (this as Tipologia).label;
      default:
        return toString().split('.').last;
    }
  }

  String getTypeTitle() {
    switch (runtimeType) {
      case MoneyFlow _:
        return "Inserisci la direzione del flusso";
      case Tipologia _:
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
             crossAxisAlignment: CrossAxisAlignment.start, // Align error text
             children: [
               Padding(
                 padding: const EdgeInsets.only(left: 10, top: 5),
                 child: Text(
                   title,
                   style: TextStyle(
                     fontSize: 16,
                     fontWeight: FontWeight.bold,
                     color: Colors.black54,
                   ),
                 ),
               ),
               GridView.builder(
                 shrinkWrap: true,
                 physics: const NeverScrollableScrollPhysics(),
                 gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                   crossAxisCount: 2,
                   childAspectRatio: 3.5,
                   crossAxisSpacing: 1,
                   mainAxisSpacing: 1,
                 ),
                 itemCount: options.length,
                 itemBuilder: (context, index) {
                   final val = options[index];
                   return Center(
                     child: RadioListTile<T>(
                       title: Text((val as dynamic).label),
                       value: val,
                       groupValue: state.value,
                       onChanged: (T? selected) {
                         state.didChange(selected);
                         onChanged?.call(selected);
                       },
                     ),
                   );
                 },
               ),
               if (state.hasError) // Display error message
                 Padding(
                   padding: const EdgeInsets.only(left: 12, top: 4, bottom: 10),
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
