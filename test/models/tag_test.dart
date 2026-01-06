import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solducci/models/tag.dart';

void main() {
  group('Tag Model Tests', () {
    test('Tag.fromMap should correctly deserialize', () {
      final map = {
        'id': '123e4567-e89b-12d3-a456-426614174000',
        'user_id': 'user-123',
        'name': 'Work',
        'description': 'Work-related tasks',
        'color': 'FF5733',
        'icon': 'work',
        'parent_tag_id': null,
        'use_advanced_states': true,
        'show_completed': false,
        'created_at': '2024-12-04T10:00:00.000Z',
        'updated_at': '2024-12-04T10:00:00.000Z',
      };

      final tag = Tag.fromMap(map);

      expect(tag.id, '123e4567-e89b-12d3-a456-426614174000');
      expect(tag.userId, 'user-123');
      expect(tag.name, 'Work');
      expect(tag.description, 'Work-related tasks');
      expect(tag.color, 'FF5733');
      expect(tag.icon, 'work');
      expect(tag.useAdvancedStates, true);
      expect(tag.showCompleted, false);
      expect(tag.isRoot, true);
    });

    test('Tag.toMap should correctly serialize', () {
      final tag = Tag(
        id: '123e4567-e89b-12d3-a456-426614174000',
        userId: 'user-123',
        name: 'Work',
        description: 'Work-related tasks',
        color: 'FF5733',
        icon: 'work',
        useAdvancedStates: true,
        showCompleted: false,
        createdAt: DateTime(2024, 12, 4, 10, 0, 0),
        updatedAt: DateTime(2024, 12, 4, 10, 0, 0),
      );

      final map = tag.toMap();

      expect(map['id'], '123e4567-e89b-12d3-a456-426614174000');
      expect(map['user_id'], 'user-123');
      expect(map['name'], 'Work');
      expect(map['color'], 'FF5733');
      expect(map['icon'], 'work');
      expect(map['use_advanced_states'], true);
      expect(map['show_completed'], false);
    });

    test('Tag.colorObject should convert hex to Color', () {
      final tag = Tag(
        id: '123',
        userId: 'user-123',
        name: 'Test',
        color: 'FF5733',
        useAdvancedStates: false,
        showCompleted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final color = tag.colorObject;

      expect(color, isNotNull);
      expect(color, isA<Color>());
      // FF5733 with FF alpha = 0xFFFF5733
      expect(color!.toARGB32(), 0xFFFF5733);
    });

    test('Tag.colorObject setter should convert Color to hex', () {
      final tag = Tag(
        id: '123',
        userId: 'user-123',
        name: 'Test',
        useAdvancedStates: false,
        showCompleted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      tag.colorObject = const Color(0xFF5733FF);

      expect(tag.color, '5733FF');
    });

    test('Tag.iconData should map icon identifiers to IconData', () {
      final workTag = Tag(
        id: '123',
        userId: 'user-123',
        name: 'Work',
        icon: 'work',
        useAdvancedStates: false,
        showCompleted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final homeTag = Tag(
        id: '456',
        userId: 'user-123',
        name: 'Home',
        icon: 'home',
        useAdvancedStates: false,
        showCompleted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(workTag.iconData, Icons.work);
      expect(homeTag.iconData, Icons.home);
    });

    test('Tag.iconData should return null for unknown icons', () {
      final tag = Tag(
        id: '123',
        userId: 'user-123',
        name: 'Test',
        icon: 'unknown_icon',
        useAdvancedStates: false,
        showCompleted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(tag.iconData, null);
    });

    test('Tag.isRoot should be based on parentTagId', () {
      final rootTag = Tag(
        id: '123',
        userId: 'user-123',
        name: 'Root',
        useAdvancedStates: false,
        showCompleted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final childTag = Tag(
        id: '456',
        userId: 'user-123',
        name: 'Child',
        parentTagId: '123',
        useAdvancedStates: false,
        showCompleted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(rootTag.isRoot, true);
      expect(childTag.isRoot, false);
    });

    test('Tag.hasChildren should return correct value', () {
      final tagWithoutChildren = Tag(
        id: '123',
        userId: 'user-123',
        name: 'Parent',
        useAdvancedStates: false,
        showCompleted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final childTag = Tag(
        id: '456',
        userId: 'user-123',
        name: 'Child',
        parentTagId: '123',
        useAdvancedStates: false,
        showCompleted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final tagWithChildren = tagWithoutChildren.copyWith(
        childTags: [childTag],
      );

      expect(tagWithoutChildren.hasChildren, false);
      expect(tagWithChildren.hasChildren, true);
    });

    test('Tag.create should create a new tag with defaults', () {
      final tag = Tag.create(
        userId: 'user-123',
        name: 'New Tag',
        description: 'Test description',
        color: 'FF5733',
        icon: 'work',
      );

      expect(tag.id, '');
      expect(tag.userId, 'user-123');
      expect(tag.name, 'New Tag');
      expect(tag.color, 'FF5733');
      expect(tag.useAdvancedStates, false);
      expect(tag.showCompleted, false);
    });

    test('Tag.copyWith should update only specified fields', () {
      final original = Tag(
        id: '123',
        userId: 'user-123',
        name: 'Original',
        description: 'Original description',
        color: 'FF5733',
        useAdvancedStates: false,
        showCompleted: false,
        createdAt: DateTime(2024, 12, 4),
        updatedAt: DateTime(2024, 12, 4),
      );

      final updated = original.copyWith(
        name: 'Updated Name',
        useAdvancedStates: true,
      );

      expect(updated.id, original.id);
      expect(updated.name, 'Updated Name');
      expect(updated.useAdvancedStates, true);
      expect(updated.description, 'Original description');
      expect(updated.color, 'FF5733');
    });
  });
}
