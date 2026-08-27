import 'package:solducci/widgets/solducci_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:solducci/service/time_management_service.dart';
import 'package:solducci/models/time_scenario.dart';

class CreateTripView extends StatefulWidget {
  const CreateTripView({super.key});

  @override
  State<CreateTripView> createState() => _CreateTripViewState();
}

class _CreateTripViewState extends State<CreateTripView> {
  int _currentStep = 0;
  final _titleController = TextEditingController();
  final _destinationController = TextEditingController();
  DateTime _startDate = DateTime.now().add(const Duration(days: 7));
  DateTime _endDate = DateTime.now().add(const Duration(days: 14));
  bool _createGhostPantry = true;
  bool _isLoading = false;

  Future<void> _submit() async {
    if (_titleController.text.isEmpty) return;
    setState(() => _isLoading = true);

    final scenario = TimeScenario(
      id: const Uuid().v4(),
      documentId: const Uuid().v4(),
      scenarioType: 'trip',
      startDate: _startDate,
      endDate: _endDate,
      location: _destinationController.text,
      metadata: {
        'title': _titleController.text,
        'ghost_pantry_enabled': _createGhostPantry,
      },
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await TimeManagementService().createTimeScenario(scenario);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: SolducciAppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Organizza Viaggio', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF6366F1), // Indigo
            surface: Color(0xFF121212),
          ),
        ),
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep < 2) {
              setState(() => _currentStep += 1);
            } else {
              _submit();
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) {
              setState(() => _currentStep -= 1);
            } else {
              context.pop();
            }
          },
          controlsBuilder: (context, details) {
            final isLastStep = _currentStep == 2;
            return Padding(
              padding: const EdgeInsets.only(top: 24.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: _isLoading ? null : details.onStepContinue,
                      child: _isLoading && isLastStep
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(isLastStep ? 'Conferma e Crea' : 'Avanti', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  if (_currentStep > 0) const SizedBox(width: 12),
                  if (_currentStep > 0)
                    TextButton(
                      onPressed: details.onStepCancel,
                      child: const Text('Indietro', style: TextStyle(color: Colors.white54)),
                    ),
                ],
              ),
            );
          },
          steps: [
            Step(
              title: const Text('Dove & Quando', style: TextStyle(color: Colors.white)),
              content: Column(
                children: [
                  TextField(
                    controller: _titleController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Nome Viaggio', labelStyle: TextStyle(color: Colors.white54)),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _destinationController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Destinazione', labelStyle: TextStyle(color: Colors.white54)),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final date = await showDatePicker(context: context, initialDate: _startDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 1000)));
                            if (date != null) setState(() => _startDate = date);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(8)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Partenza', style: TextStyle(color: Colors.white54, fontSize: 12)),
                                const SizedBox(height: 4),
                                Text("${_startDate.day}/${_startDate.month}/${_startDate.year}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final date = await showDatePicker(context: context, initialDate: _endDate, firstDate: _startDate, lastDate: DateTime.now().add(const Duration(days: 1000)));
                            if (date != null) setState(() => _endDate = date);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(8)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Ritorno', style: TextStyle(color: Colors.white54, fontSize: 12)),
                                const SizedBox(height: 4),
                                Text("${_endDate.day}/${_endDate.month}/${_endDate.year}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              isActive: _currentStep >= 0,
            ),
            Step(
              title: const Text('Logistica (Ghost Pantry)', style: TextStyle(color: Colors.white)),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Vuoi creare una Dispensa temporanea (Ghost Pantry) per organizzare cosa portare e i task pre-partenza?', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Abilita Ghost Pantry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: const Text('Genera liste isolate dal gruppo principale', style: TextStyle(color: Colors.white54)),
                    activeThumbColor: const Color(0xFF6366F1),
                    value: _createGhostPantry,
                    onChanged: (val) => setState(() => _createGhostPantry = val),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
              isActive: _currentStep >= 1,
            ),
            Step(
              title: const Text('Riepilogo', style: TextStyle(color: Colors.white)),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(_titleController.text.isEmpty ? 'Senza Titolo' : _titleController.text, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('${_destinationController.text} • ${_startDate.day}/${_startDate.month} - ${_endDate.day}/${_endDate.month}', style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFF6366F1).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        Icon(_createGhostPantry ? Icons.check_circle : Icons.cancel, color: const Color(0xFF6366F1)),
                        const SizedBox(width: 8),
                        Text(_createGhostPantry ? 'Ghost Pantry Inclusa' : 'Nessuna Dispensa', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
              isActive: _currentStep >= 2,
            ),
          ],
        ),
      ),
    );
  }
}
