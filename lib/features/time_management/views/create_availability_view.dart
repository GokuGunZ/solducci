import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:solducci/service/time_management_service.dart';
import 'package:solducci/models/time_scenario.dart';

class CreateAvailabilityView extends StatefulWidget {
  const CreateAvailabilityView({super.key});

  @override
  State<CreateAvailabilityView> createState() => _CreateAvailabilityViewState();
}

class _CreateAvailabilityViewState extends State<CreateAvailabilityView> {
  String _selectedActivity = 'Caffè';
  String _selectedTimeframe = 'Ora';
  bool _isLoading = false;

  final List<Map<String, dynamic>> _activities = [
    {'label': 'Caffè', 'icon': Icons.local_cafe, 'color': Colors.brown},
    {'label': 'Birretta', 'icon': Icons.sports_bar, 'color': Colors.amber},
    {'label': 'Cena', 'icon': Icons.restaurant, 'color': Colors.deepOrange},
    {'label': 'Gaming', 'icon': Icons.sports_esports, 'color': Colors.deepPurple},
    {'label': 'Studio', 'icon': Icons.menu_book, 'color': Colors.blueGrey},
    {'label': 'Passeggiata', 'icon': Icons.directions_walk, 'color': Colors.green},
  ];

  final List<String> _timeframes = ['Ora', 'Tra 1 ora', 'Stasera', 'Domani'];

  Future<void> _submit() async {
    setState(() => _isLoading = true);

    DateTime targetDate = DateTime.now();
    if (_selectedTimeframe == 'Tra 1 ora') {
      targetDate = targetDate.add(const Duration(hours: 1));
    } else if (_selectedTimeframe == 'Stasera') {
      targetDate = DateTime(targetDate.year, targetDate.month, targetDate.day, 21, 0); // 21:00
    } else if (_selectedTimeframe == 'Domani') {
      targetDate = targetDate.add(const Duration(days: 1));
    }

    final scenario = TimeScenario(
      id: const Uuid().v4(),
      documentId: const Uuid().v4(),
      scenarioType: 'availability',
      startDate: targetDate,
      metadata: {'title': _selectedActivity, 'timeframe_label': _selectedTimeframe},
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
        title: const Text('Disponibilità', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Cosa ti va di fare?', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemCount: _activities.length,
              itemBuilder: (context, index) {
                final activity = _activities[index];
                final isSelected = _selectedActivity == activity['label'];
                
                return GestureDetector(
                  onTap: () => setState(() => _selectedActivity = activity['label']),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected ? activity['color'] : const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(activity['icon'], size: 32, color: isSelected ? Colors.white : activity['color']),
                        const SizedBox(height: 8),
                        Text(activity['label'], style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 40),
            const Text('Quando?', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _timeframes.map((t) {
                final isSelected = _selectedTimeframe == t;
                return ChoiceChip(
                  label: Text(t, style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
                  selected: isSelected,
                  selectedColor: const Color(0xFF8B5CF6),
                  backgroundColor: const Color(0xFF1E1E1E),
                  onSelected: (bool selected) {
                    if (selected) setState(() => _selectedTimeframe = t);
                  },
                );
              }).toList(),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isLoading ? null : _submit,
                child: _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Lancia Segnale', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
