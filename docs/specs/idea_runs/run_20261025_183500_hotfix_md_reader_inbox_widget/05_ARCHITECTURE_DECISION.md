# 05 — Architectural Decision Record (ADR)

## 1. Decision Title
**ADR-20261025-01: Risoluzione Strutturale del Lettore MD, Navigatore Inbox Canvas e Bento Stack Widget**

## 2. Status
**PROPOSED (SPEC_ONLY)**

## 3. Context & Problem Statement
L'utente ha riscontrato un bug bloccante nel lettore di file Markdown: aprendo un file `.md`, la tile del documento rimane collassata mostrando solo il titolo, rendendo il contenuto accessibile solo entrando in modalità di modifica. Inoltre, mancano controlli utente sulla visualizzazione ed è necessaria una sezione dedicata "File Markdown" nella tab Spazio strutturata come "Infinite Canvas", accompagnata da un Bento Widget di quick-view per la dashboard con la medesima UX/UI a swipe del widget Sticky Notes.

## 4. Alternatives Considered

### Alternativa A: Patch minimale hardcoded nel lettore
- **Descrizione**: Cambiare solo `limit: 999` o `_isEditing: true` in `StandaloneMarkdownPage`.
- **Valutazione**: Risolve superficialmente l'apertura ma non affronta la causa radice in `LiquidMarkdownEditor` (dove `limit <= 0` collassa indebitamente la visualizzazione), non fornisce impostazioni all'utente, e ignora i requisiti di Spazio e Dashboard.
- **Esito**: **SCARTATA** (Non rispetta il vincolo di "fixare profondamente").

### Alternativa B: Riscrivere da zero un nuovo lettore e canvas disaccoppiati
- **Descrizione**: Creare un visualizzatore separato e una pagina completamente nuova senza riusare l'infrastruttura di Infinite Canvas o il motore a schede di Bento.
- **Valutazione**: Introduce duplicazione massiccia di codice, deviazione grafica, disallineamento nei gesti e tempi di sviluppo incompatibili con un rilascio rapido e sicuro.
- **Esito**: **SCARTATA** (Sproporzionata e rischiosa per la stabilità).

### Alternativa C (Raccomandata): Bounded Deep Fix con Architettura a Riutilizzo Modulare
- **Descrizione**:
  1. **Fix Strutturale del Lettore**: Rendere esplicito in `LiquidMarkdownEditor` il parametro `isExpanded` (default `true` per standalone e nodi aperti), e svincolare il rendering di lettura dal solo `limit > 0`.
  2. **Configurazione Utente**: Aggiungere `MarkdownViewerSettingsSheet` e servizio `MarkdownSettingsService` con persistenza locale (Hive).
  3. **Navigatore Inbox in Spazio**: Implementare `MarkdownInboxCanvasView` estendendo/parametrizzando `InfiniteCanvasView` con root pre-ancorata alla cartella Inbox MD di sistema.
  4. **Bento Quick View Widget**: Creare `MarkdownStackWidget` riutilizzando il motore matematico di gesture/fisica 3D di `NoteStackWidget`, sostituendo la sorgente dati con i file dell'inbox MD.
- **Esito**: **APPROVATA**. Massimizza la coerenza visiva, risolve la causa radice alla base e consente una rapida implementazione e testabilità.

---

## 5. Consequences & Tradeoffs
- **Vantaggi**:
  - Risoluzione definitiva del bug di chiusura nel lettore.
  - Zero duplicazione di layout complessi (Canvas e Swipe Physics già testati e rifiniti).
  - Piena coerenza con il design system scuro e liquido di Solducci.
- **Mitigazioni**:
  - Evitare sovrapposizioni tra lo swipe delle card nel Bento Widget e lo scroll interno dei testi markdown tramite prioritizzazione su soglia di trascinamento elastico (`ClampingScrollPhysics` e gesture threshold a 40px).
