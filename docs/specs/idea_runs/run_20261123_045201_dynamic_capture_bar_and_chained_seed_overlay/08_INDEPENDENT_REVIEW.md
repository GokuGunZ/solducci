# 08 — INDEPENDENT ARCHITECTURAL & PRODUCT REVIEW

**Run ID:** `run_20261123_045201_dynamic_capture_bar_and_chained_seed_overlay`  
**Git Branch:** `main`  
**Review Type:** Adversarial Independent Evaluation (Product, Architecture, UX)  
**Verdict:** APPROVED WITH RESOLVED CONDITIONS  

---

## 1. Intent Fidelity Audit

| User Directive | Proposed Specification Reference | Fidelity Score | Audit Findings |
| :--- | :--- | :--- | :--- |
| **Dynamic height & locked horizontal width (auto-wrap)** | `01_ORIGINAL_INTENT.md` § 2.A, `03_PRODUCT_BEHAVIOR_SPEC.md` § 1, `06_UX_INTERACTION_SPEC.md` § 1 | 100% | Text field is constrained horizontally so text wraps cleanly, growing vertically with lines. |
| **Differentiated 1-line vs multi-line spatial layout** | `03_PRODUCT_BEHAVIOR_SPEC.md` § 1.2, `06_UX_INTERACTION_SPEC.md` § 1 | 100% | When >= 2 lines, TextField shifts to Row 2 and expands to 100% width under the icons. |
| **Slide-in "Raccogli seme " label behind send icon** | `03_PRODUCT_BEHAVIOR_SPEC.md` § 1.2, `06_UX_INTERACTION_SPEC.md` § 1 | 100% | Text slides out from behind the send button to sit to its left with fluid animation. |
| **New Send UX with dimmed background overlay** | `03_PRODUCT_BEHAVIOR_SPEC.md` § 3.1, `06_UX_INTERACTION_SPEC.md` § 2 | 100% | Tapping send triggers an 80% opacity dark scrim placing the previous view into background. |
| **Committed text box ("box definitivo") with Edit button** | `03_PRODUCT_BEHAVIOR_SPEC.md` § 3.1, `06_UX_INTERACTION_SPEC.md` § 2 | 100% | Submitted seed freezes into a card; send button is replaced by an "Edit" button. |
| **Chained seed capture with separator label** | `03_PRODUCT_BEHAVIOR_SPEC.md` § 3.1, `06_UX_INTERACTION_SPEC.md` § 2 | 100% | Separator `"Raccogli una catena di semi"` followed by a fresh active capture bar for next link. |
| **"@" Tag Mention Receptor for entities** | `03_PRODUCT_BEHAVIOR_SPEC.md` § 2.1, `04_DOMAIN_AND_DATA_MODEL.md` § 1 | 100% | Typing `@` activates autocomplete for active LifeOS entities. |
| **Default: Leading tag = "Figlio di", Mid-text = "Semplice"** | `03_PRODUCT_BEHAVIOR_SPEC.md` § 2.2, `04_DOMAIN_AND_DATA_MODEL.md` § 2 | 100% | Heuristic strictly applied: leading tag defaults to `partOf`, mid-text defaults to `relatesTo`. |
| **Top row tag grouping in multi-line state** | `03_PRODUCT_BEHAVIOR_SPEC.md` § 2.3, `06_UX_INTERACTION_SPEC.md` § 1 | 100% | The freed space between the leading icon and send button becomes the tag tray. |
| **Interactive chip with popup switch for relation type** | `03_PRODUCT_BEHAVIOR_SPEC.md` § 2.3, `06_UX_INTERACTION_SPEC.md` § 3 | 100% | Tapping a tag chip opens a modal toggle allowing immediate switch between "Figlio di" and "Semplice". |

---

## 2. Adversarial Risk Analysis & Mitigations

### Risk 1: Layout Re-entry Loops during Line Measurement
- **Critique:** Calculating whether text has wrapped to 2 lines during the `build` phase can trigger `setState()` during build or erratic layout flickering when the user types at the boundary of line 1 and line 2.
- **Mitigation Mandate:**
  - Decouple line measurement from the build phase: measure text inside a debounced/immediate `addListener` on `TextEditingController` using a cached `TextPainter`.
  - Only update `_isMultiline` when the computed line count transitions from 1 to $\ge 2$ or vice versa.

### Risk 2: Software Keyboard Dismissal on Chained Overlay Spawn
- **Critique:** If the chained overlay pushes a new modal route (e.g. `Navigator.push`), Flutter frequently closes the software keyboard, causing a jarring visual drop and re-open.
- **Mitigation Mandate:**
  - Implement `ChainedCaptureOverlay` as an **in-page stateful overlay** within `LifeOsCenterView` (or a `Stack` at the scaffold level) rather than pushing a new `ModalRoute`.
  - Maintain the existing `FocusNode` so the keyboard remains smoothly elevated without dropping.

### Risk 3: RLS Constraint Violation on Chained Batch Relations
- **Critique:** As discovered in release v1.06.05, creating an `EntityRelation` whose `source_id` does not yet exist in PostgreSQL `documents` triggers error `42501 Forbidden`.
- **Mitigation Mandate:**
  - Guarantee that `LifeEntityRepository.createEntity(newSeed)` is awaited and successful *prior* to calling `EntityRelationRepository.createRelation()`.

---

## 3. Reviewer Verification Sign-Off

The specification completely captures the user's experiential feedback, respects all repository and RLS invariants, and provides an actionable blueprint.

**Verdict:** `APPROVED_FOR_BUILDER`
