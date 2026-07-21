import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:solducci/features/space/models/canvas_node.dart';
import 'package:solducci/features/space/repositories/canvas_local_repository.dart';
import 'package:solducci/features/space/services/canvas_sync_service.dart';
import 'package:solducci/core/templates/resource_template.dart';
import 'package:uuid/uuid.dart';
import 'package:solducci/utils/lexo_rank.dart';

// Removed FlattenedNode as it is no longer used

class CanvasTreeController extends ChangeNotifier {
  final CanvasLocalRepository _repo = CanvasLocalRepository();
  final CanvasSyncService _syncService = CanvasSyncService();
  
  // null = inherited, true = manually expanded, false = manually collapsed
  final Map<String, bool> _folderState = {};
  final Map<String, int> _folderDepthLimits = {};
  
  int globalDepthLimit = 1;
  
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

  void toggleExpand(String nodeId, bool currentlyExpanded) {
    _folderState[nodeId] = !currentlyExpanded;
    notifyListeners();
  }

  void setGlobalDepthLimit(int limit) {
    globalDepthLimit = limit > 0 ? limit : 1;
    notifyListeners();
  }

  void resetAllOverrides() {
    _folderState.clear();
    _folderDepthLimits.clear();
    notifyListeners();
  }

  void setDepthLimit(String folderId, int limit) {
    _folderDepthLimits[folderId] = limit >= 0 ? limit : 0;
    notifyListeners();
  }

  int? getDepthLimit(String nodeId) => _folderDepthLimits[nodeId];
  bool? getFolderState(String nodeId) => _folderState[nodeId];
  List<CanvasNode> get rootNodes => _repo.getChildren(null, groupId: groupId, userId: userId);
  List<CanvasNode> getChildren(String parentId) => _repo.getChildren(parentId, groupId: groupId, userId: userId);

  Future<void> createNode({
    required String title,
    required String type,
    String? parentId,
  }) async {
    await createNodeAndReturnId(title: title, type: type, parentId: parentId);
  }

  Future<String> createNodeAndReturnId({
    required String title,
    required String type,
    String? parentId,
    String? payloadText,
  }) async {
    final siblings = _repo.getChildren(parentId, groupId: groupId, userId: userId);
    final maxRank = siblings.isEmpty ? null : siblings.last.lexorank;
    final newRank = LexoRank.between(maxRank, null);

    final nodeId = const Uuid().v4();
    final newNode = CanvasNode(
      id: nodeId,
      parentId: parentId,
      type: type,
      lexorank: newRank,
      title: title,
      metadata: type == 'folder' ? {'children_count': 0} : {},
      payload: type == 'markdown' ? {'text': payloadText ?? '# $title\n\n'} : {},
      userId: userId,
      groupId: groupId,
      lastAccessedAt: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    if (parentId != null) {
      _folderState[parentId] = true;
    }
    
    await _syncService.pushNode(newNode);
    notifyListeners();
    return nodeId;
  }

  Future<void> updateNodeText(CanvasNode node, String newText) async {
    final updated = node.copyWith(
      payload: {...node.payload, 'text': newText},
      updatedAt: DateTime.now(),
    );
    await _syncService.pushNode(updated);
    notifyListeners();
  }

  Future<void> updateNodeTitle(CanvasNode node, String newTitle) async {
    final updated = node.copyWith(
      title: newTitle,
      updatedAt: DateTime.now(),
    );
    await _syncService.pushNode(updated);
    notifyListeners();
  }

  Future<void> injectTemplate(CanvasTemplate template) async {
    for (var node in template.nodes) {
      await _injectTemplateNode(node, parentId: null);
    }
  }

  Future<void> _injectTemplateNode(CanvasTemplateNode tNode, {String? parentId}) async {
    final nodeId = await createNodeAndReturnId(
      title: tNode.title,
      type: tNode.type,
      parentId: parentId,
      payloadText: tNode.payloadText,
    );
    
    for (var child in tNode.children) {
      await _injectTemplateNode(child, parentId: nodeId);
    }
  }

}
