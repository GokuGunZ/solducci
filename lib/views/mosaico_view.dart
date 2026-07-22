import 'package:solducci/widgets/solducci_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:solducci/theme/app_theme.dart';

class MosaicoView extends StatelessWidget {
  const MosaicoView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: SolducciAppBar(
        title: const Text('Mosaico (Design System)'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Core Components',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Glassmorphism Cards (Neon Border)'),
          const SizedBox(height: 16),
          const GlassCard(
            neonColor: AppTheme.primary,
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Primary Neon Card',
                style: TextStyle(color: AppTheme.textPrimary),
              ),
            ),
          ).animate().fadeIn().slideY(begin: 0.1, curve: Curves.easeOutQuart),
          const SizedBox(height: 16),
          const GlassCard(
            neonColor: AppTheme.success,
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Success Neon Card',
                style: TextStyle(color: AppTheme.textPrimary),
              ),
            ),
          ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, curve: Curves.easeOutQuart),
          const SizedBox(height: 16),
          const GlassCard(
            neonColor: AppTheme.warning,
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Warning Neon Card',
                style: TextStyle(color: AppTheme.textPrimary),
              ),
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, curve: Curves.easeOutQuart),
          
          const SizedBox(height: 32),
          _buildSectionTitle('Typography'),
          const SizedBox(height: 16),
          const Text('Display Large', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          const Text('Title Large', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          const Text('Body Large', style: TextStyle(fontSize: 16, color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          const Text('Body Medium (Secondary)', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppTheme.textSecondary,
        letterSpacing: 1.2,
      ),
    );
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final Color neonColor;
  final double blurRadius;

  const GlassCard({
    super.key,
    required this.child,
    required this.neonColor,
    this.blurRadius = 10.0,
  });

  @override
  Widget build(BuildContext context) {
    // Glassmorphism implementation with sharp neon border
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E).withOpacity(0.6), // Semi-transparent dark surface
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: neonColor,
          width: 1.5, // Sharp clear border
        ),
      ),
      child: child,
    );
  }
}
