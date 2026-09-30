import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:solducci/models/dashboard_config.dart';
import 'package:solducci/models/document.dart';
import 'package:solducci/models/space_items.dart';
import 'package:solducci/service/context_manager.dart';
import 'package:solducci/service/document_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:solducci/widgets/dashboard/base_list_widget.dart';

import 'package:solducci/features/space/services/space_service.dart';

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

  final TextEditingController _addController = TextEditingController();
  final FocusNode _addFocusNode = FocusNode();
  List<PantryItem> _pantryProducts = [];
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
    _loadPantryProducts();
  }

  @override
  void dispose() {
    _addController.dispose();
    _addFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadPantryProducts() async {
    try {
      final pantryDocs = await DocumentService().getDocumentsForContext(
        ContextManager().currentContext,
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
      _loadDocuments();
    }
  }

  Future<void> _loadDocuments() async {
    try {
      final docs = await DocumentService().getDocumentsForContext(
        ContextManager().currentContext,
        'shopping_list',
      );

      _documents = docs;
      final requestedDocId = widget.def.customProps?['documentId'] as String?;

      if (requestedDocId != null) {
        final matchIdx = _documents.indexWhere((d) => d.id == requestedDocId);
        if (matchIdx != -1) {
          _currentSourceIndex = matchIdx;
        }
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
          .limit(20)
          .map((data) => data
              .map((map) => ShoppingListItem.fromMap(map))
              .where((item) => !item.isBought)
              .toList())
          .asBroadcastStream();
    } else {
      _shoppingStream = Supabase.instance.client
          .from('shopping_list_items')
          .stream(primaryKey: ['id'])
          .eq('is_bought', false)
          .order('created_at', ascending: false)
          .limit(20)
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
        final items = snapshot.data ?? [];
        final isLoading = snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData;

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
              GoRouter.of(context).push('/space');
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
          items: items,
          emptyMessage: 'Nessun prodotto da comprare 🎉',
          quickActionRow: Container(
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white12, width: 0.8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: Colors.white38, size: 15),
                const SizedBox(width: 6),
                Expanded(
                  child: TextField(
                    controller: _addController,
                    focusNode: _addFocusNode,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    decoration: const InputDecoration(
                      hintText: 'Cerca prodotto o aggiungi...',
                      hintStyle: TextStyle(color: Colors.white38, fontSize: 11),
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
                    width: 14,
                    height: 14,
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
                      child: const Icon(Icons.add, color: Colors.white, size: 12),
                    ),
                  ),
              ],
            ),
          ),
          itemBuilder: (context, item, index) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () async {
                      try {
                        await Supabase.instance.client
                            .from('shopping_list_items')
                            .update({'is_bought': true})
                            .eq('id', item.id);
                      } catch (e) {
                        debugPrint('Error completing item: $e');
                      }
                    },
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white54, width: 1.5),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontFamily: 'Inter',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (item.quantity > 1 || item.unit != null)
                    Text(
                      '${item.quantity.toStringAsFixed(item.quantity.truncateToDouble() == item.quantity ? 0 : 1)} ${item.unit ?? ''}',
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
