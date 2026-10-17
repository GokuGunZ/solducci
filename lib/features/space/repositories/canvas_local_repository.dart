import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:solducci/features/space/models/canvas_node.dart';
import 'package:solducci/service/context_manager.dart';

class CanvasLocalRepository {
  static const String boxName = 'canvas_nodes';
  static final CanvasLocalRepository _instance = CanvasLocalRepository._internal();
  factory CanvasLocalRepository() => _instance;
  CanvasLocalRepository._internal();
  
  Future<void> init() async {
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox<String>(boxName);
    }
  }

  Box<String> get _box => Hive.box<String>(boxName);

  List<CanvasNode>? _cachedNodes;

  void _invalidateCache() {
    _cachedNodes = null;
  }

  Future<void> saveNode(CanvasNode node) async {
    await _box.put(node.id, jsonEncode(node.toMap()));
    _invalidateCache();
  }

  Future<void> saveNodes(List<CanvasNode> nodes) async {
    final Map<String, String> map = {
      for (var node in nodes) node.id: jsonEncode(node.toMap())
    };
    await _box.putAll(map);
    _invalidateCache();
  }

  CanvasNode? getNode(String id) {
    if (_cachedNodes != null) {
      try {
        return _cachedNodes!.firstWhere((n) => n.id == id);
      } catch (_) {
        return null;
      }
    }
    final data = _box.get(id);
    if (data == null) return null;
    return CanvasNode.fromMap(jsonDecode(data));
  }

  List<CanvasNode> getAllNodes() {
    _cachedNodes ??= _box.values.map((data) => CanvasNode.fromMap(jsonDecode(data))).toList();
    return _cachedNodes!;
  }

  List<CanvasNode> getChildrenForContext(
    String? parentId,
    ExpenseContext context, {
    String? userId,
  }) {
    return getAllNodes().where((n) {
      if (n.parentId != parentId) return false;
      if (context.isPersonal) {
        return n.groupId == null && (userId == null || n.userId == userId);
      } else if (context.isGroup) {
        return n.groupId == context.groupId;
      } else if (context.isView) {
        final matchesGroup = context.groupIds.contains(n.groupId);
        final matchesPersonal = context.includesPersonal &&
            n.groupId == null &&
            (userId == null || n.userId == userId);
        return matchesGroup || matchesPersonal;
      }
      return false;
    }).toList()
      ..sort((a, b) => a.lexorank.compareTo(b.lexorank));
  }

  List<CanvasNode> getChildren(
    String? parentId, {
    String? groupId,
    String? userId,
    bool isPersonal = false,
  }) {
    return getAllNodes()
        .where((n) =>
            n.parentId == parentId &&
            (isPersonal || (groupId == null && userId != null)
                ? (n.groupId == null && (userId == null || n.userId == userId))
                : ((groupId == null || n.groupId == groupId) &&
                    (userId == null || n.userId == userId))))
        .toList()
      ..sort((a, b) => a.lexorank.compareTo(b.lexorank));
  }

  Future<void> deleteNode(String id) async {
    await _box.delete(id);
    _invalidateCache();
  }

  Future<void> clearEvictedPayloads() async {
    final now = DateTime.now();
    final threshold = now.subtract(const Duration(days: 90)); // 3 months eviction
    
    final nodesToUpdate = <CanvasNode>[];
    
    for (var node in getAllNodes()) {
      if (node.lastAccessedAt.isBefore(threshold) && node.payload.isNotEmpty) {
        nodesToUpdate.add(node.copyWith(payload: {}));
      }
    }
    
    if (nodesToUpdate.isNotEmpty) {
      await saveNodes(nodesToUpdate);
    }
  }
}
