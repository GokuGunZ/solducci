# 06 — UX & Interaction Specification

## 1. Design Principles & Consistency
L'esperienza deve rispettare rigorosamente le linee guida del design system di Solducci:
- Sfondo profondo Obsidian: `#09090B` / `#0F172A`.
- Card con vetro satinato, bordi sottili semi-trasparenti (`rgba(255, 255, 255, 0.05)`) e raggio di curvatura di 12–20px.
- Colore d'accento principale: Indigo `#6366F1` e Cyan/Sky `#0EA5E9`.
- Tipografia markdown fluida e monospazio ad alta leggibilità per i blocchi di codice.
- Microinterazioni con feedback aptico leggero (`HapticFeedback.lightImpact()` e `HapticFeedback.selectionClick()`).

---

## 2. Component Layouts

### A. Standalone Markdown Reader
- **App Bar**:
  - Tasto indietro con icona `Icons.arrow_back_ios_new_rounded`.
  - Nome del file e icona indicatore di salvataggio.
  - Azione 1: Icona Impostazioni (`Icons.tune_rounded`) che apre il pannello di controllo.
  - Azione 2: Icona Modifica (`Icons.edit_note_rounded`) per commutazione manuale se l'utente desidera editare senza gesture.
- **Corpo del Documento**:
  - Visualizzato **aperto di default**.
  - Card espansa con padding `16px`.
  - Testo CommonMark con intestazioni scalate proporzionalmente, elenchi con bullet stilizzati in indigo, citazioni con bordo sinistro colorato e sfumatura trasparente.

### B. Foglio Impostazioni Lettore (`MarkdownViewerSettingsSheet`)
- Presentazione in modal bottom sheet arrotondato (top radius 24px) con maniglia superiore di trascinamento.
- **Controlli**:
  1. *Dimensione Testo*: Slider continuo con etichetta numerica (es. "15 pt") e preview immediata.
  2. *Stato Iniziale*: Switch toggle "Apri sempre documento per intero" (Default: ON).
  3. *Protezione da Modifiche Accidantali*: Switch toggle "Modalità Sola Lettura" (disattiva l'onda fisica di modifica).
  4. *Pulsante Reset*: Ripristina i valori predefiniti di fabbrica.

### C. Sezione "File Markdown" nella Tab Spazio
- Tile posizionata nella tab Spazio sotto `Laboratorio & Visuale` o `Pensieri & Attività`:
  - Icona: `Icons.article_rounded` in box indigo (`rgba(99, 102, 241, 0.14)`).
  - Titolo: **File Markdown** (White, 16px bold).
  - Sottotitolo: **Inbox e navigatore file Markdown (.md)** (White54, 13px).
  - Bordo luminoso indigo sottile con effetto glow al tocco.
- **Pagina di Destinazione (`/space/markdown_inbox`)**:
  - Interfaccia identica a **Infinite Canvas**:
    - Breadcrumbs in testata (`Inbox MD > Cartella ...`).
    - Barra controlli con zoom, riallineamento e menu omni-add.
    - Area canvas a grafo con drag and pan fluido.
    - Visualizzazione esclusiva della gerarchia originata dall'Inbox dei file Markdown.

### D. Bento Widget Quick View: "MD Inbox Stack"
- **Ispirazione Diretta**: `NoteStackWidget`.
- **Anatomia della Card**:
  - Card tridimensionale con rotazione d'angolo lieve (`angle = dx * 0.0005`), ombra proiettata e gradiente scuro.
  - Testata con icona file `.md`, titolo del documento e data ultimo accesso.
  - Corpo con render markdown formattato ad altezza dinamica.
  - Badge in basso a destra con indicatore numerico dello stack (es. `1 / 4`).
- **Gestualità**:
  - **Swipe Orizzontale o Verticale**:
    - Superamento soglia di 40px o velocità > 400px/s: espulsione della card corrente con effetto spring, feedback aptico e transizione fluida verso il file successivo.
    - Ritorno elastico se il trascinamento viene rilasciato prima della soglia.
  - **Doppio Tap**: Apertura a tutto schermo in `StandaloneMarkdownPage`.
