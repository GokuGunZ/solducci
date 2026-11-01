# 02 — REPOSITORY REALITY: Solducci LifeOS v1.06.01 Baseline Survey

**Run ID:** `run_20261031_211008_project_graph_and_progressive_dashboard`  
**Git Branch:** `release/v1.06.01`  
**HEAD SHA:** `33abda0d847c19096c19c81dfa6a5fdccb9559eb`  
**Mode:** `SPEC_ONLY` (Analytical Audit — No Code Mutations)  
**Date:** 2026-10-31  

---

## 1. Executive Baseline & Verification Status

Solducci has recently merged and tagged **LifeOS Step 3.2a** (`v1.06.00` / `v1.06.01`), establishing an operational personal operating system integrated into the Bento Feed and core navigation. The system is verified clean:
- **Test Suite Status:** 46/46 LifeOS tests passing (`flutter test test/features/life_os/`).
- **Database Schema:** Fully synchronized via Supabase migrations (`20261025_create_life_os_core_schema.sql` and `20261028_sync_user_preferences.sql`).
- **Persistence Adapter:** `documents` table serves as the canonical backing store for `LifeEntity` (via `metadata['life_os']`), while `entity_relations` serves as the graph edge store.
- **Cross-Device User Integrity:** User preferences and Role Property Packs reside in `user_preferences` with cache-first fast local projection via `SharedPreferences`.

This spec analyzes the exact physical files and architecture to determine how the user's vision for **Project Graphs, Hierarchical Folders, Long-Press Input Creation, and Progressive Dashboards** maps onto reality without regressions or unnecessary infrastructure additions.

---

## 2. Codebase Anatomy & Physical Anchors

