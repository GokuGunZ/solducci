import 'dart:async';
import 'package:flutter/material.dart';
import 'package:solducci/models/dashboard_config.dart';
import 'package:solducci/models/space_items.dart';
import 'package:solducci/widgets/dashboard/bento_widget_container.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UnresolvedAsterisksWidget extends StatefulWidget {
  final BentoWidgetDef def;

  const UnresolvedAsterisksWidget({super.key, required this.def});

  @override
  State<UnresolvedAsterisksWidget> createState() => _UnresolvedAsterisksWidgetState();
}

class _UnresolvedAsterisksWidgetState extends State<UnresolvedAsterisksWidget> {
  late Stream<List<AsteriskItem>> _asterisksStream;

  @override
  void initState() {
    super.initState();
    _asterisksStream = Supabase.instance.client
        .from('asterisk_items')
        .stream(primaryKey: ['id'])
        .eq('is_resolved', false)
        .order('created_at', ascending: false)
        .limit(5)
        .map((data) => data.map((map) => AsteriskItem.fromMap(map)).toList());
  }

  @override
  Widget build(BuildContext context) {
    return BentoWidgetContainer(
      isLoading: false,
      child: Stack(
        children: [
          // Post-it style background glow
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFFBBF24).withValues(alpha: 0.1),
                    const Color(0xFFFBBF24).withValues(alpha: 0.02),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.emergency, color: Color(0xFFFBBF24), size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'ASTERISCHI',
                      style: TextStyle(
                        color: const Color(0xFFFBBF24).withValues(alpha: 0.9),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: StreamBuilder<List<AsteriskItem>>(
                    stream: _asterisksStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(color: Color(0xFFFBBF24)),
                        );
                      }

                      final asterisks = snapshot.data ?? [];

                      if (asterisks.isEmpty) {
                        return Center(
                          child: Text(
                            'Nessun asterisco\nirrisolto 📝',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }

                      return ListView.separated(
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: asterisks.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = asterisks[index];
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 6.0),
                                child: Container(
                                  width: 4,
                                  height: 4,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFBBF24),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item.content,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    height: 1.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
