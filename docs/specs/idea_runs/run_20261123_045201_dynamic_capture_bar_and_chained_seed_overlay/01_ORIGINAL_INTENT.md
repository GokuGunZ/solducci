# 01 — ORIGINAL INTENT & USER DIRECTIVES

**Run ID:** `run_20261123_045201_dynamic_capture_bar_and_chained_seed_overlay`  
**Timestamp:** `2026-11-23T04:52:01+01:00`  
**Context:** LifeOS Input Bar Redesign, Chained Seed Capture Overlay, and "@" Mention Receptor  
**Origin:** Direct user dogfooding feedback on device after release v1.06.05.

---

## 1. Verbatim User Input

```text
Feedback dato dal mio usare LifeOS
@Solducci @LifeOsCenter 
Completo redesign del Input bar con diversi nuovi behaviour e concretizzazione di diversi concetti.
Form: 
- Rendere il form di altezza dinamica crescente con il numero di righe, e aggiungere l'opzione che la dimensione orizzontale è bloccata e quindi si va a capo, almeno nella visualizzazione, che aumenta di altezza appunto. aggiungere il seguente comportamento differenziato per una riga e più righe: dato che c'è l'icona a sinistra la prima si rimane alla sua destra, ma da quando ci sono due righe di testo in poi, il form si sposta nella riga sotto l'icona, allargandosi e quadagnando più spazio a sinistra e a destra (dall'icona di invio), il tutto con un animazione fluida di riposizionamento e allargamento del form. allo stesso tempo appare da dietro l'icona di invio il testo "Raccogli seme " con un effetto slide laterale che lo fa posizionare alla sinistra dell'icona di invio.
New Send UX
- Quando si invia, appare un overlay che oscura il resto della vista, tranne per il form di testo che nel frattempo si è trasformato in un box di testo "definitivo", anche se sopra appare invece di invio il tasto "edit". Questo overlay ha l'effetto di rappresentare una seconda vista sovrapposta che da la possibilità di continuare a raccogliere semi connessi a quelli precedente. questo avviene oltre che all'inscurimento e messa in secondo piano del resto della view, anche attraverso all'apparizione di una nuova barra di raccolta seme, subito sotto al box del seme appena raccolto, intermezzato solo da una scritta "Raccogli una catena di semi". Questa nuova interfaccia sovrapposta dovrà appunto permettere di raccogliere più semi in catena interconnessi.
Aggiungere al controller del form un recettore di tag, tramite l'uso del "@" che permette di creare connessioni tra il seme che si sta scrivendo e altri semi o entità più evolute del OS Center. Permettiamo due tipologie di connessioni, una "semplice", mente un altra di relazione di "figlio di", nel senso che una connessione semplice correla due semi, mentre la seconda indica che in qualche modo è seme che è figlio di uno più "grande" di lui. a livello di UX/UI, quando il tag viene fatto come prima cosa nel seme, in automatico si assume sua una correlazione figlia di, mentre se scritta in mezzo al testo diventa una correlazione semplice. Data la nuova UI nel quale la prima riga rimane vuota se non occupata dalle due icone, perché il form si è spostato sotto, questa diventa zona per raggruppare i vari tag. Questi sono di fatto delle chip tappabili per mostrare un pop up che indica il tipo di collegamento e ha uno switch per cambiarlo, con una UI/UX ben ideata e premium.
```

---

## 2. Intent Deconstruction: Explicit vs. Inferred

### A. Dynamic Multiline Input Bar Layout & Spatial Morphing
- **Explicit Directives:**
  1. **Dynamic Vertical Height:** Text field height must grow organically with the number of written lines; horizontal width is constrained so text wraps instead of scrolling horizontally off-screen.
  2. **Differentiated 1-Line vs. Multi-Line Behavior:**
     - *Single-line (1 riga):* Inline single-row layout with leading icon on the left, TextField in the middle, and send icon on the right.
     - *Multi-line (>= 2 righe):* The TextField relocates into a new row *underneath* the icons row, expanding horizontally to full container width (gaining the horizontal margin previously taken by the left icon and the right send button).
     - *Fluid Animation:* The transition between single-line and multiline states must animate smoothly (repositioning, height expansion, width stretch).
     - *Slide-in Label:* In the multiline state, a text label `"Raccogli seme "` smoothly slides out from behind the send button to sit immediately to its left.
