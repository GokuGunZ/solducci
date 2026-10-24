# LifeOS Step 3.1 — Integrity & Device Gate Report

**Date:** 2026-10-25  
**Worktree:** `C:\Users\Aless\Documents\Projects\LIFE_OS` (`LIFE_OS` branch)  
**Status:** IMPLEMENTATION COMPLETE & INTEGRITY VERIFIED (Awaiting Real Device / External DB Execution)

---

## 1. Executive Summary & Epistemic Boundary (INT-D013)

Step 3.1 consolidates the architectural and functional contracts introduced by the **Everyday Integration & Evolvable Entity** milestone (Step 3). In strict compliance with the **Epistemic Authority Boundary (INT-D013)**, this report distinguishes strictly between compiler/domain proven facts and runtime/device observations requiring physical or external agency.

| Layer / Capability | Verification Status | Epistemic Evidence |
| :--- | :--- | :--- |
| **Namespace Normalization** (`metadata['life_os']`) | **PROVEN** | Automated unit & mapper round-trip tests (`mapper_test.dart`, `step_3_everyday_integration_test.dart`) |
| **Property Codec & Identity (Upsert / Deduplication)** | **PROVEN** | Automated domain invariant tests (`step_3_everyday_integration_test.dart`) |
| **Role Change Property Non-Destruction** | **PROVEN** | Automated domain invariant test (`step_3_everyday_integration_test.dart`) |
| **Sequential Blocks Document Persistence** | **PROVEN (v0.1 Single-Writer Scope)** | Verified via mapper serialization; explicit concurrency caveats & triggers recorded |
| **View = Edit (In-Place Block Editing)** | **PROVEN** | Automated widget interaction test (`step_3_everyday_integration_test.dart`) |
| **Bento Context Scope & Isolation** | **PROVEN** | Automated widget test consuming `DashboardContextScope` with personal/group routing |
| **Android Debug Package Generation** | **BUILD VERIFIED** | `flutter build apk --debug` exit code 0 |
| **Physical Device UX / Ergonomics** | **PENDING (Waiting Human Action)** | Requires installation on physical Android device |
| **Real PostgreSQL / Supabase Integration** | **PENDING (Waiting External DB)** | Schema migration prepared; awaiting real PostgreSQL execution |

---

## 2. Integrity Hardening Details

### 2.1 Metadata Namespace Canonical Normalization
- **Canonical Contract:** All LifeOS domain fields stored in Supabase `entities.metadata` are nested strictly under the top-level namespace key `'life_os'`:
  - `metadata['life_os']['properties']` $\rightarrow$ list of serialized properties
  - `metadata['life_os']['blocks']` $\rightarrow$ list of serialized body blocks
  - `metadata['life_os']['semantic_role']`, `lifecycle_state`, `current_mode`, `is_pinned`
- **Reconciliation:** All divergences in `LIFE_OS_PROGRESSIVE_PROPERTIES_DESIGN.md` and `DECISION_REGISTER.md` (INT-D016) have been corrected to reflect the canonical contract.

### 2.2 Canonical Property Codec & Key Deduplication
- **JSON Serialization Standards:**
  - `PropertyType.text` $\rightarrow$ string (`"..."`)
  - `PropertyType.url` $\rightarrow$ string (`"https://..."`)
  - `PropertyType.date` $\rightarrow$ ISO-8601 string (`"YYYY-MM-DD"`)
  - `PropertyType.number` $\rightarrow$ JSON number (`num`, e.g. `42` or `3.14`), parsed back defensively from `num` or `String` in UI.
