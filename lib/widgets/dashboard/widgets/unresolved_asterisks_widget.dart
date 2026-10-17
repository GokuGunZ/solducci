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
import 'package:solducci/widgets/common/view_group_picker_sheet.dart';
import 'package:solducci/widgets/dashboard/context/dashboard_context_scope.dart';

class UnresolvedAsterisksWidget extends StatefulWidget {
  final BentoWidgetDef def;

  const UnresolvedAsterisksWidget({super.key, required this.def});

  @override
  State<UnresolvedAsterisksWidget> createState() => _UnresolvedAsterisksWidgetState();
}

class _UnresolvedAsterisksWidgetState extends State<UnresolvedAsterisksWidget> {
  Stream<List<AsteriskItem>>? _asterisksStream;
  ExpenseContext? _lastContext;
  List<Document> _documents = [];
  int _currentSourceIndex = 0;
  StreamSubscription? _docSubscription;
  final Set<String> _locallyResolved = {};
  final TextEditingController _asteriskController = TextEditingController();
  final FocusNode _asteriskFocusNode = FocusNode();
  bool _isCreating = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentContext = DashboardContextScope.of(context);
    if (_lastContext != currentContext) {
      _lastContext = currentContext;
      _loadDocuments(currentContext);

      _docSubscription?.cancel();
      _docSubscription = DocumentService()
          .watchDocumentsForContext(currentContext, 'asterisk')
          .listen((_) => _loadDocuments(currentContext));
    }
  }

  @override
  void didUpdateWidget(UnresolvedAsterisksWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.def.customProps != widget.def.customProps) {
      _loadDocuments(_lastContext);
    }
  }

  @override
  void dispose() {
    _docSubscription?.cancel();
    _asteriskController.dispose();
    _asteriskFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadDocuments([ExpenseContext? contextOverride]) async {
    try {
      final currentContext = contextOverride ?? _lastContext ?? DashboardContextScope.of(context);
      final docs = await DocumentService().getDocumentsForContext(currentContext, 'asterisk');

      final customProps = widget.def.customProps;
      final rawSelected = customProps?['selectedSourceIds'] as List?;
      final selectedIds = rawSelected?.map((e) => e.toString()).toSet();

      List<Document> filtered;
      if (selectedIds != null && selectedIds.isNotEmpty) {
        filtered = docs.where((d) => selectedIds.contains('doc_${d.id}') || selectedIds.contains(d.id)).toList();
        if (filtered.isEmpty) filtered = docs;
      } else {
        filtered = docs;
      }

      if (mounted) {
        setState(() {
          _documents = filtered;
          if (_currentSourceIndex >= _documents.length) {
            _currentSourceIndex = 0;
          }
          _updateStream();
        });
      }
    } catch (e) {
      debugPrint('Error loading asterisk documents: $e');
    }
  }

  void _updateStream() {
    if (_documents.isEmpty) {
      setState(() => _asterisksStream = Stream.value([]));
      return;
    }
    final activeDoc = _documents[_currentSourceIndex];
    setState(() {
      _asterisksStream = Supabase.instance.client
          .from('asterisk_items')
          .stream(primaryKey: ['id'])
          .eq('document_id', activeDoc.id)
          .order('created_at', ascending: false)
          .map((data) => data.map((m) => AsteriskItem.fromMap(m)).toList())
          .asBroadcastStream();
    });
  }

  Future<void> _quickAddAsterisk(String text) async {
    final content = text.trim();
    if (content.isEmpty || _isCreating) return;

    setState(() => _isCreating = true);

    try {
      final currentContext = _lastContext ?? ContextManager().currentContext;
      String? docId;
      if (_documents.isNotEmpty && _currentSourceIndex < _documents.length) {
        docId = _documents[_currentSourceIndex].id;
      } else {
        final docs = await DocumentService().getDocumentsForContext(currentContext, 'asterisk');
        if (docs.isNotEmpty) {
          docId = docs.first.id;
        } else {
          String? targetGroupId = currentContext.groupId;
          String? targetUserId = currentContext.isPersonal ? Supabase.instance.client.auth.currentUser?.id : null;

          if (currentContext.isView) {
            if (!mounted) return;
            final choice = await ViewGroupPickerSheet.show(
              context,
              title: 'Note & Asterischi',
              subtitle: 'Scegli in quale contesto creare questo elemento',
            );
            if (choice == null) return;
            if (choice.isPersonal) {
              targetUserId = Supabase.instance.client.auth.currentUser?.id;
              targetGroupId = null;
            } else {
              targetGroupId = choice.groupId;
              targetUserId = null;
            }
          }

          final newDoc = await DocumentService().createDocument(AsteriskDocument(
            id: '',
            userId: targetUserId,
            groupId: targetGroupId,
            title: 'Note & Asterischi',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ));
          docId = newDoc.id;
        }
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
    final currentSourceName = _documents.isNotEmpty && _currentSourceIndex < _documents.length
        ? _documents[_currentSourceIndex].title
        : 'Asterischi';

    return StreamBuilder<List<AsteriskItem>>(
      stream: _asterisksStream,
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData;
        final allAsterisks = snapshot.data ?? [];
        
        var displayAsterisks = allAsterisks.where((a) {
          return !a.isResolved || _locallyResolved.contains(a.id);
        }).toList();

        return BaseListWidget<AsteriskItem>(
          heroTag: widget.def.id,
          size: widget.def.size,
          isLoading: isLoading,
          currentSourceIndex: _currentSourceIndex,
          totalSources: _documents.length,
          onExpand: () {
            final activeDocId = _documents.isNotEmpty && _currentSourceIndex < _documents.length
                ? _documents[_currentSourceIndex].id
                : null;
            if (activeDocId != null) {
              GoRouter.of(context).push('/space/asterisks/$activeDocId', extra: {'heroTag': widget.def.id});
            } else {
              GoRouter.of(context).push('/space/asterisks', extra: {'heroTag': widget.def.id});
            }
          },
          currentSource: currentSourceName,
          color: const Color(0xFFFBBF24),
          icon: Icons.emergency,
          onPreviousSource: () {
            if (_documents.length > 1) {
              setState(() {
                _currentSourceIndex = (_currentSourceIndex - 1 + _documents.length) % _documents.length;
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
          items: displayAsterisks,
          emptyMessage: 'Nessun asterisco irrisolto 🎉',
          emptySubtitle: 'Tutti i conti e note sono allineati',
          emptyActionLabel: 'Aggiungi Nota (*)',
          onEmptyAction: () => _asteriskFocusNode.requestFocus(),
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
