# 01 — Original Intent & Requirements Extraction

## 1. Verbatim Original User Input
- **Timestamp (UTC/Local)**: 2026-10-31T21:10:08+01:00
- **Input Encoding**: UTF-8
- **SHA-256 Hash**: `7fecf2b2ae4698c0c82a64993ffeb820addc59aabe67dd9bec17746ea9141fce`
- **File Reference**: [`raw_input.txt`](file:///C:/Users/Aless/Documents/Projects/Solducci/docs/specs/idea_runs/run_20261031_211008_project_graph_and_progressive_dashboard/raw_input.txt)

```text
Creare il modo per aggiungere direttamente pensieri aggiunti ad un altra entità, come thread-seguito della cosa, e pensare di più questa cosa della connessione di elementi e di come questi si approfondiscono
Quando mi viene in mente di creare un nuovo progetto, utilizzand9 la barra di inserimento (widget o direttamente nella pagina di lifeos) tieni premuto invia e apre un bottomsheet dal quale selezioni rapidamente progetto, e se vuoi aggiungere alcune altre "idee" o entità all'interno del progetto. Poi l'entità progetto è come se è il root node del grafo associato ad esso, ed è una sorta di contenitore, che contiene i suoi figli e indirettamente anche tutti i figli che nascono dopo. chiaramente i progetti hanno diverse modalità di essere visti, sia a cartelle proiettando i vari livelli, che con un grafico in cui navigi il grafo direttamente e interattivamente, ma approfondendolo ma mano, con una navigazione che mette il focus su pochi vicini oltre al livello selezionato, (di default rispetto ad un livello di uno specifico grafo, si vedono i raggruppamenti per i vari genitori, e quindi i genitori, puoi fare poi focus solo su un sottogruppo ma rimangono in una qualche misura anche la visibilità e l'accessibilità sugli altri, per poter avere comunque una rapida navigazione e visione globale. allo stesso tempo, l'ingresso in un livello successivo non deve essere dato dal semplice click di un nodo ma bensì da un interazione diretta (doppio tap o swipe direttamente su un grafo, altrimenti si possono aprire per vedere figli di alcuni, ma il grafo non deve essere sempre clutterato di informazioni). Poi ci sono altre tipologie di visualizzazioni legate a strutture tipiche che prendono i progetti o a tipologie diverse di cose che entrano nei progetti, e quindi si può creare una visione dedicata per ognuna, per avere diversi punti di vista, e anche più modi di sfruttare questo macro concetto contenitore che è il progetto. data questa polumorfis e polifunzionali fa, ha senso creare uno scheletro di strutture di pagine di progetti, che ogni progetto avrà il suo e creare quindi un esperienza seamless di utilizzo per varie cose. l'idea è avere una Dashboard al centro, con una struttura elaborata e ben definita per dare accessibilità e visibilità a tutte le sfaccettature del progetto, ma vorrei che poi nelle istanze concrete di progetto, le loro Dashboard si compongono nel tempo con i vari componenti UI man mano che il progetto ha abbastanza struttura da mostrare quelle parti. questo significa costruire un sistema molto modulare e ben strutturato e ragionato, con una logica di costruzione tramite un contesto che mantiene le informazioni del progetto e viene utilizzato per renderizzare la pagina (questa è un idea, ma l'obiettivo finale è avere un esperienza intuitiva e comprensibile del modo in cui il progetto si complica e quindi ha più funzionalità, ma allo stesso tempo funzioni in maniera fluida e rapida, senza caricamenti infiniti un interfaccia che si carica in maniera pulita e senza movimenti confusionali e lenti dei vari elementi). Ci deve essere anche una parte di sviluppo dedicata a rendere la complessità della cosa facilmente comprensibile all utente. mi immagino la cosa come un elemento unito all'UI che manda ad una pagina di breve spiegazione iconografata, di quali punti di vista di versi si possono sfruttare l'entità progetto, e le varie pagine o le varie funzionalità. anche questo con una modalità di scoperta, nella quale la persona man mano comprende più approfonditamente la complessità del sistema, nella dimensione in cui lui la esplora naturalmente. Metterei comunque una pagina iniziale di spiegazione in cui accenna alla complessità della cosa, e mostra alcuni aspetti fondamentali (contenitore, grafo, le tipologie di entità che si associato, etc).
```

---

## 2. Structured Intent Analysis

### A. Explicit Intent (Requisiti Letterali Dichiarati)
1. **Thread-Seguito & Aggiunta Diretta di Pensieri ad Altre Entità**:
   - Possibilità di aggiungere pensieri direttamente collegati a un'altra entità esistente come filo/thread logico o seguito di approfondimento, senza dover prima entrare e navigare manualmente nella Vitrine.
2. **Cattura Strutturata tramite Pressione Prolungata (Long-Press su Invia)**:
   - Dalla barra di inserimento (sia il widget Bento `life_os_capture` sia l'input in LifeOS Center):
   - Premendo a lungo il tasto Invia (`↑`), si apre un BottomSheet contestuale.
   - Selezione rapida della Natura `Progetto`.
   - Possibilità di associare/aggiungere subito ulteriori idee o entità figlie all'interno del progetto creato.
3. **Entità Progetto come Root Node di un Grafo & Contenitore Ricorsivo**:
   - Il Progetto agisce da nodo radice (*Root Node*) di un grafo di conoscenza ed esecuzione.
   - Concetto di contenitore: contiene i suoi figli diretti e, indirettamente/ricorsivamente, tutti i discendenti che nascono a valle.
4. **Multi-Modalità di Visualizzazione del Progetto**:
   - **Vista a Cartelle (Folder View)**: proiezione gerarchica per livelli nidificati (stile file system pulito).
   - **Vista a Grafo Interattivo (Graph View)**:
     - Navigazione diretta e interattiva del grafo per livelli progressivi.
     - **Focus ristretto sui vicini immediati** (ego-graph focalizzato), evitando di mostrare l'intera galassia per prevenire il sovraccarico visivo (*anti-clutter*).
     - Raggruppamento visivo per genitori al livello selezionato, con possibilità di isolare un sottogruppo mantenendo visibilità e accessibilità periferica sugli altri.
     - **Ingresso di livello non al semplice click**, ma tramite gesture deliberata (**doppio tap o swipe sul nodo/grafo**). Il semplice click serve per ispezione/apertura dei figli locali.
   - **Viste Specializzate / Dedicated Views**: viste modellate sulle strutture tipiche che i progetti assumono (es. flusso temporale/sequenza, costellazione concettuale, lista risorse).
5. **Scheletro Modulare & Progressive Dashboard che si compone nel tempo**:
   - Scheletro architetturale unificato per la pagina di dettaglio del progetto.
   - Dashboard centrale modulare guidata da un contesto informativo (`ProjectScopeContext`).
   - **Auto-composizione progressiva nel tempo**: i componenti e i widget UI appaiono nella dashboard solo quando il progetto ha sviluppato sufficiente densità/struttura (es. niente tile grafo o bilanci se il progetto è appena nato; i moduli emergono naturalmente).
   - Requisito prestazionale: fluidità assoluta, zero salti visivi disorientanti, caricamento immediato e reattivo.
6. **Progressive Disclosure & Onboarding Pedagogico (Modalità di Scoperta)**:
   - Punto d'accesso contestuale nella UI (icona/bottone di guida) che rimanda a una **pagina di spiegazione iconografata** con i punti di vista e le funzionalità del Progetto.
   - Schermata/scheda iniziale introduttiva che accenna alla ricchezza del sistema (concetto di contenitore, grafo di nodi, tipologie di entità collegate).
   - Scoperta incrementale: l'utente apprende la complessità solo man mano che esplora naturalmente il grafo.

---

### B. Inferred Product Needs (Requisiti Impliciti Derivati)
1. **Preservazione dell'Architettura Relazionale Esistente (`entity_relations`)**:
   - Non creare una tabella alternativa di cartelle o nodi: Solducci possiede già `entity_relations` con `relation_type = part_of` e indici polimorfici. Il contenitore ricorsivo deve essere una query di chiusura transitiva sul grafo esistente.
2. **Prevenzione di Cicli nel Grafo (Acyclic Invariant)**:
   - Se un'entità A è genitore di B, B o i suoi discendenti non possono diventare genitori di A (prevenzione di riferimenti circolari).
3. **Isolamento di Contesto Multi-Utente (Context & RLS Consistency)**:
   - La gerarchia del progetto deve rispettare l'isolamento tra Personale e Gruppo già certificato nello Step 3.2a: un progetto personale può contenere solo entità personali.
4. **Algoritmo di Layout del Grafo Leggero in Flutter**:
   - La Graph View non deve dipendere da pesanti librerie web o WebView. Necessita di un custom renderer canvas o widget layout gerarchico (Sugiyama / radial tree compatto) ottimizzato a 60/120 fps.
5. **Heuristiche Deterministiche di Assemblaggio Dashboard**:
   - Regole esplicite per decidere quando un componente della Dashboard di Progetto diventa visibile (es. count figli > 0, presenza di blocchi > 2, presenza di task collegati > 0).

---

### C. Proactive Extensions (Migliorie Utili Proattive di Alto Valore)
1. **Breadcrumb Bar Interattiva**:
   - Nella navigazione a livelli del grafo e delle cartelle, una barra di breadcrumb superiore (`Progetto > Modulo Core > Idea A`) consente di risalire istantaneamente ai livelli superiori con un tap.
2. **Quick Child Creator nel Grafo**:
   - Possibilità di aggiungere un figlio direttamente da un nodo con una mini-action `+` senza abbandonare la modalità grafo.
3. **Dossier Export / Snapshot**:
   - Proiezione sintetica dell'intero albero del progetto per consultazione offline o condivisione.

---

### D. Open Technical & Design Questions
1. **Deep Links & Routing**: Come deve essere strutturato il routing per un sotto-nodo? (Es. `/life_os/project/:projectId/node/:nodeId` oppure apertura Vitrine standard con parametro `contextProjectId`?).
2. **Comportamento di Cancellazione del Root Project**: Se l'utente cancella l'entità Progetto radice, i figli vengono eliminati in cascata o promossi a semi/entità indipendenti a riposo? (Raccomandazione: disaccoppiamento non-distruttivo con rimozione della sola relazione `part_of`, preservando le entità figlie).
