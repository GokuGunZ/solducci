import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:solducci/models/dashboard_config.dart';
import 'package:solducci/models/space_items.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:solducci/widgets/dashboard/base_list_widget.dart';

import 'package:solducci/features/space/services/space_service.dart';
import 'package:solducci/models/document.dart';
import 'package:solducci/service/context_manager.dart';
import 'package:solducci/service/document_service.dart';

class UnresolvedAsterisksWidget extends StatefulWidget {
  final BentoWidgetDef def;

  const UnresolvedAsterisksWidget({super.key, required this.def});

  @override
  State<UnresolvedAsterisksWidget> createState() => _UnresolvedAsterisksWidgetState();
}

class _UnresolvedAsterisksWidgetState extends State<UnresolvedAsterisksWidget> {
  late Stream<List<AsteriskItem>> _asterisksStream;
  final Set<String> _locallyResolved = {};
  final TextEditingController _asteriskController = TextEditingController();
  final FocusNode _asteriskFocusNode = FocusNode();
  bool _isCreating = false;

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

  @override
  void dispose() {
    _asteriskController.dispose();
    _asteriskFocusNode.dispose();
    super.dispose();
  }

  Future<void> _quickAddAsterisk(String text) async {
    final content = text.trim();
    if (content.isEmpty || _isCreating) return;

    setState(() => _isCreating = true);

    try {
      final currentContext = ContextManager().currentContext;
      final docs = await DocumentService().getDocumentsForContext(currentContext, 'asterisk');
      
      String? docId;
      if (docs.isNotEmpty) {
        docId = docs.first.id;
      } else {
        // Create an initial asterisk document if none exists
        final newDoc = await DocumentService().createDocument(AsteriskDocument(
          id: '',
          userId: currentContext.isGroup ? null : Supabase.instance.client.auth.currentUser?.id,
          groupId: currentContext.isGroup ? currentContext.groupId : null,
          title: 'Note & Asterischi',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
        docId = newDoc.id;
      }

      await SpaceService().createAsteriskItem(AsteriskItem(
        id: '',
        documentId: docId,
        content: content,
        isResolved: false,
        position: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      _asteriskController.clear();
      _asteriskFocusNode.unfocus();
    } catch (e) {
      debugPrint('Error creating quick asterisk: $e');
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
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
                const Text(
                  '*',
                  style: TextStyle(
                    color: Color(0xFFFBBF24),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _asteriskController,
                    focusNode: _asteriskFocusNode,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    decoration: const InputDecoration(
                      hintText: 'Nuovo appunto o asterisco...',
                      hintStyle: TextStyle(color: Colors.white38, fontSize: 11),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onSubmitted: _quickAddAsterisk,
                    onChanged: (text) => setState(() {}),
                  ),
                ),
                if (_isCreating)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFFFBBF24)),
                  )
                else if (_asteriskController.text.trim().isNotEmpty)
                  GestureDetector(
                    onTap: () => _quickAddAsterisk(_asteriskController.text),
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFBBF24),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, color: Colors.black, size: 12),
                    ),
                  ),
              ],
            ),
          ),
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
