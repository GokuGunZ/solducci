# 06 — UX AND INTERACTION SPECIFICATION

**Run ID:** `run_20261031_211008_project_graph_and_progressive_dashboard`  
**Git Branch:** `release/v1.06.01`  
**Status:** DRAFT SPECIFICATION  
**Surfaces:** Structured Capture Sheet, Project Scaffold, Folder View, Interactive Ego-Graph, Pedagogical Guide  

---

## 1. Structured Capture BottomSheet (`StructuredCaptureSheet`)

Triggered by **long-pressing the send button (`↑`)** in either `UniversalCaptureBar` or the Bento `LifeOsCaptureWidget`.

### 1.1 Visual Layout & ASCII Wireframe
```text
┌────────────────────────────────────────────────────────┐
│                        ════                            │  <-- Drag Handle
│  Nuovo Progetto Strutturato               [ Chiudi ]   │
│                                                        │
│  [ Progetto  ▼ ]   [ Natura: Concettuale ▼ ]            │  <-- Role & Nature Pills
│                                                        │
│  TITOLO PROGETTO                                       │
│  ┌──────────────────────────────────────────────────┐  │
│  │ Lancio Podcasting Solducci                       │  │  <-- Auto-populated from bar
│  └──────────────────────────────────────────────────┘  │
│                                                        │
│  SOTTO-IDEE O ENTITÀ COLLEGATE (Opzionale)             │
│  ┌──────────────────────────────────────────────────┐  │
│  │ [+ Aggiungi pensiero o sotto-idea...          ]  │  │  <-- Inline quick adder
│  └──────────────────────────────────────────────────┘  │
│                                                        │
│  Elenco elementi iniziali:                             │
│  (●) Microfono Shure MV7                 [ × ]         │
│  (●) Scaletta Episodio 1                 [ × ]         │
│                                                        │
│  [ + Collega entità esistente... ]                     │  <-- Search existing entities
│                                                        │
│  ┌──────────────────────────────────────────────────┐  │
│  │        CREA PROGETTO CON 2 ELEMENTI              │  │  <-- Dynamic Primary CTA
│  └──────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────┘
```

### 1.2 Interaction Rules
- **Activation:** 400ms hold on send button triggers `HapticFeedback.mediumImpact`. The text currently in the capture input is transferred directly into the Project Title field.
- **Micro-Input for Sub-Ideas:** Pressing `Enter` / `Done` on the keyboard adds the chip immediately and clears the micro-input for the next item without dismissing the keyboard.
- **Dismissal & Commit:** Tapping the primary CTA commits the transaction in a single batch (root entity + child entities + `part_of` relations) and shows a floating snackbar with `"Apri Progetto"`.

---

## 2. Project Detail Scaffold & View Switcher

When viewing an entity with `role == SemanticRole.project`, the standard Vitrine view adapts to provide high-level modal switching between:
1. **Panoramica (Dashboard):** Progressive dynamic widgets.
2. **Cartelle (Folders):** Hierarchical indented tree projection.
3. **Grafo (Graph):** Interactive focused ego-graph canvas.

```text
┌────────────────────────────────────────────────────────┐
│  ← Progetti / Podcast              [ ℹ️ Guida ]  [ ⋯ ]  │  <-- Top Bar with Breadcrumbs & Guide
│                                                        │
│  ┌──────────────────────────────────────────────────┐  │
│  │ [ Panoramica ]   [ Cartelle ]   [ Grafo ]        │  │  <-- Segmented View Control
│  └──────────────────────────────────────────────────┘  │
│                                                        │
│  [  ... Selected View Content Area ...              ]  │
│                                                        │
│  ┌──────────────────────────────────────────────────┐  │
│  │ [ 💬 Aggiungi pensiero in coda al progetto... ]  │  │  <-- Sticky Thread Composer
│  └──────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────┘
```

---

## 3. Hierarchical Folder View (`ProjectFolderView`)

Projects organize knowledge naturally into levels. The Folder View provides a clean, zero-distraction tree projection.

### 3.1 Visual Structure
```text
▼ 📁 Lancio Podcasting Solducci (Root)
    ├─ 📄 Brief Concettuale e Obiettivi
    ├─ ▼ 📁 Setup Hardware & Audio (2)
    │      ├─ 📦 Microfono Shure MV7
    │      └─ 📦 Asta & Filtro Antipop
    ├─ ▼ 📁 Episodi & Contenuti (3)
    │      ├─ 📝 Scaletta Episodio 1
    │      ├─ 📝 Intervista Ospite A
    │      └─ 📝 Sound Design Outro
    └─ [ + Aggiungi elemento in questa cartella ]
```

