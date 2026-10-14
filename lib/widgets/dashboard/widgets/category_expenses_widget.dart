import 'dart:async';
import 'package:flutter/material.dart';
import 'package:solducci/models/dashboard_config.dart';
import 'package:solducci/models/dashboard_data.dart';
import 'package:solducci/models/expense_form.dart';
import 'package:solducci/service/expense_service_cached.dart';
import 'package:solducci/utils/category_helpers.dart';
import 'package:solducci/views/category_expenses_page.dart';
import 'package:solducci/widgets/dashboard/bento_empty_state.dart';
import 'package:solducci/widgets/dashboard/bento_skeleton.dart';
import 'package:solducci/widgets/dashboard/bento_widget_container.dart';

/// Bento Widget "Spese per Categoria": visualizza la ripartizione per categoria con navigazione al tocco
class CategoryExpensesWidget extends StatefulWidget {
  final BentoWidgetDef def;

  const CategoryExpensesWidget({super.key, required this.def});

  @override
  State<CategoryExpensesWidget> createState() => _CategoryExpensesWidgetState();
}

class _CategoryExpensesWidgetState extends State<CategoryExpensesWidget> {
  final _expenseService = ExpenseServiceCached();
  bool _isLoading = true;
  List<CategoryBreakdown> _categories = [];
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _sub = _expenseService.stream.listen((_) => _calculateCategories());
    _calculateCategories();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _calculateCategories() {
    final expenses = _expenseService.getAllCachedExpenses();
    final now = DateTime.now();

    // Filtra per il mese corrente
    final monthExpenses = expenses
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .toList();

    if (monthExpenses.isEmpty) {
      if (mounted) {
        setState(() {
          _categories = [];
          _isLoading = false;
        });
      }
      return;
    }

    final breakdown = DashboardService.categoryBreakdown(monthExpenses);
    // Ordina per spesa decrescente
    breakdown.sort((a, b) => b.total.compareTo(a.total));

    if (mounted) {
      setState(() {
        _categories = breakdown;
        _isLoading = false;
      });
    }
  }

  void _openCategoryDetail(Tipologia category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => CategoryExpensesPage(category: category),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final is1x1 = widget.def.size.crossAxisCellCount == 1 && widget.def.size.mainAxisCellCount == 1;

    return BentoWidgetContainer(
      heroTag: widget.def.id,
      size: widget.def.size,
      skeletonType: BentoSkeletonType.list,
      isLoading: _isLoading && _categories.isEmpty,
      onRetry: _calculateCategories,
      child: _categories.isEmpty && !_isLoading
          ? BentoEmptyState(
              icon: Icons.pie_chart_outline_rounded,
              title: 'Nessuna spesa',
              subtitle: 'Nessuna spesa registrata questo mese',
              color: const Color(0xFF10B981),
              isCompact: is1x1,
            )
          : _buildContent(is1x1),
    );
  }

  Widget _buildContent(bool is1x1) {
    if (is1x1) {
      final top = _categories.first;
      final color = CategoryHelpers.getCategoryColor(top.category);
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: color.withOpacity(0.2),
                child: Icon(CategoryHelpers.getCategoryIcon(top.category), size: 13, color: color),
              ),
              const SizedBox(height: 4),
              Text(
                '€${top.total.toStringAsFixed(0)}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              ),
              Text(
                top.category.label,
                style: const TextStyle(color: Colors.white54, fontSize: 10),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.category_rounded, size: 14, color: Color(0xFF10B981)),
                  SizedBox(width: 6),
                  Text(
                    'SPESE PER CATEGORIA',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${_categories.length}',
                  style: const TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),

        // Categories List
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            itemCount: _categories.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final cat = _categories[index];
              final color = CategoryHelpers.getCategoryColor(cat.category);
              final icon = CategoryHelpers.getCategoryIcon(cat.category);

              return InkWell(
                onTap: () => _openCategoryDetail(cat.category),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF18181D),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withOpacity(0.06)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.18),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: color, size: 14),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cat.category.label,
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${cat.count} ${cat.count == 1 ? "spesa" : "spese"} • ${cat.percentage.toStringAsFixed(1)}%',
                              style: TextStyle(color: Colors.white.withOpacity(0.38), fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '€${cat.total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.chevron_right_rounded, color: Colors.white24, size: 16),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
