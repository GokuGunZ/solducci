import 'package:solducci/features/life_os/domain/models/models.dart';
import 'package:solducci/features/life_os/domain/repositories/repositories.dart';

/// Node representing an item in the project hierarchy tree.
class ProjectHierarchyNode {
  final LifeEntity entity;
  final int depthLevel;
  final List<ProjectHierarchyNode> children;
  final bool isExpanded;

  const ProjectHierarchyNode({
    required this.entity,
    required this.depthLevel,
    this.children = const [],
    this.isExpanded = false,
  });

  ProjectHierarchyNode copyWith({
    LifeEntity? entity,
    int? depthLevel,
    List<ProjectHierarchyNode>? children,
    bool? isExpanded,
  }) {
    return ProjectHierarchyNode(
      entity: entity ?? this.entity,
      depthLevel: depthLevel ?? this.depthLevel,
      children: children ?? this.children,
      isExpanded: isExpanded ?? this.isExpanded,
    );
  }

  int get totalDescendantCount =>
      children.length +
      children.fold(0, (sum, child) => sum + child.totalDescendantCount);
}

/// Service providing DAG traversal, recursive tree resolution, and cycle prevention
/// for hierarchical project structures in LifeOS.
class ProjectHierarchyService {
  final LifeEntityRepository entityRepository;
  final EntityRelationRepository relationRepository;

  ProjectHierarchyService({
    required this.entityRepository,
    required this.relationRepository,
  });

  /// Checks if adding a containment edge (childId is part_of parentId) would create a cycle.
  /// Returns `true` if it WOULD create a cycle (illegal operation), `false` if safe.
  Future<bool> wouldCreateCycle({
    required String childId,
    required String parentId,
  }) async {
    if (childId == parentId) return true;

    // Traverse upwards from parentId towards ancestors.
    // If we ever encounter childId, then childId is already an ancestor of parentId,
    // so making childId part_of parentId forms a closed cycle.
    final visited = <String>{};
    final queue = <String>[parentId];

    while (queue.isNotEmpty) {
      final currentId = queue.removeLast();
      if (currentId == childId) {
        return true; // Cycle detected!
      }
      visited.add(currentId);

      final relations = await relationRepository.getRelationsForSource(currentId);
      for (final rel in relations) {
        if (rel.relationType == RelationType.partOf &&
            rel.targetType == TargetType.entity) {
          if (!visited.contains(rel.targetId)) {
            queue.add(rel.targetId);
          }
        }
      }
    }

    return false; // Safe
  }

  /// Recursively resolves the full tree of child nodes rooted at [rootEntityId].
  Future<List<ProjectHierarchyNode>> buildHierarchyTree(
    String rootEntityId, {
    int currentDepth = 0,
    Set<String>? visitedAncestorIds,
  }) async {
    final visited = visitedAncestorIds != null
        ? Set<String>.from(visitedAncestorIds)
        : <String>{};
    visited.add(rootEntityId);

    // Incoming relations where targetId == rootEntityId and relationType == partOf
    final incomingRelations = await relationRepository.getRelationsForTarget(
      rootEntityId,
      TargetType.entity,
    );

    final childRelations = incomingRelations
        .where((r) => r.relationType == RelationType.partOf)
        .toList();

    // Sort by order_index if present
    childRelations.sort((a, b) {
      final orderA = (a.metadata['order_index'] as num?)?.toInt() ?? 0;
      final orderB = (b.metadata['order_index'] as num?)?.toInt() ?? 0;
      return orderA.compareTo(orderB);
    });

    final nodes = <ProjectHierarchyNode>[];

    for (final rel in childRelations) {
      final childId = rel.sourceId;
      if (visited.contains(childId)) {
        // Cycle avoidance
        continue;
      }

      final entity = await entityRepository.getEntityById(childId);
      if (entity == null) continue;

      final grandChildren = await buildHierarchyTree(
        childId,
        currentDepth: currentDepth + 1,
        visitedAncestorIds: visited,
      );

      nodes.add(ProjectHierarchyNode(
        entity: entity,
        depthLevel: currentDepth + 1,
        children: grandChildren,
        isExpanded: true,
      ));
    }

    return nodes;
  }

  /// Returns a flattened list of all descendant entities under [rootEntityId].
  Future<List<LifeEntity>> getRecursiveDescendants(String rootEntityId) async {
    final tree = await buildHierarchyTree(rootEntityId);
    final results = <LifeEntity>[];

    void collect(ProjectHierarchyNode node) {
      results.add(node.entity);
      for (final child in node.children) {
        collect(child);
      }
    }

    for (final rootNode in tree) {
      collect(rootNode);
    }

    return results;
  }

  /// Re-parents a child entity to a new parent container, verifying DAG invariants.
  /// If [newParentId] is null, removes containment relation.
  Future<bool> reparentEntity({
    required String childId,
    required String? newParentId,
    required String userId,
  }) async {
    if (newParentId != null) {
      final cycle = await wouldCreateCycle(childId: childId, parentId: newParentId);
      if (cycle) return false;
    }

    // Find and delete existing part_of relations for childId
    final existingRelations = await relationRepository.getRelationsForSource(childId);
    for (final rel in existingRelations) {
      if (rel.relationType == RelationType.partOf && rel.targetType == TargetType.entity) {
        await relationRepository.deleteRelation(rel.id);
      }
    }

    // If newParentId is provided, create the new relation
    if (newParentId != null) {
      final newRelation = EntityRelation(
        id: '${childId}_part_of_${newParentId}_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        sourceId: childId,
        targetType: TargetType.entity,
        targetId: newParentId,
        relationType: RelationType.partOf,
        createdAt: DateTime.now(),
      );
      await relationRepository.createRelation(newRelation);
    }

    return true;
  }
}
