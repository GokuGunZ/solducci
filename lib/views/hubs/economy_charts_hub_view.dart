import 'package:flutter/material.dart';
import 'package:solducci/service/expense_service_cached.dart';
import 'package:solducci/models/expense.dart';
import 'package:solducci/models/dashboard_data.dart';
import 'dart:math';

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
      body: StreamBuilder<List<Expense>>(
        stream: ExpenseServiceCached().stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)));
          }

          final expenses = snapshot.data ?? [];
          if (expenses.isEmpty) {
            return const Center(
              child: Text(
                'Nessuna spesa registrata per generare i grafici.',
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
            );
          }

          final monthlyGroups = DashboardService.groupByMonth(expenses);
          final categoryData = DashboardService.categoryBreakdown(expenses);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Andamento Mensile',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildMockChartCard(
                title: 'Spese degli ultimi mesi',
                height: 240,
                child: _buildBarChartReal(monthlyGroups),
              ),
              const SizedBox(height: 24),
              const Text(
                'Distribuzione Categorie',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildMockChartCard(
                title: 'Ripartizione Totale',
                height: min(300.0, max(150.0, categoryData.length * 50.0 + 50.0)),
                child: _buildCategoryListReal(categoryData),
              ),
            ],
          );
        },
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

  Widget _buildBarChartReal(List<MonthlyGroup> monthlyGroups) {
    if (monthlyGroups.isEmpty) return const SizedBox.shrink();

    // Take up to 6 most recent months, reverse to show chronological order left-to-right
    final recentGroups = monthlyGroups.take(6).toList().reversed.toList();
    final maxTotal = recentGroups.map((g) => g.total).reduce(max);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: recentGroups.map((group) {
        final heightFactor = maxTotal > 0 ? (group.total / maxTotal) : 0.0;
        final monthAbbr = group.monthLabel.split(' ')[0].substring(0, 3);
        
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('€${group.total.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white54, fontSize: 10)),
            const SizedBox(height: 4),
            _buildBar(heightFactor),
            const SizedBox(height: 8),
            Text(monthAbbr, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildBar(double heightFactor) {
    // Ensure minimum visible height for non-zero values
    final effectiveFactor = heightFactor > 0 ? max(0.05, heightFactor) : 0.0;
    
    return Expanded(
      child: FractionallySizedBox(
        heightFactor: effectiveFactor,
        alignment: Alignment.bottomCenter,
        child: Container(
          width: 32,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF047857)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryListReal(List<CategoryBreakdown> categories) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final cat = categories[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.primaries[index % Colors.primaries.length],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  cat.category.label,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
              Text(
                '€${cat.total.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 48,
                child: Text(
                  '${cat.percentage.toStringAsFixed(1)}%',
                  textAlign: TextAlign.right,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
