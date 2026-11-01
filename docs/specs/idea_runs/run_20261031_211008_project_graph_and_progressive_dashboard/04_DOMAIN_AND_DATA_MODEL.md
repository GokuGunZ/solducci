# 04 — DOMAIN AND DATA MODEL SPECIFICATION

**Run ID:** `run_20261031_211008_project_graph_and_progressive_dashboard`  
**Git Branch:** `release/v1.06.01`  
**Status:** DRAFT SPECIFICATION  
**Scope:** Polymorphic Graph Architecture, DAG Cycle Prevention, ProjectScopeContext, Ego-Graph State Models  

---

## 1. Relational Graph Foundations & Containment Hierarchy

Solducci's LifeOS utilizes an edge-based model where entities are vertices and `EntityRelation` instances are directed edges.

### 1.1 Containment Semantic via `RelationType.partOf`
A project containment hierarchy is defined by directed edges with `relation_type = 'part_of'`:
```text
Child Entity (source_entity_id) ──[ relation_type: 'part_of' ]──► Parent Container (target_id, target_type: 'entity')
```
- **Semantic Meaning:** "Source entity is part of Target container".
- **Directionality:** The edge points from Child to Parent (`Child -> Parent`).
- **Root Node Definition:** An entity $R$ where `role = SemanticRole.project` and there exists no outgoing `part_of` edge pointing to another entity (or it is explicitly designated as the root context).
- **Polymorphic Scope:** Because `EntityRelation.target_type` supports `TargetType.entity`, `TargetType.task`, `TargetType.expense`, and `TargetType.timeScenario`, a Project can contain non-entity Solducci primitives:
  ```text
  Task A (source_entity_id or polymorphic link) ──[ part_of ]──► Project R
  Expense B (polymorphic target) ──[ part_of / allocated_to ]──► Project R
  ```

---

## 2. Directed Acyclic Graph (DAG) Cycle Prevention Invariant

### 2.1 The Invariant
Containment hierarchies must form a strict Directed Acyclic Graph (DAG). An entity cannot directly or transitively contain itself:
$$\forall A, B \in \text{Entities}, \quad (A \xrightarrow{part\_of^*} B) \implies \neg (B \xrightarrow{part\_of^+} A)$$

### 2.2 Pre-Insertion Cycle Detection Algorithm (DFS)
Before persisting any new `EntityRelation` where `relationType == RelationType.partOf`:
```dart
/// Verifies if creating a containment edge (childId -> parentId) would create a cycle.
/// Returns true if safe, false if it would form a cycle.
Future<bool> canAddContainmentEdge({
  required String childId,
  required String parentId,
  required EntityRelationRepository relationRepository,
}) async {
  if (childId == parentId) return false;

  // If parentId is already a descendant of childId, adding childId -> parentId creates a cycle.
  final visited = <String>{};
  final queue = <String>[parentId];

  while (queue.isNotEmpty) {
    final currentId = queue.removeLast();
    if (currentId == childId) {
      // Cycle detected!
      return false;
    }
    visited.add(currentId);

    // Get containers of currentId (ancestors)
    final outgoing = await relationRepository.getOutgoingRelations(currentId);
    for (final rel in outgoing) {
      if (rel.relationType == RelationType.partOf && rel.targetType == TargetType.entity) {
        if (!visited.contains(rel.targetId)) {
          queue.add(rel.targetId);
        }
      }
    }
  }

  return true;
}
```

---

## 3. ProjectScopeContext: Progressive Dashboard Engine

The progressive dashboard is driven by a computed domain state object: `ProjectScopeContext`. It aggregates direct and recursive descendants and decides which dashboard modules should self-assemble.

### 3.1 Domain Model Definition
```dart
enum ProjectModuleType {
  heroHeader,         // Title, nature, status, metadata vitrine
  folderTreePreview,  // Hierarchical folder projection
  egoGraphRadar,      // Focused radial graph widget
  taskHorizon,        // Associated actionable tasks & deadlines
  financialScope,     // Connected expenses, budget ceiling, burn rate
  thoughtStream,      // Contextual thread & evolvable blocks
  continuityPulse,    // Open questions, recent activity, next step prompt
}

class ProjectScopeContext {
  final LifeEntity rootEntity;
  final List<LifeEntity> directChildren;
  final List<LifeEntity> recursiveDescendants;
  final List<ProjectHierarchyNode> hierarchyTree;
  final List<EntityRelation> internalEdges;
  final List<String> linkedTaskIds;
  final List<String> linkedExpenseIds;
  final int maxDepth;
  final int totalItemCount;
  final Set<ProjectModuleType> activeModules;

  const ProjectScopeContext({
    required this.rootEntity,
    required this.directChildren,
    required this.recursiveDescendants,
    required this.hierarchyTree,
    required this.internalEdges,
    this.linkedTaskIds = const [],
    this.linkedExpenseIds = const [],
    required this.maxDepth,
    required this.totalItemCount,
    required this.activeModules,
  });

  /// Evaluates active modules progressively based on structural complexity.
  static Set<ProjectModuleType> evaluateModules({
    required int directChildrenCount,
    required int recursiveCount,
    required int maxDepth,
    required int taskCount,
    required int expenseCount,
    required int blockCount,
  }) {
    final modules = <ProjectModuleType>{ProjectModuleType.heroHeader};

    // Always provide the thought stream / scratchpad for immediate captures
    modules.add(ProjectModuleType.thoughtStream);

    // Folder tree appears as soon as there is at least 1 child
    if (directChildrenCount > 0) {
      modules.add(ProjectModuleType.folderTreePreview);
    }

    // Ego Graph radar activates when there is relational structure (depth >= 2 or items >= 3)
    if (recursiveCount >= 3 || maxDepth >= 2) {
      modules.add(ProjectModuleType.egoGraphRadar);
    }

    // Polymorphic Solducci integrations activate strictly when content exists
    if (taskCount > 0) {
      modules.add(ProjectModuleType.taskHorizon);
    }
    if (expenseCount > 0) {
      modules.add(ProjectModuleType.financialScope);
    }

    // Continuity pulse appears when the project has accumulated meaningful activity
    if (recursiveCount > 2 || blockCount > 3) {
      modules.add(ProjectModuleType.continuityPulse);
    }

    return modules;
  }
}
```

