import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:solducci/models/task.dart';
import 'package:solducci/models/space_items.dart';
import 'package:solducci/models/time_scenario.dart';
import 'package:intl/intl.dart';

class ImportantHubView extends StatefulWidget {
  const ImportantHubView({super.key});

  @override
  State<ImportantHubView> createState() => _ImportantHubViewState();
}

class _ImportantHubViewState extends State<ImportantHubView> {
  bool _isLoading = true;
  List<Task> _upcomingTasks = [];
  List<TimeScenario> _upcomingEvents = [];
  List<AsteriskItem> _unresolvedAsterisks = [];
  List<ShoppingListItem> _unboughtShopping = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final supabase = Supabase.instance.client;
      final now = DateTime.now();
      final inTwoDays = now.add(const Duration(days: 2));

      // Tasks in scadenza
      final tasksRes = await supabase
          .from('tasks')
          .select()
          .neq('status', 'completed')
          .not('due_date', 'is', null)
          .gte('due_date', now.subtract(const Duration(days: 30)).toIso8601String()) // Overdue limit
          .lte('due_date', inTwoDays.toIso8601String())
          .order('due_date', ascending: true)
          .limit(5);
      final upcomingTasks = tasksRes.map((e) => Task.fromMap(e)).toList();

      // Eventi imminenti
      final eventsRes = await supabase
          .from('time_scenarios')
          .select()
          .gte('start_date', now.toIso8601String())
          .lte('start_date', inTwoDays.toIso8601String())
          .order('start_date', ascending: true)
          .limit(3);
      final upcomingEvents = eventsRes.map((e) => TimeScenario.fromMap(e)).toList();

      // Asterischi non risolti
      final asteriskRes = await supabase
          .from('asterisk_items')
          .select()
          .eq('is_resolved', false)
          .order('created_at', ascending: false)
          .limit(3);
      final unresolvedAsterisks = asteriskRes.map((e) => AsteriskItem.fromMap(e)).toList();

      // Spesa da comprare
      final shoppingRes = await supabase
          .from('shopping_list_items')
          .select()
          .eq('is_bought', false)
          .order('created_at', ascending: false)
          .limit(3);
      final unboughtShopping = shoppingRes.map((e) => ShoppingListItem.fromMap(e)).toList();

      if (mounted) {
        setState(() {
          _upcomingTasks = upcomingTasks;
          _upcomingEvents = upcomingEvents;
          _unresolvedAsterisks = unresolvedAsterisks;
          _unboughtShopping = unboughtShopping;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching important hub data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Importanti', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orangeAccent))
          : RefreshIndicator(
              onRefresh: _fetchData,
              color: Colors.orangeAccent,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSectionTitle('In Scadenza', Icons.warning_amber_rounded, Colors.orangeAccent),
                  if (_upcomingTasks.isEmpty && _upcomingEvents.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 24),
                      child: Text('Niente in scadenza a breve!', style: TextStyle(color: Colors.white54)),
                    ),
                  ..._upcomingTasks.map((t) => _buildMockCard(
                        t.title,
                        'Scade il: ${DateFormat('dd MMM HH:mm').format(t.dueDate!)}',
                        Colors.orangeAccent,
                      )),
                  ..._upcomingEvents.map((e) => _buildMockCard(
                        e.title,
                        'Evento: ${DateFormat('dd MMM HH:mm').format(e.startDate)}',
                        Colors.orangeAccent,
                      )),
                  const SizedBox(height: 32),
                  
                  _buildSectionTitle('Da non dimenticare', Icons.priority_high, Colors.pinkAccent),
                  if (_unresolvedAsterisks.isEmpty && _unboughtShopping.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 24),
                      child: Text('Tutto sotto controllo!', style: TextStyle(color: Colors.white54)),
                    ),
                  ..._unresolvedAsterisks.map((a) => _buildMockCard(
                        a.content,
                        'Asterisco irrisolto',
                        Colors.pinkAccent,
                      )),
                  ..._unboughtShopping.map((s) => _buildMockCard(
                        s.name,
                        'Da comprare (${s.quantity}${s.unit ?? ''})',
                        Colors.pinkAccent,
                      )),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildMockCard(String title, String subtitle, Color accentColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 14)),
        ],
      ),
    );
  }
}
