import 'package:flutter/material.dart';
import 'package:solducci/models/dashboard_config.dart';
import 'package:solducci/widgets/dashboard/bento_widget_container.dart';

class MonthlyBurnRateWidget extends StatefulWidget {
  final BentoWidgetDef def;

  const MonthlyBurnRateWidget({super.key, required this.def});

  @override
  State<MonthlyBurnRateWidget> createState() => _MonthlyBurnRateWidgetState();
}

class _MonthlyBurnRateWidgetState extends State<MonthlyBurnRateWidget> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 1000));
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BentoWidgetContainer(
      isLoading: _isLoading,
      child: Stack(
        children: [
          // Background Gradient to simulate chart/glassmorphism
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFFE068F1).withValues(alpha: 0.2),
                    Colors.transparent,
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'BURN RATE',
                      style: TextStyle(
                        color: const Color(0xFFE068F1).withValues(alpha: 0.8),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const Icon(Icons.trending_up, color: Color(0xFFE068F1), size: 16),
                  ],
                ),
                const Spacer(),
                const Text(
                  '450.00 €',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Media ultimi 3 mesi: 420.00 €',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 8),
                // Simple Progress Bar
                LinearProgressIndicator(
                  value: 450 / 600, // example ratio
                  backgroundColor: Colors.white10,
                  color: const Color(0xFFE068F1),
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
