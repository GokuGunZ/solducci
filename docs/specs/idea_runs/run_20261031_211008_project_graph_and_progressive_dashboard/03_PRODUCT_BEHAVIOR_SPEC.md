# 03 — PRODUCT BEHAVIOR SPECIFICATION: Project Graph, Folders & Progressive Dashboard

**Run ID:** `run_20261031_211008_project_graph_and_progressive_dashboard`  
**Git Branch:** `release/v1.06.01`  
**Status:** DRAFT SPECIFICATION  
**Scope:** Universal Capture Long-Press, Recursive Project Graphs, Multi-Modal Views, Progressive Dashboard, Pedagogical Discovery  

---

## 1. User Scenarios & Product Journeys

### Journey 1: Quick Capture to Structured Project Creation via Long-Press
1. The user types an idea into the Universal Capture Bar (either on the LifeOS home screen or the Bento Capture Widget), e.g., `"Lancio Podcasting Solducci"`.
2. Instead of a single tap on the send button (`↑`), the user **long-presses** the send button.
3. Haptic feedback triggers immediately (`HapticFeedback.mediumImpact`), and the `StructuredCaptureSheet` slides up smoothly.
4. The text `"Lancio Podcasting Solducci"` is pre-populated as the Project Title.
5. The sheet displays:
   - **Role Selector:** Automatically pre-selected to `Progetto` (with subtle badge).
   - **Sub-idea Quick Adder:** An inline micro-input `"Aggiungi sotto-idea o entità..."`.
   - The user rapidly adds 2 initial child thoughts: `"Microfono Shure MV7"` and `"Scaletta Episodio 1"`.
   - **Attach Existing Picker:** An optional chip to search and link existing entities or resources.
6. The user taps `"Crea Progetto con 2 elementi"`.
7. The system creates the root `LifeEntity` (Role: `project`), the two child `LifeEntity` records, and creates two `EntityRelation` records (`relation_type = 'part_of'`) linking them to the project root.
8. The sheet dismisses with a brief snackbar with a direct `"Apri Progetto"` action.

---

### Journey 2: Contextual Threading ("Thread-Seguito") on an Existing Entity
1. The user is reviewing an existing Entity (e.g., an architectural design note or a feature concept).
2. The user has an immediate follow-up thought or observation.
3. Rather than editing old text or writing a disjointed note, the user taps the `"Aggiungi pensiero in coda"` button or types into the entity's thread composer.
4. The system appends a timestamped block (`EntityBlock`) directly into the entity's evolvable body OR spawns a linked child entity (`relation_type = 'relates_to'` or `'part_of'`) with the relationship badge displayed.
5. The entity's updated timestamp advances, preserving continuity of thought across days without re-reading the entire file.

---

### Journey 3: Exploring a Project in Folder View (Vista a Cartelle)
1. The user opens the Project detail screen and selects the **"Cartelle" (Folders)** tab.
2. The user sees a clean, indented tree view organized strictly by hierarchical levels:
   - **Livello 0:** Root Project (`"Lancio Podcasting Solducci"`).
   - **Livello 1 (Sottocartelle / Moduli):**
     - 📁 *"Attrezzatura & Setup"* (2 items)
     - 📁 *"Contenuti & Episodi"* (4 items)
     - 📄 *"Note Generali"* (1 item)
3. Tapping a folder icon expands/collapses the tree branch smoothly with an arrow animation.
4. Long-pressing or dragging an item allows reordering or nesting an item into another parent folder.
5. Each item shows its Nature badge (Material, Digital, Conceptual, Social) and completion/state indicator.

---

### Journey 4: Exploring a Project in Focused Ego-Graph View (Vista a Grafo Interattivo)
1. The user switches to the **"Grafo"** tab.
2. Rather than displaying an overwhelming spiderweb of 80 nodes, the canvas renders a **Focused Ego-Graph** centered on the current level:
   - The currently focused parent node is centered with an active accent aura.
   - Immediate children (3 to 6 nodes) are arranged radially or in an orbital arc.
   - Surrounding parent clusters and sibling groups are visible as condensed cluster pills on the periphery, maintaining global context without visual clutter.
