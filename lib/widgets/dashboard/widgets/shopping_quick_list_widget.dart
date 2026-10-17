import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:solducci/models/dashboard_config.dart';
import 'package:solducci/models/document.dart';
import 'package:solducci/models/space_items.dart';
import 'package:solducci/service/auth_service.dart';
import 'package:solducci/service/document_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:solducci/widgets/dashboard/base_list_widget.dart';

import 'package:solducci/features/space/services/space_service.dart';
import 'package:solducci/widgets/dashboard/context/dashboard_context_scope.dart';

class ShoppingQuickListWidget extends StatefulWidget {
  final BentoWidgetDef def;

  const ShoppingQuickListWidget({super.key, required this.def});

  @override
  State<ShoppingQuickListWidget> createState() => _ShoppingQuickListWidgetState();
}

class _ShoppingQuickListWidgetState extends State<ShoppingQuickListWidget> {
  Stream<List<ShoppingListItem>>? _shoppingStream;
  List<Document> _documents = [];
  int _currentSourceIndex = 0;
  bool _isLoadingDocs = true;
  ExpenseContext? _lastContext;

  final Set<String> _optimisticBoughtIds = {};
  final Set<String> _optimisticUnboughtIds = {};

  final TextEditingController _addController = TextEditingController();
  final FocusNode _addFocusNode = FocusNode();
  List<PantryItem> _pantryProducts = [];
  bool _isAdding = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentContext = DashboardContextScope.of(context);
    if (_lastContext != currentContext) {
      _lastContext = currentContext;
      _loadDocuments(currentContext);
      _loadPantryProducts(currentContext);
    }
  }

  @override
  void dispose() {
    _addController.dispose();
    _addFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadPantryProducts([ExpenseContext? contextOverride]) async {
    try {
      final ctx = contextOverride ?? _lastContext ?? DashboardContextScope.of(context);
      final pantryDocs = await DocumentService().getDocumentsForContext(
        ctx,
        'dispensa',
      );
      if (pantryDocs.isNotEmpty) {
        final items = await SpaceService().watchPantryItems(pantryDocs.first.id).first;
        if (mounted) {
          setState(() {
            _pantryProducts = items;
          });
        }
      }
    } catch (_) {}
  }

  @override
  void didUpdateWidget(ShoppingQuickListWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.def.customProps != widget.def.customProps) {
      _loadDocuments(_lastContext);
    }
  }

  Future<void> _loadDocuments([ExpenseContext? contextOverride]) async {
    try {
      final ctx = contextOverride ?? _lastContext ?? DashboardContextScope.of(context);
      final contextDocs = await DocumentService().getDocumentsForContext(
        ctx,
        'shopping_list',
      );
      List<Document> userDocs = [];
      try {
        userDocs = await DocumentService().getDocumentsByType('shopping_list').first.timeout(
          const Duration(milliseconds: 1500),
          onTimeout: () => [],
        );
      } catch (_) {}

      final Map<String, Document> uniqueDocs = {};
      for (final d in contextDocs) {
        uniqueDocs[d.id] = d;
      }
      for (final d in userDocs) {
        uniqueDocs[d.id] = d;
      }
      final allDocs = uniqueDocs.values.toList();

      final customProps = widget.def.customProps;
      final rawSelected = customProps?['selectedSourceIds'] as List?;
      final selectedIds = rawSelected?.map((e) => e.toString()).toSet();

      List<Document> filtered;
      if (selectedIds != null && selectedIds.isNotEmpty) {
        filtered = allDocs.where((d) => selectedIds.contains('doc_${d.id}') || selectedIds.contains(d.id)).toList();
        if (filtered.isEmpty) filtered = allDocs;
      } else {
        filtered = allDocs;
      }

      _documents = filtered;
      if (_currentSourceIndex >= _documents.length) {
        _currentSourceIndex = 0;
      }

      _updateStream();
    } catch (e) {
      debugPrint('Error loading shopping documents: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingDocs = false;
        });
      }
    }
  }

  Future<void> _quickAddItem(String text) async {
    final name = text.trim();
    if (name.isEmpty || _isAdding) return;

    final activeDocId = _documents.isNotEmpty && _currentSourceIndex < _documents.length
        ? _documents[_currentSourceIndex].id
        : null;

    if (activeDocId == null) return;

    setState(() => _isAdding = true);

    try {
      // Check if product exists in pantry
      final match = _pantryProducts
          .where((p) => p.name.toLowerCase() == name.toLowerCase())
          .firstOrNull;

      await SpaceService().createShoppingListItem(ShoppingListItem(
        id: '',
        documentId: activeDocId,
        pantryItemId: match?.id,
        name: match?.name ?? name,
        quantity: 1.0,
        unit: match?.unit,
        isBought: false,
        position: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      _addController.clear();
      _addFocusNode.unfocus();
    } catch (e) {
      debugPrint('Error quick adding shopping item: $e');
    } finally {
      if (mounted) {
        setState(() => _isAdding = false);
      }
    }
  }

  void _updateStream() {
    final activeDocId = _documents.isNotEmpty && _currentSourceIndex < _documents.length
        ? _documents[_currentSourceIndex].id
        : null;

    if (activeDocId != null) {
      _shoppingStream = Supabase.instance.client
          .from('shopping_list_items')
          .stream(primaryKey: ['id'])
          .eq('document_id', activeDocId)
          .order('created_at', ascending: false)
          .limit(30)
          .map((data) => data.map((map) => ShoppingListItem.fromMap(map)).toList())
          .asBroadcastStream();
    } else {
      _shoppingStream = Supabase.instance.client
          .from('shopping_list_items')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false)
          .limit(30)
          .map((data) => data.map((map) => ShoppingListItem.fromMap(map)).toList())
          .asBroadcastStream();
    }
  }

  String get _currentSourceName {
    if (_documents.isNotEmpty && _currentSourceIndex < _documents.length) {
      return _documents[_currentSourceIndex].title;
    }
    return widget.def.customProps?['title'] as String? ?? 'Lista Spesa';
  }

  bool _computeIsBought(ShoppingListItem item) {
    if (_optimisticBoughtIds.contains(item.id)) return true;
    if (_optimisticUnboughtIds.contains(item.id)) return false;
    return item.isBought;
  }

  Future<void> _toggleItemBought(ShoppingListItem item) async {
    HapticFeedback.selectionClick();
    final currentlyBought = _computeIsBought(item);
    final nextBought = !currentlyBought;

    setState(() {
      if (nextBought) {
        _optimisticBoughtIds.add(item.id);
        _optimisticUnboughtIds.remove(item.id);
      } else {
        _optimisticUnboughtIds.add(item.id);
        _optimisticBoughtIds.remove(item.id);
      }
    });

    try {
      await Supabase.instance.client
          .from('shopping_list_items')
          .update({'is_bought': nextBought})
          .eq('id', item.id);
    } catch (e) {
      debugPrint('Error toggling shopping item: $e');
      if (mounted) {
        setState(() {
          if (nextBought) {
            _optimisticBoughtIds.remove(item.id);
          } else {
            _optimisticUnboughtIds.remove(item.id);
          }
        });
      }
    }
  }

  Future<void> _cancelCompletedItems(List<ShoppingListItem> items) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancella elementi presi', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Text(
          'Vuoi eliminare ${items.length} ${items.length == 1 ? "elemento preso" : "elementi presi"} dalla lista?',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annulla', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancella'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final idsToDelete = items.map((e) => e.id).toSet();
      setState(() {
        _optimisticBoughtIds.removeAll(idsToDelete);
        _optimisticUnboughtIds.removeAll(idsToDelete);
      });
      for (final item in items) {
        await SpaceService().deleteShoppingListItem(item.id);
      }
    }
  }

  Future<void> _buyCompletedItems(List<ShoppingListItem> items) async {
    HapticFeedback.heavyImpact();
    final currentContext = _lastContext ?? DashboardContextScope.of(context);

    final rawPantries = await DocumentService().getDocumentsForContext(currentContext, 'dispensa');
    final pantries = rawPantries.whereType<DispensaDocument>().toList();

    final activeDoc = _documents.isNotEmpty && _currentSourceIndex < _documents.length
        ? _documents[_currentSourceIndex]
        : null;
    final pantryTitle = activeDoc?.title ?? 'Alimentari';

    var targetPantry = pantries.where((p) => p.title.trim().toLowerCase() == pantryTitle.trim().toLowerCase()).firstOrNull;
    if (targetPantry == null) {
      if (pantries.isNotEmpty) {
        targetPantry = pantries.first;
      } else {
        final effectiveUserId = activeDoc?.userId ?? (currentContext.isPersonal ? AuthService().currentUserId : null);
        final effectiveGroupId = activeDoc?.groupId ?? (currentContext.isGroup ? currentContext.groupId : null);
        final newPantryDoc = DispensaDocument(
          id: '',
          userId: effectiveUserId,
          groupId: effectiveGroupId,
          title: pantryTitle,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        targetPantry = (await DocumentService().createDocument(newPantryDoc)) as DispensaDocument;
      }
    }

    final idsToTransfer = items.map((e) => e.id).toSet();
    setState(() {
      _optimisticBoughtIds.removeAll(idsToTransfer);
      _optimisticUnboughtIds.removeAll(idsToTransfer);
    });

    await SpaceService().transferBoughtItemsToPantry(
      itemsToTransfer: items,
      targetPantryDocId: targetPantry.id,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.kitchen_outlined, color: Color(0xFF10B981), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${items.length} ${items.length == 1 ? "prodotto trasferito" : "prodotti trasferiti"} in Dispensa!',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF18181B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFF10B981)),
          ),
        ),
      );
    }
  }

  Widget _buildBentoDock(List<ShoppingListItem> bought) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF10B981).withOpacity(0.45),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final showLabel = w >= 170;
          final isUltraNarrow = w < 130;

          return Row(
            children: [
              // Left badge: check icon + count
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.18),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_rounded, color: Color(0xFF10B981), size: 12),
                    const SizedBox(width: 3),
                    Text(
                      '${bought.length}',
                      style: const TextStyle(
                        color: Color(0xFF10B981),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (showLabel) ...[
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    bought.length == 1 ? 'preso' : 'presi',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              const Spacer(),
              // Delete Action
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _cancelCompletedItems(bought),
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFFEF4444),
                    size: 14,
                  ),
                ),
              ),
              const SizedBox(width: 5),
              // Buy Action (Transfer to pantry)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _buyCompletedItems(bought),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isUltraNarrow ? 6 : 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.kitchen_outlined,
                        color: Colors.black,
                        size: 12,
                      ),
                      if (!isUltraNarrow) ...[
                        const SizedBox(width: 4),
                        const Text(
                          'Compra',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 10.5,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingDocs) {
      return BaseListWidget<ShoppingListItem>(
        heroTag: widget.def.id,
        isLoading: true,
        currentSource: _currentSourceName,
        color: const Color(0xFF3B82F6),
        icon: Icons.shopping_cart_outlined,
        onPreviousSource: () {},
        onNextSource: () {},
        items: const [],
        emptyMessage: '',
        itemBuilder: (_, __, ___) => const SizedBox.shrink(),
      );
    }

    return StreamBuilder<List<ShoppingListItem>>(
      stream: _shoppingStream,
      builder: (context, snapshot) {
        final allItems = snapshot.data ?? [];
        final isLoading = snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData;

        final unbought = allItems.where((i) => !_computeIsBought(i)).toList();
        final bought = allItems.where((i) => _computeIsBought(i)).toList();
        final sortedItems = [...unbought, ...bought];

        return BaseListWidget<ShoppingListItem>(
          heroTag: widget.def.id,
          isLoading: isLoading,
          onExpand: () {
            final activeDocId = _documents.isNotEmpty && _currentSourceIndex < _documents.length
                ? _documents[_currentSourceIndex].id
                : null;
            if (activeDocId != null) {
              GoRouter.of(context).push('/space/shopping/$activeDocId');
            } else {
              GoRouter.of(context).push('/space/shopping');
            }
          },
          currentSource: _currentSourceName,
          color: const Color(0xFF3B82F6),
          icon: Icons.shopping_cart_outlined,
          onPreviousSource: () {
            if (_documents.length > 1) {
              setState(() {
                _currentSourceIndex = (_currentSourceIndex - 1) < 0
                    ? _documents.length - 1
                    : _currentSourceIndex - 1;
                _updateStream();
              });
            }
          },
          onNextSource: () {
            if (_documents.length > 1) {
              setState(() {
                _currentSourceIndex = (_currentSourceIndex + 1) % _documents.length;
                _updateStream();
              });
            }
          },
          size: widget.def.size,
          items: sortedItems,
          emptyMessage: 'Nessun prodotto',
          emptySubtitle: 'Aggiungi ciò che ti serve comprare',
          emptyActionLabel: widget.def.size.crossAxisCellCount <= 2 ? 'Aggiungi' : 'Aggiungi Prodotto',
          onEmptyAction: () => _addFocusNode.requestFocus(),
          quickActionRow: Container(
            height: 30,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: Colors.white12, width: 0.8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: Colors.white38, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: TextField(
                    controller: _addController,
                    focusNode: _addFocusNode,
                    style: const TextStyle(color: Colors.white, fontSize: 11.5),
                    decoration: const InputDecoration(
                      hintText: 'Aggiungi o cerca...',
                      hintStyle: TextStyle(color: Colors.white38, fontSize: 10.5),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onSubmitted: _quickAddItem,
                    onChanged: (text) => setState(() {}),
                  ),
                ),
                if (_isAdding)
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFF3B82F6)),
                  )
                else if (_addController.text.trim().isNotEmpty)
                  GestureDetector(
                    onTap: () => _quickAddItem(_addController.text),
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Color(0xFF3B82F6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 11),
                    ),
                  ),
              ],
            ),
          ),
          bottomDock: (bought.isNotEmpty && (widget.def.size.mainAxisCellCount >= 3 || unbought.isEmpty))
              ? _buildBentoDock(bought)
              : null,
          itemBuilder: (context, item, index) {
            final isBought = _computeIsBought(item);
            final isFirstBought = isBought && index == unbought.length && unbought.isNotEmpty;

            final Widget itemTile = GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _toggleItemBought(item),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.5),
                child: Row(
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: isBought ? const Color(0xFF10B981) : Colors.transparent,
                        border: Border.all(
                          color: isBought ? const Color(0xFF10B981) : Colors.white54,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: isBought
                          ? const Icon(Icons.check, size: 12, color: Colors.black)
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.name,
                        style: TextStyle(
                          color: isBought ? Colors.white38 : Colors.white,
                          decoration: isBought ? TextDecoration.lineThrough : null,
                          decorationColor: Colors.white38,
                          fontSize: 12.5,
                          fontWeight: isBought ? FontWeight.normal : FontWeight.w500,
                          fontFamily: 'Inter',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (item.quantity > 1 || (item.unit != null && item.unit!.isNotEmpty))
                      Text(
                        '${item.quantity.toStringAsFixed(item.quantity.truncateToDouble() == item.quantity ? 0 : 1)} ${item.unit ?? ''}',
                        style: TextStyle(
                          color: isBought ? Colors.white24 : Colors.white54,
                          fontSize: 10.5,
                        ),
                      ),
                  ],
                ),
              ),
            );

            if (isFirstBought) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6, bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline_rounded, size: 10, color: Color(0xFF10B981)),
                        const SizedBox(width: 4),
                        Text(
                          'PRESI (${bought.length})',
                          style: const TextStyle(
                            color: Color(0xFF10B981),
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Expanded(child: Divider(color: Colors.white12, height: 1)),
                      ],
                    ),
                  ),
                  itemTile,
                ],
              );
            }

            return itemTile;
          },
        );
      },
    );
  }
}
