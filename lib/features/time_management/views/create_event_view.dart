import 'package:solducci/widgets/solducci_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:solducci/service/time_management_service.dart';
import 'package:solducci/models/time_scenario.dart';

class CreateEventView extends StatefulWidget {
  const CreateEventView({super.key});

  @override
  State<CreateEventView> createState() => _CreateEventViewState();
}

class _CreateEventViewState extends State<CreateEventView> {
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isLoading = false;

  Future<void> _submit() async {
    if (_titleController.text.isEmpty) return;
    setState(() => _isLoading = true);

    final targetDate = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final scenario = TimeScenario(
      id: const Uuid().v4(),
      documentId: const Uuid().v4(),
      scenarioType: 'event',
      startDate: targetDate,
      location: _locationController.text.isNotEmpty ? _locationController.text : null,
      metadata: {'title': _titleController.text},
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
        title: const Text('Nuovo Evento', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          TextField(
            controller: _titleController,
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              hintText: 'Es. Festa a Sorpresa',
              hintStyle: TextStyle(color: Colors.white30, fontSize: 24, fontWeight: FontWeight.bold),
              border: InputBorder.none,
            ),
          ),
          const SizedBox(height: 32),
          _buildActionTile(
            icon: Icons.calendar_today,
            title: 'Data',
            value: "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date != null) setState(() => _selectedDate = date);
            },
          ),
          _buildActionTile(
            icon: Icons.access_time,
            title: 'Ora',
            value: _selectedTime.format(context),
            onTap: () async {
              final time = await showTimePicker(context: context, initialTime: _selectedTime);
              if (time != null) setState(() => _selectedTime = time);
            },
          ),
          _buildActionTile(
            icon: Icons.location_on,
            title: 'Luogo',
            value: _locationController.text.isEmpty ? 'Aggiungi Luogo' : _locationController.text,
            onTap: () {
              // Placeholder for a quick dialog or just let user type in the field
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _locationController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Indirizzo o Link Google Maps',
              hintStyle: TextStyle(color: Colors.white30),
              prefixIcon: Icon(Icons.map, color: Colors.white54),
              filled: true,
              fillColor: Color(0xFF1E1E1E),
              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide.none),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 48),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _isLoading ? null : _submit,
            child: _isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Crea Evento', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({required IconData icon, required String title, required String value, required VoidCallback onTap}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: const Color(0xFF10B981)),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white54, fontSize: 14)),
      subtitle: Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right, color: Colors.white30),
      onTap: onTap,
    );
  }
}
