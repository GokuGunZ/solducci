import 'dart:async';

/// Singleton notifier for task updates
/// Used to trigger UI updates when tasks are modified locally
/// This works around Supabase realtime stream limitations
class TaskUpdateNotifier {
  static final TaskUpdateNotifier _instance = TaskUpdateNotifier._internal();
  factory TaskUpdateNotifier() => _instance;
  TaskUpdateNotifier._internal();

  // Stream controller for broadcasting task update events
  final _controller = StreamController<String>.broadcast();

  /// Stream of document IDs that have been updated
  Stream<String> get updates => _controller.stream;

  /// Notify that a task in this document has been updated
  void notifyTaskUpdate(String documentId) {
    if (!_controller.isClosed) {
      print('📢 TaskUpdateNotifier: Broadcasting update for document $documentId');
      _controller.add(documentId);
    }
  }

  /// Dispose the notifier
  void dispose() {
    _controller.close();
  }
}
