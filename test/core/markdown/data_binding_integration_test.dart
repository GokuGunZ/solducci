import 'package:flutter_test/flutter_test.dart';
import 'package:solducci/data/repositories/in_memory_task_repository.dart';
import 'package:solducci/models/document.dart';
import 'package:solducci/core/markdown/models/line_element.dart';
import 'package:solducci/core/markdown/models/document_markdown_config.dart';
import 'package:solducci/core/markdown/parser/markdown_ast_visitor.dart';
import 'package:solducci/core/markdown/adapters/task_data_source_adapter.dart';
import 'package:solducci/core/markdown/adapters/shopping_list_data_source_adapter.dart';
import 'package:solducci/core/markdown/adapters/data_binding_engine.dart';

void main() {
  group('Phase C — Data Binding Integration Tests', () {
    late InMemoryTaskRepository taskRepo;
    late TaskDataSourceAdapter taskAdapter;
    late ShoppingListDataSourceAdapter shoppingAdapter;
    late MarkdownDataBindingEngine bindingEngine;
    late MarkdownAstVisitor parser;

    setUp(() {
      taskRepo = InMemoryTaskRepository(enableDelays: false);
      taskAdapter = TaskDataSourceAdapter(repository: taskRepo);
      shoppingAdapter = ShoppingListDataSourceAdapter();
      bindingEngine = MarkdownDataBindingEngine();
      bindingEngine.registerAdapter(taskAdapter);
      bindingEngine.registerAdapter(shoppingAdapter);
      parser = MarkdownAstVisitor();
    });

    test('creates Task entity idempotently when checkbox rule is bound to tasks', () async {
      final doc = TodoDocument(
        id: 'doc-bind-001',
        userId: 'user-001',
        title: 'Project Tasks',
        createdAt: DateTime(2026, 10, 25),
        updatedAt: DateTime(2026, 10, 25),
      );

      // Configure checkbox to bind to 'task'
      doc.setMarkdownConfig(DocumentMarkdownConfig(
        rules: {
          LineMarkerType.checkbox: const LineMarkerRule(
            markerType: LineMarkerType.checkbox,
            dataSource: DataSourceBindingConfig(
              isConnected: true,
              targetEntityType: 'task',
            ),
          ),
        },
      ));

      final markdownText = [
        '# Tasks for Today',
        '- [ ] Implement parser hardening',
        '- [ ] Persist metadata rules',
      ].join('\n');

      final elements = parser.parse(markdownText);
      expect(elements.where((e) => e.markerType == LineMarkerType.checkbox).length, equals(2));

      // 1. Initial sync
      final updatedConfig = await bindingEngine.syncDocument(
        document: doc,
        elements: elements,
      );

      expect(updatedConfig.bindings.length, equals(2));
      final allTasks = await taskRepo.getAll(documentId: doc.id);
      expect(allTasks.length, equals(2));
      expect(allTasks[0].title, equals('Implement parser hardening'));
      expect(allTasks[1].title, equals('Persist metadata rules'));

      // 2. Idempotency test: Re-syncing the exact same document must NOT create duplicate tasks
      doc.setMarkdownConfig(updatedConfig);
      final secondConfig = await bindingEngine.syncDocument(
        document: doc,
        elements: elements,
      );

      expect(secondConfig.bindings.length, equals(2));
      final tasksAfterSecondSync = await taskRepo.getAll(documentId: doc.id);
      expect(tasksAfterSecondSync.length, equals(2)); // Still exactly 2!
    });

    test('synchronizes completion state between checkbox toggle and Task entity', () async {
      final doc = TodoDocument(
        id: 'doc-bind-002',
        userId: 'user-001',
        title: 'Sprint Checklist',
        createdAt: DateTime(2026, 10, 25),
        updatedAt: DateTime(2026, 10, 25),
      );

      doc.setMarkdownConfig(DocumentMarkdownConfig(
        rules: {
          LineMarkerType.checkbox: const LineMarkerRule(
            markerType: LineMarkerType.checkbox,
            dataSource: DataSourceBindingConfig(
              isConnected: true,
              targetEntityType: 'task',
            ),
          ),
        },
      ));

      final initialMarkdown = '- [ ] Fix production bug';
      var elements = parser.parse(initialMarkdown);

      // Create initial task
      var config = await bindingEngine.syncDocument(document: doc, elements: elements);
      doc.setMarkdownConfig(config);

      var tasks = await taskRepo.getAll(documentId: doc.id);
      expect(tasks.first.isCompleted, isFalse);

      // User checks the box in markdown
      final updatedMarkdown = MarkdownAstVisitor.toggleCheckboxInMarkdown(initialMarkdown, elements.first.lineIndex);
      elements = parser.parse(updatedMarkdown);
      expect(elements.first.isChecked, isTrue);

      // Re-sync
      config = await bindingEngine.syncDocument(document: doc, elements: elements);
      doc.setMarkdownConfig(config);

      // Verify task status in repository
      tasks = await taskRepo.getAll(documentId: doc.id);
      expect(tasks.first.isCompleted, isTrue);
    });

    test('synchronizes edited line text to Task entity', () async {
      final doc = TodoDocument(
        id: 'doc-bind-003',
        userId: 'user-001',
        title: 'Notes',
        createdAt: DateTime(2026, 10, 25),
        updatedAt: DateTime(2026, 10, 25),
      );

      doc.setMarkdownConfig(DocumentMarkdownConfig(
        rules: {
          LineMarkerType.checkbox: const LineMarkerRule(
            markerType: LineMarkerType.checkbox,
            dataSource: DataSourceBindingConfig(
              isConnected: true,
              targetEntityType: 'task',
            ),
          ),
        },
      ));

      final text1 = '- [ ] Buy groceries';
      var elements = parser.parse(text1);
      var config = await bindingEngine.syncDocument(document: doc, elements: elements);
      doc.setMarkdownConfig(config);

      // User edits the wording
      final text2 = '- [ ] Buy organic groceries and apples';
      elements = parser.parse(text2);

      config = await bindingEngine.syncDocument(document: doc, elements: elements);
      doc.setMarkdownConfig(config);

      final tasks = await taskRepo.getAll(documentId: doc.id);
      expect(tasks.first.title, equals('Buy organic groceries and apples'));
    });

    test('ShoppingListDataSourceAdapter creates and toggles items', () async {
      final id = await shoppingAdapter.createItem(
        documentId: 'doc-shop-1',
        text: 'Greek Yogurt',
        isCompleted: false,
        idempotencyKey: 'shop-key-1',
      );

      var itemMap = await shoppingAdapter.fetchItem(id);
      expect(itemMap?['title'], equals('Greek Yogurt'));
      expect(itemMap?['is_completed'], isFalse);

      await shoppingAdapter.toggleItem(entityId: id, isCompleted: true);
      itemMap = await shoppingAdapter.fetchItem(id);
      expect(itemMap?['is_completed'], isTrue);
    });
  });
}
