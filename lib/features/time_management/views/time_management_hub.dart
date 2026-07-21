import 'package:flutter/material.dart';
import 'package:solducci/features/time_management/views/routine_hub.dart';

class TimeManagementHub extends StatelessWidget {
  const TimeManagementHub({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Deep dark mode
      appBar: AppBar(
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
            icon: const Icon(Icons.alarm, color: Colors.white70),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RoutineHub()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
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
              _buildRadarRow(),
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
              _buildEventCard(
                title: 'Viaggio a Londra',
                dateStr: 'Tra 14 Giorni',
                type: 'trip',
                color: const Color(0xFF6366F1), // Indigo
              ),
              const SizedBox(height: 12),
              _buildEventCard(
                title: 'Grigliata di Fine Estate',
                dateStr: 'Sabato, 20:00',
                type: 'outing',
                color: const Color(0xFFF43F5E), // Rose
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Apri modale per creare Evento, Viaggio o Pubblicare Slot
        },
        backgroundColor: const Color(0xFF10B981), // Emerald
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildRadarRow() {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        itemBuilder: (context, index) {
          if (index == 0) {
            // Pulsante per pubblicare propria disponibilità
            return Container(
              width: 70,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white30, width: 2),
              ),
              child: const Icon(Icons.add, color: Colors.white54),
            );
          }
          
          return Container(
            width: 70,
            margin: const EdgeInsets.only(right: 12),
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
          );
        },
      ),
    );
  }

  Widget _buildEventCard({
    required String title,
    required String dateStr,
    required String type,
    required Color color,
  }) {
    return Container(
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
                  type.toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    color: color,
                  ),
                ),
              ),
              const Icon(Icons.more_horiz, color: Colors.white54),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
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
                dateStr,
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
    );
  }
}
