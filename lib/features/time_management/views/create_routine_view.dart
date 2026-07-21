import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:solducci/service/time_management_service.dart';
import 'package:solducci/models/routine.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreateRoutineView extends StatefulWidget {
  const CreateRoutineView({super.key});

  @override
  State<CreateRoutineView> createState() => _CreateRoutineViewState();
}

class _CreateRoutineViewState extends State<CreateRoutineView> {
  final _nameController = TextEditingController();
  TimeOfDay _targetTime = const TimeOfDay(hour: 8, minute: 0);
  final Set<int> _selectedDays = {1, 2, 3, 4, 5}; // Mon-Fri default
  
  // List of temporary alarms. (offsetMinutes, label, alarmType)
  final List<Map<String, dynamic>> _alarms = [];
  
  bool _isLoading = false;

  void _addAlarm(int offset, String label, String type) {
    setState(() {
      _alarms.add({
        'offset': offset,
        'label': label,
        'type': type,
      });
      // Sort by offset so they appear in chronological order
      _alarms.sort((a, b) => (a['offset'] as int).compareTo(b['offset'] as int));
    });
  }

  void _showAddAlarmSheet() {
    int localOffset = -30;
    String localLabel = '';
    String localType = 'push';
    
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 24, right: 24, top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Nuovo Allarme Relativo', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Text('Offset (minuti): ', style: TextStyle(color: Colors.white70)),
                      Text(localOffset.toString(), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Slider(
                    value: localOffset.toDouble(),
                    min: -120,
                    max: 60,
                    divisions: 36,
                    activeColor: const Color(0xFF8B5CF6),
                    onChanged: (val) => setSheetState(() => localOffset = val.toInt()),
                  ),
                  TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Etichetta (es. Prepara borsa)',
                      labelStyle: TextStyle(color: Colors.white54),
                    ),
                    onChanged: (val) => localLabel = val,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Notifica 📱'),
                          selected: localType == 'push',
                          selectedColor: const Color(0xFF8B5CF6),
                          onSelected: (val) { if(val) setSheetState(() => localType = 'push'); },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Sveglia 🔔'),
                          selected: localType == 'native_aggressive',
                          selectedColor: const Color(0xFFEF4444),
                          onSelected: (val) { if(val) setSheetState(() => localType = 'native_aggressive'); },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6)),
                      onPressed: () {
                        if (localLabel.isEmpty) localLabel = 'Allarme';
                        _addAlarm(localOffset, localLabel, localType);
                        Navigator.pop(ctx);
                      },
                      child: const Text('Aggiungi', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          }
        );
      }
    );
  }

  Future<void> _submit() async {
    if (_nameController.text.isEmpty || _selectedDays.isEmpty) return;
    setState(() => _isLoading = true);

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final templateId = const Uuid().v4();
    final template = RoutineTemplate(
      id: templateId,
      userId: userId,
      name: _nameController.text,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final schedules = _selectedDays.map((day) => RoutineSchedule(
      id: const Uuid().v4(),
      routineTemplateId: templateId,
      targetTime: _targetTime,
      dayOfWeek: day,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    )).toList();

    final alarmObjects = _alarms.map((a) => RoutineAlarm(
      id: const Uuid().v4(),
      routineTemplateId: templateId,
      offsetMinutes: a['offset'],
      label: a['label'],
      alarmType: a['type'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    )).toList();

    try {
      await TimeManagementService().createRoutineTemplate(template, schedules, alarmObjects);
      if (mounted) context.pop();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore: $e')));
      }
    }
  }

  String _formatTime(TimeOfDay time, int offset) {
    int totalMinutes = time.hour * 60 + time.minute + offset;
    if (totalMinutes < 0) totalMinutes += 24 * 60;
    final h = (totalMinutes ~/ 60) % 24;
    final m = totalMinutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Nuovo Set', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextField(
            controller: _nameController,
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              hintText: 'Nome Routine (es. Palestra)',
              hintStyle: TextStyle(color: Colors.white30, fontSize: 24),
              border: InputBorder.none,
            ),
          ),
          const SizedBox(height: 32),
          
          // Section 1: Target Time
          InkWell(
            onTap: () async {
              final t = await showTimePicker(context: context, initialTime: _targetTime);
              if (t != null) setState(() => _targetTime = t);
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Ora X (Target)', style: TextStyle(color: Colors.white70, fontSize: 16)),
                  Text('${_targetTime.hour.toString().padLeft(2, '0')}:${_targetTime.minute.toString().padLeft(2, '0')}', 
                    style: const TextStyle(color: const Color(0xFF8B5CF6), fontSize: 24, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          // Section 2: Days
          const Text('Giorni', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDayBubble('L', 1),
              _buildDayBubble('M', 2),
              _buildDayBubble('M', 3),
              _buildDayBubble('G', 4),
              _buildDayBubble('V', 5),
              _buildDayBubble('S', 6),
              _buildDayBubble('D', 7),
            ],
          ),
          const SizedBox(height: 32),
          
          // Section 3: Alarms
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Timeline Allarmi', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.add_circle, color: Color(0xFF8B5CF6)),
                onPressed: _showAddAlarmSheet,
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Render Alarms
          if (_alarms.isEmpty)
            const Text('Nessun allarme impostato. Aggiungi il primo!', style: TextStyle(color: Colors.white30))
          else
            ..._alarms.map((a) {
              final isNative = a['type'] == 'native_aggressive';
              final color = isNative ? const Color(0xFFEF4444) : const Color(0xFF3B82F6);
              final icon = isNative ? Icons.notifications_active : Icons.phone_iphone;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(icon, color: color, size: 20),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a['label'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          Text(a['offset'] < 0 ? '${a['offset']}m prima' : '+${a['offset']}m dopo', 
                            style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        ],
                      ),
                    ),
                    Text(_formatTime(_targetTime, a['offset']), 
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white30, size: 16),
                      onPressed: () => setState(() => _alarms.remove(a)),
                    ),
                  ],
                ),
              );
            }).toList(),
            
          const SizedBox(height: 48),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _isLoading ? null : _submit,
            child: _isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Salva Set', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDayBubble(String label, int dayIndex) {
    final isSelected = _selectedDays.contains(dayIndex);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) _selectedDays.remove(dayIndex);
          else _selectedDays.add(dayIndex);
        });
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? const Color(0xFF8B5CF6) : const Color(0xFF1E1E1E),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white54,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
