# 02 — Repository Reality & Codebase Grounding

## 1. Git Repository State
- **Repository Path**: `C:\Users\Aless\Documents\Projects\Solducci`
- **Active Branch**: `new_design` (tracking `origin/new_design`)
- **HEAD Commit SHA**: `6b1b04ec1358bedc7d5bb6aefd6710a5c2d58672`
- **Remote Origin**: `https://github.com/GokuGunZ/Solducci.git`
- **Remote Branches Identificate**:
  - `origin/new_design`
  - `origin/test` (Target per staging su device)
  - `origin/develop`
  - `origin/main`
  - `origin/release/v1.03.00`, `origin/release/v1.04.00`
  - `origin/hotfix/v1.03.01`
- **Working Tree Cleanliness**:
  - Piattaforme native autogenerate con diff minime (`windows/`, `linux/`, `macos/`).
  - Spazio spec isolato in `docs/specs/idea_runs/`.

---

## 2. Component Inspection & Concrete Symbols

### A. Lettore Markdown Standalone
- **File**: `lib/views/standalone_markdown_page.dart`
- **Simboli**:
  - `StandaloneMarkdownPage` (`StatefulWidget`, L6-13)
  - `_StandaloneMarkdownPageState` (`State<StandaloneMarkdownPage>`, L15-113)
  - `_loadFile()` (L27-58) legge da `File(widget.filePath)` e registra in `RecentMarkdownService().addFile()`.
  - `LiquidMarkdownEditor` (L98-109):
    ```dart
    LiquidMarkdownEditor(
      initialText: _content,
      initialTitle: _fileName.replaceAll('.md', ''),
      autoOpenEditor: false,
      maxWidth: MediaQuery.of(context).size.width - 32,
      onTextChanged: (newText) { _content = newText; },
      onSave: () { _saveFile(_content); },
    )
    ```
- **Fattore Critico**: Non passa `limit` (che ha default `limit = 0`), né parametri di configurazione dello stato aperto.

### B. Widget `LiquidMarkdownEditor`
- **File**: `lib/widgets/liquid_markdown_editor.dart`
- **Simboli**:
  - `LiquidMarkdownEditor` (L8-42)
  - `_LiquidMarkdownEditorState` (L44-637)
  - **Condizione Bloccante del Preview** (L410):
    ```dart
    if (widget.limit > 0 || _isEditing) ...[
      const SizedBox(height: 12),
      ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
        child: SingleChildScrollView(
          child: MarkdownBody(
            data: _textController.text.isEmpty ? '*Tocca e tira per scrivere un appunto...*' : _textController.text,
            ...
    ```
  - **Fattore Critico**: Quando `widget.limit == 0` e `!_isEditing`, il widget non mostra il corpo del documento markdown. Rende unicamente l'intestazione col titolo (`_titleController.text`).

### C. Sezione Spazio e Infinite Canvas
- **File**: `lib/features/space/views/space_home_view.dart`
  - Contiene `ListView` (L48-126) con sezioni `Pensieri & Attività`, `Casa & Quotidiano`, `Laboratorio & Visuale`.
  - La route `/space/infinite_canvas` è attualmente associata a `InfiniteCanvasView`.
- **File**: `lib/features/space/views/infinite_canvas_view.dart`
  - Simbolo: `InfiniteCanvasView` (L21-29), `_InfiniteCanvasViewState` (L31-1705).
  - Utilizza `CanvasTreeController` (`lib/features/space/controllers/canvas_tree_controller.dart`).
  - Utilizza `CanvasLocalRepository` per accedere e persistere i nodi (`CanvasNode`).
  - L'importazione di file `.md` tramite `FilePicker` (L307-331) crea già nodi con `type: 'markdown'`.

### D. Widget Sticky Notes (Note Stack)
- **File**: `lib/widgets/dashboard/widgets/note_stack_widget.dart`
- **Simboli**:
  - `NoteStackWidget` (L18-25), `_NoteStackWidgetState` (L27-1663).
  - Implementa gesture recognizer su `DragUpdateDetails` e `DragEndDetails` (L179-250) sia orizzontali che verticali per lo sfogliamento a carosello con haptic feedback e spring simulation.
  - Registrazione nel Bento Mosaic Engine:
    - `lib/widgets/dashboard/dashboard_widget_factory.dart` (L86-87)
    - `lib/widgets/dashboard/config/bento_widget_config_registry.dart` (L47-49)
    - `lib/widgets/dashboard/gallery/bento_widget_preview_factory.dart` (L134-135)
    - `lib/widgets/dashboard/widget_gallery_sheet.dart`

---

## 3. Discrepanze e Lacune Rilevate nel Repository

1. **Assenza di una Categoria Inbox Distinta in Canvas**:
   - Quando `InfiniteCanvasView` importa un file, lo inserisce come nodo generico (`CanvasNode`) nella radice o nella cartella attiva.
   - Non esiste attualmente una cartella o flag di sistema denominato `Inbox File MD` riservato ai documenti aperti tramite Intent o importati per visualizzazione rapida.
2. **Disconnessione tra `RecentMarkdownService` e `CanvasLocalRepository`**:
   - `RecentMarkdownService` utilizza Hive (`recent_markdowns`) con max 5 file salvando solo percorso e nome file, senza legarsi a `CanvasNode`.
   - Per supportare una vista Infinite Canvas dedicata all'Inbox MD e uno swipeable widget coerente, i file aperti devono generare o aggiornare nodi indicizzati nell'inbox.
3. **Mancanza di Impostazioni Utente per il Visualizzatore MD**:
   - Attualmente non esistono impostazioni persistenti per la visualizzazione Markdown (font size globale del lettore, wrapping, modalità di apertura di default).