### 3.2 Hierarchy Tree Representation
```dart
class ProjectHierarchyNode {
  final LifeEntity entity;
  final int depthLevel;
  final List<ProjectHierarchyNode> children;
  final bool isExpanded;

  const ProjectHierarchyNode({
    required this.entity,
    required this.depthLevel,
    required this.children,
    this.isExpanded = false,
  });

  int get totalDescendantCount =>
      children.length +
      children.fold(0, (sum, child) => sum + child.totalDescendantCount);
}
```

---

## 4. Ego-Graph State & Visual Models

To satisfy the user's explicit directive:
> *"una navigazione che mette il focus su pochi vicini oltre al livello selezionato, di default si vedono i raggruppamenti per i vari genitori... l'ingresso in un livello successivo non deve essere dato dal semplice click di un nodo ma bensì da un interazione diretta (doppio tap o swipe direttamente su un grafo)"*

We specify the visual models powering the interactive graph canvas.

### 4.1 EgoGraphState
```dart
class EgoGraphState {
  final String focusedRootId;
  final String? inspectedNodeId;
  final List<GraphDisplayNode> nodes;
  final List<GraphDisplayEdge> edges;
  final List<String> breadcrumbPath; // Ancestor chain for fast back navigation
  final double zoomScale;
  final Offset panOffset;

  const EgoGraphState({
    required this.focusedRootId,
    this.inspectedNodeId,
    required this.nodes,
    required this.edges,
    required this.breadcrumbPath,
    this.zoomScale = 1.0,
    this.panOffset = Offset.zero,
  });
}

enum GraphNodeType {
  focalRoot,      // The active center node (large, glowing halo)
  directChild,    // Immediate child in current level (orbiting circle)
  clusterPill,    // Condensed representation of sibling/parent groupings
  leafItem,       // Simple leaf thought or resource
}

class GraphDisplayNode {
  final String id;
  final String label;
  final EntityNature nature;
  final GraphNodeType nodeType;
  final Offset position;
  final double radius;
  final int hiddenChildrenCount;
  final bool isSelected;

  const GraphDisplayNode({
    required this.id,
    required this.label,
    required this.nature,
    required this.nodeType,
    required this.position,
    required this.radius,
    this.hiddenChildrenCount = 0,
    this.isSelected = false,
  });
}

class GraphDisplayEdge {
  final String sourceId;
  final String targetId;
  final RelationType relationType;
  final bool isHighlighted;

  const GraphDisplayEdge({
    required this.sourceId,
    required this.targetId,
    required this.relationType,
    this.isHighlighted = false,
  });
}
```

---

## 5. Storage Mapping & Migration Zero Guarantee

All data required for this capability maps transparently onto existing tables without schema changes:

1. **Root & Child Entities:** Stored in `documents` table with:
   - `metadata['life_os']['role'] = 'project' | 'seed' | 'resource' | 'goal' | 'reflection'`
   - `metadata['life_os']['nature'] = 'material' | 'digital' | 'conceptual' | 'social'`
   - `metadata['life_os']['blocks'] = [...]`
   - `metadata['life_os']['properties'] = [...]`
2. **Hierarchy & Connections:** Stored in `entity_relations` table with:
   - `source_entity_id = <child_entity_id>`
   - `target_id = <parent_container_id>`
   - `target_type = 'entity'`
   - `relation_type = 'part_of'`
   - `metadata = {"order_index": 0, "color_override": null}`
3. **Cross-Domain Polymorphism:**
   - Tasks linked via `target_type = 'task'`, `target_id = <solducci_task_id>`.
   - Expenses linked via `target_type = 'expense'`, `target_id = <solducci_expense_id>`.
