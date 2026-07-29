import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:solducci/models/dashboard_config.dart';
import 'package:solducci/models/space_items.dart';
import 'package:solducci/widgets/dashboard/bento_widget_container.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:solducci/widgets/dashboard/data_source_switcher_header.dart';

import 'package:solducci/widgets/dashboard/base_list_widget.dart';

class ShoppingQuickListWidget extends StatefulWidget {
  final BentoWidgetDef def;

  const ShoppingQuickListWidget({super.key, required this.def});

  @override
  State<ShoppingQuickListWidget> createState() => _ShoppingQuickListWidgetState();
}

class _ShoppingQuickListWidgetState extends State<ShoppingQuickListWidget> {
  late Stream<List<ShoppingListItem>> _shoppingStream;
  final List<String> _sources = ['Da Comprare', 'Spesa Settimanale', 'Amazon', 'Ikea'];
  int _currentSourceIndex = 0;

  @override
  void initState() {
    super.initState();
    _shoppingStream = Supabase.instance.client
        .from('shopping_list_items')
        .stream(primaryKey: ['id'])
        .eq('is_bought', false)
        .order('created_at', ascending: false)
        .limit(10)
        .map((data) => data.map((map) => ShoppingListItem.fromMap(map)).toList())
        .asBroadcastStream();
        
    if (widget.def.customProps != null && widget.def.customProps!['source'] != null) {
      final initialSource = widget.def.customProps!['source'] as String;
      if (!_sources.contains(initialSource)) {
        _sources.insert(1, initialSource);
      }
      _currentSourceIndex = _sources.indexOf(initialSource);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ShoppingListItem>>(
      stream: _shoppingStream,
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];
        final isLoading = snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData;

        return BaseListWidget<ShoppingListItem>(
          heroTag: widget.def.id,
          isLoading: isLoading,
          onExpand: () {
            GoRouter.of(context).push('/space/shopping', extra: {'heroTag': widget.def.id});
          },
          currentSource: _sources[_currentSourceIndex],
          color: const Color(0xFF3B82F6),
          icon: Icons.shopping_cart_outlined,
          onPreviousSource: () {
            setState(() {
              _currentSourceIndex = (_currentSourceIndex - 1) < 0 ? _sources.length - 1 : _currentSourceIndex - 1;
            });
          },
          onNextSource: () {
            setState(() {
              _currentSourceIndex = (_currentSourceIndex + 1) % _sources.length;
            });
          },
          items: items,
          emptyMessage: 'Lista vuota 🎉',
          itemBuilder: (context, item, index) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white54, width: 1.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (item.quantity > 1 || item.unit != null)
                    Text(
                      '${item.quantity.toStringAsFixed(item.quantity.truncateToDouble() == item.quantity ? 0 : 1)}${item.unit ?? ''}',
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
