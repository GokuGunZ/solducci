import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solducci/models/document.dart';
import 'package:solducci/core/markdown/models/line_element.dart';
import 'package:solducci/core/markdown/models/document_markdown_config.dart';

void main() {
  group('Phase B — Document Metadata & Rules Persistence Tests', () {
    test('serializes and deserializes LineMarkerRule and LineBindingLink accurately', () {
      final config = DocumentMarkdownConfig(
        schemaVersion: 1,
        rules: {
          LineMarkerType.checkbox: LineMarkerRule(
            markerType: LineMarkerType.checkbox,
            customIconName: 'task_alt',
            modifier: const LineModifierStyle(
              strikethrough: true,
              bold: true,
              textColor: Color(0xFF10B981),
              opacity: 0.7,
            ),
            dataSource: const DataSourceBindingConfig(
              isConnected: true,
              targetEntityType: 'task',
              targetDocumentId: 'doc-123',
              contextScope: 'personal',
            ),
          ),
        },
        bindings: {
          'anchor-001': LineBindingLink(
            anchorKey: 'anchor-001',
            targetEntityType: 'task',
            targetEntityId: 'task-uuid-456',
            lastKnownText: 'Buy sourdough bread',
            lastKnownLineIndex: 4,
            syncState: LineSyncState.synced,
            updatedAt: DateTime(2026, 10, 25, 12, 0, 0),
          ),
        },
      );

      final map = config.toMap();
      final jsonStr = jsonEncode(map);
      final decodedMap = jsonDecode(jsonStr) as Map<String, dynamic>;

      final recovered = DocumentMarkdownConfig.fromMetadata({
        DocumentMarkdownConfig.metadataKey: decodedMap,
      });

      expect(recovered.schemaVersion, equals(1));
      expect(recovered.rules.containsKey(LineMarkerType.checkbox), isTrue);

      final rule = recovered.rules[LineMarkerType.checkbox]!;
      expect(rule.customIconName, equals('task_alt'));
      expect(rule.modifier.strikethrough, isTrue);
      expect(rule.modifier.bold, isTrue);
      expect(rule.modifier.textColor?.value, equals(const Color(0xFF10B981).value));
      expect(rule.modifier.opacity, equals(0.7));
      expect(rule.dataSource.isConnected, isTrue);
      expect(rule.dataSource.targetEntityType, equals('task'));

      expect(recovered.bindings.containsKey('anchor-001'), isTrue);
      final binding = recovered.bindings['anchor-001']!;
      expect(binding.targetEntityId, equals('task-uuid-456'));
      expect(binding.syncState, equals(LineSyncState.synced));
      expect(binding.lastKnownLineIndex, equals(4));
    });

    test('preserves existing metadata fields when updating markdown configuration', () {
      final doc = TodoDocument.create(
        userId: 'user-001',
        title: 'Project Roadmap',
      );
      doc.colorHex = '#3B82F6';
      doc.iconName = 'map';
      doc.metadata['custom_tag'] = 'urgent';

      final config = DocumentMarkdownConfig(
        rules: {
          LineMarkerType.bullet: const LineMarkerRule(
            markerType: LineMarkerType.bullet,
            modifier: LineModifierStyle(bold: true),
          ),
        },
      );

      doc.setMarkdownConfig(config);

      // Verify that markdown config is set
      expect(doc.markdownConfig.rules.containsKey(LineMarkerType.bullet), isTrue);
      expect(doc.markdownConfig.rules[LineMarkerType.bullet]!.modifier.bold, isTrue);

      // Verify that existing metadata was completely preserved
      expect(doc.colorHex, equals('#3B82F6'));
      expect(doc.iconName, equals('map'));
      expect(doc.metadata['custom_tag'], equals('urgent'));
    });

    test('recovers gracefully from legacy documents without markdown metadata', () {
      final legacyMap = {
        'id': 'legacy-doc-1',
        'document_type': 'todo',
        'title': 'Old Document',
        'user_id': 'user-001',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'metadata': <String, dynamic>{},
      };

      final doc = Document.fromMap(legacyMap);
      final config = doc.markdownConfig;

      expect(config.rules, isEmpty);
      expect(config.bindings, isEmpty);
      expect(config.schemaVersion, equals(DocumentMarkdownConfig.currentVersion));
    });

    test('tolerates corrupted or partial metadata safely without throwing', () {
      final corruptedMetadata = {
        DocumentMarkdownConfig.metadataKey: {
          'version': 99,
          'rules': 'invalid-not-a-map',
          'bindings': {
            'corrupted-anchor': 'not-a-map',
            'valid-anchor': {
              'anchor_key': 'valid-anchor',
              'target_entity_type': 'task',
              'target_entity_id': 'task-123',
              'last_known_text': 'Valid item',
              'last_known_line_index': 1,
            },
          },
        },
      };

      final recovered = DocumentMarkdownConfig.fromMetadata(corruptedMetadata);
      expect(recovered.rules, isEmpty);
      expect(recovered.bindings.length, equals(1));
      expect(recovered.bindings['valid-anchor']!.targetEntityId, equals('task-123'));
    });

    test('round-trip persistence through TodoDocument serialization', () {
      final doc = TodoDocument(
        id: 'doc-uuid-001',
        userId: 'user-001',
        title: 'Weekly Sprint',
        createdAt: DateTime(2026, 10, 25, 10, 0, 0),
        updatedAt: DateTime(2026, 10, 25, 10, 0, 0),
      );

      final initialConfig = DocumentMarkdownConfig(
        rules: {
          LineMarkerType.checkbox: const LineMarkerRule(
            markerType: LineMarkerType.checkbox,
            modifier: LineModifierStyle(strikethrough: true),
            dataSource: DataSourceBindingConfig(isConnected: true, targetEntityType: 'task'),
          ),
        },
      );

      doc.setMarkdownConfig(initialConfig);

      // Simulate serialization to Supabase / local database
      final serializedMap = doc.toMap()..['created_at'] = doc.createdAt.toIso8601String();

      // Simulate re-fetching from database
      final reloadedDoc = Document.fromMap(serializedMap);

      expect(reloadedDoc.markdownConfig.rules.containsKey(LineMarkerType.checkbox), isTrue);
      expect(reloadedDoc.markdownConfig.rules[LineMarkerType.checkbox]!.modifier.strikethrough, isTrue);
      expect(reloadedDoc.markdownConfig.rules[LineMarkerType.checkbox]!.dataSource.isConnected, isTrue);
    });
  });
}
