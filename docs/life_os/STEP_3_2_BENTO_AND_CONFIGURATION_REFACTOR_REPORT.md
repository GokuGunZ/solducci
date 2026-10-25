# LifeOS Step 3.2 — Bento-Native Refactor, Configuration Integrity & Depth Design Report

**Status:** IMPLEMENTED & TESTED (Build & Verification Gate Passed)  
**Evidence Level:** `IMPLEMENTED` • `UNIT TESTED (57/57)` • `WIDGET TESTED` • `BUILD VERIFIED` • `DEVICE TESTED: PENDING`  
**Branch:** `LIFE_OS`  
**Date:** 2026-10-25  

---

## 1. Evidence Classification

In strict adherence to **INT-D013** and domain integrity constraints, observations and requirements are classified as:

### USER LIVED-USE OBSERVATION / REQUIREMENT (Empirical)
1. **Bento Dimension Unawareness:** Bento widgets squeezed identical layouts into incompatible aspect ratios (e.g., `2x1` and `4x1` were cramped and non-functional).
2. **Quick Capture Usability in H1:** The `2x1` and `4x1` capture tiles contained nested cards, redundant headers ("Cattura Rapida"), and tiny unreachable inputs.
3. **Pinned Entity Configuration Broken:** Selecting an entity failed to resolve accessible entities in current context and did not correlate properly with Weekly Rail focus.
4. **Custom Properties Broken in Vitrine:** Adding a custom property triggered a `ProviderNotFoundException` runtime crash.
5. **Configurable Property Suggestions:** User requested the ability to customize suggested property packs per Nature (add, remove, reorder, reset).
6. **Floating Composer Keyboard Jump:** When the software keyboard opened in the Vitrine, the composer jumped toward the center of the viewport due to double bottom-inset padding.
7. **LifeOS Depth Perception:** LifeOS was still perceived primarily as a sophisticated note-taker rather than an integrated operational operating system.

---

## 2. Bento Dimension Semantics & Architecture Refactor

Per `WIDGET_DESIGN_PHILOSOPHY_AND_DIMENSIONS.md`, different Bento sizes are **different compositions of the same capability**, not squeezed cards.

### 2.1 The 4 Bento Dimension Matrices

#### Matrix 1: `life_os_capture` (Universal Capture)
| Dimension | Height (px) | Purpose | Primary Gesture | Visible Information | Intentionally Omitted |
|---|---|---|---|---|---|
| **2x1** | ~54px (H1) | Instant reflex capture | Tap input / Enter / `↑` | `∞` icon, direct TextField (`Scrivi qualcosa...`), submit `↑` | Headers, chrome, category labels, multi-line padding |
| **4x1** | ~54px (H1) | Wide instant reflex capture | Tap input / Enter / `↑` | `∞` icon, spacious TextField (`Cattura un pensiero al volo...`), submit `↑` | Card headers, multi-line text, timestamps |
| **2x2** | ~124px (H2) | Dominant capture card | Tap & multi-line typing | `∞` header, status feedback, framed multi-line input box | Extraneous menus, role pickers |

#### Matrix 2: `life_os_recent_seeds` (Recent Seeds)
| Dimension | Height (px) | Purpose | Primary Gesture | Visible Information | Intentionally Omitted |
|---|---|---|---|---|---|
| **2x1** | ~54px (H1) | Glanceable banner | Tap row $\rightarrow$ Vitrine | Eco glyph, latest seed title, total seed count badge, chevron | List stream, timestamps, descriptions |
| **2x2** | ~124px (H2) | Compact recent list | Tap item $\rightarrow$ Vitrine | Header + count, 2-3 recent resting seeds with bullet markers | Complex analytics, filters, actions |
| **4x2** | ~124px (H2 Wide) | Asymmetric overview | Tap item $\rightarrow$ Vitrine, Tap left $\rightarrow$ LifeOS | **Left (35%):** Eco glyph, large count number ("a riposo"), "Apri LifeOS" action.<br>**Right (65%):** Operational list of recent seeds with relative times (`12m fa`). | Nested scrolling, search bar |

#### Matrix 3: `life_os_active_entities` (Active Entities)
| Dimension | Height (px) | Purpose | Primary Gesture | Visible Information | Intentionally Omitted |
|---|---|---|---|---|---|
| **2x2** | ~124px (H2) | Immediate active focus | Tap item $\rightarrow$ Vitrine | Header + active count, top 2 active entities with Nature badge | Deep relations, session history |
| **4x2** | ~124px (H2 Wide) | Active radar split | Tap item $\rightarrow$ Vitrine | **Left (35%):** `∞` radar header, active count, "Tutte le entità" link.<br>**Right (65%):** Stream of top 3 active entities with Nature chip, title, and relative update time. | Detailed body blocks, complex metadata |

#### Matrix 4: `life_os_pinned_entity` (Pinned Entity)
| Dimension | Height (px) | Purpose | Primary Gesture | Visible Information | Intentionally Omitted |
|---|---|---|---|---|---|
| **Unconfigured** | Any | Onboarding / setup | Tap tile $\rightarrow$ Config Sheet | Pin glyph, "Tocca per scegliere un'entità" CTA | Dummy data, generic placeholders |
| **2x1** | ~54px (H1) | Minimal focal reference | Tap row $\rightarrow$ Vitrine | Amber pin glyph, Nature icon, Entity title, Nature pill | Body content, blocks, timestamps |
| **2x2** | ~124px (H2) | Focal entity card | Tap card $\rightarrow$ Vitrine | "In Evidenza" header, Nature badge, prominent title, latest snippet/property preview | Full block history, relations list |
| **4x2** | ~124px (H2 Wide) | Asymmetric entity dossier | Tap left/right $\rightarrow$ Vitrine | **Left (35%):** Pin glyph, Nature uppercase label, title, "Apri Vitrine" button.<br>**Right (65%):** "CONTENUTI & PROPRIETÀ" header, latest living content block or properties snippet. | Heavy multi-column editors |

