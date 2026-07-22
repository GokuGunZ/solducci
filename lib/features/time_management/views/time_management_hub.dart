import 'package:solducci/widgets/solducci_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:solducci/features/time_management/views/routine_hub.dart';
import 'package:solducci/blocs/time_management/time_management_bloc.dart';
import 'package:solducci/blocs/time_management/time_management_event.dart';
import 'package:solducci/blocs/time_management/time_management_state.dart';
import 'package:solducci/models/time_scenario.dart';
import 'package:solducci/service/time_management_service.dart';

class TimeManagementHub extends StatelessWidget {
  const TimeManagementHub({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TimeManagementBloc()..add(SubscribeToTimeScenarios()),
      child: const _TimeManagementHubView(),
    );
  }
}

class _TimeManagementHubView extends StatelessWidget {
  const _TimeManagementHubView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Deep dark mode
      appBar: SolducciAppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Time Management',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => _showCreationBottomSheet(context),
          ),
          IconButton(
            icon: const Icon(Icons.alarm, color: Colors.white70),
            onPressed: () {
              context.push('/space/time_management/routines');
            },
          ),
        ],
      ),
      body: BlocBuilder<TimeManagementBloc, TimeManagementState>(
        builder: (context, state) {
          if (state is TimeManagementLoading || state is TimeManagementInitial) {
            return const Center(child: CircularProgressIndicator(color: Colors.pinkAccent));
          }

          if (state is TimeManagementError) {
            return Center(child: Text('Errore: ${state.message}', style: const TextStyle(color: Colors.red)));
          }

          if (state is TimeManagementLoaded) {
            return _buildContent(context, state);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _showCreationBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Cosa vuoi organizzare?', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              _buildCreationOption(context, 'Viaggio', 'Pianifica con RSVP e Dispensa', Icons.flight_takeoff, const Color(0xFF6366F1), 'trip'),
              _buildCreationOption(context, 'Evento', 'Appuntamenti fissi e scadenze', Icons.event, const Color(0xFF10B981), 'event'),
              _buildCreationOption(context, 'Uscita Leggera', 'Sondaggi su dove e quando', Icons.local_bar, const Color(0xFFF43F5E), 'outing'),
              _buildCreationOption(context, 'Radar', 'Segnala che sei libero', Icons.radar, const Color(0xFF8B5CF6), 'availability'),
            ],
          ),
        );
      }
    );
  }

  Widget _buildCreationOption(BuildContext context, String title, String subtitle, IconData icon, Color color, String type) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54)),
      onTap: () {
        context.pop(); // close bottom sheet
        context.push('/space/time_management/create/$type');
      },
    );
  }

  Widget _buildContent(BuildContext context, TimeManagementLoaded state) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Radar Section
            const Text(
              'Radar Disponibilità',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            _buildRadarRow(state.radarScenarios),
            const SizedBox(height: 32),
            
            // Upcoming Events Section
            const Text(
              'In Arrivo',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            
            if (state.eventScenarios.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Text('Nessun evento in arrivo.', style: TextStyle(color: Colors.white54)),
              )
            else
              ...state.eventScenarios.map((scenario) => Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: _buildEventCard(context, scenario),
              )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRadarRow(List<TimeScenario> radarScenarios) {
    return SizedBox(
      height: 120, // Increased height for name text
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: radarScenarios.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            // Button to add my own availability
            return GestureDetector(
              onTap: () {
                context.push('/space/time_management/create/availability');
              },
              child: Container(
                width: 70,
                margin: const EdgeInsets.only(right: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 66,
                      height: 66,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white30, width: 2),
                      ),
                      child: const Icon(Icons.add, color: Colors.white54),
                    ),
                    const SizedBox(height: 4),
                    const Text('Nuovo', style: TextStyle(color: Colors.white54, fontSize: 10)),
                  ],
                ),
              ),
            );
          }
          
          final scenario = radarScenarios[index - 1];
          return GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: const Color(0xFF1E1E1E),
                  title: Text(scenario.metadata['userName'] as String? ?? 'Utente', style: const TextStyle(color: Colors.white)),
                  content: const Text('Questa persona è disponibile. Vuoi organizzare qualcosa con lei?', style: TextStyle(color: Colors.white70)),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla', style: TextStyle(color: Colors.white54))),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        context.push('/space/time_management/create/outing');
                      }, 
                      child: const Text('Invita', style: TextStyle(color: Color(0xFF6366F1)))
                    ),
                  ]
                ),
              );
            },
            child: Container(
              width: 70,
              margin: const EdgeInsets.only(right: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                    Container(
                      width: 66,
                      height: 66,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(color: Colors.black, width: 3),
                      ),
                      child: const Center(
                        child: CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.transparent,
                          child: Icon(Icons.person, color: Colors.white), 
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    scenario.metadata['userName'] as String? ?? 'Utente',
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, TimeScenario scenario) {
    // Dynamic color based on type
    Color color = const Color(0xFF6366F1); // Indigo default
    if (scenario.scenarioType == 'outing') color = const Color(0xFFF43F5E); // Rose
    if (scenario.scenarioType == 'event') color = const Color(0xFF10B981); // Emerald

    return GestureDetector(
      onTap: () {
        context.push('/space/time_management/scenario/${scenario.scenarioType}/${scenario.id}');
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    scenario.scenarioType.toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      color: color,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () {
                    TimeManagementService().deleteTimeScenario(scenario.id);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              scenario.title,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: Colors.white54),
                const SizedBox(width: 6),
                Text(
                  scenario.targetDate != null 
                    ? scenario.targetDate!.toLocal().toString().split(' ')[0] 
                    : 'Data da definire',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
