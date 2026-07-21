import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:solducci/service/time_management_service.dart';
import 'package:solducci/models/time_scenario.dart';

class CreateOutingView extends StatefulWidget {
  const CreateOutingView({super.key});

  @override
  State<CreateOutingView> createState() => _CreateOutingViewState();
}

class _CreateOutingViewState extends State<CreateOutingView> {
  final _titleController = TextEditingController();
  final List<String> _pollOptions = [];
  final _optionController = TextEditingController();
  String _selectedTimeframe = 'Questo Weekend';
  bool _isLoading = false;

  final List<String> _timeframes = ['Stasera', 'Domani', 'Questo Weekend', 'Prossima Settimana'];

  void _addOption() {
    if (_optionController.text.isNotEmpty) {
      setState(() {
        _pollOptions.add(_optionController.text);
        _optionController.clear();
      });
    }
  }

  Future<void> _submit() async {
    if (_titleController.text.isEmpty) return;
    setState(() => _isLoading = true);

    // In a real app we would create the TimePoll and TimePollOptions here too.
    // For now we just create the Outing scenario.
    final scenario = TimeScenario(
      id: const Uuid().v4(),
      documentId: const Uuid().v4(),
      scenarioType: 'outing',
      startDate: DateTime.now().add(const Duration(days: 2)), // Approximation based on timeframe
      metadata: {
        'title': _titleController.text,
        'timeframe': _selectedTimeframe,
        'initial_poll_options': _pollOptions,
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Proponi Uscita', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          TextField(
            controller: _titleController,
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'Che facciamo?',
              hintStyle: TextStyle(color: Colors.white24, fontSize: 32, fontWeight: FontWeight.w900),
              border: InputBorder.none,
            ),
          ),
          const SizedBox(height: 24),
          const Text('Quando a grandi linee?', style: TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _timeframes.map((t) {
                final isSelected = _selectedTimeframe == t;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(t, style: TextStyle(color: isSelected ? Colors.white : Colors.white54)),
                    selected: isSelected,
                    selectedColor: const Color(0xFFF43F5E),
                    backgroundColor: const Color(0xFF1E1E1E),
                    onSelected: (bool selected) {
                      if (selected) setState(() => _selectedTimeframe = t);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 32),
          const Text('Opzioni Sondaggio (Dove/Cosa)', style: TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 12),
          ..._pollOptions.map((opt) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF43F5E).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.poll, color: Color(0xFFF43F5E), size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text(opt, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white30, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => setState(() => _pollOptions.remove(opt)),
                )
              ],
            ),
          )),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _optionController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Es. Sushi, Pub in centro...',
                    hintStyle: TextStyle(color: Colors.white30),
                    filled: true,
                    fillColor: Color(0xFF1E1E1E),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide.none),
                  ),
                  onSubmitted: (_) => _addOption(),
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                onTap: _addOption,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF43F5E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 48),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF43F5E),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _isLoading ? null : _submit,
            child: _isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Lancia Idea', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
