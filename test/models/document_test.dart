import 'package:flutter_test/flutter_test.dart';
import 'package:solducci/models/document.dart';

void main() {
  group('Document Model Tests', () {
    test('TodoDocument.fromMap should correctly deserialize', () {
      final map = {
        'id': '123e4567-e89b-12d3-a456-426614174000',
        'user_id': 'user-123',
        'group_id': null,
        'document_type': 'todo',
        'title': 'My Todo List',
        'description': 'A test todo list',
        'created_at': '2024-12-04T10:00:00.000Z',
        'updated_at': '2024-12-04T10:00:00.000Z',
        'metadata': {'version': 1},
      };

      final doc = TodoDocument.fromMap(map);

      expect(doc.id, '123e4567-e89b-12d3-a456-426614174000');
      expect(doc.userId, 'user-123');
      expect(doc.groupId, null);
      expect(doc.documentType, 'todo');
      expect(doc.title, 'My Todo List');
      expect(doc.description, 'A test todo list');
      expect(doc.metadata['version'], 1);
    });

    test('TodoDocument.toMap should correctly serialize', () {
      final doc = TodoDocument(
        id: '123e4567-e89b-12d3-a456-426614174000',
        userId: 'user-123',
        title: 'My Todo List',
        description: 'A test todo list',
        createdAt: DateTime(2024, 12, 4, 10, 0, 0),
        updatedAt: DateTime(2024, 12, 4, 10, 0, 0),
        metadata: {'version': 1},
      );

      final map = doc.toMap();

      expect(map['id'], '123e4567-e89b-12d3-a456-426614174000');
      expect(map['user_id'], 'user-123');
      expect(map['group_id'], null);
      expect(map['document_type'], 'todo');
      expect(map['title'], 'My Todo List');
      expect(map['description'], 'A test todo list');
      expect(map['metadata']['version'], 1);
    });

    test('Document.isPersonal should return true when groupId is null', () {
      final doc = TodoDocument(
        id: '123',
        userId: 'user-123',
        title: 'Personal Doc',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(doc.isPersonal, true);
      expect(doc.isGroup, false);
    });

    test('Document.isGroup should return true when userId is null', () {
      final doc = TodoDocument(
        id: '123',
        groupId: 'group-123',
        title: 'Group Doc',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(doc.isPersonal, false);
      expect(doc.isGroup, true);
    });

    test('TodoDocument.create should create a new document with empty id', () {
      final doc = TodoDocument.create(
        userId: 'user-123',
        title: 'New Todo',
        description: 'Test description',
      );

      expect(doc.id, '');
      expect(doc.userId, 'user-123');
      expect(doc.title, 'New Todo');
      expect(doc.description, 'Test description');
      expect(doc.documentType, 'todo');
    });

    test('TodoDocument.copyWith should update only specified fields', () {
      final original = TodoDocument(
        id: '123',
        userId: 'user-123',
        title: 'Original',
        description: 'Original description',
        createdAt: DateTime(2024, 12, 4),
        updatedAt: DateTime(2024, 12, 4),
      );

      final updated = original.copyWith(title: 'Updated Title');

      expect(updated.id, original.id);
      expect(updated.title, 'Updated Title');
      expect(updated.description, 'Original description');
      expect(updated.createdAt, original.createdAt);
    });

    test('Document.fromMap should route to correct subclass', () {
      final map = {
        'id': '123',
        'user_id': 'user-123',
        'group_id': null,
        'document_type': 'todo',
        'title': 'Test',
        'description': null,
        'created_at': '2024-12-04T10:00:00.000Z',
        'updated_at': '2024-12-04T10:00:00.000Z',
        'metadata': {},
      };

      final doc = Document.fromMap(map);

      expect(doc, isA<TodoDocument>());
      expect(doc.documentType, 'todo');
    });

    test('Document.fromMap should throw for unknown document type', () {
      final map = {
        'id': '123',
        'user_id': 'user-123',
        'group_id': null,
        'document_type': 'unknown_type',
        'title': 'Test',
        'created_at': '2024-12-04T10:00:00.000Z',
        'updated_at': '2024-12-04T10:00:00.000Z',
        'metadata': {},
      };

      expect(() => Document.fromMap(map), throwsArgumentError);
    });
  });
}
