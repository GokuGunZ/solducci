import 'package:solducci/widgets/solducci_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:solducci/blocs/time_management/time_management_bloc.dart';
import 'package:solducci/blocs/time_management/time_management_event.dart';
import 'package:solducci/models/time_scenario.dart';
import 'package:uuid/uuid.dart';

class CreateScenarioView extends StatefulWidget {
  const CreateScenarioView({super.key});

  @override
  State<CreateScenarioView> createState() => _CreateScenarioViewState();
}

class _CreateScenarioViewState extends State<CreateScenarioView> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  String _scenarioType = 'event';
  DateTime? _targetDate;

  final List<Map<String, String>> _types = [
    {'value': 'event', 'label': 'Evento (Classico)'},
    {'value': 'trip', 'label': 'Viaggio (Con Dispensa)'},
    {'value': 'outing', 'label': 'Uscita (Leggera)'},
    {'value': 'availability', 'label': 'Disponibilità (Radar)'},
  ];

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      final newScenario = TimeScenario(
        id: const Uuid().v4(),
        documentId: const Uuid().v4(), // Simplified
        scenarioType: _scenarioType,
        startDate: _targetDate ?? DateTime.now(),
        metadata: {'title': _title},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      context.read<TimeManagementBloc>().add(CreateTimeScenarioRequested(newScenario));
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: SolducciAppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Crea Nuovo', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Titolo',
                  labelStyle: const TextStyle(color: Colors.white54),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                  focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.pinkAccent)),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Inserisci un titolo' : null,
                onSaved: (val) => _title = val!,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _scenarioType,
                dropdownColor: const Color(0xFF1E1E1E),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Tipologia',
                  labelStyle: const TextStyle(color: Colors.white54),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                  focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.pinkAccent)),
                ),
                items: _types.map((t) => DropdownMenuItem(
                  value: t['value'],
                  child: Text(t['label']!),
                )).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _scenarioType = val);
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: Colors.white24),
                  borderRadius: BorderRadius.circular(4),
                ),
                title: Text(
                  _targetDate == null ? 'Seleziona Data Target' : _targetDate.toString().split(' ')[0],
                  style: const TextStyle(color: Colors.white),
                ),
                trailing: const Icon(Icons.calendar_today, color: Colors.pinkAccent),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setState(() => _targetDate = date);
                  }
                },
              ),
              const Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _submit,
                child: const Text('Crea', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
