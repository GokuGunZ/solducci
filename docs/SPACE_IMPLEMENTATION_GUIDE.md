# 🤖 Spazio Feature — Implementation Guide

> **Audience**: Claude Agents, Developers implementing the feature
> **Purpose**: Step-by-step guide to implement "Spazio" from scratch
> **Prerequisite**: Read `SPACE_PRODUCT_REQUIREMENTS.md` and `SPACE_TECHNICAL_DESIGN.md` first

---

## Agent Mission

Implementa la feature **"Spazio"** nell'app Flutter Solducci. Spazio è una nuova 5a tab nel bottom nav che raggruppa cinque tipologie di contenuti condivisi (Task, Note, Asterischi, Risorse, Dispensa + Lista della spesa), tutte context-aware tramite il `ContextManager` esistente.

---

## Prima di iniziare: leggi questi file

```
docs/SPACE_PRODUCT_REQUIREMENTS.md   ← Vision e requisiti funzionali
docs/SPACE_TECHNICAL_DESIGN.md       ← Schema DB, modelli, services, routing
docs/SENIOR_DEV_DOCUMENTS_ARCHITECTURE.md ← Architettura esistente Documents (da riutilizzare)
docs/README_MULTIUSER.md             ← Come funziona ContextManager
lib/service/context_manager.dart     ← Implementazione ContextManager
lib/models/document.dart             ← Classe base Document (da estendere)
lib/service/document_service.dart    ← DocumentService (da estendere)
lib/views/shell_with_nav.dart        ← Bottom nav (da modificare)
lib/routes/app_router.dart           ← Router (da modificare)
```

---

## Piano d'Implementazione a Fasi

Implementa una fase alla volta, nell'ordine indicato. Ogni fase è un'unità indipendente e deployabile.

---

## FASE 1 — Scaffolding: Tab Spazio + Navigazione

**Obiettivo**: Aggiungere la tab "Spazio" con la schermata principale (5 card placeholder) e il routing completo.

### Step 1.1 — SpaceHomeView (schermata principale)

Crea `lib/features/space/views/space_home_view.dart`.

La schermata mostra 5 card navigabili. Ogni card ha:
- Icona
- Titolo
- Breve descrizione
- Freccia di navigazione
- `onTap` che naviga alla rispettiva route

| Card | Label | Icona suggerita | Route |
|---|---|---|---|
| Task | "Task" | `Icons.checklist` | `/space/tasks` |
| Note | "Note" | `Icons.notes` | `/space/notes` |
| Asterischi | "Asterischi" | `Icons.star_outline` | `/space/asterisks` |
| Risorse | "Risorse" | `Icons.link` | `/space/resources` |
| Dispensa | "Dispensa" | `Icons.kitchen_outlined` | `/space/pantry` |

La schermata deve reagire al contesto corrente: mostrare in header il nome del contesto attivo (leggere da `ContextManager().contextDisplayName`).

### Step 1.2 — SpaceDocumentListView (widget generico)

Crea `lib/features/space/views/space_document_list_view.dart`.

Widget riutilizzabile che mostra la lista dei Document di un certo tipo per il contesto corrente. Riceve `documentType` e `sectionLabel` come parametri.

Comportamento:
- Legge `ContextManager().currentContext`
- Chiama `DocumentService().getDocumentsForContext(context, documentType)` (aggiungere questo metodo)
- Mostra lista di card con titolo del documento + data creazione
- FAB "+" per creare un nuovo documento (dialog con campo titolo)
- Tap su card → naviga a `/$sectionPath/:id`

### Step 1.3 — Modifica `shell_with_nav.dart`

```dart
// Sostituire DocumentsHomeView() con SpaceHomeView() nell'IndexedStack
// Aggiornare BottomNavigationBarItem: label 'Spazio', icon Icons.space_dashboard_outlined
```

### Step 1.4 — Modifica `app_router.dart`

Rimuovere la route `/notes`. Aggiungere tutte le routes `/space/*` come da `SPACE_TECHNICAL_DESIGN.md` sezione "Navigation & Routing".

Per le viste intermedie delle singole tipologie (es. `/space/notes/:id`), per ora usare un placeholder `Scaffold` con AppBar e testo "Coming soon — [tipologia]".

### Step 1.5 — Aggiungere a `DocumentService`

```dart
Future<List<Document>> getDocumentsForContext(ExpenseContext context, String documentType)
Stream<List<Document>> watchDocumentsForContext(ExpenseContext context, String documentType)
```

