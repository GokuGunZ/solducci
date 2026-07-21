import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:solducci/features/space/models/canvas_node.dart';
import 'package:solducci/features/space/repositories/canvas_local_repository.dart';

class CanvasSyncService {
  static final CanvasSyncService _instance = CanvasSyncService._internal();
  factory CanvasSyncService() => _instance;
  
  final CanvasLocalRepository _localRepo = CanvasLocalRepository();
  final _supabase = Supabase.instance.client;
  
  RealtimeChannel? _channel;
  
  // A stream controller to notify the UI when local DB has been updated by sync
  final _updateController = StreamController<void>.broadcast();
  Stream<void> get onUpdate => _updateController.stream;

  CanvasSyncService._internal();

  Future<void> initialize() async {
    await _localRepo.init();
  }

  void startSync() {
    _channel?.unsubscribe();
    _fetchSkeleton();

    // Listen to realtime changes using channel
    _channel = _supabase
        .channel('public:canvas_nodes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'canvas_nodes',
          callback: (payload) {
            _handleRealtimeUpdate(payload);
          },
        )
        .subscribe();
  }

  void _handleRealtimeUpdate(PostgresChangePayload payload) {
    if (payload.eventType == PostgresChangeEvent.delete) {
      final id = payload.oldRecord['id'] as String?;
      if (id != null) _localRepo.deleteNode(id);
    } else {
      final newRecord = payload.newRecord;
      if (newRecord.isNotEmpty) {
        // We only want to sync the skeleton to not overwrite an unloaded payload with an empty one
        final currentLocal = _localRepo.getNode(newRecord['id'] as String);
        final newNode = CanvasNode.fromMap(newRecord);
        
        // Preserve local payload if remote didn't send a payload or if we just want to protect it
        final nodeToSave = newNode.copyWith(
          payload: (newRecord['payload'] == null || newRecord['payload'].isEmpty) && currentLocal != null
              ? currentLocal.payload
              : newNode.payload,
        );
        
        _localRepo.saveNode(nodeToSave);
      }
    }
    _updateController.add(null);
  }

  Future<void> _fetchSkeleton() async {
    try {
      final data = await _supabase.from('canvas_nodes').select(
        'id, parent_id, type, lexorank, title, metadata, user_id, group_id, last_accessed_at, created_at, updated_at'
      );
      
      final nodes = data.map((map) {
        final currentLocal = _localRepo.getNode(map['id'] as String);
        map['payload'] = currentLocal?.payload ?? {}; // Keep local payload if exists
        return CanvasNode.fromMap(map);
      }).toList();
      
      await _localRepo.saveNodes(nodes);
      _updateController.add(null);
    } catch (e) {
      debugPrint('Error fetching canvas skeleton: $e');
    }
  }

  Future<void> loadPayload(String nodeId) async {
    final localNode = _localRepo.getNode(nodeId);
    if (localNode == null) return;
    
    try {
      final data = await _supabase.from('canvas_nodes').select('payload').eq('id', nodeId).single();
      final updatedNode = localNode.copyWith(
        payload: Map<String, dynamic>.from(data['payload'] ?? {}),
        lastAccessedAt: DateTime.now(),
      );
      await _localRepo.saveNode(updatedNode);
      _updateController.add(null);
      
      _supabase.from('canvas_nodes').update({'last_accessed_at': DateTime.now().toUtc().toIso8601String()}).eq('id', nodeId).then((_) {});
    } catch (e) {
      debugPrint('Error loading payload for $nodeId: $e');
    }
  }

  Future<void> pushNode(CanvasNode node) async {
    // 1. Optimistic local update
    await _localRepo.saveNode(node);
    _updateController.add(null);
    
    // 2. Server push (Last Write Wins)
    try {
      await _supabase.from('canvas_nodes').upsert(node.toMap());
    } catch (e) {
      debugPrint('Error pushing node: $e');
      // B2: On structural error (like pushing to a deleted parent), rollback
      _fetchSkeleton();
    }
  }

  void dispose() {
    _channel?.unsubscribe();
    _updateController.close();
  }
}
