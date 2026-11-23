# 02 — REPOSITORY REALITY & BASELINE AUDIT

**Run ID:** `run_20261123_045201_dynamic_capture_bar_and_chained_seed_overlay`  
**Git Branch:** `main`  
**Git HEAD Commit:** `40fd38693635061c820eb02c63558796ca49fda4`  
**Flutter / Dart SDK:** Dart `>=3.5.0 <4.0.0`, Flutter 3.24+  

---

## 1. Concrete Codebase Anchors

### A. Current Capture Bar Implementation
- **File:** [`lib/features/life_os/presentation/widgets/universal_capture_bar.dart`](file:///C:/Users/Aless/Documents/Projects/Solducci/lib/features/life_os/presentation/widgets/universal_capture_bar.dart)
- **Status:** Rigid single-row layout (`Row` containing `Icon(Icons.eco_outlined)`, `Expanded(TextField)`, and `InkWell(Icon(Icons.arrow_upward_rounded))`).
- **Limitations:**
  - `TextField` uses `isDense: true` and single-line `contentPadding: EdgeInsets.symmetric(vertical: 10)` with no multiline expansion. Long text scrolls horizontally or truncates visually.
  - No tag detection (`@`) or mention listener.
  - Submitting immediately fires `onCapture(text)` and resets the controller, without offering chained capture or context continuation.

### B. LifeOS Center & Cubit Orchestration
- **File:** [`lib/features/life_os/presentation/views/life_os_center_view.dart`](file:///C:/Users/Aless/Documents/Projects/Solducci/lib/features/life_os/presentation/views/life_os_center_view.dart)
- **File:** [`lib/features/life_os/presentation/controllers/life_os_center_cubit.dart`](file:///C:/Users/Aless/Documents/Projects/Solducci/lib/features/life_os/presentation/controllers/life_os_center_cubit.dart)
- **File:** [`lib/features/life_os/presentation/controllers/life_os_center_state.dart`](file:///C:/Users/Aless/Documents/Projects/Solducci/lib/features/life_os/presentation/controllers/life_os_center_state.dart)
- **Status:**
  - `LifeOsCenterCubit.captureSeed(title, description)` creates a single `LifeEntity(semanticRole: SemanticRole.seed)` and prepends it to `state.seeds`.
  - It does NOT currently support creating associated `EntityRelation` instances alongside seed creation.
  - However, `EntityRelationRepository` is already registered in `getIt` and used in `StructuredCaptureSheet` and `ProjectHierarchyService`.

### C. Domain & Persistence Primitives
- **Data Model:** [`EntityRelation`](file:///C:/Users/Aless/Documents/Projects/Solducci/lib/features/life_os/domain/models/entity_relation.dart)
  - `sourceId`: UUID of source entity (the newly created seed).
  - `targetType`: `TargetType.entity`.
  - `targetId`: UUID of the tagged or parent entity.
  - `relationType`: `RelationType.partOf` ("figlio di") or `RelationType.relatesTo` ("semplice").
  - `metadata`: JSONB map, capable of storing `order_index`, `chain_id`, or `mention_position`.
- **Database Schema & RLS:**
  - PostgreSQL table `entity_relations` with foreign keys and RLS check:
    ```sql
    EXISTS (SELECT 1 FROM documents d WHERE d.id = source_id AND ...)
    AND (target_type = 'entity' AND EXISTS (SELECT 1 FROM documents td WHERE td.id::text = target_id AND ...))
    ```
  - **Critical Rule Established in v1.06.05:** The seed MUST be created in `documents` first before creating its `EntityRelation` rows, so that foreign key and RLS constraints pass without error `42501`.

---

## 2. Gap Analysis Between Reality & User Intent

| Feature Dimension | Existing Code Reality | User Directives Required |
| :--- | :--- | :--- |
| **Input Bar Layout** | Single horizontal line (52px height) | Morphing container: 1-line inline $\leftrightarrow$ multiline 2-tier spatial layout with full-width text area. |
| **Multiline Expansion** | No multiline support; single line scrolling | Constrained width, wrapping text, dynamic height expansion with smooth animation. |
| **Send Action Label** | Pure arrow icon | Sliding label `"Raccogli seme "` emerging from behind the send button when multiline. |
| **Send Feedback** | Immediate reset of input bar; item added to list | Modal dimmed overlay with committed seed card ("box definitivo") + "Edit" button. |
| **Chained Seed Capture** | Not supported; user must tap empty bar again | Chained stream below committed card with `"Raccogli una catena di semi"` and auto-linking. |
| **Mention System** | None | `@` trigger opening active entity suggestion overlay. |
| **Semantic Relation Types** | Generic enum available in domain, not exposed in capture | Automatic default: Leading tag $\rightarrow$ "Figlio di" (`partOf`); Mid-text tag $\rightarrow$ "Semplice" (`relatesTo`). |
| **Tag Grouping UI** | None | Top row of multiline container acts as tag chip tray with interactive type-toggle sheets. |
