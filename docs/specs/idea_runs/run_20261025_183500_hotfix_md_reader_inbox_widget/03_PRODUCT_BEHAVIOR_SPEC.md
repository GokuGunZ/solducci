# 03 — Product Behavior Specification

## 1. Actor Stories

### US-01: Apertura Istantanea e Lettura Naturale di un Documento MD
- **Come** utente Solducci o utente che apre un file `.md` da un'altra applicazione (es. file manager Android),
- **Voglio** che all'apertura del lettore la card del documento sia espansa, formattata e immediatamente leggibile,
- **Affinché** possa consultare subito il contenuto del file senza dover cliccare o attivare la modalità di modifica.

### US-02: Controllo e Personalizzazione del Visualizzatore Markdown
- **Come** utente con preferenze di lettura specifiche,
- **Voglio** poter accedere a un menu/foglio impostazioni del lettore Markdown per regolare la dimensione dei caratteri (font size) e impostare le preferenze di apertura (default aperto/collassato, sola lettura vs interattivo),
- **Affinché** l'esperienza di fruizione dei documenti si adatti alle mie esigenze visive e operative.

### US-03: Navigazione Dedicata dei File Markdown nella Tab Spazio
- **Come** utente della sezione "Spazio",
- **Voglio** trovare una sezione "File Markdown" che apra una pagina visuale strutturata esattamente come Infinite Canvas,
- **Affinché** possa esplorare l'inbox dei file Markdown importati o aperti con Solducci in un ambiente grafico fluido a grafo/cartelle.

### US-04: Quick View & Swipe dei File Markdown sulla Dashboard
- **Come** utente della Dashboard Bento,
- **Voglio** aggiungere un widget di visualizzazione rapida dell'inbox MD identico nello stile e nell'UX a Sticky Notes,
- **Affinché** possa sfogliare i miei file Markdown direttamente dalla home con uno swipe fluido e consultarli in anteprima.

### US-05: Validazione su Smartphone Fisico prima della Release
- **Come** maintainer e product owner dell'app,
- **Voglio** che le modifiche vengano prima testate su branch `test` sul mio telefono fisico con conferma esplicita,
- **Affinché** sia garantito che l'hotfix non introduca regressioni prima del rilascio definitivo.

---

## 2. Interaction Flows & Scenarios

### Scenario 1: Apertura File Standalone
1. L'utente tocca un file `.md` nel gestore file Android oppure seleziona un file dalla lista recenti in Solducci.
2. L'app avvia la route `/markdown-viewer` con il parametro `filePath`.
3. Il file viene caricato in memoria da disco.
4. `LiquidMarkdownEditor` viene inizializzato con `defaultExpanded: true` (e `limit: -1` o flag equivalente).
5. Il titolo viene visualizzato in alto e il corpo del documento Markdown è **completamente visibile** con la tipografia formattata (headings, elenchi, code blocks, quote).
6. L'utente può scorrere verticalmente il testo in modo naturale.

### Scenario 2: Regolazione Impostazioni Lettore MD
1. Nella barra superiore di `StandaloneMarkdownPage`, l'utente tocca l'icona ingranaggio/impostazioni (`Icons.tune_rounded` o `Icons.settings_outlined`).
2. Si apre un bottom sheet elegante in tema dark (`MarkdownViewerSettingsSheet`):
   - Slider dimensione font (12pt – 26pt, con preview in tempo reale).
   - Switch: "Mostra documento aperto per impostazione predefinita" (default: true).
   - Switch: "Blocca modifiche (Sola lettura)" (permette di leggere senza rischio di trascinamento accidentale dell'onda di editing).
3. Le preferenze vengono salvate localmente in `SharedPreferences` o `Hive` e applicate istantaneamente a tutti i lettori markdown dell'app.

### Scenario 3: Accesso alla Sezione "File Markdown" in Spazio
1. L'utente naviga nella tab **Spazio** (`SpaceHomeView`).
2. Sotto la sezione dedicata ai documenti o al laboratorio visivo, è visibile la nuova tile:
   - Titolo: **File Markdown**
   - Sottotitolo: **Inbox e navigatore file Markdown (.md)**
   - Icona: `Icons.article_rounded` con sfondo accent indigo (`#6366F1`).
3. L'utente tocca la tile. L'app naviga verso `/space/markdown_inbox`.
4. La pagina renderizza l'infrastruttura di **Infinite Canvas**:
   - Header con breadcrumbs, zoom, ricerca, menu radiale omni-add.
   - Canvas zoomabile e navigabile.
   - Cartella radice pre-filtrata su **"Inbox Markdown"**, contenente tutti i documenti Markdown aperti e importati con Solducci.
   - Possibilità di aggiungere cartelle, importare nuovi `.md` da file picker, riorganizzare e aprire ogni file in editor liquido.

### Scenario 4: Utilizzo del Widget Markdown Stack in Dashboard
1. L'utente apre la Dashboard Bento, tocca "Aggiungi Widget" ed entra nella gallery.
2. Trova il widget **"MD Quick Stack"** (Visualizzazione Rapida Inbox MD) con preview a carte sovrapposte.
3. Seleziona le dimensioni preferite (2x2, 2x3 o 3x3) e lo posiziona sulla dashboard.
4. Il widget carica i file Markdown dell'inbox:
   - Mostra la prima card in primo piano con effetto 3D e profondità.
   - L'utente esegue uno swipe orizzontale o verticale: la card corrente scorre via con animazione elastica (spring physics), emette feedback aptico e lascia il posto alla card successiva.
   - Toccando due volte o toccando il pulsante espandi, si apre il file completo in `StandaloneMarkdownPage` o nel visualizzatore full-screen.

---

## 3. Edge Cases & Handling

1. **File Markdown vuoto o contenente solo spazi**:
   - Mostrare un placeholder discreto (`*Nessun contenuto nel documento*`) senza collassare la card.
2. **File Markdown gigantesco (> 500 KB / migliaia di righe)**:
   - Nel widget Bento Quick Stack: limitare l'anteprima alle prime 50 righe con indicatore "Continua a leggere..." per prevenire blocchi di memoria sul thread UI di Flutter.
   - Nel visualizzatore standalone: consentire rendering fluido tramite scrolling ottimizzato di `MarkdownBody`.
3. **File aperto da percorso esterno temporaneo Android (`content://`)**:
   - Il `main.dart` e il lettore devono gestire in modo trasparente la copia nella cache locale o la lettura dello stream senza crash.
4. **Zero file nell'Inbox Markdown**:
   - La pagina Canvas Inbox e il widget Bento mostrano uno stato vuoto chiaro con pulsante "+ Importa il tuo primo file MD".
