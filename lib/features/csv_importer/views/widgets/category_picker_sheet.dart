import 'package:flutter/material.dart';
import 'package:solducci/models/expense_form.dart';
import 'package:solducci/theme/app_theme.dart';

class CategoryPickerSheet extends StatelessWidget {
  final Tipologia currentCategory;
  final ValueChanged<Tipologia> onCategorySelected;

  const CategoryPickerSheet({
    super.key,
    required this.currentCategory,
    required this.onCategorySelected,
  });

  static IconData getIcon(Tipologia type) {
    switch (type) {
      case Tipologia.affitto:
        return Icons.home_rounded;
      case Tipologia.cibo:
        return Icons.shopping_basket_rounded;
      case Tipologia.utenze:
        return Icons.bolt_rounded;
      case Tipologia.prodottiCasa:
        return Icons.cleaning_services_rounded;
      case Tipologia.ristorante:
        return Icons.restaurant_rounded;
      case Tipologia.tempoLibero:
        return Icons.sports_esports_rounded;
      case Tipologia.altro:
        return Icons.category_rounded;
      case Tipologia.investimento:
        return Icons.trending_up_rounded;
    }
  }

  static Color getColor(Tipologia type) {
    switch (type) {
      case Tipologia.affitto:
        return const Color(0xFF3B82F6);
      case Tipologia.cibo:
        return const Color(0xFF10B981);
      case Tipologia.utenze:
        return const Color(0xFFF59E0B);
      case Tipologia.prodottiCasa:
        return const Color(0xFF14B8A6);
      case Tipologia.ristorante:
        return const Color(0xFFF97316);
      case Tipologia.tempoLibero:
        return const Color(0xFF8B5CF6);
      case Tipologia.altro:
        return const Color(0xFF6B7280);
      case Tipologia.investimento:
        return const Color(0xFF6366F1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Scegli Categoria',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Assegna una tipologia a questa spesa',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: Tipologia.values.map((type) {
                final isSelected = type == currentCategory;
                final color = getColor(type);

                return Material(
                  color: isSelected
                      ? color.withOpacity(0.25)
                      : const Color(0xFF27272A),
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      onCategorySelected(type);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? color : Colors.white10,
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            getIcon(type),
                            size: 18,
                            color: isSelected ? color : Colors.white70,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            type.label,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
