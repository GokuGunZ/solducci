import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:solducci/models/dashboard_config.dart';
import 'package:solducci/models/dashboard_data.dart';
import 'package:solducci/models/expense_form.dart';
import 'package:solducci/service/expense_service_cached.dart';
import 'package:solducci/utils/category_helpers.dart';
import 'package:solducci/views/category_expenses_page.dart';
import 'package:solducci/widgets/dashboard/bento_empty_state.dart';
import 'package:solducci/widgets/dashboard/bento_skeleton.dart';
import 'package:solducci/widgets/dashboard/bento_widget_container.dart';

/// Bento Widget "Spese per Categoria": visualizza la ripartizione per categoria con layout adattivi
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
  double _totalMonthExpense = 0.0;
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
          _totalMonthExpense = 0.0;
          _isLoading = false;
        });
      }
      return;
    }

    final total = monthExpenses.fold(0.0, (sum, e) => sum + e.amount);
    final breakdown = DashboardService.categoryBreakdown(monthExpenses);
    // Ordina per spesa decrescente
    breakdown.sort((a, b) => b.total.compareTo(a.total));

    if (mounted) {
      setState(() {
        _categories = breakdown;
        _totalMonthExpense = total;
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
    final size = widget.def.size;
    final is1x1 = size.crossAxisCellCount == 1 && size.mainAxisCellCount == 1;
    final is2x1 = size.crossAxisCellCount >= 2 && size.mainAxisCellCount <= 1;
    final isWide = size.crossAxisCellCount >= 3;
    final isHeight3 = size.mainAxisCellCount == 3;
    final isHeight4 = size.mainAxisCellCount >= 4;

    return BentoWidgetContainer(
      heroTag: widget.def.id,
      size: size,
      skeletonType: BentoSkeletonType.list,
      isLoading: _isLoading && _categories.isEmpty,
      onTap: () {
        if (_categories.isNotEmpty) {
          _openCategoryDetail(_categories.first.category);
        }
      },
      onRetry: _calculateCategories,
      child: _categories.isEmpty && !_isLoading
          ? BentoEmptyState(
              icon: Icons.pie_chart_outline_rounded,
              title: 'Nessuna spesa',
              subtitle: 'Nessuna spesa registrata questo mese',
              color: const Color(0xFF10B981),
              isCompact: is1x1 || is2x1,
            )
          : _buildContent(
              is1x1: is1x1,
              is2x1: is2x1,
              isWide: isWide,
              isHeight3: isHeight3,
              isHeight4: isHeight4,
            ),
    );
  }

  Widget _buildContent({
    required bool is1x1,
    required bool is2x1,
    required bool isWide,
    required bool isHeight3,
    required bool isHeight4,
  }) {
    final currencyFormatter = NumberFormat.currency(locale: 'it_IT', symbol: '€');

    // 1x1: Icona touch con top category
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

    // 2x1: Mini Banner compatto
    if (is2x1) {
      final top = _categories.first;
      final color = CategoryHelpers.getCategoryColor(top.category);
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.category_rounded, size: 13, color: Color(0xFF10B981)),
                ),
                const SizedBox(width: 8),
                const Text(
                  'TOP SPESA',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CategoryHelpers.getCategoryIcon(top.category), size: 11, color: color),
                  const SizedBox(width: 4),
                  Text(
                    '${top.category.label}: €${top.total.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // 4x2: Panoramico a Due Colonne
    if (isWide) {
      final top4 = _categories.take(4).toList();
      return Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Left column: Total & count
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.category_rounded, size: 12, color: Color(0xFF10B981)),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'SPESE TOTALI',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    currencyFormatter.format(_totalMonthExpense),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_categories.length} ${_categories.length == 1 ? "categoria" : "categorie"}',
                    style: const TextStyle(color: Colors.white38, fontSize: 10),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Right column: Top 4 grid
            Expanded(
              flex: 6,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      if (top4.isNotEmpty) Expanded(child: _buildMiniCatTile(top4[0])),
                      if (top4.length > 1) ...[
                        const SizedBox(width: 6),
                        Expanded(child: _buildMiniCatTile(top4[1])),
                      ],
                    ],
                  ),
                  if (top4.length > 2) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(child: _buildMiniCatTile(top4[2])),
                        if (top4.length > 3) ...[
                          const SizedBox(width: 6),
                          Expanded(child: _buildMiniCatTile(top4[3])),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    // 2x3: Due Livelli a Confronto (Altezza 3, ~194px)
    if (isHeight3) {
      final top3 = _categories.take(3).toList();
      return Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.category_rounded, size: 12, color: Color(0xFF10B981)),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'CATEGORIE',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                Text(
                  currencyFormatter.format(_totalMonthExpense),
                  style: const TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Livello 1: Barra segmentata multi-colore continua
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 6,
                child: Row(
                  children: _categories.take(6).map((c) {
                    final color = CategoryHelpers.getCategoryColor(c.category);
                    final weight = (c.percentage * 10).round().clamp(1, 1000);
                    return Expanded(
                      flex: weight,
                      child: Container(
                        color: color,
                        margin: const EdgeInsets.symmetric(horizontal: 0.5),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Livello 2: Top 3 Categorie a confronto
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: top3.map((cat) {
                  final color = CategoryHelpers.getCategoryColor(cat.category);
                  final icon = CategoryHelpers.getCategoryIcon(cat.category);
                  return InkWell(
                    onTap: () => _openCategoryDetail(cat.category),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1E),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white.withOpacity(0.04)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.18),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, color: color, size: 12),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      cat.category.label,
                                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '€${cat.total.toStringAsFixed(0)}',
                                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(2),
                                  child: LinearProgressIndicator(
                                    value: (cat.percentage / 100).clamp(0.0, 1.0),
                                    backgroundColor: Colors.white.withOpacity(0.06),
                                    color: color,
                                    minHeight: 3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      );
    }

    // 2x2: Compatto stabile (Altezza 2, ~124px - 2 card fisse, zero overflow)
    if (!isHeight4) {
      final top2 = _categories.take(2).toList();
      return Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.category_rounded, size: 13, color: Color(0xFF10B981)),
                    SizedBox(width: 6),
                    Text(
                      'TOP CATEGORIE',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 9.5,
                        letterSpacing: 1.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    '${_categories.length}',
                    style: const TextStyle(color: Color(0xFF10B981), fontSize: 9.5, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            ...top2.map((cat) {
              final color = CategoryHelpers.getCategoryColor(cat.category);
              final icon = CategoryHelpers.getCategoryIcon(cat.category);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF18181D),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.18),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: color, size: 12),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        cat.category.label,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '€${cat.total.toStringAsFixed(0)}',
                      style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      );
    }

    // 2x4 (o superiore): Full ListView scrollabile
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

  Widget _buildMiniCatTile(CategoryBreakdown cat) {
    final color = CategoryHelpers.getCategoryColor(cat.category);
    final icon = CategoryHelpers.getCategoryIcon(cat.category);

    return InkWell(
      onTap: () => _openCategoryDetail(cat.category),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF18181D),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: color.withOpacity(0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 10),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                cat.category.label,
                style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '€${cat.total.toStringAsFixed(0)}',
              style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