### 3.2 Interaction Specs
- **Expand / Collapse:** Tapping the folder chevron toggles the branch with an 180ms ease-in-out height animation.
- **Tap on Leaf Item:** Slides open a quick-peek drawer or navigates directly to the entity detail.
- **Reordering & Reparenting:** Long-press drag on an item allows dropping it into another folder, automatically updating its `part_of` relation target.

---

## 4. Focused Ego-Graph Canvas (`ProjectGraphView`)

To satisfy the user's explicit directive against visual clutter and standard single-click navigation:
> *"una navigazione che mette il focus su pochi vicini oltre al livello selezionato... l'ingresso in un livello successivo non deve essere dato dal semplice click di un nodo ma bensì da un interazione diretta (doppio tap o swipe direttamente su un grafo)"*

### 4.1 Ego-Graph Topology
```text
                     [ Setup Audio ]
                    (Cluster Pill: 2)
                           ▲
                           │
      [ Hardware ] ◄── ( PROGETTO ) ──► [ Contenuti ]
       (Child Node)      (Focal Root)    (Child Node)
                           │
                           ▼
                   (Cluster Pill: 3)
                   [ Note & Varie ]
```

### 4.2 Interaction & Gesture Matrix
| Gesture | Target | System Response | Visual Feedback |
| :--- | :--- | :--- | :--- |
| **Single Tap** | Any Node | **Selects & Inspects.** Does NOT navigate. | Node emits a glowing selection ring; bottom summary card slides up with node title, nature, block count, and direct actions. |
| **Double Tap** | Child Node | **Descends into Level.** Makes tapped node the new focal root. | Canvas performs a smooth 300ms zoom-in camera transition; child node smoothly moves to center; its immediate sub-nodes bloom radially; breadcrumb updates at top. |
| **Horizontal Swipe** | Selected Node | **Direct Level Transit.** Swiping right drills down; swiping left ascends one level up. | Inertial sliding transition between graph hierarchies with light haptic tick. |
| **Pinch-to-Zoom** | Background | Scales canvas between 0.5x and 2.5x. | Radial grid background smoothly scales. |
| **Pan / Drag** | Background | Pans canvas smoothly across the local neighborhood. | Velocity-based inertial glide with soft bounce at limits. |

### 4.3 Node Inspection Peek Card (Single Tap)
When a node is tapped once, a compact floating card appears at the bottom of the graph:
```text
┌────────────────────────────────────────────────────────┐
│  📦 Microfono Shure MV7        [ Natura: Materiale ]   │
│  2 blocchi di note • Collegato a 1 spesa stimata       │
│                                                        │
│  [ Doppio tap per entrare ]      [ Apri Dettaglio ↗ ]  │
└────────────────────────────────────────────────────────┘
```

---

## 5. Pedagogical Discovery Sheet (`ProjectDiscoverySheet`)

Accessible via the `[ ℹ️ Guida ]` icon in the project app bar.

### 5.1 Content Modules
1. **Il Progetto come Contenitore e Nodo Radice:**  
   Illustrates how a Project is not just a static page, but the root of a living tree of ideas, materials, and actions that inherit its context.
2. **Cartelle vs. Grafo: Due Occhi per la Stessa Realtà:**  
   - *Cartelle:* Per pianificare, ordinare, e avere chiarezza gerarchica lineare.
   - *Grafo:* Per esplorare associazioni, vedere la costellazione di elementi e cogliere connessioni trasversali.
3. **I Gesti nel Grafo (Guida Rapida):**  
   - *1 Tap:* Ispeziona e leggi un'anteprima senza muovere la mappa.
   - *2 Tap:* Entra dentro il nodo ed esplora le sue sotto-idee.
   - *Swipe:* Scivola velocemente tra i livelli del progetto.
4. **Dashboard Progressiva:**  
   Spiega che la pagina cresce e si arricchisce automaticamente man mano che il progetto raccoglie compiti, budget e riflessioni.

---

## 6. Accessibility & Theme Integration

- **Dark & Light Mode:** High-contrast SVG node markers with distinct Nature colors (Material = Amber/Bronze, Digital = Cyan, Conceptual = Purple, Social = Emerald).
- **Reduced Motion Support:** If system accessibility specifies reduced motion, graph zoom transitions change to a clean 100ms fade.
- **Screen Reader Semantics:** The folder view provides full hierarchical screen reader labels (`"Cartella Setup Audio, livello 1 di 2, contiene 2 elementi"`).