3. **Gesture Interaction & Level Descent:**
   - **Single tap on a node:** Selects the node, displaying a bottom preview card (title, nature, child count, quick peek). Does **NOT** navigate or dive into the node.
   - **Double-tap on a node:** Enters/descends into that node. The canvas smoothly zooms and animates transitions, making the tapped node the new center of the ego-graph.
   - **Swipe / Drag on a node:** Swiping horizontally across an active node performs a rapid level drill-down (or breadcrumb jump backward when swiping left).
   - **Pinch-to-zoom & Pan:** Fluid navigation around the local neighborhood.
4. Breadcrumbs at the top of the graph (`Progetto > Contenuti > Episodio 1`) allow instant one-tap return to any ancestor level.

---

### Journey 5: Progressive Dashboard Assembly
1. A newly created Project with only 1 child entity displays a **Nascent Stage Dashboard**:
   - Hero Header (Title, description, nature, status).
   - Focused Scratchpad / Stream.
   - Lightweight Folder Preview.
2. As the user connects tasks, budget, and additional sub-entities, the `ProjectScopeContext` detects the increased semantic depth:
   - When tasks > 0: The **Task & Action Horizon** module automatically appears.
   - When expenses/budget > 0: The **Financial & Resource Allocation** module unlocks.
   - When child entities > 4 across > 1 depth level: The **Ego-Graph Radar** module embeds into the dashboard.
   - When active threads > 0: The **Continuity & Recent Insights** module highlights unresolved thoughts.
3. The dashboard adapts dynamically: zero empty-state clutter when small, rich cockpit when deep.

---

### Journey 6: Pedagogical Discovery & Iconographic Guide
1. In the Project app bar, a subtle discovery icon (`Icons.hub_outlined` with `"Guida Progetti"`) is accessible.
2. Tapping it opens the `ProjectDiscoverySheet`:
   - Visual illustration of a Project as a root container.
   - Comparison chart: When to use Folders (structured tree, linear planning) vs. Graph (radial relationships, associative exploration).
   - Gesture cheatsheet: Single tap = Inspect, Double tap = Descend level, Swipe = Quick transit.
   - Reassurance that ideas never get lost: children inherit context from ancestors automatically.

---

## 2. Gherkin Acceptance Criteria

### Feature 1: Structured Capture Long-Press
```gherkin
Feature: Structured Project Capture via Long-Press

  Scenario: User long-presses send button with text in Universal Capture Bar
    Given the user is on the LifeOS screen or viewing the Bento Capture Widget
    And the capture text field contains "Ristrutturazione Studio Audio"
    When the user long-presses the send icon button (duration > 500ms)
    Then medium haptic feedback is triggered
    And the StructuredCaptureSheet opens modally
    And the title field is pre-populated with "Ristrutturazione Studio Audio"
    And the semantic role is set to "project" by default
    And the sub-idea quick entry field is focused and ready for input

  Scenario: User adds sub-ideas in the StructuredCaptureSheet
    Given the StructuredCaptureSheet is open with project title "Ristrutturazione Studio Audio"
    When the user types "Pannelli fonoassorbenti" into the sub-idea input and hits enter
    And the user types "Scrivania regolabile" and hits enter
    Then 2 child item chips are rendered under the sub-idea list
    And the submit button label updates to "Crea Progetto con 2 elementi"

  Scenario: Submitting the Structured Project
    Given the StructuredCaptureSheet contains 1 project title and 2 child items
    When the user taps "Crea Progetto con 2 elementi"
    Then a LifeEntity with role "project" is created in Supabase documents
    And two LifeEntity records are created for the child items
    And two EntityRelation records are created with relation_type "part_of" and target_id equal to the project ID
    And the sheet is dismissed
    And a confirmation snackbar appears with an "Apri Progetto" action
```

### Feature 2: Thread-Seguito (Contextual Thought Continuation)
```gherkin
Feature: Contextual Thought Threading

  Scenario: Appending a thought to an existing entity
    Given the user is viewing an existing LifeEntity detail screen
    When the user enters "Necessario verificare compatibilità XLR" into the thread input
    And taps the append button
    Then an EntityBlock of type "note" is appended to the entity's blocks list
    And the entity updated_at timestamp is refreshed
    And the new block is rendered at the tail of the stream with an animated fade-in
    And no modal navigation occurs
```

