import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:solducci/features/space/models/canvas_node.dart';
import 'package:solducci/features/space/repositories/canvas_local_repository.dart';
import 'package:solducci/features/space/services/canvas_sync_service.dart';
import 'package:uuid/uuid.dart';
import 'package:solducci/utils/lexo_rank.dart';

// Removed FlattenedNode as it is no longer used

class CanvasTreeController extends ChangeNotifier {
  final CanvasLocalRepository _repo = CanvasLocalRepository();
  final CanvasSyncService _syncService = CanvasSyncService();
  
  final Set<String> _expandedFolders = {};
  final Map<String, int> _folderDepthLimits = {};
  
  final String? userId;
  final String? groupId;
  
  StreamSubscription? _syncSub;

  CanvasTreeController({this.userId, this.groupId}) {
    _syncSub = _syncService.onUpdate.listen((_) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _syncSub?.cancel();
    super.dispose();
  }

  void toggleExpand(String nodeId) {
    if (_expandedFolders.contains(nodeId)) {
      _expandedFolders.remove(nodeId);
    } else {
      _expandedFolders.add(nodeId);
    }
    notifyListeners();
  }

  void setDepthLimit(String folderId, int limit) {
    _folderDepthLimits[folderId] = limit > 0 ? limit : 1;
    notifyListeners();
  }

  int getDepthLimit(String nodeId) => _folderDepthLimits[nodeId] ?? 1;
  bool isExpanded(String nodeId) => _expandedFolders.contains(nodeId);
  List<CanvasNode> get rootNodes => _repo.getChildren(null, groupId: groupId, userId: userId);
  List<CanvasNode> getChildren(String parentId) => _repo.getChildren(parentId, groupId: groupId, userId: userId);

  Future<void> createNode({
    required String title,
    required String type,
    String? parentId,
  }) async {
    final siblings = _repo.getChildren(parentId, groupId: groupId, userId: userId);
    final maxRank = siblings.isEmpty ? null : siblings.last.lexorank;
    final newRank = LexoRank.between(maxRank, null);

    final newNode = CanvasNode(
      id: const Uuid().v4(),
      parentId: parentId,
      type: type,
      lexorank: newRank,
      title: title,
      metadata: type == 'folder' ? {'children_count': 0} : {},
      payload: type == 'markdown' ? {'text': '# $title\n\n'} : {},
      userId: userId,
      groupId: groupId,
      lastAccessedAt: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    if (parentId != null) {
      _expandedFolders.add(parentId);
    }
    
    await _syncService.pushNode(newNode);
    notifyListeners();
  }

  Future<void> updateNodeText(CanvasNode node, String newText) async {
    final updated = node.copyWith(
      payload: {...node.payload, 'text': newText},
      updatedAt: DateTime.now(),
    );
    await _syncService.pushNode(updated);
    notifyListeners();
  }

}
