import 'package:flutter/material.dart';

class RoutineHub extends StatelessWidget {
  const RoutineHub({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Hub Sveglie',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildRoutineCard(
            title: 'Lavoro in Presenza',
            targetTime: '07:30',
            days: 'Lun - Ven',
            isActive: true,
            color: const Color(0xFF3B82F6), // Blue
          ),
          const SizedBox(height: 16),
          _buildRoutineCard(
            title: 'Sveglia Hardcore',
            targetTime: '09:00',
            days: 'Sab - Dom',
            isActive: false,
            color: const Color(0xFFEF4444), // Red
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.add),
        label: const Text('Nuovo Set'),
        backgroundColor: const Color(0xFF8B5CF6),
      ),
    );
  }

  Widget _buildRoutineCard({
    required String title,
    required String targetTime,
    required String days,
    required bool isActive,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isActive ? color.withOpacity(0.5) : Colors.transparent, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              // Apre dettaglio delle singole sveglie relative
            },
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: isActive ? Colors.white : Colors.white54,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              targetTime,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: isActive ? color : Colors.white30,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white10,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                days,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Switch(
                        value: isActive,
                        onChanged: (val) {},
                        activeColor: color,
                      ),
                      if (isActive)
                        TextButton.icon(
                          onPressed: () {
                            // Mette in pausa solo per oggi
                          },
                          icon: const Icon(Icons.pause_circle_outline, size: 16),
                          label: const Text('Pausa Oggi', style: TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.orangeAccent,
                            padding: EdgeInsets.zero,
                          ),
                        )
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
