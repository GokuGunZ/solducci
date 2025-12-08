import 'package:flutter/material.dart';
import 'package:solducci/models/recurrence.dart';

/// Dialog for creating or editing a recurrence rule
/// Two-level configuration: Intra-day (times) + Inter-day (days)
class RecurrenceFormDialog extends StatefulWidget {
  final Recurrence? recurrence; // null = create, non-null = edit

  const RecurrenceFormDialog({
    super.key,
    this.recurrence,
  });

  @override
  State<RecurrenceFormDialog> createState() => _RecurrenceFormDialogState();
}

class _RecurrenceFormDialogState extends State<RecurrenceFormDialog> {
  // Intra-day frequency
  IntraDayFrequencyType _intraDayType = IntraDayFrequencyType.once;
  int _hourlyFrequency = 1;
  List<TimeOfDay> _specificTimes = [];

  // Inter-day frequency
  InterDayFrequencyType _interDayType = InterDayFrequencyType.daily;
  int _dailyFrequency = 1;
  Set<int> _weeklyDays = {};
  Set<int> _monthlyDays = {};

  // Period
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    if (widget.recurrence != null) {
      _loadExistingRecurrence();
    }
  }

  void _loadExistingRecurrence() {
    final r = widget.recurrence!;

    // Intra-day
    _intraDayType = r.intraDayType;
    if (r.hourlyFrequency != null) {
      _hourlyFrequency = r.hourlyFrequency!;
    }
    if (r.specificTimes != null) {
      _specificTimes = List.from(r.specificTimes!);
    }

    // Inter-day
    _interDayType = r.interDayType;
    if (r.dailyFrequency != null) {
      _dailyFrequency = r.dailyFrequency!;
    }
    if (r.weeklyDays != null) {
      _weeklyDays = Set.from(r.weeklyDays!);
    }
    if (r.monthlyDays != null) {
      _monthlyDays = Set.from(r.monthlyDays!);
    }

    // Period
    _startDate = r.startDate;
    _endDate = r.endDate;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[700],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.repeat, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Configura Ricorrenza',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Form content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Level 1: Intra-day frequency
                    _buildIntraDaySection(),

                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 24),

                    // Level 2: Inter-day frequency
                    _buildInterDaySection(),

                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 24),

                    // Period
                    _buildPeriodSection(),
                  ],
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(4),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Annulla'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _saveRecurrence,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[700],
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Salva'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntraDaySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Livello 1: Quante volte al giorno?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Scegli con che frequenza la task si ripete durante la giornata',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 16),

        // Radio buttons for intra-day type
        RadioListTile<IntraDayFrequencyType>(
          title: const Text('Una volta al giorno'),
          value: IntraDayFrequencyType.once,
          groupValue: _intraDayType,
          onChanged: (value) => setState(() => _intraDayType = value!),
        ),

        RadioListTile<IntraDayFrequencyType>(
          title: const Text('Ogni N ore'),
          value: IntraDayFrequencyType.hourly,
          groupValue: _intraDayType,
          onChanged: (value) => setState(() => _intraDayType = value!),
        ),

        if (_intraDayType == IntraDayFrequencyType.hourly)
          Padding(
            padding: const EdgeInsets.only(left: 32, right: 16),
            child: Row(
              children: [
                const Text('Ogni'),
                const SizedBox(width: 8),
                SizedBox(
                  width: 80,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    controller: TextEditingController(
                      text: _hourlyFrequency.toString(),
                    ),
                    onChanged: (value) {
                      final parsed = int.tryParse(value);
                      if (parsed != null && parsed > 0) {
                        _hourlyFrequency = parsed;
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                const Text('ore'),
              ],
            ),
          ),

        RadioListTile<IntraDayFrequencyType>(
          title: const Text('A orari specifici'),
          value: IntraDayFrequencyType.specific,
          groupValue: _intraDayType,
          onChanged: (value) => setState(() => _intraDayType = value!),
        ),

        if (_intraDayType == IntraDayFrequencyType.specific)
          Padding(
            padding: const EdgeInsets.only(left: 32, right: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  children: _specificTimes
                      .map((time) => Chip(
                            label: Text(time.format(context)),
                            onDeleted: () {
                              setState(() {
                                _specificTimes.remove(time);
                              });
                            },
                          ))
                      .toList(),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _addSpecificTime,
                  icon: const Icon(Icons.add),
                  label: const Text('Aggiungi orario'),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildInterDaySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Livello 2: In quali giorni?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Scegli in quali giorni la task si ripete',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 16),

        // Radio buttons for inter-day type
        RadioListTile<InterDayFrequencyType>(
          title: const Text('Ogni giorno'),
          value: InterDayFrequencyType.daily,
          groupValue: _interDayType,
          onChanged: (value) => setState(() => _interDayType = value!),
        ),

        if (_interDayType == InterDayFrequencyType.daily)
          Padding(
            padding: const EdgeInsets.only(left: 32, right: 16),
            child: Row(
              children: [
                const Text('Ogni'),
                const SizedBox(width: 8),
                SizedBox(
                  width: 80,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    controller: TextEditingController(
                      text: _dailyFrequency.toString(),
                    ),
                    onChanged: (value) {
                      final parsed = int.tryParse(value);
                      if (parsed != null && parsed > 0) {
                        _dailyFrequency = parsed;
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                const Text('giorni'),
              ],
            ),
          ),

        RadioListTile<InterDayFrequencyType>(
          title: const Text('Giorni della settimana specifici'),
          value: InterDayFrequencyType.weekly,
          groupValue: _interDayType,
          onChanged: (value) => setState(() => _interDayType = value!),
        ),

        if (_interDayType == InterDayFrequencyType.weekly)
          Padding(
            padding: const EdgeInsets.only(left: 32, right: 16),
            child: Wrap(
              spacing: 8,
              children: [
                _buildDayChip('Dom', 0),
                _buildDayChip('Lun', 1),
                _buildDayChip('Mar', 2),
                _buildDayChip('Mer', 3),
                _buildDayChip('Gio', 4),
                _buildDayChip('Ven', 5),
                _buildDayChip('Sab', 6),
              ],
            ),
          ),

        RadioListTile<InterDayFrequencyType>(
          title: const Text('Giorni del mese specifici'),
          value: InterDayFrequencyType.monthly,
          groupValue: _interDayType,
          onChanged: (value) => setState(() => _interDayType = value!),
        ),

        if (_interDayType == InterDayFrequencyType.monthly)
          Padding(
            padding: const EdgeInsets.only(left: 32, right: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Seleziona i giorni del mese (1-31):'),
                const SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: 31,
                  itemBuilder: (context, index) {
                    final day = index + 1;
                    final isSelected = _monthlyDays.contains(day);
                    return FilterChip(
                      label: Text(
                        '$day',
                        style: const TextStyle(fontSize: 12),
                      ),
                      selected: isSelected,
                      showCheckmark: false,
                      selectedColor: Colors.purple[700],
                      elevation: isSelected ? 4 : 0,
                      shadowColor: Colors.purple.withAlpha(100),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _monthlyDays.add(day);
                          } else {
                            _monthlyDays.remove(day);
                          }
                        });
                      },
                    );
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDayChip(String label, int weekday) {
    final isSelected = _weeklyDays.contains(weekday);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _weeklyDays.add(weekday);
          } else {
            _weeklyDays.remove(weekday);
          }
        });
      },
    );
  }

  Widget _buildPeriodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Periodo di Validità',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Start date
        ListTile(
          leading: const Icon(Icons.calendar_today),
          title: const Text('Data inizio'),
          subtitle: Text(
            '${_startDate.day}/${_startDate.month}/${_startDate.year}',
          ),
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _startDate,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 3650)),
            );
            if (date != null) {
              setState(() => _startDate = date);
            }
          },
        ),

        // End date (optional)
        SwitchListTile(
          title: const Text('Data fine'),
          subtitle: _endDate != null
              ? Text('${_endDate!.day}/${_endDate!.month}/${_endDate!.year}')
              : const Text('Nessuna (ricorrenza infinita)'),
          value: _endDate != null,
          onChanged: (value) {
            if (value) {
              showDatePicker(
                context: context,
                initialDate: _startDate.add(const Duration(days: 30)),
                firstDate: _startDate,
                lastDate: DateTime.now().add(const Duration(days: 3650)),
              ).then((date) {
                if (date != null) {
                  setState(() => _endDate = date);
                }
              });
            } else {
              setState(() => _endDate = null);
            }
          },
        ),
      ],
    );
  }

  Future<void> _addSpecificTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time != null) {
      setState(() {
        if (!_specificTimes.any((t) => t.hour == time.hour && t.minute == time.minute)) {
          _specificTimes.add(time);
          _specificTimes.sort((a, b) {
            final aMinutes = a.hour * 60 + a.minute;
            final bMinutes = b.hour * 60 + b.minute;
            return aMinutes.compareTo(bMinutes);
          });
        }
      });
    }
  }

  void _saveRecurrence() {
    // Validate intra-day frequency
    int? hourlyFreq;
    List<TimeOfDay>? specificTimes;

    if (_intraDayType == IntraDayFrequencyType.hourly) {
      if (_hourlyFrequency <= 0) {
        _showError('Inserisci un intervallo orario valido (maggiore di 0)');
        return;
      }
      hourlyFreq = _hourlyFrequency;
    } else if (_intraDayType == IntraDayFrequencyType.specific) {
      if (_specificTimes.isEmpty) {
        _showError('Aggiungi almeno un orario specifico');
        return;
      }
      specificTimes = _specificTimes;
    }

    // Validate inter-day frequency
    int? dailyFreq;
    List<int>? weeklyDays;
    List<int>? monthlyDays;

    if (_interDayType == InterDayFrequencyType.daily) {
      if (_dailyFrequency <= 0) {
        _showError('Inserisci un intervallo giornaliero valido (maggiore di 0)');
        return;
      }
      dailyFreq = _dailyFrequency;
    } else if (_interDayType == InterDayFrequencyType.weekly) {
      if (_weeklyDays.isEmpty) {
        _showError('Seleziona almeno un giorno della settimana');
        return;
      }
      weeklyDays = _weeklyDays.toList()..sort();
    } else if (_interDayType == InterDayFrequencyType.monthly) {
      if (_monthlyDays.isEmpty) {
        _showError('Seleziona almeno un giorno del mese');
        return;
      }
      monthlyDays = _monthlyDays.toList()..sort();
    }

    // Validate period
    if (_endDate != null && _endDate!.isBefore(_startDate)) {
      _showError('La data fine deve essere successiva alla data inizio');
      return;
    }

    // Create Recurrence object
    try {
      final recurrence = Recurrence(
        id: widget.recurrence?.id ?? '', // Will be generated by service
        taskId: widget.recurrence?.taskId,
        tagId: widget.recurrence?.tagId,
        hourlyFrequency: hourlyFreq,
        specificTimes: specificTimes,
        dailyFrequency: dailyFreq,
        weeklyDays: weeklyDays,
        monthlyDays: monthlyDays,
        yearlyDates: null, // Not implemented in UI yet
        startDate: _startDate,
        endDate: _endDate,
        createdAt: widget.recurrence?.createdAt ?? DateTime.now(),
      );

      // Return the recurrence object
      Navigator.pop(context, recurrence);
    } catch (e) {
      _showError('Errore nella creazione della ricorrenza: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
