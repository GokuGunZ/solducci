import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:solducci/models/dashboard_config.dart';
import 'package:solducci/models/space_items.dart';
import 'package:solducci/widgets/dashboard/bento_widget_container.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:solducci/widgets/dashboard/base_list_widget.dart';

class UnresolvedAsterisksWidget extends StatefulWidget {
  final BentoWidgetDef def;

  const UnresolvedAsterisksWidget({super.key, required this.def});

  @override
  State<UnresolvedAsterisksWidget> createState() => _UnresolvedAsterisksWidgetState();
}

class _UnresolvedAsterisksWidgetState extends State<UnresolvedAsterisksWidget> {
  late Stream<List<AsteriskItem>> _asterisksStream;
  final Set<String> _locallyResolved = {};

  @override
  void initState() {
    super.initState();
    // We fetch all recent asterisks, not just unresolved, so we can keep the crossed-out ones visible
    _asterisksStream = Supabase.instance.client
        .from('asterisk_items')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .limit(20)
        .map((data) => data.map((map) => AsteriskItem.fromMap(map)).toList())
        .asBroadcastStream();
  }

  void _toggleResolve(AsteriskItem item) async {
    final bool isCurrentlyResolved = item.isResolved || _locallyResolved.contains(item.id);
    
    setState(() {
      if (isCurrentlyResolved) {
        _locallyResolved.remove(item.id);
      } else {
        _locallyResolved.add(item.id);
      }
    });

    try {
      await Supabase.instance.client
          .from('asterisk_items')
          .update({'is_resolved': !isCurrentlyResolved})
          .eq('id', item.id);
    } catch (e) {
      // Revert on error
      setState(() {
        if (isCurrentlyResolved) {
          _locallyResolved.add(item.id);
        } else {
          _locallyResolved.remove(item.id);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AsteriskItem>>(
      stream: _asterisksStream,
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData;
        final allAsterisks = snapshot.data ?? [];
        
        // Filter to only show unresolved ones, OR ones that were just locally resolved during this session
        var displayAsterisks = allAsterisks.where((a) {
          return !a.isResolved || _locallyResolved.contains(a.id);
        }).toList();

        // Limit to 5 or so for display if needed
        if (displayAsterisks.length > 8) {
          displayAsterisks = displayAsterisks.sublist(0, 8);
        }

        return BaseListWidget<AsteriskItem>(
          heroTag: widget.def.id,
          isLoading: isLoading,
          onExpand: () {
            GoRouter.of(context).push('/space/asterisks', extra: {'heroTag': widget.def.id});
          },
          currentSource: 'Asterischi',
          color: const Color(0xFFFBBF24),
          icon: Icons.emergency,
          onPreviousSource: () {}, // No other sources for asterisks currently
          onNextSource: () {},
          items: displayAsterisks,
          emptyMessage: 'Nessun asterisco\nirrisolto 📝',
          itemBuilder: (context, item, index) {
            final isResolved = item.isResolved || _locallyResolved.contains(item.id);
            
            return GestureDetector(
              onTap: () => _toggleResolve(item),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Text(
                        '*',
                        style: TextStyle(
                          color: isResolved ? Colors.white24 : const Color(0xFFFBBF24),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.content,
                        style: TextStyle(
                          color: isResolved ? Colors.white38 : Colors.white,
                          fontSize: 13,
                          height: 1.3,
                          decoration: isResolved ? TextDecoration.lineThrough : null,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
