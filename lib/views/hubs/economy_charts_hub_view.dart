import 'package:flutter/material.dart';

class EconomyChartsHubView extends StatelessWidget {
  const EconomyChartsHubView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Dashboard Grafici', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Panoramica Mensile',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildMockChartCard(
            title: 'Andamento Spese',
            height: 200,
            child: _buildBarChartMock(),
          ),
          const SizedBox(height: 24),
          const Text(
            'Distribuzione Categorie',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildMockChartCard(
            title: 'Ripartizione per Categoria',
            height: 240,
            child: _buildPieChartMock(),
          ),
        ],
      ),
    );
  }

  Widget _buildMockChartCard({required String title, required double height, required Widget child}) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 16),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildBarChartMock() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildBar(0.4),
        _buildBar(0.7),
        _buildBar(0.3),
        _buildBar(0.9),
        _buildBar(0.5),
        _buildBar(0.8),
      ],
    );
  }

  Widget _buildBar(double heightFactor) {
    return FractionallySizedBox(
      heightFactor: heightFactor,
      child: Container(
        width: 24,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF10B981), Color(0xFF047857)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }

  Widget _buildPieChartMock() {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 140,
            height: 140,
            child: CircularProgressIndicator(
              value: 0.7,
              strokeWidth: 20,
              backgroundColor: const Color(0xFF2A2A2D),
              color: const Color(0xFF10B981),
            ),
          ),
          const Text('70%\nCasa', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