### Feature 3: Hierarchical Folder View
```gherkin
Feature: Project Folder View

  Scenario: Displaying multi-level hierarchical structure
    Given a Project entity has 3 direct children (Level 1)
    And one Level 1 child has 2 sub-children (Level 2)
    When the user opens the "Cartelle" tab of the Project
    Then all 3 Level 1 children are displayed in a clean indented list
    And the parent child shows an expand arrow and an item counter "(2)"
    When the user taps the expand arrow
    Then the 2 Level 2 sub-children animate into view with increased indentation
    And tapping any leaf item opens its preview without closing the tree
```

### Feature 4: Focused Ego-Graph View & Gestural Navigation
```gherkin
Feature: Focused Ego-Graph Navigation

  Scenario: Initial rendering of project ego-graph
    Given a project has 12 connected descendant nodes across 3 levels
    When the user opens the "Grafo" tab
    Then the root project node is rendered in the center
    And only the immediate Level 1 children (max 6 visible directly) are rendered radially
    And sibling or deeper clusters are represented as condensed cluster nodes
    And visual clutter is prevented

  Scenario: Single tap inspects node without navigating
    Given the ego-graph canvas is active
    When the user performs a single tap on a child node "Microfono"
    Then the node is highlighted with a focal ring
    And a bottom summary card displays "Microfono", its Nature, and connected counts
    And the current zoom level and graph position remain stable

  Scenario: Double tap descends into node level
    Given the ego-graph canvas is active
    When the user performs a double-tap gesture on a child node "Microfono"
    Then a smooth transition animation centers the canvas on "Microfono"
    And "Microfono" becomes the new focal root
    And its direct children are expanded radially
    And the breadcrumb trail appends "Microfono" at the top

  Scenario: Swipe gesture on node triggers quick level drill-down
    Given the ego-graph canvas is active
    When the user performs a horizontal right-swipe gesture directly across a node
    Then the canvas transitions directly into that node's sub-graph
```

### Feature 5: Progressive Dashboard Assembly
```gherkin
Feature: Progressive Dashboard Modular Skeleton

  Scenario: Nascent Project Dashboard
    Given a Project entity has only 1 note and no tasks or budget
    When the user opens the Project Dashboard
    Then the Hero header and Notes stream are rendered
    And Task horizon, Financial scope, and Graph radar modules are omitted
    And no empty-state placeholders ("Nessun task", "Nessun budget") clutter the screen

  Scenario: Dynamic module expansion as project deepens
    Given an existing Project entity
    When 2 tasks and a budget limit property are associated with the project
    Then the ProjectScopeContext recalculates
    And the Task Horizon widget appears seamlessly on the dashboard
    And the Financial Scope widget appears with budget allocation progress
```

### Feature 6: Pedagogical Discovery Sheet
```gherkin
Feature: Pedagogical Discovery and Onboarding

  Scenario: User opens project guide
    Given the user is on any Project detail screen
    When the user taps the "Guida Progetti" button in the app bar
    Then the ProjectDiscoverySheet slides up
    And displays the visual mental model: Project as root container
    And illustrates the difference between Folder View and Graph View
    And explains gesture shortcuts (Double tap to descend, single tap to inspect)
```

---

## 3. Non-Functional & Behavioral Invariants

1. **Graph Rendering Performance:** The custom graph painter must maintain 60 FPS (or 120 FPS on ProMotion/high-refresh mobile screens) during panning and zooming. Layout simulation must converge in < 15ms for graphs up to 100 nodes.
2. **Cycle Prevention:** A child node cannot be linked as `part_of` itself or any of its own descendants. Any attempt to form a circular containment loop must be intercepted and rejected with an explanatory notification.
3. **Graceful Offline Mode:** All tree and graph operations must work 100% offline using local cache. Edges and entities created offline queue in the local sync engine without UI blocking.
4. **Keyboard Responsiveness:** When adding sub-ideas in `StructuredCaptureSheet`, keyboard opening must not obscure the submit button or input field (`viewInsets.bottom` handled cleanly).