### 2.1 Domain Models (`lib/features/life_os/domain/`)
| File | Symbol / Capability | Reality Status & Role in New Vision |
| :--- | :--- | :--- |
| [`life_entity.dart`](file:///C:/Users/Aless/Documents/Projects/Solducci/lib/features/life_os/domain/life_entity.dart) | `LifeEntity` | Core entity model. Already has `role: SemanticRole.project`, `nature: EntityNature`, `metadata: Map<String, dynamic>`. Holds `blocks: List<EntityBlock>` and `properties: List<EntityProperty>`. Serves directly as the project root node or child node. |
| [`entity_relation.dart`](file:///C:/Users/Aless/Documents/Projects/Solducci/lib/features/life_os/domain/entity_relation.dart) | `EntityRelation` | First-class polymorphic graph edge. Connects `sourceEntityId` to `targetId` with `TargetType targetType` and `RelationType relationType`. Already defines `RelationType.partOf`, which constitutes the exact parent-child container edge needed for project hierarchies. |
| [`enums.dart`](file:///C:/Users/Aless/Documents/Projects/Solducci/lib/features/life_os/domain/enums.dart) | `SemanticRole`, `RelationType`, `TargetType` | `SemanticRole.project` is already defined alongside `goal`, `area`, `resource`, `seed`, `reflection`, `ritual`. `RelationType.partOf` is defined. `TargetType.entity`, `TargetType.task`, `TargetType.expense`, `TargetType.timeScenario` enable polymorphic project scoping. |
| [`entity_block.dart`](file:///C:/Users/Aless/Documents/Projects/Solducci/lib/features/life_os/domain/entity_block.dart) | `EntityBlock`, `BlockType` | Structured content within entities (notes, checklists, quotes, insights). Supports continuous thread evolution. |
| [`entity_property.dart`](file:///C:/Users/Aless/Documents/Projects/Solducci/lib/features/life_os/domain/entity_property.dart) | `EntityProperty`, `PropertyType` | Canonical typed attributes (`text`, `number`, `date`, `url`) stored in `metadata['life_os']['properties']`. Used to track project parameters (e.g., target completion date, budget ceiling, repo URL). |

### 2.2 Persistence & Repositories (`lib/features/life_os/data/`)
| File | Contract & Implementation | Reality Status & Gaps |
| :--- | :--- | :--- |
| [`life_entity_repository.dart`](file:///C:/Users/Aless/Documents/Projects/Solducci/lib/features/life_os/data/life_entity_repository.dart) | `LifeEntityRepository` | Abstract interface for querying entities by role, nature, tags, updated dates. |
| [`supabase_life_entity_repository.dart`](file:///C:/Users/Aless/Documents/Projects/Solducci/lib/features/life_os/data/supabase_life_entity_repository.dart) | `SupabaseLifeEntityRepository` | Maps `LifeEntity` to and from Supabase `documents` table using `LifeEntityMapper`. Fast, resilient, schema-tolerant. |
| [`entity_relation_repository.dart`](file:///C:/Users/Aless/Documents/Projects/Solducci/lib/features/life_os/data/entity_relation_repository.dart) | `EntityRelationRepository` | Defines `saveRelation()`, `deleteRelation()`, `getOutgoingRelations(sourceId)`, `getIncomingRelations(targetId)`. **Current Gap:** Only provides single-hop queries. Does not yet provide recursive tree traversal or transitive descendant resolution (`getDescendants(rootId)`). |
| [`supabase_entity_relation_repository.dart`](file:///C:/Users/Aless/Documents/Projects/Solducci/lib/features/life_os/data/supabase_entity_relation_repository.dart) | `SupabaseEntityRelationRepository` | Maps to `entity_relations` table. Supports batch fetching of incoming and outgoing edges for entities. |

### 2.3 Presentation & User Surfaces (`lib/features/life_os/presentation/`)
| File | Current Component | Reality Status & Extension Points |
| :--- | :--- | :--- |
| [`life_os_screen.dart`](file:///C:/Users/Aless/Documents/Projects/Solducci/lib/features/life_os/presentation/life_os_screen.dart) | Main LifeOS Hub | Provides role filters, search, quick capture bar, entity vitrine cards. Hosts the primary input bar where long-press needs to be wired. |
| [`entity_detail_screen.dart`](file:///C:/Users/Aless/Documents/Projects/Solducci/lib/features/life_os/presentation/entity_detail_screen.dart) | Entity Detail Page | Currently presents a uniform view (Vitrine header, Property strip, Blocks list, Floating composer). For an entity with `role == SemanticRole.project`, it lacks project-specific views (Folders, Ego-Graph, Progressive Dashboard). |
| [`widgets/universal_capture_bar.dart`](file:///C:/Users/Aless/Documents/Projects/Solducci/lib/features/life_os/presentation/widgets/universal_capture_bar.dart) | Bottom Floating Input Bar | Contains a `TextField` and an action button (`IconButton` with `Icons.arrow_upward`). Currently only handles single tap to submit. Long-press on the send button (`onLongPress`) is completely unhandled. |
| [`lib/widgets/dashboard/widgets/life_os/life_os_capture_widget.dart`](file:///C:/Users/Aless/Documents/Projects/Solducci/lib/widgets/dashboard/widgets/life_os/life_os_capture_widget.dart) | Bento Quick Capture | Dedicated Feed widget for capturing ideas. Uses the same single-tap submission pattern. Needs long-press support on its submit button as well. |

### 2.4 Database Schema (`supabase/migrations/`)
```sql
-- Existing entity_relations table (20261025_create_life_os_core_schema.sql)
CREATE TABLE IF NOT EXISTS public.entity_relations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    source_entity_id UUID NOT NULL REFERENCES public.documents(id) ON DELETE CASCADE,
    target_type TEXT NOT NULL, -- 'entity', 'task', 'expense', 'time_scenario'
    target_id TEXT NOT NULL,
    relation_type TEXT NOT NULL, -- 'part_of', 'relates_to', 'depends_on', etc.
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);
```
**Key Database Takeaway:** The schema is already 100% capable of storing `part_of` relations connecting child entities to a project root, as well as polymorphic links to Solducci tasks, expenses, and time scenarios. **No database migrations are needed to support the project graph data model.**

---

## 3. Reality Analysis of the User's 6 Key Directives

### Directive 1: Thread-Seguito / Aggiunta Pensieri Diretti ad Altra Entità
- **Current State:** A user can add blocks to the entity they are currently viewing via `EntityDetailScreen`'s bottom composer. However, from the Universal Capture Bar or from a child entity, there is no direct mechanism to "reply to" or "deepen" an existing entity as a contextual thread.
- **Feasibility:** High. Can be achieved either by creating a new `EntityBlock` directly on the target entity or by creating a new `LifeEntity` (e.g., `seed` or `reflection`) linked with `relation_type = 'derived_from'` or `'relates_to'` / `'part_of'`.

### Directive 2: Long-Press on Send (↑) → Structured Project BottomSheet
- **Current State:** Both `UniversalCaptureBar` and `LifeOsCaptureWidget` handle `onSubmitted` on the `TextField` and `onPressed` on the submit button.
- **Feasibility:** High. Wrapping the send button in a `GestureDetector(onLongPress: ...)` or utilizing a long-press handler opens a modal bottom sheet (`StructuredCaptureSheet`). It captures the text already entered in the bar, defaults the semantic role to `Project`, and presents a frictionless picker/chips interface to attach sub-ideas, existing entities, or child seeds.

### Directive 3: Project as Root Node of a Graph & Recursive Container
- **Current State:** The database stores flat edges in `entity_relations`. If Entity B is `part_of` Entity A (Project), and Entity C is `part_of` Entity B, C is a grandchild of A. Currently, no query traverses this hierarchy recursively.
- **Feasibility:** High. Because personal knowledge graphs in Solducci have typical depths of 2–6 levels and tens to hundreds of nodes (not millions), in-memory Directed Acyclic Graph (DAG) traversal in Dart is computationally instantaneous (< 2ms). It requires:
  1. A `ProjectGraphService` / `ProjectHierarchyService` that traverses `part_of` edges.
  2. Cycle detection (Tarjan/DFS) to prevent accidental circular loops.
  3. Polymorphic leaf aggregation (collecting linked tasks, expenses, and notes recursively).

### Directive 4: Multi-Modal Views (Folders, Ego-Graph with Clustered Parents, Dedicated Perspectives)
- **Current State:** Only the standard flat vitrine view exists.
- **Feasibility:** High.
  - **Folder View (`ProjectFolderView`):** A recursive tree widget (like standard file-tree or indented level list) projecting direct children and nesting grandchildren upon expansion.
  - **Interactive Ego-Graph (`ProjectGraphView`):**
    - The user specifically demanded: **Focus on few neighbors + parent grouping visibility + explicit interaction (double-tap or swipe on graph node) to enter/descend levels**.
    - Single click should NOT dive into the child level; it selects/inspects the node. Double-tap or swipe enters the child level.
    - Can be implemented via Flutter CustomPainter or a lightweight interactive force/tree canvas with high frame rates and full gesture handling (`onDoubleTap`, `onPanUpdate`).

### Directive 5: Modular Skeleton & Progressive Dashboard
- **Current State:** Bento Feed widgets exist on the home screen, but entity detail pages are hardcoded column layouts.
- **Feasibility:** High. We define a `ProjectScopeContext` that evaluates the project's real contents:
  - Has sub-tasks? → Activates Task Stream module.
  - Has linked expenses/budget? → Activates Financial Scope module.
  - Has deep hierarchy? → Activates Folder / Hierarchy module.
  - Has multiple connections? → Activates Graph Radar module.
  - Has open questions / recent updates? → Activates Continuity / Thread module.
  - **Zero clutter:** When an idea is just born (a seed-turned-project with 1 note), the dashboard displays only a lightweight minimalist workspace, avoiding visual fatigue.

### Directive 6: Integrated Entrypoint & Pedagogical Discovery Page
- **Current State:** LifeOS currently lacks an iconography/onboarding explanation sheet that explains its mental model (Projects as root containers, graphs vs. folders, progressive emergence).
- **Feasibility:** High. An info badge/button (`Icons.help_outline` or `Icons.hub_outlined`) on the Project screen opens a dedicated `ProjectDiscoverySheet` explaining:
  1. *Il Progetto come Nodo Radice e Contenitore Vivente*
  2. *Esplorazione a Cartelle vs Grafo Radiale*
  3. *Gesti Chiave (Doppio tap o swipe per scendere di livello)*
  4. *Evoluzione Progressiva del Dashboard*

---

## 4. Technical Constraints & Invariants

1. **Zero Database Migrations:** The schema in `20261025_create_life_os_core_schema.sql` is sufficient. `entity_relations` already contains all needed foreign keys, types, and JSONB metadata.
2. **Offline Resilience & Cache First:** All graph computations must operate seamlessly offline against local cached entities and relations.
3. **No Heavy Foreign Dependencies:** Avoid adding heavy, unmaintained third-party Flutter graph visualization packages that could cause Flutter 3.x build breaks or web/desktop incompatibility. A clean, custom `CustomPainter` with Flutter's built-in physics and gesture detectors guarantees lifetime maintainability.
4. **Preserve Existing Step 3.2 Contracts:** Do not alter `LifeEntityMapper`, `metadata['life_os']`, or `UserPropertyPackService`.

---

## 5. Verification Sign-Off

The repository is fully ready for this capability design. All necessary foundational primitives (`LifeEntity`, `EntityRelation`, `RelationType.partOf`, `SemanticRole.project`, `UniversalCaptureBar`) are solidly in place. The architectural and UX specifications will now be developed in complete detail.
