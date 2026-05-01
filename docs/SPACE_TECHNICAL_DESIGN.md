# 🏗️ Spazio Feature — Technical Design

> **Audience**: Senior Developers, Architects
> **Level**: Deep technical implementation details
> **Prerequisite**: Read `SPACE_PRODUCT_REQUIREMENTS.md` first

---

## Table of Contents
1. [Architectural Overview](#architectural-overview)
2. [Core Principle: Document as Hub](#core-principle-document-as-hub)
3. [Database Schema](#database-schema)
4. [Dart Models](#dart-models)
5. [Services Layer](#services-layer)
6. [State Management (BLoC)](#state-management-bloc)
7. [Navigation & Routing](#navigation--routing)
8. [Context Awareness](#context-awareness)
9. [RLS Policies](#rls-policies)
10. [File Structure](#file-structure)

---

## Architectural Overview

"Spazio" è costruito sopra l'infrastruttura **già esistente** di Solducci senza reinventare nulla:

| Infrastruttura | Riuso |
|---|---|
| `Document` (abstract class) | Hub per tutte le tipologie tramite `document_type` |
| `ContextManager` | Context-awareness gratuita — Personal / Group / View |
| Pattern BLoC | Ogni tipologia ha il proprio BLoC, stesso schema di `UnifiedTaskListBloc` |
| Supabase Realtime | Stream-based updates già funzionanti |
| RLS policies | Pattern già consolidato, da estendere |

---

## Core Principle: Document as Hub

Ogni "lista" di qualsiasi tipologia è una riga nella tabella `documents`.
Il campo `document_type` discrimina il tipo. `user_id` o `group_id` determinano il contesto.

```
documents
  ├── type='todo'           → tasks (già esistente)
  ├── type='note'           → note_items
  ├── type='asterisk'       → asterisk_items
  ├── type='resource_list'  → resource_items
  ├── type='dispensa'       → pantry_items → pantry_quantities
  └── type='shopping_list'  → shopping_list_items (FK a pantry_items)
```

**Implicazioni**:
- Aggiungere una nuova tipologia = aggiungere un nuovo `document_type` + tabella items
- Il listing delle liste per contesto è una query generica su `documents` filtrata per tipo e contesto
- La creazione di una lista è sempre `DocumentService.createDocument(type, context)`

---

## Database Schema

### Tabelle esistenti (nessuna modifica strutturale)
```sql
documents (id, user_id, group_id, document_type, title, description, metadata, created_at, updated_at)
tasks     (id, document_id, title, status, priority, t_shirt_size, due_date, position, ...)
tags      (id, document_id, name, color, ...)
task_tags (task_id, tag_id)
```

### Modifica alla tabella tasks
```sql
ALTER TABLE tasks
  ADD COLUMN assigned_to UUID REFERENCES profiles(id) ON DELETE SET NULL;

CREATE INDEX idx_tasks_assigned_to ON tasks(assigned_to);
```

### Nuove tabelle

```sql
-- NOTE ITEMS
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

-- ASTERISK ITEMS
-- IMPORTANTE: il campo `body` è protetto da RLS — visibile solo al created_by
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
CREATE INDEX idx_asterisk_items_status      ON asterisk_items(status);

-- RESOURCE ITEMS
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
CREATE INDEX idx_resource_items_document_id ON resource_items(document_id);

-- Tags per risorse: riusa la tabella tags esistente (document_id punta al resource_list document)
-- Junction separata per resource items
CREATE TABLE resource_item_tags (
  resource_item_id UUID REFERENCES resource_items(id) ON DELETE CASCADE,
  tag_id           UUID REFERENCES tags(id) ON DELETE CASCADE,
  PRIMARY KEY (resource_item_id, tag_id)
);

-- Stato "visto" per membro (uno per (risorsa, utente))
CREATE TABLE resource_item_reads (
  resource_item_id UUID REFERENCES resource_items(id) ON DELETE CASCADE,
  user_id          UUID REFERENCES profiles(id) ON DELETE CASCADE,
  read_at          TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (resource_item_id, user_id)
);

-- PANTRY ITEMS (elementi della dispensa)
CREATE TABLE pantry_items (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  document_id   UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
  name          TEXT NOT NULL,
  category      TEXT CHECK (category IN ('frigo','surgelati','dispensa','pulizia','casa')),
  min_threshold NUMERIC,      -- NULL = nessuna soglia minima configurata
  is_hidden     BOOLEAN NOT NULL DEFAULT false,  -- nascosto dalla vista "Mancanti"
  created_at    TIMESTAMPTZ DEFAULT now(),
  updated_at    TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX idx_pantry_items_document_id ON pantry_items(document_id);
CREATE INDEX idx_pantry_items_category    ON pantry_items(category);

-- PANTRY QUANTITIES (quantità multiple per elemento)
-- Es: Latte → [{ unit: 'confezioni', value: 2 }, { unit: 'litri', value: 0.5 }]
CREATE TABLE pantry_quantities (
  id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  pantry_item_id UUID NOT NULL REFERENCES pantry_items(id) ON DELETE CASCADE,
  unit_type      TEXT NOT NULL
                   CHECK (unit_type IN ('kg','litri','pezzi','confezioni')),
  value          NUMERIC NOT NULL CHECK (value > 0),
  created_at     TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX idx_pantry_quantities_item_id ON pantry_quantities(pantry_item_id);

-- SHOPPING LIST ITEMS
CREATE TABLE shopping_list_items (
  id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  document_id    UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
  -- FK opzionale alla dispensa: NULL se aggiunto manualmente
  pantry_item_id UUID REFERENCES pantry_items(id) ON DELETE SET NULL,
  custom_name    TEXT,        -- usato se pantry_item_id è NULL
  unit_type      TEXT CHECK (unit_type IN ('kg','litri','pezzi','confezioni')),
  quantity_value NUMERIC,
  is_checked     BOOLEAN NOT NULL DEFAULT false,
  created_at     TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX idx_shopping_list_items_document_id ON shopping_list_items(document_id);

-- Constraint: almeno uno tra pantry_item_id e custom_name deve essere valorizzato
ALTER TABLE shopping_list_items
  ADD CONSTRAINT shopping_item_has_name
  CHECK (pantry_item_id IS NOT NULL OR custom_name IS NOT NULL);
```

---

## Dart Models

### Pattern da seguire
Ogni model segue il pattern già consolidato in `Document` e `Task`:
- `fromMap(Map<String, dynamic>)` factory
- `toMap()`, `toInsertMap()`, `toUpdateMap()`
- `copyWith(...)` per modifiche immutabili

### Nuovi Document subtypes (in `lib/models/document.dart`)

```dart
// Aggiungere al switch in Document.fromMap():
case 'note':
  return NoteDocument.fromMap(map);
case 'asterisk':
  return AsteriskDocument.fromMap(map);
case 'resource_list':
  return ResourceListDocument.fromMap(map);
case 'dispensa':
  return DispensaDocument.fromMap(map);
case 'shopping_list':
  return ShoppingListDocument.fromMap(map);
```

### Nuovi item models (in `lib/features/space/models/`)

```
asterisk_item.dart    → AsteriskItem { id, documentId, title, body?, createdBy, status, createdAt, updatedAt }
note_item.dart        → NoteItem { id, documentId, title, body?, createdBy, createdAt, updatedAt }
resource_item.dart    → ResourceItem { id, documentId, title, url, description?, createdBy, tags, isReadByMe, createdAt, updatedAt }
pantry_item.dart      → PantryItem { id, documentId, name, category, minThreshold?, isHidden, quantities, createdAt, updatedAt }
pantry_quantity.dart  → PantryQuantity { id, pantryItemId, unitType, value, createdAt }
shopping_list_item.dart → ShoppingListItem { id, documentId, pantryItemId?, customName?, unitType?, quantityValue?, isChecked, createdAt }
```

**Enum da creare:**
```dart
enum AsteriskStatus { active, archived }
enum PantryCategory { frigo, surgelati, dispensa, pulizia, casa }
enum PantryUnitType { kg, litri, pezzi, confezioni }
```

**Logica `PantryItem.isMissing`:**
```dart
bool get isMissing {
  if (isHidden) return false;
  if (quantities.isEmpty) return true;
  if (minThreshold == null) return false;
  final total = quantities.fold(0.0, (sum, q) => sum + q.value);
  return total < minThreshold!;
}
```

---

## Services Layer

Tutti i service seguono il **singleton pattern** già usato in `ExpenseService`, `GroupService`, etc.

### Nuovi service (in `lib/features/space/services/`)

```
asterisk_service.dart
  - getAsterisksStream(documentId) → Stream<List<AsteriskItem>>
  - createAsterisk(documentId, title, body?)
  - archiveAsterisk(id)
  - updateBody(id, body)  // solo creatore — RLS protegge già a DB level

note_service.dart
  - getNotesStream(documentId) → Stream<List<NoteItem>>
  - createNote(documentId, title, body?)
  - updateNote(id, title, body)
  - deleteNote(id)

resource_service.dart
  - getResourcesStream(documentId) → Stream<List<ResourceItem>>
  - createResource(documentId, title, url, description?, tagIds)
  - markAsRead(resourceItemId)          // inserisce in resource_item_reads
  - preloadReadStatus(documentId)       // batch query per evitare N+1
  - deleteResource(id)

pantry_service.dart
  - getPantryItemsStream(documentId) → Stream<List<PantryItem>>
  - createPantryItem(documentId, name, category, minThreshold?)
  - addQuantity(pantryItemId, unitType, value)
  - removeQuantity(quantityId)
  - updateMinThreshold(pantryItemId, threshold?)
  - toggleHidden(pantryItemId)
  - getMissingItems(documentId) → List<PantryItem>  // computed client-side

shopping_list_service.dart
  - getShoppingListItemsStream(documentId) → Stream<List<ShoppingListItem>>
  - createFromMissingItems(shoppingListDocId, pantryItems)
  - addManualItem(documentId, name, unitType?, value?)
  - toggleCheck(itemId)
  - confirmPurchase(documentId)  // "Spesa fatta": aggiunge quantità alla dispensa per tutti gli item checked
  - deleteItem(id)
```

### DocumentService — metodo da aggiungere

Il `DocumentService` già gestisce i CRUD sui `documents`. Aggiungere:
```dart
// Fetch lista documenti per contesto e tipo
Future<List<Document>> getDocumentsForContext(
  ExpenseContext context,
  String documentType,
)
Stream<List<Document>> watchDocumentsForContext(
  ExpenseContext context,
  String documentType,
)
```

---

## State Management (BLoC)

### Pattern di riferimento: `UnifiedTaskListBloc`

Ogni tipologia ha il suo BLoC in `lib/features/space/blocs/<tipologia>/`.
Struttura standard:

```
blocs/
├── asterisks/
│   ├── asterisk_bloc.dart
│   ├── asterisk_event.dart
│   └── asterisk_state.dart
├── notes/
│   ├── note_bloc.dart
│   ├── note_event.dart
│   └── note_state.dart
├── resources/
│   ├── resource_bloc.dart
│   ├── resource_event.dart
│   └── resource_state.dart
└── pantry/
    ├── pantry_bloc.dart
    ├── pantry_event.dart
    └── pantry_state.dart
    shopping_list/
    ├── shopping_list_bloc.dart
    ├── shopping_list_event.dart
    └── shopping_list_state.dart
```

### Reazione ai cambi di contesto

Ogni BLoC deve ascoltare `ContextManager` e ricaricare i dati quando cambia il contesto:

```dart
class AsteriskBloc extends Bloc<AsteriskEvent, AsteriskState> {
  final _contextManager = ContextManager();

  AsteriskBloc() : super(AsteriskInitial()) {
    _contextManager.addListener(_onContextChanged);
    // ...
  }

  void _onContextChanged() {
    add(AsteriskContextChanged());
  }

  @override
  Future<void> close() {
    _contextManager.removeListener(_onContextChanged);
    return super.close();
  }
}
```

---

## Navigation & Routing

### Bottom nav — modifica a `shell_with_nav.dart`

La tab "ToDo" (indice 1) diventa "Spazio":
```dart
// _pages: sostituire DocumentsHomeView() con SpaceHomeView()
static const List<Widget> _pages = [
  NewHomepage(),
  SpaceHomeView(),   // era DocumentsHomeView()
  DashboardHub(),
  ProfilePage(),
];

// BottomNavigationBarItem: aggiornare label e icona
BottomNavigationBarItem(
  icon: Icon(Icons.space_dashboard_outlined),
  label: 'Spazio',
),
```

### Routes — modifiche a `app_router.dart`

Sostituire `/notes` con struttura completa:

```dart
// RIMUOVERE:
GoRoute(path: '/notes', builder: ...DocumentsHomeView...)

// AGGIUNGERE:
GoRoute(path: '/space',             builder: (_, __) => const SpaceHomeView()),
GoRoute(path: '/space/tasks',       builder: (_, __) => const SpaceDocumentListView(type: 'todo')),
GoRoute(path: '/space/tasks/:id',   builder: (c, s)  => DocumentsHomeView(documentId: s.pathParameters['id']!)),
GoRoute(path: '/space/notes',       builder: (_, __) => const SpaceDocumentListView(type: 'note')),
GoRoute(path: '/space/notes/:id',   builder: (c, s)  => NoteListView(documentId: s.pathParameters['id']!)),
GoRoute(path: '/space/asterisks',   builder: (_, __) => const SpaceDocumentListView(type: 'asterisk')),
GoRoute(path: '/space/asterisks/:id', builder: (c, s) => AsteriskListView(documentId: s.pathParameters['id']!)),
GoRoute(path: '/space/resources',   builder: (_, __) => const SpaceDocumentListView(type: 'resource_list')),
GoRoute(path: '/space/resources/:id', builder: (c, s) => ResourceListView(documentId: s.pathParameters['id']!)),
GoRoute(path: '/space/pantry',      builder: (_, __) => const SpaceDocumentListView(type: 'dispensa')),
GoRoute(path: '/space/pantry/:id',  builder: (c, s)  => PantryView(documentId: s.pathParameters['id']!)),
GoRoute(
  path: '/space/pantry/:pantryId/shopping/:id',
  builder: (c, s) => ShoppingListView(
    documentId:    s.pathParameters['id']!,
    pantryDocumentId: s.pathParameters['pantryId']!,
  ),
),
```

### `SpaceDocumentListView` — widget generico

Un unico widget riutilizzabile che mostra la lista dei Document di un tipo per il contesto corrente, con bottone "Crea nuova lista". Riceve `documentType` come parametro.

---

## Context Awareness

### Come i service filtrano per contesto

```dart
// In ogni service — esempio per AsteriskService
Stream<List<AsteriskItem>> getAsterisksForContext(
  ExpenseContext context,
  String documentId,
) {
  // Il documentId è già filtrato per contesto (viene da SpaceDocumentListView)
  // Il service lavora sempre su un documento specifico
  return _supabase
    .from('asterisk_items')
    .stream(primaryKey: ['id'])
    .eq('document_id', documentId)
    .map(...);
}
```

### Come DocumentService filtra i documenti per contesto

```dart
Future<List<Document>> getDocumentsForContext(
  ExpenseContext context,
  String documentType,
) async {
  var query = _supabase
    .from('documents')
    .select()
    .eq('document_type', documentType);

  if (context.isPersonal) {
    final userId = AuthService().currentUserId!;
    query = query.eq('user_id', userId).isFilter('group_id', null);
  } else if (context.isGroup) {
    query = query.eq('group_id', context.groupId!);
  } else if (context.isView) {
    // Vista: tutti i group_id della vista + opzionalmente personal
    query = query.inFilter('group_id', context.groupIds);
    if (context.view!.includePersonal) {
      // Supabase non supporta OR nativamente su stream — usare RPC o fetch separato e merge
    }
  }

  final data = await query;
  return data.map((m) => Document.fromMap(m)).toList();
}
```

---

## RLS Policies

### documents
```sql
-- Lettura: personal (user_id) o membro del gruppo (group_id)
CREATE POLICY "space_documents_select" ON documents FOR SELECT TO authenticated
USING (
  user_id = auth.uid()
  OR group_id IN (SELECT group_id FROM group_members WHERE user_id = auth.uid())
);

-- Insert: personal o membro del gruppo
CREATE POLICY "space_documents_insert" ON documents FOR INSERT TO authenticated
WITH CHECK (
  (user_id = auth.uid() AND group_id IS NULL)
  OR group_id IN (SELECT group_id FROM group_members WHERE user_id = auth.uid())
);
```

### asterisk_items — body visibile solo al creatore
```sql
-- Tutti i membri vedono il record, ma body viene mascherato via view o gestito in app
-- Approccio consigliato: colonna body leggibile solo se created_by = auth.uid()
-- Implementazione: SELECT con CASE oppure Column-Level Security (Postgres 15+)
-- Alternativa più semplice: il client Flutter ignora il body se created_by != currentUser

CREATE POLICY "asterisk_items_select" ON asterisk_items FOR SELECT TO authenticated
USING (
  document_id IN (
    SELECT id FROM documents
    WHERE user_id = auth.uid()
    OR group_id IN (SELECT group_id FROM group_members WHERE user_id = auth.uid())
  )
);
-- NOTA: la logica "body visibile solo al creatore" è gestita lato Flutter:
-- se item.createdBy != currentUserId → body viene ignorato/non mostrato
-- Il body viene incluso nella risposta ma l'app lo oscura
```

### note_items, resource_items, pantry_items, shopping_list_items
```sql
-- Pattern identico: accesso via document_id → documents → gruppo/personal
-- Replicare il pattern di asterisk_items_select per ogni tabella
```

---

## File Structure

```
lib/
├── features/
│   ├── documents/              (esistente — invariato)
│   └── space/
│       ├── models/
│       │   ├── asterisk_item.dart
│       │   ├── note_item.dart
│       │   ├── resource_item.dart
│       │   ├── pantry_item.dart
│       │   ├── pantry_quantity.dart
│       │   └── shopping_list_item.dart
│       ├── services/
│       │   ├── asterisk_service.dart
│       │   ├── note_service.dart
│       │   ├── resource_service.dart
│       │   ├── pantry_service.dart
│       │   └── shopping_list_service.dart
│       ├── blocs/
│       │   ├── asterisks/
│       │   │   ├── asterisk_bloc.dart
│       │   │   ├── asterisk_event.dart
│       │   │   └── asterisk_state.dart
│       │   ├── notes/
│       │   ├── resources/
│       │   └── pantry/
│       │       ├── pantry/
│       │       └── shopping_list/
│       └── views/
│           ├── space_home_view.dart
│           ├── space_document_list_view.dart  (widget generico per listing)
│           ├── tasks/                         (wrappa DocumentsHomeView)
│           ├── notes/
│           │   ├── note_list_view.dart
│           │   └── note_detail_view.dart
│           ├── asterisks/
│           │   ├── asterisk_list_view.dart
│           │   └── asterisk_detail_view.dart  (solo per il creatore)
│           ├── resources/
│           │   ├── resource_list_view.dart
│           │   └── resource_form_dialog.dart
│           └── pantry/
│               ├── pantry_view.dart
│               ├── pantry_item_form_dialog.dart
│               └── shopping_list/
│                   └── shopping_list_view.dart
│
├── models/
│   └── document.dart           (aggiungere i nuovi subtypes al factory fromMap)
│
├── views/
│   └── shell_with_nav.dart     (aggiungere tab Spazio, sostituire DocumentsHomeView)
│
└── routes/
    └── app_router.dart         (aggiungere routes /space/*)
```

---

## Note Implementative

### Priorità di query performance
- Aggiungere `idx_pantry_items_document_id`, `idx_asterisk_items_document_id`, etc. — già inclusi nello schema
- `resource_item_reads`: fare una query batch per documento (non per singola risorsa) — evitare N+1
- `pantry_quantities`: fare join con `pantry_items` in una sola query

### Shopping list — logica "Spesa fatta"
```dart
Future<void> confirmPurchase(String shoppingListDocumentId) async {
  // 1. Fetch tutti gli item checked della lista
  // 2. Per ogni item con pantry_item_id:
  //    - Inserire una nuova PantryQuantity con unitType e quantityValue
  // 3. Opzionalmente: deselezionare tutti gli item o cancellare la lista
  // La dispensa NON cancella le quantità esistenti — si aggiungono
}
```

### Task — campo assigned_to
Il campo `assigned_to` si aggiunge al model `Task`, al `toMap()`/`fromMap()`, e al form di creazione/edit. I member sono caricati da `GroupService().getGroupMembers(groupId)` quando il contesto è un gruppo.
