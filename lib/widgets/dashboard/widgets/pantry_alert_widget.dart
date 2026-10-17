import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:solducci/models/dashboard_config.dart';
import 'package:solducci/models/space_items.dart';
import 'package:solducci/service/document_service.dart';
import 'package:solducci/features/space/services/space_service.dart';
import 'package:solducci/widgets/dashboard/bento_empty_state.dart';
import 'package:solducci/widgets/dashboard/bento_widget_container.dart';
import 'package:solducci/widgets/dashboard/context/dashboard_context_scope.dart';

class PantryAlertWidget extends StatefulWidget {
  final BentoWidgetDef def;

  const PantryAlertWidget({super.key, required this.def});

  @override
  State<PantryAlertWidget> createState() => _PantryAlertWidgetState();
}

class _PantryAlertWidgetState extends State<PantryAlertWidget> {
  final _documentService = DocumentService();
  final _spaceService = SpaceService();

  bool _isLoading = true;
  String? _documentId;
  String _documentTitle = 'Dispensa';
  List<PantryItem> _lowStockItems = [];
  int _totalItemsCount = 0;
  StreamSubscription? _pantrySub;
  ExpenseContext? _lastContext;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentContext = DashboardContextScope.of(context);
    if (_lastContext != currentContext) {
      _lastContext = currentContext;
      _initPantry(currentContext);
    }
  }

  @override
  void dispose() {
    _pantrySub?.cancel();
    super.dispose();
  }

  Future<void> _initPantry(ExpenseContext ctx) async {
    await _pantrySub?.cancel();
    _pantrySub = null;

    final customDocId = widget.def.customProps?['documentId'] as String?;

    try {
      if (customDocId != null && customDocId.isNotEmpty) {
        final doc = await _documentService.getDocumentById(customDocId);
        final belongsToContext = doc != null && (
          (ctx.isPersonal && doc.groupId == null) ||
          (ctx.isGroup && doc.groupId == ctx.groupId) ||
          (ctx.isView && (ctx.groupIds.contains(doc.groupId) || (ctx.includesPersonal && doc.groupId == null)))
        );
        if (belongsToContext) {
          _documentId = customDocId;
          _documentTitle = doc.title;
        } else {
          _documentId = null;
        }
      } else {
        // Fetch the first pantry document for current context
        final docs = await _documentService.getDocumentsForContext(ctx, 'dispensa');
        if (docs.isNotEmpty) {
          _documentId = docs.first.id;
          _documentTitle = docs.first.title;
        } else {
          _documentId = null;
        }
      }

      if (_documentId != null) {
        _pantrySub = _spaceService.watchPantryItems(_documentId!).listen((items) async {
          final lowItems = <PantryItem>[];
          for (final item in items) {
            final quantities = await _spaceService.getPantryQuantities(item.id);
            final total = quantities.fold<double>(0.0, (sum, q) => sum + q.totalQuantity);
            if (item.thresholdLow != null && total <= item.thresholdLow!) {
              lowItems.add(item);
            }
          }

          if (mounted) {
            setState(() {
              _totalItemsCount = items.length;
              _lowStockItems = lowItems;
              _isLoading = false;
            });
          }
        });
      } else {
        if (mounted) {
          setState(() {
            _lowStockItems = [];
            _totalItemsCount = 0;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasLowStock = _lowStockItems.isNotEmpty;
    final alertColor = hasLowStock ? const Color(0xFFEF4444) : const Color(0xFF10B981);
    final is1x1 = widget.def.size.crossAxisCellCount <= 1 && widget.def.size.mainAxisCellCount <= 1;
    final is2x1 = widget.def.size.crossAxisCellCount >= 2 && widget.def.size.mainAxisCellCount <= 1;
    final isExpanded = widget.def.size.mainAxisCellCount >= 2;

    void navigateToPantry() {
      if (_documentId != null) {
        GoRouter.of(context).push('/space/pantry/$_documentId');
      } else {
        GoRouter.of(context).push('/space/pantry');
      }
    }

    return BentoWidgetContainer(
      heroTag: widget.def.id,
      size: widget.def.size,
      isLoading: _isLoading,
      onTap: navigateToPantry,
      onExpand: navigateToPantry,
      child: _documentId == null && !_isLoading
          ? BentoEmptyState(
              icon: Icons.kitchen_rounded,
              title: 'Nessuna dispensa',
              subtitle: 'Crea una dispensa per tracciare le scorte',
              color: const Color(0xFF10B981),
              actionLabel: 'Crea Dispensa',
              onAction: () => GoRouter.of(context).push('/space/pantry'),
              isCompact: is1x1 || is2x1,
            )
          : is2x1
              ? Padding(
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
                              color: alertColor.withOpacity(0.18),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              hasLowStock ? Icons.warning_amber_rounded : Icons.kitchen_rounded,
                              color: alertColor,
                              size: 13,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 90),
                            child: Text(
                              _documentTitle.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: alertColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: alertColor.withOpacity(0.3)),
                        ),
                        child: Text(
                          hasLowStock ? '${_lowStockItems.length} da comprare' : 'Scorte OK',
                          style: TextStyle(
                            color: alertColor,
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : widget.def.size.mainAxisCellCount >= 3
                  ? _buildH3View(hasLowStock: hasLowStock, alertColor: alertColor)
                  : Stack(
                  alignment: Alignment.center,
                  children: [
                // Ambient Glow behind count if low stock
                if (hasLowStock)
                  Center(
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: alertColor.withOpacity(0.35),
                            blurRadius: 25,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),

                Positioned(
                  top: 12,
                  left: 12,
                  child: Icon(
                    hasLowStock ? Icons.warning_amber_rounded : Icons.kitchen_rounded,
                    color: alertColor,
                    size: 16,
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        hasLowStock ? '${_lowStockItems.length}' : '$_totalItemsCount',
                        style: TextStyle(
                          color: alertColor,
                          fontSize: isExpanded ? 34 : 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasLowStock ? 'IN ESAURIMENTO' : 'DISPENSA OK',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: alertColor.withOpacity(0.9),
                          fontSize: 8.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _documentTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (isExpanded && hasLowStock) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          alignment: WrapAlignment.center,
                          children: _lowStockItems.take(2).map((item) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444).withOpacity(0.14),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
                              ),
                              child: Text(
                                item.name,
                                style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 9.5),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildH3View({required bool hasLowStock, required Color alertColor}) {
    return Padding(
      padding: const EdgeInsets.all(14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Level 1: Status banner & count
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: alertColor.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  hasLowStock ? Icons.warning_amber_rounded : Icons.kitchen_rounded,
                  color: alertColor,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _documentTitle.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      hasLowStock ? '${_lowStockItems.length} in esaurimento' : 'Tutte le scorte ok',
                      style: TextStyle(
                        color: alertColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: alertColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: alertColor.withOpacity(0.3)),
                ),
                child: Text(
                  hasLowStock ? '${_lowStockItems.length}' : '$_totalItemsCount',
                  style: TextStyle(
                    color: alertColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Level 2: Critical items list
          Expanded(
            child: hasLowStock
                ? ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: _lowStockItems.length.clamp(0, 3),
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final item = _lowStockItems[index];
                      final thresholdStr = item.thresholdLow != null
                          ? '≤ ${item.thresholdLow! % 1 == 0 ? item.thresholdLow!.toInt() : item.thresholdLow!.toStringAsFixed(1)} ${item.unit}'
                          : null;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.remove_shopping_cart_outlined,
                              size: 13,
                              color: Color(0xFFFCA5A5),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (thresholdStr != null)
                              Text(
                                thresholdStr,
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline_rounded,
                          size: 24,
                          color: Colors.white.withOpacity(0.25),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Scorte sufficienti',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          if (hasLowStock && _lowStockItems.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Center(
                child: Text(
                  '+${_lowStockItems.length - 3} altri articoli in esaurimento',
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