- **Inferred Product Needs:**
  - Need an accurate text-measurement or layout listener (`TextPainter` or line calculation on `TextEditingController` changes) to trigger the spatial transition without glitchy layout jumps.
  - Smooth animation using `AnimatedCrossFade`, `AnimatedSize`, and `SlideTransition`/`AnimatedOpacity`.

### B. New Send UX & Chained Seed Overlay ("Raccogli una catena di semi")
- **Explicit Directives:**
  1. **Dimmed Modal Overlay:** When Send is tapped, a translucent dark scrim dims the rest of the view, placing the background into a defocused second plane.
  2. **Committed Text Box Transformation:** The original text form morphs into a finalized/committed read-only card ("box di testo definitivo").
  3. **Edit Action:** The send button on this card is replaced by an `"Edit"` button, enabling the user to re-open/modify the committed seed if needed.
  4. **Chained Collection Strip:** Directly below the finalized card, a transitional header displays `"Raccogli una catena di semi"`.
  5. **New Input Bar for Next Link:** Directly underneath the header, a fresh active capture bar appears.
  6. **Interconnected Seed Chain:** Any subsequent seed captured through this chained interface is automatically linked to the preceding seed (or chain root) in the graph.
- **Inferred Product Needs:**
  - Need a clear dismissal or confirmation mechanism (e.g. tapping the dimmed background, a "Fine / Concludi catena" button, or Android back gesture) that finalizes the chain and refreshes the LifeOsCenter list.
  - Relation type between chain links: sequentially linked via `EntityRelation` (`partOf` or `relatesTo`), maintaining chain order (`metadata: {'chain_order': index, 'chain_root_id': rootId}`).

### C. "@" Tag Mention Receptor & Semantic Connections
- **Explicit Directives:**
  1. **"@" Mention Receptor:** In the input controller, typing `@` triggers an entity picker to link the current seed to existing seeds or evolved entities (Projects, Concepts, Practices) in LifeOS.
  2. **Two Connection Types Supported:**
     - *"Figlio di" (Child of / `RelationType.partOf`):* Indicates the new seed belongs to or is subordinate to a larger entity.
     - *"Semplice" (Simple Correlation / `RelationType.relatesTo`):* Symmetric or peer conceptual association.
  3. **Automatic Position-Based Defaulting:**
     - If `@entity` is placed as the *first* token of the seed, it automatically defaults to **"figlio di"**.
     - If `@entity` is placed in the *middle* of the text, it automatically defaults to **"semplice"**.
  4. **Top Row Tag Grouping (Multi-Line State):**
     - When the text field drops to row 2, the top row space between the leading icon and the send button/label becomes the container for active tag chips.
  5. **Interactive Tag Chips with Modal Toggle:**
     - Each tag chip is tappable.
     - Tapping opens a premium popup/sheet displaying the entity name, current connection type, and an interactive switch/toggle to switch between "Figlio di" and "Semplice" (plus delete/detach option).

---

## 3. Scope Boundaries & Constraints
- **Zero Schema Migrations:** All relations are represented using the existing `entity_relations` table (`source_id: newSeed.id`, `target_id: taggedEntity.id`, `relation_type: RelationType.partOf` or `RelationType.relatesTo`).
- **Offline & Optimistic Integrity:** Mentions query the local cached entities loaded by `LifeOsCenterCubit` or `LifeEntityRepository.getEntities()`.
- **Haptic & Visual Polish:** Haptic feedback on tag insertion, state changes, and chain submission matching Solducci's high-end dark glassmorphism theme.