- **Property Identity & Upsert:**
  - Invariant: *One entity + one semantic key $\rightarrow$ at most one active property with that key.*
  - Added [`LifeEntity.upsertProperty(EntityProperty)`](file:///C:/Users/Aless/Documents/Projects/LIFE_OS/lib/features/life_os/domain/models/life_entity.dart) and [`LifeEntity.removeProperty(String)`](file:///C:/Users/Aless/Documents/Projects/LIFE_OS/lib/features/life_os/domain/models/life_entity.dart) to domain models.
  - Added deterministic **Last-Write-Wins** deduplication in [`LifeEntityMapper.fromRow`](file:///C:/Users/Aless/Documents/Projects/LIFE_OS/lib/features/life_os/data/mappers/life_entity_mapper.dart) so accidental duplicate keys in incoming JSON payloads are cleanly collapsed to a single property.

### 2.3 Non-Prescriptive Role Packs
- Changing an entity's `semanticRole` (e.g. from `project` to `concept` or `seed`) **never** deletes or mutates existing properties. Role Property Packs serve purely as suggestion templates in the UI picker without imposing strict ontological validation rules.

### 2.4 Blocks Persistence: Scope & Explicit Revisit Triggers
- **Current Strategy (v0.1):** Single-writer JSON document serialization inside `metadata['life_os']['blocks']`. This eliminates migration overhead for Step 3, perfectly serving personal sequential thoughts and low-volume append operations.
- **Correction:** We withdraw and repudiate any previous claim of "zero race conditions". In multi-device or concurrent editing scenarios, document-level overwrites will result in Last-Write-Wins lost updates.
- **Formal Revisit Triggers for Dedicated Table Storage:**
  1. *Concurrent Multi-Device / Multi-User Editing:* Simultaneous edits from multiple clients requiring CRDTs, OT, or row-level locking.
  2. *High Volume / Large Block History:* Entities accumulating >50 blocks, where reading and writing the entire array degrades payload latency.
  3. *Independent Block Queries & Search:* Need for PostgreSQL full-text search indexing on block content or vector embeddings per block.
  4. *Inter-Block Relations:* When individual blocks need to reference external tasks, documents, or other entities.
  5. *Rich / Binary Block Types:* Audio notes, attachments, or media requiring independent upload states and lifecycles.

### 2.5 In-Place Block Editing (View = Edit Completed)
- Existing blocks in the entity vitrine body ([`_LivingBlockCard`](file:///C:/Users/Aless/Documents/Projects/LIFE_OS/lib/features/life_os/presentation/views/entity_vitrine_view.dart)) are no longer read-only or dependent on modal dialogs.
- **Interaction:**
  - Double-tap or selecting "Modifica blocco" from the card menu transitions the block into inline editing mode.
  - Provides inline text field with direct Save (check icon) and Cancel (close icon) actions.
  - Guarded against accidental loss: empty submissions retain original content; cancel discards uncommitted keystrokes.

### 2.6 Bento Context Correctness
- Verified that all four LifeOS Bento widgets ([`LifeOsCaptureWidget`](file:///C:/Users/Aless/Documents/Projects/LIFE_OS/lib/widgets/dashboard/widgets/life_os/life_os_capture_widget.dart), [`LifeOsRecentSeedsWidget`](file:///C:/Users/Aless/Documents/Projects/LIFE_OS/lib/widgets/dashboard/widgets/life_os/life_os_recent_seeds_widget.dart), [`LifeOsActiveEntitiesWidget`](file:///C:/Users/Aless/Documents/Projects/LIFE_OS/lib/widgets/dashboard/widgets/life_os/life_os_active_entities_widget.dart), [`LifeOsPinnedEntityWidget`](file:///C:/Users/Aless/Documents/Projects/LIFE_OS/lib/widgets/dashboard/widgets/life_os/life_os_pinned_entity_widget.dart)) strictly query through [`DashboardContextScope.of(context)`](file:///C:/Users/Aless/Documents/Projects/LIFE_OS/lib/widgets/dashboard/context/dashboard_context_scope.dart) and fall back gracefully to `ContextManager().currentContext`.
- Captures from `UniversalCaptureWidget` route to personal context or trigger `ViewGroupPickerSheet` when placed in an aggregated view.

---

## 3. Automated Test Suite Results

Full test suite under `test/features/life_os` executed with **44 / 44 tests passing**:
- `capabilities_test.dart` (4 tests) — Pass
- `domain_invariants_test.dart` (4 tests) — Pass
- `integration_validation_test.dart` (10 tests) — Pass
- `mapper_test.dart` (5 tests) — Pass
- `minimal_living_hatch_test.dart` (9 tests) — Pass
- `step_3_everyday_integration_test.dart` (12 unit + 2 widget tests) — Pass

---

## 4. Required Action for Human User

1. **Physical Device Installation:**
   - Install `build/app/outputs/flutter-apk/app-debug.apk` on a physical Android handset via ADB:
     ```bash
     adb install -r build/app/outputs/flutter-apk/app-debug.apk
     ```
2. **Lived-Use Evaluation Points:**
   - **Bento Feed:** Add `Universal Capture` and `Recent Seeds` to your dashboard. Test quick thumb capture directly from feed.
   - **Inline Vitrine:** Open any entity, edit the title directly, add a quick thought using the floating composer, double-tap an existing block to edit it inline.
   - **Progressive Properties:** Add a custom property (e.g. Scadenza, Link, o Numero) without feeling overwhelmed by an ontological schema. Change role and verify property preservation.
