import 'package:flutter/material.dart';
import 'package:solducci/service/time_management_service.dart';
import 'package:solducci/models/routine.dart';
import 'package:solducci/service/context_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'base_quick_add_sheet.dart';

class RoutineQuickAddForm extends StatefulWidget {
  final String? selectedFolderId; // Usato qui come 'Categoria' per coerenza
  final VoidCallback onAdded;

  const RoutineQuickAddForm({
    super.key,
    this.selectedFolderId,
    required this.onAdded,
  });

  static Future<void> show({
    required BuildContext context,
    required Future<List<CollectionFolder>> foldersFuture,
    required VoidCallback onAdded,
  }) {
    return BaseQuickAddSheet.show(
      context: context,
      title: 'Nuova Routine',
      themeColor: const Color(0xFFF59E0B),
      folderSelectorLabel: 'Categoria',
      foldersFuture: foldersFuture,
      childBuilder: (ctx, folderId) => RoutineQuickAddForm(
        selectedFolderId: folderId,
        onAdded: onAdded,
      ),
    );
  }

  @override
  State<RoutineQuickAddForm> createState() => _RoutineQuickAddFormState();
}

class _RoutineQuickAddFormState extends State<RoutineQuickAddForm> {
  final _nameController = TextEditingController();
  TimeOfDay _targetTime = const TimeOfDay(hour: 8, minute: 0);
  final Set<int> _selectedDays = {1, 2, 3, 4, 5};
  final List<Map<String, dynamic>> _alarms = [];
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addAlarm(int offset, String label, String type) {
    setState(() {
      _alarms.add({
        'offset': offset,
        'label': label,
        'type': type,
      });
      _alarms.sort((a, b) => (a['offset'] as int).compareTo(b['offset'] as int));
    });
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      final categoryName = ['Mattina', 'Sera', 'Lavoro', 'Fitness'].elementAtOrNull(int.tryParse(widget.selectedFolderId ?? '0') ?? 0) ?? 'Generale';
      final currentContext = ContextManager().currentContext;
      
      final templateId = const Uuid().v4();
      final template = RoutineTemplate(
        id: templateId,
        userId: Supabase.instance.client.auth.currentUser?.id ?? '', 
        groupId: currentContext.isGroup ? currentContext.groupId : null,
        name: name,
        description: 'Categoria: $categoryName',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final schedules = _selectedDays.map((dayOfWeek) => RoutineSchedule(
        id: const Uuid().v4(),
        routineTemplateId: templateId,
        dayOfWeek: dayOfWeek,
        targetTime: _targetTime,
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

      await TimeManagementService().createRoutineTemplate(template, schedules, alarmObjects);
      
      if (mounted) {
        widget.onAdded();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Errore durante l'aggiunta")));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildDayBubble(String label, int dayIndex) {
    final isSelected = _selectedDays.contains(dayIndex);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedDays.remove(dayIndex);
          } else {
            _selectedDays.add(dayIndex);
          }
        });
      },
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF59E0B) : const Color(0xFF2A2A2D),
          shape: BoxShape.circle,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white54,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _showAddAlarmDialog() {
    int localOffset = -30;
    String localLabel = '';
    String localType = 'push';
    
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              title: const Text('Nuovo Allarme', style: TextStyle(color: Colors.white)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('Offset (minuti): ', style: TextStyle(color: Colors.white70)),
                        Text(localOffset.toString(), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Slider(
                      value: localOffset.toDouble(),
                      min: -120,
                      max: 60,
                      divisions: 36,
                      activeColor: const Color(0xFFF59E0B),
                      onChanged: (val) => setDialogState(() => localOffset = val.toInt()),
                    ),
                    TextField(
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Etichetta (es. Prepara)',
                        labelStyle: TextStyle(color: Colors.white54),
                      ),
                      onChanged: (val) => localLabel = val,
                    ),
                    const SizedBox(height: 16),
                    ChoiceChip(
                      label: const Text('Notifica'),
                      selected: localType == 'push',
                      selectedColor: const Color(0xFFF59E0B).withOpacity(0.2),
                      onSelected: (val) { if(val) setDialogState(() => localType = 'push'); },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Sveglia'),
                      selected: localType == 'native_aggressive',
                      selectedColor: const Color(0xFFEF4444).withOpacity(0.2),
                      onSelected: (val) { if(val) setDialogState(() => localType = 'native_aggressive'); },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annulla', style: TextStyle(color: Colors.white54))),
                ElevatedButton(
                  onPressed: () {
                    _addAlarm(localOffset, localLabel.isEmpty ? 'Allarme' : localLabel, localType);
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B)),
                  child: const Text('Aggiungi'),
                ),
              ],
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _nameController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Nome Routine *',
            labelStyle: const TextStyle(color: Colors.white54),
            filled: true,
            fillColor: const Color(0xFF2A2A2D),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () async {
            final t = await showTimePicker(context: context, initialTime: _targetTime);
            if (t != null) setState(() => _targetTime = t);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2D),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Ora Target', style: TextStyle(color: Colors.white70)),
                Text('${_targetTime.hour.toString().padLeft(2, '0')}:${_targetTime.minute.toString().padLeft(2, '0')}', 
                  style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Giorni', style: TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildDayBubble('L', 1), _buildDayBubble('M', 2), _buildDayBubble('M', 3),
            _buildDayBubble('G', 4), _buildDayBubble('V', 5), _buildDayBubble('S', 6),
            _buildDayBubble('D', 7),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Allarmi', style: TextStyle(color: Colors.white54, fontSize: 12)),
            TextButton.icon(
              onPressed: _showAddAlarmDialog,
              icon: const Icon(Icons.add, size: 16, color: Color(0xFFF59E0B)),
              label: const Text('Aggiungi', style: TextStyle(color: Color(0xFFF59E0B))),
            )
          ],
        ),
        if (_alarms.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 120),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _alarms.length,
              itemBuilder: (context, index) {
                final a = _alarms[index];
                final sign = (a['offset'] as int) > 0 ? '+' : '';
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: Icon(a['type'] == 'push' ? Icons.notifications : Icons.alarm, color: Colors.white70, size: 20),
                  title: Text(a['label'], style: const TextStyle(color: Colors.white)),
                  trailing: Text('$sign${a['offset']} min', style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold)),
                );
              },
            ),
          ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF59E0B),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            disabledBackgroundColor: const Color(0xFFF59E0B).withValues(alpha: 0.5),
          ),
          child: _isSaving
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Aggiungi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
