import 'package:flutter/foundation.dart';
import 'package:solducci/features/space/models/canvas_node.dart';
import 'package:solducci/features/space/repositories/canvas_local_repository.dart';
import 'package:solducci/service/context_manager.dart';
import 'package:solducci/service/recent_markdown_service.dart';
import 'package:solducci/utils/lexo_rank.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class MarkdownInboxService extends ChangeNotifier {
  static const String inboxFolderId = 'inbox_markdown_root';
  static final MarkdownInboxService _instance = MarkdownInboxService._internal();
  factory MarkdownInboxService() => _instance;
  MarkdownInboxService._internal();

  final _canvasRepo = CanvasLocalRepository();

  Future<CanvasNode> ensureInboxFolder() async {
    await _canvasRepo.init();
    final existing = _canvasRepo.getNode(inboxFolderId);
    if (existing != null) {
      return existing;
    }

    final ctx = ContextManager().currentContext;
    String? gId;
    String? uId;
    if (ctx.isGroup) {
      gId = ctx.groupId;
    } else {
      uId = Supabase.instance.client.auth.currentUser?.id;
    }

    final inboxNode = CanvasNode(
      id: inboxFolderId,
      parentId: null,
      type: 'folder',
      lexorank: '0|000000:',
      title: 'Inbox File MD',
      metadata: const {
        'isSystemInbox': true,
        'icon': 'article',
        'color': 0xFF6366F1,
      },
      userId: uId,
      groupId: gId,
      lastAccessedAt: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _canvasRepo.saveNode(inboxNode);
    notifyListeners();
    return inboxNode;
  }

  Future<void> registerFile(String filePath, String fileName, String content) async {
    await ensureInboxFolder();

    final allNodes = _canvasRepo.getAllNodes();
    CanvasNode? existingNode;
    try {
      existingNode = allNodes.firstWhere(
        (n) => n.parentId == inboxFolderId && (n.payload['filePath'] == filePath || n.title == fileName.replaceAll('.md', '')),
      );
    } catch (_) {
      existingNode = null;
    }

    final cleanTitle = fileName.replaceAll('.md', '').replaceAll('.txt', '');

    if (existingNode != null) {
      final updated = existingNode.copyWith(
        title: cleanTitle,
        payload: {
          ...existingNode.payload,
          'text': content,
          'filePath': filePath,
        },
        lastAccessedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _canvasRepo.saveNode(updated);
    } else {
      final ctx = ContextManager().currentContext;
      String? gId;
      String? uId;
      if (ctx.isGroup) {
        gId = ctx.groupId;
      } else {
        uId = Supabase.instance.client.auth.currentUser?.id;
      }

      final existingInboxChildren = _canvasRepo.getChildren(inboxFolderId);
      final lastRank = existingInboxChildren.isEmpty ? null : existingInboxChildren.last.lexorank;
      final newRank = LexoRank.between(lastRank, null);

      final newNode = CanvasNode(
        id: const Uuid().v4(),
        parentId: inboxFolderId,
        type: 'markdown',
        lexorank: newRank,
        title: cleanTitle,
        payload: {
          'text': content,
          'filePath': filePath,
        },
        metadata: {
          'source': 'imported_file',
          'fileName': fileName,
        },
        userId: uId,
        groupId: gId,
        lastAccessedAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _canvasRepo.saveNode(newNode);
    }

    await RecentMarkdownService().addFile(filePath, fileName);
    notifyListeners();
  }

  Future<List<CanvasNode>> getInboxNodes() async {
    await ensureInboxFolder();
    final nodes = _canvasRepo.getChildren(inboxFolderId);
    // Sort by lastAccessedAt descending
    nodes.sort((a, b) => b.lastAccessedAt.compareTo(a.lastAccessedAt));
    return nodes;
  }
}
