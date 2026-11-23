# 04 — Domain and Data Model

## 1. Domain Entities & Identity

### A. Entità `MarkdownSettings`
Modello per la persistenza delle preferenze utente del lettore Markdown.
- **Storage**: Hive box `markdown_preferences` o `SharedPreferences`.
- **Campi**:
  - `defaultExpanded`: `bool` (default: `true`) — se il lettore apre le card con il testo visibile.
  - `fontSize`: `double` (default: `14.5`, range: `11.0` - `26.0`) — dimensione carattere del testo CommonMark.
  - `readOnlyLock`: `bool` (default: `false`) — se attivato, disabilita il gesto di pull-down per l'onda di editing.
  - `codeFontMonospace`: `bool` (default: `true`) — font monospazio per blocchi di codice.

### B. Entità `CanvasNode` (Estensione Morfologica per Inbox MD)
L'entità `CanvasNode` esistente (`lib/features/space/models/canvas_node.dart`) gestisce già nodi ad albero con `type: 'folder'` e `type: 'markdown'`.
- Per modellare la cartella Inbox dei file Markdown:
  - Viene definita una cartella di sistema speciale:
    - `id`: `'inbox_markdown_root'` (oppure deterministica per utente: `'inbox_md_${userId}'`).
    - `parentId`: `null` (nodo radice).
    - `title`: `'Inbox File MD'`.
    - `type`: `'folder'`.
    - `metadata`: `{'isSystemInbox': true, 'icon': 'article', 'color': 0xFF6366F1}`.
- Per ogni file aperto o importato:
  - Viene creato o aggiornato un `CanvasNode`:
    - `id`: generato (o derivato da hash/path del file).
    - `parentId`: `'inbox_markdown_root'`.
    - `type`: `'markdown'`.
    - `title`: nome del file (senza estensione `.md`).
    - `payload`: `{'text': content, 'filePath': originalPath}`.
    - `metadata`: `{'source': 'import_or_external', 'lastOpenedAt': timestamp}`.

---

## 2. Synchronization & Storage Lifecycle

```
[File Esterno / Intent / FilePicker]
              │
              ▼
    [MarkdownInboxService]
              │
      ┌───────┴───────────────────┐
      ▼                           ▼
[CanvasLocalRepository]    [RecentMarkdownService]
(Nodi Canvas Inbox MD)     (Cronologia rapida recenti)
      │
      ├───────────────────────────┬───────────────────────────┐
      ▼                           ▼                           ▼
[StandaloneMarkdownPage]   [MarkdownInboxCanvasView]   [MarkdownStackWidget]
(Visualizzatore singolo)   (Navigatore ad albero)      (Bento Swipeable Stack)
```

1. **Apertura File**:
   - `MarkdownInboxService.registerOpenedFile(path, name, content)` salva il documento sia nello storico recenti che nel nodo Canvas all'interno di `Inbox File MD`.
2. **Aggiornamento Contenuto**:
   - Qualsiasi modifica effettuata nel visualizzatore o in canvas aggiorna il file su disco locale (se accessibile) e il payload del `CanvasNode`.
3. **Multi-User & Context Scoping**:
   - I nodi inbox appartengono al contesto corrente (`userId` o `groupId`), garantendo pieno isolamento e rispetto delle Row-Level Security rules se sincronizzati su Supabase.
