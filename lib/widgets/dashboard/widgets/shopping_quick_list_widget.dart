import 'dart:async';
import 'package:flutter/material.dart';
import 'package:solducci/models/dashboard_config.dart';
import 'package:solducci/models/space_items.dart';
import 'package:solducci/widgets/dashboard/bento_widget_container.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:solducci/widgets/dashboard/data_source_switcher_header.dart';

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
        .map((data) => data.map((map) => ShoppingListItem.fromMap(map)).toList());
        
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
    return BentoWidgetContainer(
      isLoading: false,
      onExpand: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Apertura Pagina Lista Spesa...')),
        );
      },
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF3B82F6).withValues(alpha: 0.1),
                    const Color(0xFF3B82F6).withValues(alpha: 0.02),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DataSourceSwitcherHeader(
                  title: _sources[_currentSourceIndex],
                  color: const Color(0xFF3B82F6),
                  icon: Icons.shopping_cart_outlined,
                  onPrevious: () {
                    setState(() {
                      _currentSourceIndex = (_currentSourceIndex - 1) < 0 ? _sources.length - 1 : _currentSourceIndex - 1;
                    });
                  },
                  onNext: () {
                    setState(() {
                      _currentSourceIndex = (_currentSourceIndex + 1) % _sources.length;
                    });
                  },
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: StreamBuilder<List<ShoppingListItem>>(
                    stream: _shoppingStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
                        );
                      }

                      final items = snapshot.data ?? [];

                      if (items.isEmpty) {
                        return Center(
                          child: Text(
                            'Lista vuota 🎉',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }

                      return ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        itemCount: items.length,
                        separatorBuilder: (context, index) => const Divider(color: Colors.white10, height: 1),
                        itemBuilder: (context, index) {
                          final item = items[index];
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
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
