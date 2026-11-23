# LifeOS Step 2.1 — Evidence Boundary Repair Report

**Document Version:** 2.0 (Evidence Boundary Repaired)  
**Date:** 2026-10-24  
**Branch / Worktree:** `LIFE_OS` (`C:\Users\Aless\Documents\Projects\LIFE_OS`)  
**Scope:** Strict Epistemic Realignment of Step 2.1, Distinction between Technical Verification and Lived-Use Observation, Evidence Authority Boundaries, and Identification of Required Human/External Actions.  
**Companion Artifacts:**  
- [STEP_2_MINIMAL_LIVING_HATCH_REPORT.md](file:///C:/Users/Aless/Documents/Projects/LIFE_OS/docs/life_os/STEP_2_MINIMAL_LIVING_HATCH_REPORT.md)  
- [DECISION_REGISTER.md](file:///C:/Users/Aless/Documents/Projects/LIFE_OS/docs/life_os/DECISION_REGISTER.md) (Decisions `INT-D011`, `INT-D012`, `INT-D013`)  
- [LIFE_OS_UX_INTEGRATION_STUDY_V0_1.md](file:///C:/Users/Aless/Documents/Projects/LIFE_OS/docs/life_os/LIFE_OS_UX_INTEGRATION_STUDY_V0_1.md)  

---

## 1. Environment Validation & Epistemic Matrix

Under the **Evidence Authority Boundary** ([`INT-D013`](file:///C:/Users/Aless/Documents/Projects/LIFE_OS/docs/life_os/DECISION_REGISTER.md)), an evidence level can only be promoted by an actor or tool capable of directly observing that phenomenon.

No inferior verification layer may serve as a narrative substitute for a superior layer.

| Verification Layer | Epistemic Classification | Actual Status | Authority / Observational Boundary |
| :--- | :--- | :--- | :--- |
| **Domain Models & Invariants** | `UNIT TESTED` | **VERIFIED (13 tests)** | Dart Test Runner. `SemanticRole` vs `LifecycleState` independence, `currentMode = null` default on captures, `ResumeTension`, and capability contracts. |
| **Security & Multi-Tenant Isolation** | `SIMULATED INTEGRATION TESTED` | **VERIFIED (11 tests)** | SQLite/Dart In-Memory Simulator. Visibility checks, author-only `LifeSession` isolation, `UserEntityOverlay` isolation, and polymorphic cleanup triggers. |
| **UI Presentation & Journeys** | `WIDGET / SIMULATED INTEGRATION TESTED` | **VERIFIED (6 tests)** | Flutter Widget Tester. Center view mounting, capture input dispatch, sheet opening, retry banner display, Weekly Rail toggle. |
| **Android APK Compilation** | `BUILD VERIFIED` | **VERIFIED** | Gradle / Android SDK. `build/app/outputs/flutter-apk/app-debug.apk` compiled successfully in 176s. |
| **Physical Device Installation** | `DEVICE TESTED` | **PENDING** | Requires adb installation or physical package deployment on real hardware / emulator. |
| **Physical Device UX** | `DEVICE TESTED` | **PENDING** | Cannot be proven by build or widget tests. Thumb reach, keyboard transition insets, real touch targets, gesture responsiveness, and frame smoothness require device observation. |
| **PostgreSQL Migration DDL** | `REAL DB TESTED` | **BLOCKED / WAITING FOR USER ACTION** | [`20261025_create_life_os_core_schema.sql`](file:///C:/Users/Aless/Documents/Projects/LIFE_OS/supabase/migrations/20261025_create_life_os_core_schema.sql) is syntactically valid. Local Docker daemon is unavailable; application to remote dev Supabase (`fpvzviseqayuxbxjvxea`) requires user execution or CI trigger. |
| **PostgreSQL RLS Enforcement** | `REAL DB TESTED` | **BLOCKED / WAITING FOR USER ACTION** | Directly contingent on migration deployment on PostgreSQL. |
| **Real Human Daily Usage** | `LIVED-USE OBSERVED` | **PENDING (WAITING FOR HUMAN INPUT)** | Only a human being living with the tool across real days can generate lived-use evidence. |

---

## 2. Validated Scenario Walkthroughs

The following walkthroughs reflect **code execution pathways verified by automated tests and static analysis**, explicitly distinguishing what is technically proven from what remains an unverified hypothesis.

### Walkthrough 1: Ultra-Fast Thought Capture (`"Studiare meglio F2L"`)
- **Scenario:** Immediate entry of a fleeting thought into the Universal Capture Bar without classification.
- **Behavior technically verified:**
  - The input field accepts text and dispatches submission without intercepting modal dialogues or mandatory category prompts.
  - The entity is persisted with `semanticRole: SemanticRole.seed`, `lifecycleState: LifecycleState.active`, and `currentMode: null`.
- **What remains hypothetical:**
  - Whether a single tap to the bar feels fast enough to prevent mental capture abandonment in daily situations.
  - How real on-screen software keyboards affect viewport scrolling and input responsiveness.
- **What lived-use evidence would validate it:**
  - A human user reporting that quick thoughts were captured repeatedly during daily routines rather than lost or written down elsewhere.

---

### Walkthrough 2: Progressive Structuring of Complex Intent (`"Capire auth GDPR per Solducci"`)
- **Scenario:** Opening a raw seed and applying human intentions via the Entity Vitrine.
- **Behavior technically verified:**
  - Selecting *"Trattalo come progetto"* in [`HumanRoleActionSheet`](file:///C:/Users/Aless/Documents/Projects/LIFE_OS/lib/features/life_os/presentation/widgets/human_intention_action_sheet.dart) updates `semanticRole` to `project` and strictly preserves `currentMode = null` (INT-D012).
  - Selecting *"Esplora"* in [`HumanModeActionSheet`](file:///C:/Users/Aless/Documents/Projects/LIFE_OS/lib/features/life_os/presentation/widgets/human_intention_action_sheet.dart) updates `currentMode` to `exploration` without modifying `semanticRole`.
- **What remains hypothetical:**
  - Whether human beings naturally distinguish "What nature does this have?" from "How am I approaching it right now?".
  - Whether users find having two separate selection cards intuitive or pedantic.
- **What lived-use evidence would validate it:**
  - A human user structuring multiple varied entities over several days and evaluating whether the prompts match their internal mental model.

---

### Walkthrough 3: Ambient Idea Left at Rest (`"Fare un maglione oversize"`)
- **Scenario:** A low-urgency capture sitting in the system without immediate promotion or deadlines.
- **Behavior technically verified:**
  - The entity persists in `RecentSeedsSection` as an active seed.
  - The system triggers no notifications, applies no overdue marks, and requires no target completion date.
- **What remains hypothetical:**
  - Whether leaving unorganized seeds visible in the feed creates psychological reassurance or cumulative visual clutter and guilt.
- **What lived-use evidence would validate it:**
  - A human user observing their personal reaction to a list of unprocessed seeds accumulating over a week.

---

### Walkthrough 4: Independent Mode Assignment on a Seed (`"Approfondire agrivoltaico"`)
- **Scenario:** Actively exploring a topic without formalizing it as a "Project" or "Idea".
- **Behavior technically verified:**
  - Vitrine persists `currentMode = OperationMode.exploration` while keeping `semanticRole = SemanticRole.seed`.
- **What remains hypothetical:**
  - Whether users actually want to enter exploration mode while leaving an entity classified as a seed, or if they instinctively expect an idea/project label.
- **What lived-use evidence would validate it:**
  - A human user reporting real sessions or notes tied to unpromoted exploratory seeds.

---

## 3. Technical Frictions Resolved in Step 2.1

The following technical frictions were identified during design verification and corrected in code:

1. **Premature Conflation of Role and Mode ([`INT-D012`](file:///C:/Users/Aless/Documents/Projects/LIFE_OS/docs/life_os/DECISION_REGISTER.md)):**
   - *Technical issue:* Step 2 UI conflated "Trattalo come progetto" with `currentMode = execution`, and "Esplora" with `semanticRole = idea`.
   - *Resolution:* Separated Vitrine actions into two orthogonal sheets ([`HumanRoleActionSheet`](file:///C:/Users/Aless/Documents/Projects/LIFE_OS/lib/features/life_os/presentation/widgets/human_intention_action_sheet.dart) and [`HumanModeActionSheet`](file:///C:/Users/Aless/Documents/Projects/LIFE_OS/lib/features/life_os/presentation/widgets/human_intention_action_sheet.dart)).
2. **Title Truncation on Capture Feeds:**
   - *Technical issue:* Titles longer than 6–7 words truncated with `...` on a single line.
   - *Resolution:* Increased `maxLines` to 2 in [`RecentSeedsSection`](file:///C:/Users/Aless/Documents/Projects/LIFE_OS/lib/features/life_os/presentation/widgets/recent_seeds_section.dart) and [`ActiveEntitiesSection`](file:///C:/Users/Aless/Documents/Projects/LIFE_OS/lib/features/life_os/presentation/widgets/active_entities_section.dart).
3. **Repository Error Contract Ambiguity ([`INT-D011`](file:///C:/Users/Aless/Documents/Projects/LIFE_OS/docs/life_os/DECISION_REGISTER.md)):**
   - *Technical issue:* Discrepancy between documentation mentioning `OperationResult<T>` and repositories returning direct futures throwing exceptions.
   - *Resolution:* Canonized direct method return (`Future<T>`) with exception propagation, aligning LifeOS with native Solducci services. Presentation Cubits catch errors and emit explicit UI retry states.
4. **Headless Test Auth Dependency:**
   - *Technical issue:* `SolducciAppBar` defaulted to instantiating `ContextSwitcher`, which threw initialization assertions in headless test environments.
   - *Resolution:* Added `showContextSwitcher: false` parameter to [`LifeOsCenterView`](file:///C:/Users/Aless/Documents/Projects/LIFE_OS/lib/features/life_os/presentation/views/life_os_center_view.dart) and [`EntityVitrineView`](file:///C:/Users/Aless/Documents/Projects/LIFE_OS/lib/features/life_os/presentation/views/entity_vitrine_view.dart).

---

## 4. Architectural Observations & Lived-Use Hypotheses

All experiential statements are reclassified strictly as design hypotheses awaiting human lived-use feedback:

- **Hypothesis 1 (Surface Consolidation):** Recent Seeds provides a single surface for unpromoted captures. *Whether this produces psychological safety or creates anxiety over an unstructured inbox is a lived-use hypothesis.*
- **Hypothesis 2 (Role vs Mode Usability):** Splitting "Che natura ha?" and "Come la stai affrontando?" reflects Dart domain orthogonality. *Whether users find this distinction intuitive or pedantic in practice is an unverified hypothesis.*
- **Hypothesis 3 (In-Product Pedagogy):** The *Strutturazione Progressiva* card displays the count of unpromoted seeds. *Whether this serves as an encouraging nudge or ambient noise is an unverified hypothesis.*
- **Hypothesis 4 (Next Action Flow):** A direct "Start Session" action from an Active Entity is a plausible subsequent interaction. *Whether the user naturally wants to trigger work from this surface is an unverified hypothesis.*

---

## 5. Candidate Hypotheses for Step 3 (Design-Led, Not Lived-Use Derived)

Because lived-use data is pending human trial, candidates for Step 3 are evaluated solely on architectural and design criteria:

| Candidate | Architectural / Design Evaluation | Status |
| :--- | :--- | :--- |
| **Session Runner (Lightweight Sampling)** | Logically closes the operational loop (`Capture → Structure → Act → Sample`). Necessary to test whether session tracking adds value or friction. | **Design Candidate** |
| **Weekly Rails on Time Dial** | Bridges LifeOS entities with Solducci's core temporal visualization surface ([`TimeDialWidget`](file:///C:/Users/Aless/Documents/Projects/Solducci/lib/features/time_dial/presentation/widgets/time_dial_widget.dart)). | **Design Candidate** |
| **Search & Filter in Center** | Anticipates list growth beyond 15–20 seeds. Secondary until real capture volume justifies retrieval aids. | **Deferred** |
| **Vitrine Graph Relations** | Connects entities, tasks, and expenses. Premature before multiple entities are established in real usage. | **Deferred** |

---

## 6. Success Criterion Answer

> **Domanda del Gate:** *Il Minimal Living Hatch riduce davvero il costo di catturare, ritrovare e iniziare a strutturare ciò che emerge nella mia vita?*

### Valutazione Rigorosa: **NOT YET PROVEN IN LIVED USE**

**Ciò che è tecnicamente dimostrato (`UNIT TESTED`, `SIMULATED INTEGRATION TESTED`, `BUILD VERIFIED`):**
- L'infrastruttura mobile supporta la catena `capture → retrieve → open → progressively structure` con zero categorizzazione obbligatoria e salvataggio coerente.
- Il disaccoppiamento tra natura (`SemanticRole`) e approccio operativo (`OperationMode`) è implementato e verificato nei controller e nei widget.
- Il pacchetto binario Android debug è compilabile ed esente da errori di sintassi o analisi statica (`0 issues found`).

**Ciò che NON è dimostrato e rimane in attesa di osservazione umana reale:**
- Se il sistema venga effettivamente aperto e usato spontaneamente durante la giornata.
- Se riduca il carico cognitivo o se introduca un nuovo overhead di manutenzione.
- Se la sezione *Recent Seeds* rimanga accogliente e gestibile nel corso dei giorni.
- Se il *LifeOS Center* diventi un punto di riferimento naturale per orientare le proprie giornate.

---

## 7. Next Actions to Elevate Evidence

Per promuovere i livelli di evidenza attualmente in sospeso:

1. **PostgreSQL Migration (`REAL DB TESTED`):**
   - Applicare [`supabase/migrations/20261025_create_life_os_core_schema.sql`](file:///C:/Users/Aless/Documents/Projects/LIFE_OS/supabase/migrations/20261025_create_life_os_core_schema.sql) sulla console SQL del progetto Supabase dev (`fpvzviseqayuxbxjvxea`) o tramite deploy pipeline.
2. **Physical Device Installation (`DEVICE TESTED`):**
   - Installare l'APK compilato [`build/app/outputs/flutter-apk/app-debug.apk`](file:///C:/Users/Aless/Documents/Projects/LIFE_OS/build/app/outputs/flutter-apk/app-debug.apk) su un dispositivo Android reale o emulatore attivo tramite comando:
     ```powershell
     adb install -r C:\Users\Aless\Documents\Projects\LIFE_OS\build\app\outputs\flutter-apk\app-debug.apk
     ```
3. **Lived Usage Validation (`LIVED-USE OBSERVED`):**
   - L'utente umano deve utilizzare la superficie per catturare e strutturare pensieri reali per almeno 24–48 ore, registrando direttamente attriti ed esperienze soggettive.