### Verifica Fase 1
- [ ] Tab "Spazio" appare nel bottom nav
- [ ] Tap apre `SpaceHomeView` con 5 card
- [ ] Tap su ogni card naviga alla route corretta
- [ ] Tap su "Task" mostra la lista dei TodoDocument del contesto corrente
- [ ] Cambiare contesto (Personal ↔ Group) aggiorna la lista documenti
- [ ] Creazione di un nuovo documento funziona

---

## FASE 2 — Task: migrazione Documents + assigned_to

**Obiettivo**: Rendere la sezione Task di Spazio funzionante riutilizzando Documents. Aggiungere assegnazione a membro.

### Step 2.1 — Migration DB

```sql
ALTER TABLE tasks
  ADD COLUMN assigned_to UUID REFERENCES profiles(id) ON DELETE SET NULL;

CREATE INDEX idx_tasks_assigned_to ON tasks(assigned_to);
```

### Step 2.2 — Aggiornare il model `Task`

In `lib/models/task.dart`:
- Aggiungere campo `String? assignedTo`
- Aggiornare `fromMap()`, `toMap()`, `toUpdateMap()`, `copyWith()`

### Step 2.3 — Task view nel contesto Spazio

La route `/space/tasks/:id` deve puntare all'esistente `DocumentsHomeView`, passando il `documentId` come parametro.

