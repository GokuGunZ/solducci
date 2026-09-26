# Solducci - Specifiche Redesign Dashboard (Bento Grid)

Questo documento definisce l'architettura, le specifiche UI/UX dei widget e il piano implementativo per la nuova Dashboard principale di Solducci. L'obiettivo è trasformare l'app in un vero e proprio "Life OS" tramite una pagina altamente modulare e personalizzabile.

## 1. Architettura di Base (Livello 1)

*   **Layout Engine**: Sistema a griglia (Bento Grid) ottimizzato per **Mobile-first**. La griglia base sarà composta da 2 o 4 colonne logiche per permettere incastri di widget di varie dimensioni (es. `1x1`, `2x1`, `2x2`).
*   **Gestione Stato e Interattività**: Modalità di modifica (**Edit Mode**) dedicata. Quando in Edit Mode, i widget espongono controlli per il drag & drop, la rimozione e il ridimensionamento (se supportato). Quando l'Edit Mode è disattivato, i widget sono elementi interattivi vivi.
*   **Persistenza**: La struttura della dashboard (es. l'array dei widget attivi e le loro coordinate) è salvata nel **Backend (Supabase)** per garantire la sincronizzazione cross-device, con caching locale per avvio istantaneo.
*   **Strategia di Fetching**: **Isolamento Asincrono**. La pagina carica solo lo schema (JSON) della griglia e mostra i contenitori con **Skeleton Loaders**. Successivamente, *ogni widget* è responsabile del fetching indipendente dei propri dati per azzerare i tempi di blocco UI.

## 2. Linee Guida UI/UX (Rif. `DESIGN_GUIDELINES.md`)

I widget della dashboard devono incarnare il design premium di Solducci:
*   **Superfici e Forme**: Sfondo widget `Color(0xFF18181B)`. Forma a "squircle" con `BorderRadius.circular(24)`. Nessuna shadow pesante, usare bordi fini `BorderSide(color: Colors.white10, width: 1)`.
*   **Neon Glow**: Gli elementi attivi o i dati critici nei widget (es. saldo positivo, task urgenti) devono sfruttare ombre colorate (es. `MaskFilter.blur(BlurStyle.solid)`) usando i colori accento (Indigo, Emerald, Amber, Pink).
*   **Glassmorphism**: Durante il Drag & Drop o nei widget in sovrimpressione, applicare `BackdropFilter` con sfocatura e container semi-trasparenti.
*   **Micro-animazioni**: Ogni widget deve scalare dolcemente al tap (es. `scale(0.98)`). Le statistiche che caricano i dati asincroni devono "sfumare" morbidamente (Fade-in).

---

## 3. Specifiche dei Widget (Livello 2)

I widget sono classificati per dimensione nella griglia logica (1x1 = quadrato piccolo, 2x1 = rettangolo orizzontale, 2x2 = quadrato grande, 1x2 = rettangolo verticale).

### 3.1 Spese & Finanza
*   **Balance Pill (1x1)**:
    *   **UI**: Numero grande centrato, colore Emerald (se credito) o Red (se debito) con effetto *Neon Glow*. Sotto, micro-avatar dell'utente controparte.
    *   **Dati**: Fetch asincrono del saldo netto da `ExpenseService`.
*   **Monthly Burn Rate (2x1)**:
    *   **UI**: Sfondo sfumato verso il trasparente. Un grafico spline minimale (`NeonWaveGraph`) o una progress bar che mostra la spesa attuale vs media storica.
*   **Quick Expense (2x1)**:
    *   **UI**: Tastierino compatto integrato. Pulsante primario Indigo per salvare immediatamente la spesa. *Azione Rapida*.

### 3.2 Task (Gestione Attività)
*   **Focus Oggi (2x2)**:
    *   **UI**: Lista testuale compatta dei 3 task più urgenti. Checkbox a sinistra, tag priorità a destra.
    *   **Interazione**: Il tap sulla checkbox chiama l'update su DB al volo e anima il task (sbarrandolo) prima di farlo scomparire dalla lista.
*   **Daily Progress (1x1)**:
    *   **UI**: Circular Progress Ring (stile Apple Fitness). Al centro il numero di task completati su quelli totali previsti per la giornata.

### 3.3 Eventi, Viaggi (Time Scenarios)
*   **Hero Countdown (2x1 o 2x2)**:
    *   **UI**: Immagine di sfondo (recuperata dai metadata) scurita tramite Glassmorphism. Testo bianco bold con i giorni rimanenti all'evento.
*   **Time Poll Alert (1x1)**:
    *   **UI**: Widget con icona "Campanella" o "Sondaggio" animata se c'è un poll aperto. Il tap apre il dialog per votare.

### 3.4 Infinite Canvas (Note, Asterischi, Risorse)
*   **Unresolved Asterisks (2x2)**:
    *   **UI**: Stile post-it (Accent color Amber tenue). Elenco puntato di `AsteriskItem` con `isResolved == false`.
*   **Media Scroller (2x1)**:
    *   **UI**: Mini-carosello scorrevole orizzontalmente con le miniature (thumbnails) delle ultime risorse aggiunte in `ResourceListDocument`.

### 3.5 Routine
*   **Habit Tracker (2x1)**:
    *   **UI**: Griglia di contribuzione stile GitHub (ultimi 7 giorni) per monitorare lo *streak* di una routine specifica.
*   **Prossima Routine (1x1)**:
    *   **UI**: Icona della routine, orario, e un bottone "Play/Check" d'accento per segnarla completata.

### 3.6 Dispensa & Spesa
*   **Pantry Warning (1x1)**:
    *   **UI**: Contatore grande rosso (con Glow) se ci sono elementi della dispensa sotto la `thresholdLow`. Verde con spunta altrimenti.
*   **Shopping Quick List (1x2 Colonna)**:
    *   **UI**: Elenco scrollabile degli item in `ShoppingListDocument` direttamente in Home.

---

## 4. Design Pattern e Architettura Software

Per garantire alte prestazioni e codice manutenibile:

1.  **Widget Factory Pattern**: I dati del backend restituiranno JSON del tipo `{"id": "w1", "type": "balance", "size": "1x1", "pos": {"x":0, "y":0}}`. Una classe `DashboardWidgetFactory` mapperà la stringa `type` al corrispondente Flutter Widget (es. `BalanceWidget()`).
2.  **State Management (Riverpod / BLoC)**: 
    *   Uno state controller globale `DashboardLayoutProvider` gestisce l'array JSON del layout e lo stato `isEditing`.
    *   Ogni singolo widget avrà il proprio provider indipendente (es. `balanceProvider`, `todayTasksProvider`) caricato *solo* se il widget è istanziato nella griglia.
3.  **Skeleton Loader Mixin**: Creare un wrapper generico `BentoWidgetContainer` che gestisce i bordi squircle, lo sfondo dark e accetta un `AsyncValue`. Se in loading, renderizza un effetto shimmer elegante in scala di grigi scuri.

---

## 5. Piano Implementativo (Task Breakdown)

I task sono strutturati per fornire incrementi di valore iterativi senza rompere la build corrente.

### Phase 1: Core Engine & Supabase (Backend & Models)
*   **Task 1.1**: Creare la tabella Supabase `user_dashboards` (campi: `user_id`, `layout_json`, `device_type`).
*   **Task 1.2**: Creare i modelli Dart `DashboardConfig` e `BentoWidgetDef`.
*   **Task 1.3**: Implementare `DashboardRepository` per leggere/salvare la configurazione. Caching locale opzionale (SharedPreferences/Hive).

### Phase 2: UI Foundation & Grid System (Infrastruttura)
*   **Task 2.1**: Ricerca e implementazione del motore di griglia. (Valutare package come `flutter_staggered_grid_view` o un custom `Wrap`/`GridView` drag-and-drop).
*   **Task 2.2**: Sviluppare il componente `BentoWidgetContainer` base (con `BorderRadius.circular(24)`, `white10` border, `Color(0xFF18181B)` background).
*   **Task 2.3**: Implementare la logica dell'**Edit Mode** a livello di pagina (toggle interattività vs drag-handles).
*   **Task 2.4**: Creare la `DashboardWidgetFactory` (inizialmente con Mock Widgets).

### Phase 3: Sviluppo Base Widgets (Le Fondamenta)
*   **Task 3.1**: Sviluppare *Balance Pill Widget* (Integrazione `ExpenseService`, implementazione UI Neon Glow).
*   **Task 3.2**: Sviluppare *Focus Oggi Widget* (Integrazione `TaskService`, UI interattiva checklist).
*   **Task 3.3**: Sviluppare *Quick Expense Widget* (Action rapida).
*   **Task 3.4**: Test integrazione dei widget nella griglia e verifica del caricamento asincrono indipendente (Skeleton funzionanti).

### Phase 4: Sviluppo Advanced Widgets & Polish
*   **Task 4.1**: Sviluppare widget per *Time Scenarios* (Countdown e Polls) integrando animazioni glassmorphism per le card con immagini di background.
*   **Task 4.2**: Sviluppare widget per *Infinite Canvas* (Asterischi e Dispensa).
*   **Task 4.3**: Sviluppare widget per *Routine* (Habit Tracker contributions graph).
*   **Task 4.4**: Final Polish: applicare `flutter_animate` a tutti i widget per micro-interazioni (tap scaling, fade-in ai caricamenti, transizioni fluide in Edit Mode).

---
*Fine Documento*
