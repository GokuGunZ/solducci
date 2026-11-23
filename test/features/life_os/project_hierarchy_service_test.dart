import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solducci/features/life_os/domain/models/models.dart';
import 'package:solducci/features/life_os/domain/repositories/repositories.dart';
import 'package:solducci/features/life_os/domain/services/project_hierarchy_service.dart';

class MockLifeEntityRepository extends Mock implements LifeEntityRepository {}
class MockEntityRelationRepository extends Mock implements EntityRelationRepository {}

class FakeLifeEntity extends Fake implements LifeEntity {}
class FakeEntityRelation extends Fake implements EntityRelation {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeLifeEntity());
    registerFallbackValue(FakeEntityRelation());
  });

  group('ProjectHierarchyService DAG & Cycle Tests', () {
    late MockLifeEntityRepository entityRepo;
    late MockEntityRelationRepository relationRepo;
    late ProjectHierarchyService service;

    setUp(() {
      entityRepo = MockLifeEntityRepository();
      relationRepo = MockEntityRelationRepository();
      service = ProjectHierarchyService(
        entityRepository: entityRepo,
        relationRepository: relationRepo,
      );
    });

    test('Self-containment (A is part_of A) returns cycle = true', () async {
      final isCycle = await service.wouldCreateCycle(childId: 'node_A', parentId: 'node_A');
      expect(isCycle, isTrue);
    });

    test('Direct 2-node cycle (A is part_of B, trying to make B part_of A) returns true', () async {
      // Current state: A is part_of B
      when(() => relationRepo.getRelationsForSource('node_B')).thenAnswer((_) async => [
        EntityRelation(
          id: 'rel_1',
          userId: 'user_1',
          sourceId: 'node_B',
          targetType: TargetType.entity,
          targetId: 'node_A',
          relationType: RelationType.partOf,
          createdAt: DateTime.now(),
        ),
      ]);
      when(() => relationRepo.getRelationsForSource('node_A')).thenAnswer((_) async => []);

      // If we ask: would making A part_of B create a cycle?
      final isCycle = await service.wouldCreateCycle(childId: 'node_A', parentId: 'node_B');
      expect(isCycle, isTrue);
    });

    test('Transitive 3-node cycle (C is part_of B, B is part_of A, trying to make A part_of C) returns true', () async {
      // Parent chain from C -> B -> A
      when(() => relationRepo.getRelationsForSource('node_C')).thenAnswer((_) async => [
        EntityRelation(
          id: 'rel_c_b',
          userId: 'user_1',
          sourceId: 'node_C',
          targetType: TargetType.entity,
          targetId: 'node_B',
          relationType: RelationType.partOf,
          createdAt: DateTime.now(),
        ),
      ]);
      when(() => relationRepo.getRelationsForSource('node_B')).thenAnswer((_) async => [
        EntityRelation(
          id: 'rel_b_a',
          userId: 'user_1',
          sourceId: 'node_B',
          targetType: TargetType.entity,
          targetId: 'node_A',
          relationType: RelationType.partOf,
          createdAt: DateTime.now(),
        ),
      ]);
      when(() => relationRepo.getRelationsForSource('node_A')).thenAnswer((_) async => []);

      // Checking if making node_A part_of node_C creates a cycle
      final isCycle = await service.wouldCreateCycle(childId: 'node_A', parentId: 'node_C');
      expect(isCycle, isTrue);
    });

    test('Safe new edge between independent branches returns false', () async {
      when(() => relationRepo.getRelationsForSource('node_D')).thenAnswer((_) async => []);
      when(() => relationRepo.getRelationsForSource('node_A')).thenAnswer((_) async => []);

      final isCycle = await service.wouldCreateCycle(childId: 'node_D', parentId: 'node_A');
      expect(isCycle, isFalse);
    });
  });

  group('ProjectHierarchyService Tree Resolution Tests', () {
    late MockLifeEntityRepository entityRepo;
    late MockEntityRelationRepository relationRepo;
    late ProjectHierarchyService service;

    setUp(() {
      entityRepo = MockLifeEntityRepository();
      relationRepo = MockEntityRelationRepository();
      service = ProjectHierarchyService(
        entityRepository: entityRepo,
        relationRepository: relationRepo,
      );
    });

    test('buildHierarchyTree resolves multi-level nesting and descendant counts', () async {
      final now = DateTime.now();

      final rootEntity = LifeEntity(
        id: 'root_project',
        title: 'Podcast Launch',
        semanticRole: SemanticRole.project,
        createdAt: now,
        updatedAt: now,
      );

      final childA = LifeEntity(
        id: 'child_hardware',
        title: 'Hardware Setup',
        semanticRole: SemanticRole.idea,
        createdAt: now,
        updatedAt: now,
      );

      final grandChildA1 = LifeEntity(
        id: 'grandchild_mic',
        title: 'Shure MV7',
        semanticRole: SemanticRole.seed,
        createdAt: now,
        updatedAt: now,
      );

      // Relations:
      // child_hardware -> root_project
      when(() => relationRepo.getRelationsForTarget('root_project', TargetType.entity))
          .thenAnswer((_) async => [
                EntityRelation(
                  id: 'rel_1',
                  userId: 'user_1',
                  sourceId: 'child_hardware',
                  targetType: TargetType.entity,
                  targetId: 'root_project',
                  relationType: RelationType.partOf,
                  metadata: const {'order_index': 0},
                  createdAt: now,
                ),
              ]);

      // grandchild_mic -> child_hardware
      when(() => relationRepo.getRelationsForTarget('child_hardware', TargetType.entity))
          .thenAnswer((_) async => [
                EntityRelation(
                  id: 'rel_2',
                  userId: 'user_1',
                  sourceId: 'grandchild_mic',
                  targetType: TargetType.entity,
                  targetId: 'child_hardware',
                  relationType: RelationType.partOf,
                  metadata: const {'order_index': 0},
                  createdAt: now,
                ),
              ]);

      when(() => relationRepo.getRelationsForTarget('grandchild_mic', TargetType.entity))
          .thenAnswer((_) async => []);

      when(() => entityRepo.getEntityById('root_project')).thenAnswer((_) async => rootEntity);
      when(() => entityRepo.getEntityById('child_hardware')).thenAnswer((_) async => childA);
      when(() => entityRepo.getEntityById('grandchild_mic')).thenAnswer((_) async => grandChildA1);

      final tree = await service.buildHierarchyTree('root_project');

      expect(tree.length, 1);
      final level1 = tree.first;
      expect(level1.entity.id, 'child_hardware');
      expect(level1.depthLevel, 1);
      expect(level1.children.length, 1);

      final level2 = level1.children.first;
      expect(level2.entity.id, 'grandchild_mic');
      expect(level2.depthLevel, 2);
      expect(level2.children, isEmpty);

      expect(level1.totalDescendantCount, 1);

      // Test flattened descendants
      final descendants = await service.getRecursiveDescendants('root_project');
      expect(descendants.length, 2);
      expect(descendants.map((e) => e.id), containsAll(['child_hardware', 'grandchild_mic']));
    });
  });
}
