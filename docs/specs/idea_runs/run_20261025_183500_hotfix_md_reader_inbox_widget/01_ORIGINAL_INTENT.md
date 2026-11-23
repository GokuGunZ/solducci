# 01 — Original Intent & Requirements Extraction

## 1. Verbatim Original User Input
- **Timestamp (Local)**: 2026-10-25T18:32:16+01:00
- **Input Encoding**: UTF-8
- **SHA-256 Hash**: `a4c45190d0918f0b4852eca4f6b52d3b9713fb3f6bcb76cd6df8134c0f03720c`

```text
Hotfix da fixare profondamente e rilasciare in fretta. subito prima di rilasciare faremo un push tu test, cosi provo io sul mio telefono e ti do xonferma di chiusura, e poi prosegui con il rilascio. Il lettore di file MD è buggato: quando ne apro uno, si vede il tutolo ma la tile del file markdown rimane chiusa e non posso vederlo, rissco a vederlo solo se entro in modalita modifica. aggiungi delle impostazioni per avere piu controllo, e lascia di default che il documento è aperto e si vede. bisogna poi aggiungere una sezione "File Markdown" nella tab Spazio, in cui si va in una nuova pagina, fatta esattamente come "Infinite Canvas", solo che ha solo la cartella degli invox dei file MD e si possono navigare quelli importati/aperti con solducci. Aggiungere poi un widget di visualizzazione rapida degli inbox dei file md che ha lo stesso identico stile e UI/UX del widget sticky notes, solo che l'elemento che swipi è il visualizzatore markdown.
```

---

## 2. Structured Intent Analysis

### A. Explicit Intent (Requisiti Letterali Dichiarati)
1. **Urgenza & Qualità Operativa ("Hotfix profondo e veloce")**:
   - Trattare l'intervento con standard da hotfix critico, ma eseguito in modo robusto e strutturale ("fixare profondamente").
2. **Release Workflow con Staging su Branch di Test e Verifica Fisica**:
   - Prima del rilascio effettivo in produzione/main, eseguire il push sul branch `test`.
   - L'utente compilerà/testerà la build direttamente sul proprio smartphone fisico.
   - Il merge/release prosegue solo dopo esplicita conferma umana di chiusura.
3. **Risoluzione Bug nel Lettore di File MD (`StandaloneMarkdownPage` / `LiquidMarkdownEditor`)**:
   - Quando un file Markdown viene aperto, viene visualizzato solo il titolo nella testata, mentre la card/tile del corpo markdown rimane chiusa/collassata.
   - Il contenuto del file è visibile unicamente entrando in modalità di modifica.
   - Comportamento richiesto: per impostazione predefinita il documento deve essere **aperto e visibile** immediatamente all'apertura.
4. **Pannello Impostazioni e Controllo del Lettore MD**:
   - Aggiungere controlli/impostazioni di visualizzazione per dare all'utente piena gestione (es. dimensione testo, stato di apertura di default, modalità lettura vs editing).
5. **Nuova Sezione "File Markdown" nella Tab "Spazio" (`SpaceHomeView`)**:
   - Aggiungere una sezione/tile dedicata ai file Markdown all'interno dell'hub Spazio.
   - La tile apre una nuova pagina creata con la medesima struttura, architettura visiva e interattiva di **"Infinite Canvas"** (`InfiniteCanvasView`).
   - La pagina contiene la cartella Inbox dedicata ai file MD e consente di navigare tutti i file Markdown importati o aperti con Solducci.
6. **Widget Dashboard di Visualizzazione Rapida (Twin di Sticky Notes / `NoteStackWidget`)**:
   - Creare un nuovo Bento Widget per la dashboard che replica fedelmente lo stile, l'ergonomia gestuale (swipe orizzontale e verticale, stack tridimensionale a carte sovrapposte) del widget Sticky Notes (`NoteStackWidget`).
   - Differenza cardine: l'elemento sfogliabile/swipabile nello stack è il visualizzatore Markdown con il rispettivo file MD dall'inbox.

---

### B. Inferred Product Needs (Requisiti Impliciti Derivati)
1. **Root Cause del Bug di Collasso**:
   - In `LiquidMarkdownEditor`, la condizione di rendering del corpo è `if (widget.limit > 0 || _isEditing)`.
   - In `StandaloneMarkdownPage`, il widget viene istanziato senza specificare `limit` (valore predefinito: `0`) e con `autoOpenEditor: false` (`_isEditing: false`).
   - Di conseguenza `(0 > 0 || false)` valuta a `false`, impedendo il rendering del corpo CommonMark fino all'attivazione dell'editing.
2. **Persistenza & Connessione dell'Inbox MD**:
   - Attualmente `RecentMarkdownService` memorizza unicamente fino a 5 percorsi recenti in una box Hive locale non sincronizzata con Canvas.
   - Affinché la vista clone di Infinite Canvas e il widget swipeable operino in sincronia, i file aperti/importati devono essere agganciati al modello a nodi (`CanvasNode` con `type: 'markdown'`) o raggruppati deterministicamente sotto una root node/folder di sistema denominata `Inbox Markdown`.
3. **Isolamento e Compatibilità Context/Multi-User**:
   - I file Markdown dell'inbox devono rispettare il contesto attivo di Solducci (`userId` personale o `groupId`), prevenendo leakage tra contesti.
4. **Prestazioni dello Stack Widget con Documenti Complessi**:
   - Lo stack del Bento Widget richiede rendering fluido durante il trascinamento gestuale (`DragUpdateDetails`). A differenza di note testuali brevi, un documento markdown può contenere centinaia di righe. È necessario ottimizzare l'altezza massima del viewport del widget e implementare scroll interno virtualizzato senza confliggere con il gesture recognizer dello swipe.

---

### C. Confirmed Facts vs Inferences

| Aspetto | Stato | Evidenza |
| :--- | :--- | :--- |
| Bug corpo chiuso nel lettore | **Fatto Confermato** | `lib/widgets/liquid_markdown_editor.dart` riga 410: `if (widget.limit > 0 || _isEditing)` collassa il body se `limit == 0`. |
| Assenza di `limit` in Standalone | **Fatto Confermato** | `lib/views/standalone_markdown_page.dart` riga 98-109: invoca `LiquidMarkdownEditor` senza parametro `limit`. |
| Tab Spazio con sezioni modulari | **Fatto Confermato** | `lib/features/space/views/space_home_view.dart` riga 52-124 contiene liste di sezioni con tile verso routes dedicate. |
| Esistenza di Infinite Canvas | **Fatto Confermato** | `lib/features/space/views/infinite_canvas_view.dart` gestisce visualizzazione e albero di `CanvasNode`. |
| Esistenza del widget Sticky Notes | **Fatto Confermato** | `lib/widgets/dashboard/widgets/note_stack_widget.dart` implementa lo stack swipeable 3D con fisiche personalizzate. |
| Branch `test` presente sul remote | **Fatto Confermato** | `origin/test` è presente nei remote branches di Solducci. |