Se `DocumentsHomeView` non accetta `documentId` come parametro esterno (attualmente usa il documento di default dell'utente), refactorare per accettarlo.

### Step 2.4 — UI assigned_to

Nel form di creazione/edit task (`task_form.dart`):
- Se il contesto è un gruppo, mostrare un dropdown "Assegna a" con i membri del gruppo
- Caricare i membri con `GroupService().getGroupMembers(contextManager.currentGroupId!)`
- Se contesto è Personal, non mostrare il campo

Nel task list item, mostrare l'avatar/nickname dell'assegnatario se presente.

### Verifica Fase 2
- [ ] Task esistenti funzionano come prima
- [ ] Possibile creare più liste task per contesto
- [ ] Campo "Assegna a" appare nel form quando si è in un gruppo
- [ ] L'assegnatario è visibile nel task list item

---

## FASE 3 — Note Testuali

**Obiettivo**: Implementare la sezione Note con creazione/lettura/modifica.

### Step 3.1 — Migration DB

```sql
CREATE TABLE note_items (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  document_id UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
  title       TEXT NOT NULL,
  body        TEXT,
  created_by  UUID REFERENCES profiles(id) ON DELETE SET NULL,
  created_at  TIMESTAMPTZ DEFAULT now(),
  updated_at  TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX idx_note_items_document_id ON note_items(document_id);
```

RLS:
```sql
CREATE POLICY "note_items_select" ON note_items FOR SELECT TO authenticated
USING (document_id IN (
  SELECT id FROM documents
  WHERE user_id = auth.uid()
  OR group_id IN (SELECT group_id FROM group_members WHERE user_id = auth.uid())
));
-- Aggiungere policies INSERT, UPDATE, DELETE analoghe
```

### Step 3.2 — Model `NoteItem`

Crea `lib/features/space/models/note_item.dart`.

```dart
class NoteItem {
  final String id;
  final String documentId;
  String title;
  String? body;
  final String? createdBy;
  final DateTime createdAt;
  DateTime updatedAt;
  // fromMap, toMap, toInsertMap, toUpdateMap, copyWith
}
```

### Step 3.3 — `NoteService`

Crea `lib/features/space/services/note_service.dart`. Singleton.

```dart
Stream<List<NoteItem>> getNotesStream(String documentId)
Future<NoteItem> createNote(String documentId, String title, String? body)
Future<void> updateNote(String id, String title, String? body)
Future<void> deleteNote(String id)
```

### Step 3.4 — BLoC Note

Crea `lib/features/space/blocs/notes/` con `note_bloc.dart`, `note_event.dart`, `note_state.dart`.

Events: `NoteLoadRequested`, `NoteCreated`, `NoteUpdated`, `NoteDeleted`
States: `NoteInitial`, `NoteLoading`, `NoteLoaded(items)`, `NoteError`

### Step 3.5 — UI Note

- `NoteListView`: lista note con titolo + preview corpo. FAB per creare. Swipe per eliminare.
- `NoteDetailView`: titolo editabile + corpo editabile (TextField multiline). Auto-save o bottone salva.

### Verifica Fase 3
- [ ] Lista note vuota mostra stato empty + FAB per creare
- [ ] Creazione nota funziona
- [ ] Modifica titolo e corpo funziona
- [ ] Eliminazione con swipe funziona
- [ ] Nota creata in gruppo è visibile a tutti i membri

---

## FASE 4 — Asterischi

**Obiettivo**: Implementare asterischi con visibilità selettiva del corpo e stati attivo/archiviato.

### Step 4.1 — Migration DB

```sql
CREATE TABLE asterisk_items (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  document_id UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
  title       TEXT NOT NULL,
  body        TEXT,
  created_by  UUID REFERENCES profiles(id) ON DELETE SET NULL,
  status      TEXT NOT NULL DEFAULT 'active'
                CHECK (status IN ('active', 'archived')),
  created_at  TIMESTAMPTZ DEFAULT now(),
  updated_at  TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX idx_asterisk_items_document_id ON asterisk_items(document_id);
```

RLS: identico al pattern di note_items.

### Step 4.2 — Model `AsteriskItem`

```dart
class AsteriskItem {
  final String id;
  final String documentId;
  String title;
  String? body;         // può essere null o vuoto per non-creatori
  final String? createdBy;
  AsteriskStatus status;
  final DateTime createdAt;
  DateTime updatedAt;
}

enum AsteriskStatus { active, archived }
```

### Step 4.3 — `AsteriskService`

```dart
Stream<List<AsteriskItem>> getAsterisksStream(String documentId)  // solo 'active'
Stream<List<AsteriskItem>> getArchivedStream(String documentId)
Future<AsteriskItem> createAsterisk(String documentId, String title, String? body)
Future<void> archiveAsterisk(String id)
Future<void> updateBody(String id, String body)  // solo il creatore lo invoca
Future<void> deleteAsterisk(String id)
```

### Step 4.4 — Logica visibilità body

**Non serve logica DB speciale.** Il body è presente nella risposta Supabase per tutti, ma il client Flutter lo nasconde se non sei il creatore:

```dart
// In AsteriskListItem widget:
final currentUserId = AuthService().currentUserId;
final isCreator = item.createdBy == currentUserId;

// Mostra body solo se isCreator
if (isCreator) Text(item.body ?? '')
```

Il corpo è modificabile solo dal creatore — il bottone "Modifica corpo" appare solo se `isCreator`.

### Step 4.5 — UI Asterischi

- `AsteriskListView`: tab bar "Attivi" | "Archiviati". FAB per creare.
- Item in lista: titolo (tutti), sotto-testo "Il tuo appunto: ..." (solo creatore). Bottone "Archivia".
- `AsteriskDetailView` (solo creatore): mostra titolo + campo body editabile.

### Verifica Fase 4
- [ ] Creazione asterisco con titolo + corpo opzionale
- [ ] Titolo visibile a tutti i membri
- [ ] Corpo visibile solo al creatore
- [ ] Archiviazione sposta in tab "Archiviati"
- [ ] Solo il creatore può modificare il corpo

---

## FASE 5 — Risorse

**Obiettivo**: Lista di link condivisi con tag e stato "visto" per membro.

### Step 5.1 — Migration DB

```sql
CREATE TABLE resource_items (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  document_id UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
  title       TEXT NOT NULL,
  url         TEXT NOT NULL,
  description TEXT,
  created_by  UUID REFERENCES profiles(id) ON DELETE SET NULL,
  created_at  TIMESTAMPTZ DEFAULT now(),
  updated_at  TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE resource_item_tags (
  resource_item_id UUID REFERENCES resource_items(id) ON DELETE CASCADE,
  tag_id           UUID REFERENCES tags(id) ON DELETE CASCADE,
  PRIMARY KEY (resource_item_id, tag_id)
);

CREATE TABLE resource_item_reads (
  resource_item_id UUID REFERENCES resource_items(id) ON DELETE CASCADE,
  user_id          UUID REFERENCES profiles(id) ON DELETE CASCADE,
  read_at          TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (resource_item_id, user_id)
);
```

### Step 5.2 — Model `ResourceItem`

```dart
class ResourceItem {
  final String id;
  final String documentId;
  String title;
  String url;
  String? description;
  final String? createdBy;
  List<Tag> tags;
  bool isReadByMe;       // calcolato client-side
  final DateTime createdAt;
  DateTime updatedAt;
}
```

### Step 5.3 — `ResourceService`

Punti chiave:
- `preloadReadStatus(documentId)`: fetch batch di `resource_item_reads` per tutti gli item del documento, evitando N+1
- `markAsRead(resourceItemId)`: upsert in `resource_item_reads`
- Caricare i tag in join o batch separato

### Step 5.4 — UI Risorse

- `ResourceListView`: lista con titolo, URL preview, tag chips, indicatore "visto" (check icon). FAB per aggiungere.
- Tap sulla risorsa: apre URL nel browser (`url_launcher`). Segna automaticamente come letta.
- Form aggiunta risorsa: titolo, URL, descrizione, multi-select tag.

### Verifica Fase 5
- [ ] Aggiunta risorsa con URL, titolo, tag
- [ ] Apertura URL nel browser
- [ ] Stato "visto" viene aggiornato dopo apertura
- [ ] Stato "visto" è personale (non condiviso)
- [ ] Filtraggio per tag funziona

---

## FASE 6 — Dispensa

**Obiettivo**: Inventario con quantità multiple, categorie, soglie, vista "Mancanti".

### Step 6.1 — Migration DB

```sql
CREATE TABLE pantry_items (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  document_id   UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
  name          TEXT NOT NULL,
  category      TEXT CHECK (category IN ('frigo','surgelati','dispensa','pulizia','casa')),
  min_threshold NUMERIC,
  is_hidden     BOOLEAN NOT NULL DEFAULT false,
  created_at    TIMESTAMPTZ DEFAULT now(),
  updated_at    TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE pantry_quantities (
  id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  pantry_item_id UUID NOT NULL REFERENCES pantry_items(id) ON DELETE CASCADE,
  unit_type      TEXT NOT NULL CHECK (unit_type IN ('kg','litri','pezzi','confezioni')),
  value          NUMERIC NOT NULL CHECK (value > 0),
  created_at     TIMESTAMPTZ DEFAULT now()
);
```

### Step 6.2 — Models

`PantryItem`:
```dart
class PantryItem {
  final String id;
  final String documentId;
  String name;
  PantryCategory? category;
  double? minThreshold;
  bool isHidden;
  List<PantryQuantity> quantities;  // lazy-loaded
  final DateTime createdAt;
  DateTime updatedAt;

  bool get isMissing {
    if (isHidden) return false;
    if (quantities.isEmpty) return true;
    if (minThreshold == null) return false;
    final total = quantities.fold(0.0, (sum, q) => sum + q.value);
    return total < minThreshold!;
  }
}

class PantryQuantity {
  final String id;
  final String pantryItemId;
  final PantryUnitType unitType;
  final double value;
  final DateTime createdAt;
}

enum PantryCategory { frigo, surgelati, dispensa, pulizia, casa }
enum PantryUnitType { kg, litri, pezzi, confezioni }
```

### Step 6.3 — `PantryService`

```dart
Stream<List<PantryItem>> getPantryItemsStream(String documentId)
// Stream deve caricare pantry_items + pantry_quantities in join

Future<PantryItem> createPantryItem(String documentId, String name, PantryCategory? cat)
Future<void> addQuantity(String pantryItemId, PantryUnitType unit, double value)
Future<void> removeQuantity(String quantityId)
Future<void> updateMinThreshold(String pantryItemId, double? threshold)
Future<void> toggleHidden(String pantryItemId)
```

### Step 6.4 — UI Dispensa

`PantryView` ha due tab:
1. **Tutto**: lista per categoria, ogni item mostra quantità. Tap per modificare/aggiungere quantità.
2. **Mancanti**: solo `item.isMissing == true`. Bottone "Crea lista della spesa" che naviga a `/space/pantry/:id/shopping/new`.

Item widget: nome + chip per ogni quantità (es. "2 confezioni", "1.5 kg"). Swipe per eliminare. Long press per impostare soglia minima o nascondere.

### Verifica Fase 6
- [ ] Aggiunta elemento con nome e categoria
- [ ] Aggiunta quantità multipla allo stesso elemento
- [ ] Elemento senza quantità appare in "Mancanti"
- [ ] Soglia minima: elemento appare in "Mancanti" se sotto soglia
- [ ] "Nascondi" rimuove dall'elenco Mancanti
- [ ] Tutto funziona in contesto gruppo (tutti i membri vedono la stessa dispensa)

---

## FASE 7 — Lista della Spesa

**Obiettivo**: Liste della spesa collegate alla dispensa, checkabili, con "Spesa fatta".

### Step 7.1 — Migration DB

```sql
CREATE TABLE shopping_list_items (
  id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  document_id    UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
  pantry_item_id UUID REFERENCES pantry_items(id) ON DELETE SET NULL,
  custom_name    TEXT,
  unit_type      TEXT CHECK (unit_type IN ('kg','litri','pezzi','confezioni')),
  quantity_value NUMERIC,
  is_checked     BOOLEAN NOT NULL DEFAULT false,
  created_at     TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE shopping_list_items
  ADD CONSTRAINT shopping_item_has_name
  CHECK (pantry_item_id IS NOT NULL OR custom_name IS NOT NULL);
```

### Step 7.2 — Model `ShoppingListItem`

```dart
class ShoppingListItem {
  final String id;
  final String documentId;
  final String? pantryItemId;   // null se aggiunto manualmente
  final String? customName;
  final PantryUnitType? unitType;
  final double? quantityValue;
  bool isChecked;
  final DateTime createdAt;

  String get displayName => customName ?? pantryItemId; // risolvere nome da pantry
}
```

### Step 7.3 — `ShoppingListService`

```dart
Stream<List<ShoppingListItem>> getItemsStream(String documentId)
Future<void> createFromMissingItems(String shoppingListDocId, List<PantryItem> missingItems)
Future<void> addManualItem(String documentId, String name, PantryUnitType? unit, double? value)
Future<void> toggleCheck(String itemId)
Future<void> confirmPurchase(String shoppingListDocId, String pantryDocumentId)
// confirmPurchase: per ogni item checked con pantry_item_id, inserisce PantryQuantity
Future<void> deleteItem(String itemId)
```

### Step 7.4 — Creazione lista dalla dispensa

Dalla `PantryView` tab "Mancanti":
1. Bottone "Nuova lista della spesa"
2. Si può selezionare un sottoinsieme degli elementi mancanti
3. Crea un nuovo `ShoppingListDocument` (document_type = 'shopping_list') con titolo default "Lista spesa - [data]"
4. Crea gli `ShoppingListItem` per ogni elemento mancante selezionato
5. Naviga a `/space/pantry/:pantryId/shopping/:shoppingId`

### Step 7.5 — UI Lista della Spesa

`ShoppingListView`:
- Lista items con checkbox. Tap → `toggleCheck`.
- FAB per aggiungere item manuale (dialog: nome, unità, quantità opzionali)
- AppBar action: bottone **"Spesa fatta"** (solo se almeno un item è checked)
  - Conferma con dialog
  - Chiama `confirmPurchase`
  - Mostra feedback "Dispensa aggiornata"

### Verifica Fase 7
- [ ] Creazione lista dalla schermata "Mancanti"
- [ ] Item checkabili
- [ ] Aggiunta item manuale
- [ ] "Spesa fatta" aggiorna la dispensa con le quantità
- [ ] Più liste della spesa possono coesistere in parallelo

---

## Pattern e convenzioni da rispettare

### Singleton services
```dart
class MyService {
  static final MyService _instance = MyService._internal();
  factory MyService() => _instance;
  MyService._internal();
}
```

### BLoC context listener
```dart
@override
void initState() {
  super.initState();
  ContextManager().addListener(_onContextChanged);
}
@override
void dispose() {
  ContextManager().removeListener(_onContextChanged);
  super.dispose();
}
```

### Logging debug
```dart
if (kDebugMode) print('🏠 [PantryService] Loaded ${items.length} items');
```

### Nomi italiani per label UI, inglesi per codice
- Labels UI: italiano (es. "Aggiungi elemento", "Spesa fatta")
- Nomi classi/metodi: inglese (es. `PantryItem`, `confirmPurchase`)

---

## Checklist finale

- [ ] Tutte le nuove tabelle hanno RLS abilitato
- [ ] Tutti i nuovi model hanno `fromMap`, `toMap`, `toInsertMap`, `toUpdateMap`, `copyWith`
- [ ] Tutti i nuovi service sono singleton
- [ ] Ogni BLoC si iscrive e disiscrive dal `ContextManager`
- [ ] `Document.fromMap` factory gestisce tutti i nuovi `document_type`
- [ ] `app_router.dart` ha tutte le nuove routes
- [ ] `shell_with_nav.dart` usa `SpaceHomeView` con label "Spazio"
- [ ] La sezione Tasks riutilizza `DocumentsHomeView` senza duplicare codice