---

## 3. Canonical Visual Identity

- **Canonical Icon:** `∞` (`Icons.all_inclusive_rounded`).
- **Brand Color:** `#8B5CF6` (Electric Purple/Violet) aligned with LifeOS Center in Resources.
- **Widget Gallery:** LifeOS category uses `Icons.all_inclusive_rounded`.
- **Gallery Previews:** Refactored `bento_widget_preview_factory.dart` to produce geometric layout blueprints faithful to real widget dimensions for all supported sizes (`2x1`, `4x1`, `2x2`, `4x2`).

---

## 4. Configuration & Domain Integrity Fixes

### 4.1 Pinned Entity Configuration Repair
- **Problem:** Configuration did not allow selecting from context-aware entities or prioritizing active focus entities.
- **Solution:**
  1. Updated `BentoWidgetConfigRegistry._buildLifeOsPinnedConfig`:
     - Queries accessible entities matching active `ExpenseContext` (personal vs group).
     - Prioritizes entities flagged in `UserEntityOverlay.isInWeeklyRail` under an amber `★ NEL TUO FOCUS` top section.
     - Lists all other accessible active entities clearly categorized with role glyphs.
  2. Fixed `BentoConfigSheet` to recognize `entity_id` (in addition to `documentId` and `source`) to pre-select configured entities.

### 4.2 Custom Properties Provider Bug Fix
- **Problem:** In `EntityVitrineView`, calling `_showAddPropertyDialog` created a new dialog route where `context.read<EntityVitrineCubit>()` threw `ProviderNotFoundException` due to Flutter context shadowing.
- **Solution:** Captured `final cubit = context.read<EntityVitrineCubit>();` prior to calling `showDialog(..., builder: (dialogContext) => ...)`.

### 4.3 User-Configurable Role Property Packs
- **Domain Invariant Preserved:** Role property packs are suggestions, not schema requirements. Changing Nature does not mutate, delete, or hide existing properties.
- **Service:** Created `UserPropertyPackService` backed by `SharedPreferences` with namespace `life_os_role_packs_{userId}_{role}`.
- **UI:** Created `CustomizeLifeOsView` (`/life_os/customize`) accessible via tune icon in `LifeOsCenterView`:
  - Visual selector across Natures (Progetto, Pratica, Concetto, Idea).
  - Add custom suggested properties with name and type (text, number, date, url).
  - Remove unwanted suggestions.
  - Reorder suggestion priority.
  - Reset to domain defaults.

### 4.4 Floating Composer Keyboard Geometry
- **Problem:** When the virtual keyboard appeared, the floating bottom composer traveled upward toward the middle of the screen.
- **Root Cause:** Double inset compensation. `Scaffold(resizeToAvoidBottomInset: true)` naturally lifted the stack. Adding `MediaQuery.viewInsetsOf(context).bottom` in `Positioned(bottom: ...)` applied the keyboard height a second time.
- **Solution:**
  ```dart
  final isKeyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
  Positioned(
    left: 16,
    right: 16,
    bottom: isKeyboardOpen ? 8 : 16,
    child: ...
  )
  ```
  The composer now rests stably 8px above the software keyboard when typing and 16px above the navigation bar when resting.

---

## 5. LifeOS Depth Surfacing Design (Step 4 Bridge)

To address observation #7 (*"LifeOS perceived as just note-taking"*), design document [`docs/life_os/LIFE_OS_DEPTH_SURFACING_DESIGN_V0_1.md`](file:///C:/Users/Aless/Documents/Projects/LIFE_OS/docs/life_os/LIFE_OS_DEPTH_SURFACING_DESIGN_V0_1.md) was formulated:
- Analyzes four loops:
  - **Loop A (The Capture Reflex):** Instant thought capture $\rightarrow$ Seed storage.
  - **Loop B (The Evolution Loop):** Seed $\rightarrow$ Living Body blocks $\rightarrow$ Progressive Properties.
  - **Loop C (The Continuity Loop):** Entity $\rightarrow$ Focused Session $\rightarrow$ Bookmarking $\rightarrow$ Resuming.
  - **Loop D (The Horizon Loop):** Weekly Rails $\rightarrow$ Sunday Ceremony $\rightarrow$ Mirror Signals.
- **Step 4 Target Recommendation:** Prioritize **Loop C (The Continuity Loop)**. Bridging Entities directly into actionable Sessions with bookmarking ("Dove ero rimasto?") creates a fundamental qualitative leap distinguishing LifeOS from static notes without overwhelming cognitive load.

---

## 6. Verification & Test Suite Summary

### Test Suite Execution (`flutter test test/features/life_os`)
All test suites passed with **100% success rate**:

| Suite | Tests | Status |
|---|:---:|:---:|
| `capabilities_test.dart` | 4 | PASS |
| `domain_invariants_test.dart` | 4 | PASS |
| `integration_validation_test.dart` | 10 | PASS |
| `mapper_test.dart` | 5 | PASS |
| `minimal_living_hatch_test.dart` | 6 | PASS |
| `step_3_everyday_integration_test.dart` | 16 | PASS |
| `step_3_2_bento_and_configuration_test.dart` | 12 | PASS |
| **Total** | **57** | **ALL PASSED (57/57)** |

### Static Analysis
`flutter analyze lib/features/life_os lib/widgets/dashboard test/features/life_os`
- **Result:** `No issues found!` (0 errors, 0 warnings, 0 lints).
