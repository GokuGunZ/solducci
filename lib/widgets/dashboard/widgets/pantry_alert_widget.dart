import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:solducci/models/dashboard_config.dart';
import 'package:solducci/models/space_items.dart';
import 'package:solducci/service/context_manager.dart';
import 'package:solducci/service/document_service.dart';
import 'package:solducci/features/space/services/space_service.dart';
import 'package:solducci/widgets/dashboard/bento_empty_state.dart';
import 'package:solducci/widgets/dashboard/bento_widget_container.dart';

class PantryAlertWidget extends StatefulWidget {
  final BentoWidgetDef def;

  const PantryAlertWidget({super.key, required this.def});

  @override
  State<PantryAlertWidget> createState() => _PantryAlertWidgetState();
}

class _PantryAlertWidgetState extends State<PantryAlertWidget> {
  final _documentService = DocumentService();
  final _spaceService = SpaceService();
  final _contextManager = ContextManager();

  bool _isLoading = true;
  String? _documentId;
  String _documentTitle = 'Dispensa';
  List<PantryItem> _lowStockItems = [];
  int _totalItemsCount = 0;
  StreamSubscription? _pantrySub;

  @override
  void initState() {
    super.initState();
    _initPantry();
  }

  @override
  void dispose() {
    _pantrySub?.cancel();
    super.dispose();
  }

  Future<void> _initPantry() async {
    final customDocId = widget.def.customProps?['documentId'] as String?;
    final context = _contextManager.currentContext;

    try {
      if (customDocId != null && customDocId.isNotEmpty) {
        _documentId = customDocId;
        final doc = await _documentService.getDocumentById(customDocId);
        if (doc != null) {
          _documentTitle = doc.title;
        }
      } else {
        // Fetch the first pantry document for current context
        final docs = await _documentService.getDocumentsForContext(context, 'dispensa');
        if (docs.isNotEmpty) {
          _documentId = docs.first.id;
          _documentTitle = docs.first.title;
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
    final isExpanded = widget.def.size.mainAxisCellCount >= 2;

    return BentoWidgetContainer(
      heroTag: widget.def.id,
      size: widget.def.size,
      isLoading: _isLoading,
      onExpand: () {
        if (_documentId != null) {
          GoRouter.of(context).push('/space/pantry/$_documentId');
        } else {
          GoRouter.of(context).push('/space/pantry');
        }
      },
      child: _documentId == null && !_isLoading
          ? BentoEmptyState(
              icon: Icons.kitchen_rounded,
              title: 'Nessuna dispensa',
              subtitle: 'Crea una dispensa per tracciare le scorte',
              color: const Color(0xFF10B981),
              actionLabel: 'Crea Dispensa',
              onAction: () => GoRouter.of(context).push('/space/pantry'),
            )
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
}
