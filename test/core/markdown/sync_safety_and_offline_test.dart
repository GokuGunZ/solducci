import 'package:flutter_test/flutter_test.dart';
import 'package:solducci/data/repositories/in_memory_task_repository.dart';
import 'package:solducci/models/document.dart';
import 'package:solducci/core/markdown/models/line_element.dart';
import 'package:solducci/core/markdown/models/document_markdown_config.dart';
import 'package:solducci/core/markdown/parser/markdown_ast_visitor.dart';
import 'package:solducci/core/markdown/adapters/task_data_source_adapter.dart';
import 'package:solducci/core/markdown/adapters/offline_mutation_queue.dart';
import 'package:solducci/core/markdown/adapters/data_binding_engine.dart';

void main() {
  group('Phase D — Sync Safety, Offline Queue & Conflict Handling Tests', () {
    late InMemoryTaskRepository taskRepo;
    late TaskDataSourceAdapter taskAdapter;
    late OfflineMutationQueue queue;
    late MarkdownDataBindingEngine engine;
    late MarkdownAstVisitor parser;

    setUp(() {
      taskRepo = InMemoryTaskRepository(enableDelays: false);
      taskAdapter = TaskDataSourceAdapter(repository: taskRepo);
      queue = OfflineMutationQueue();
      engine = MarkdownDataBindingEngine(queue: queue);
      engine.registerAdapter(taskAdapter);
      parser = MarkdownAstVisitor();
    });

    test('deleting a line from markdown unlinks the binding but does NOT delete the Task record', () async {
      final doc = TodoDocument(
        id: 'doc-safety-001',
        userId: 'user-001',
        title: 'Safety Test Doc',
        createdAt: DateTime(2026, 10, 25),
        updatedAt: DateTime(2026, 10, 25),
      );

      doc.setMarkdownConfig(DocumentMarkdownConfig(
        rules: {
          LineMarkerType.checkbox: const LineMarkerRule(
            markerType: LineMarkerType.checkbox,
            dataSource: DataSourceBindingConfig(isConnected: true, targetEntityType: 'task'),
          ),
        },
      ));

      final initialMd = '- [ ] Important Mission Critical Task\n- [ ] Second Task';
      var elements = parser.parse(initialMd);
      var config = await engine.syncDocument(document: doc, elements: elements);
      doc.setMarkdownConfig(config);

      var tasks = await taskRepo.getAll(documentId: doc.id);
      expect(tasks.length, equals(2));
      final task1 = tasks.firstWhere((t) => t.title == 'Important Mission Critical Task');
      final task1Id = task1.id;

      // User deletes the first line from Markdown
      final updatedMd = '- [ ] Second Task';
      elements = parser.parse(updatedMd);

      config = await engine.syncDocument(document: doc, elements: elements);
      doc.setMarkdownConfig(config);

      // Verify that the binding for task 1 is unlinked, NOT destroyed
      final bindingForTask1 = config.bindings.values.firstWhere((b) => b.targetEntityId == task1Id);
      expect(bindingForTask1.syncState, equals(LineSyncState.unlinked));

      // CRITICAL SAFETY GUARANTEE: Task record still exists safely in TaskRepository!
      final stillExistingTask = await taskRepo.getById(task1Id);
      expect(stillExistingTask, isNotNull);
      expect(stillExistingTask!.title, equals('Important Mission Critical Task'));
    });

    test('offline mutation queue enqueues actions when offline and flushes on reconnect', () async {
      queue.isOnline = false; // Simulate offline mode

      // Enqueue a task creation
      queue.enqueue(QueuedMutation(
        id: 'mut-1',
        entityType: 'task',
        action: MutationAction.create,
        documentId: 'doc-offline-1',
        text: 'Offline Created Task',
        isCompleted: false,
        idempotencyKey: 'offline-key-1',
      ));

      expect(queue.pendingCount, equals(1));

      // Attempting flush while offline should do nothing
      var applied = await queue.flush(taskAdapter);
      expect(applied, equals(0));
      expect(queue.pendingCount, equals(1));

      // Reconnect online
      queue.isOnline = true;
      applied = await queue.flush(taskAdapter);
      expect(applied, equals(1));
      expect(queue.pendingCount, equals(0));

      final tasks = await taskRepo.getAll(documentId: 'doc-offline-1');
      expect(tasks.length, equals(1));
      expect(tasks.first.title, equals('Offline Created Task'));
    });

    test('enforces DirectContextBound constraints: group tasks require groupId', () async {
      expect(
        taskAdapter.createItem(
          documentId: 'doc-1',
          text: 'Group item with missing groupId',
          isCompleted: false,
          contextScope: 'group',
          groupId: null, // INVALID
          idempotencyKey: 'key-err',
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}
