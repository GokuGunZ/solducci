# ✅ FASE 3B COMPLETATA: Context Switcher Widget

## 🎉 Cosa è Stato Implementato

Il **Context Switcher** è ora completamente funzionante! Questo è il cuore del sistema multi-user che permette di switchare tra spese personali e gruppi.

## 📁 File Creati

### 1. [lib/widgets/context_switcher.dart](../lib/widgets/context_switcher.dart)
**Widget principale che mostra il contesto corrente e permette di switchare**

**Features**:
- ✅ Mostra icona + nome contesto (👤 Personale o 👥 Nome Gruppo)
- ✅ Tap apre BottomSheet con lista contesti
- ✅ Radio button per selezione
- ✅ Sezione "I TUOI GRUPPI" con tutti i gruppi dell'utente
- ✅ Bottone "Crea Nuovo Gruppo" (link a placeholder)
- ✅ `ListenableBuilder` per rebuild automatico
- ✅ Check icon verde sul contesto selezionato
- ✅ Draggable BottomSheet (scorri handle bar)

**UI Details**:
```dart
// In AppBar mostra:
👤 Personale ▼    // Se contesto personal
👥 Coppia Carl & Pit ▼  // Se contesto gruppo

// Tap → Apre BottomSheet:
┌─────────────────────────────────┐
│    Seleziona Contesto           │
├─────────────────────────────────┤
│ ⦿ 👤 Personale                  │ ← Selected
│   Le tue spese personali        │
├─────────────────────────────────┤
│     I TUOI GRUPPI               │
├─────────────────────────────────┤
│ ○ 👥 Coppia Carl & Pit          │
│   2 membri                      │
│ ○ 👥 Casa Coinquilini           │
│   4 membri                      │
├─────────────────────────────────┤
│ ➕ Crea Nuovo Gruppo            │
└─────────────────────────────────┘
```

## 📁 File Modificati

### 2. [lib/views/new_homepage.dart](../lib/views/new_homepage.dart)
**Aggiunto Context Switcher in AppBar**

**Modifiche**:
- Import: `import 'package:solducci/widgets/context_switcher.dart';`
- AppBar title: `title: const ContextSwitcher()`

**Prima**:
```dart
AppBar(
  title: const Text("Solducci - Home"),
  ...
)
```

**Dopo**:
```dart
AppBar(
  title: const ContextSwitcher(),
  ...
)
```

### 3. [lib/views/expense_list.dart](../lib/views/expense_list.dart)
**Aggiunto Context Switcher in AppBar**

**Modifiche**:
- Import: `import 'package:solducci/widgets/context_switcher.dart';`
- AppBar title: `title: const ContextSwitcher()`

### 4. [lib/main.dart](../lib/main.dart)
**Inizializzazione ContextManager al login**

**Modifiche**:
- Import: `import 'package:solducci/service/context_manager.dart';`
- Inizializza ContextManager se utente già loggato
- Listener su `onAuthStateChange` per init/clear automatico

**Codice aggiunto**:
```dart
// Initialize ContextManager if user is already logged in
final session = Supabase.instance.client.auth.currentSession;
if (session != null) {
  await ContextManager().initialize();
}

// Listen to auth state changes
Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
  if (data.session != null) {
    // User logged in
    await ContextManager().initialize();
  } else {
    // User logged out
    ContextManager().clear();
  }
});
```

### 5. [lib/routes/app_router.dart](../lib/routes/app_router.dart)
**Aggiunta route placeholder per create group**

**Route aggiunta**:
```dart
GoRoute(
  path: '/groups/create',
  builder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('Crea Nuovo Gruppo')),
    body: Center(
      child: Text('Questa funzionalità sarà disponibile nella prossima fase (FASE 3C).'),
    ),
  ),
),
```

## 🎯 Come Funziona

### Architettura

```
User tap su Context Switcher
    ↓
Apre BottomSheet con ListenableBuilder
    ↓
Mostra: Personal + Lista Gruppi (da ContextManager)
    ↓
User seleziona gruppo
    ↓
Chiama: ContextManager().switchToGroup(selectedGroup)
    ↓
ContextManager.notifyListeners()
    ↓
Context Switcher rebuilds (mostra nuovo nome)
    ↓
ExpenseService.stream rebuilds (filtra per nuovo contesto)
    ↓
ExpenseList/Homepage rebuilds (mostra spese filtrate)
```

### Data Flow

1. **ContextManager** (Singleton ChangeNotifier)
   - Mantiene `_currentContext` (Personal o Group)
   - Mantiene `_userGroups` (lista gruppi utente)
   - Metodi: `switchToPersonal()`, `switchToGroup(group)`
   - Notifica listeners al cambio

2. **Context Switcher Widget**
   - `ListenableBuilder` ascolta ContextManager
   - Mostra contesto corrente
   - Permette selezione nuovo contesto

3. **ExpenseService**
   - Stream filtra automaticamente in base a `ContextManager().currentContext`
   - Se Personal → spese con `user_id` e `group_id == null`
   - Se Group → spese con `group_id == context.groupId`

4. **UI (ExpenseList/Homepage)**
   - `StreamBuilder` su `ExpenseService.stream`
   - Rebuild automatico al cambio contesto

## 🧪 Come Testare

### Test 1: Context Switcher Appare
1. **Avvia app**: `flutter run`
2. **Fai login**
3. **Vai a Home o Spese**
4. **Verifica**: Dovresti vedere "👤 Personale ▼" in AppBar
5. **Tap** sul switcher
6. **Verifica**: Si apre BottomSheet con "Seleziona Contesto"

### Test 2: Nessun Gruppo (Primo Avvio)
1. **In BottomSheet**, verifica lista:
   - ✅ Opzione "Personale" con check verde
   - ✅ Sezione "I TUOI GRUPPI" (vuota se non hai gruppi)
   - ✅ Bottone "Crea Nuovo Gruppo"

### Test 3: Crea Gruppo (Placeholder)
1. **Tap** su "Crea Nuovo Gruppo"
2. **Verifica**: Naviga a pagina placeholder
3. **Verifica**: Mostra messaggio "Questa funzionalità sarà disponibile nella prossima fase"
4. **Tap** back

### Test 4: Switch Contesto (Con Gruppo)
**Setup**: Prima crea un gruppo via SQL:
```sql
-- Trova tuo user ID
SELECT id FROM auth.users WHERE email = 'tua-email@qui.com';

-- Crea gruppo test
DO $$
DECLARE
  user_uuid UUID := 'TUO-USER-ID'::uuid;
  new_group_id UUID;
BEGIN
  INSERT INTO groups (name, description, created_by)
  VALUES ('Test Gruppo', 'Gruppo di test', user_uuid)
  RETURNING id INTO new_group_id;

  INSERT INTO group_members (group_id, user_id, role)
  VALUES (new_group_id, user_uuid, 'admin');
END $$;
```

**Test**:
1. **Riavvia app** (o pull-to-refresh in Profile)
2. **Tap** Context Switcher
3. **Verifica**: "Test Gruppo" appare nella lista
4. **Tap** su "Test Gruppo"
5. **Verifica**: BottomSheet si chiude
6. **Verifica**: Switcher ora mostra "👥 Test Gruppo ▼"
7. **Verifica**: Console log: `🔄 Switching to Group context: Test Gruppo`

### Test 5: Filtraggio Spese
1. **In contesto Personal**: Crea una spesa
2. **Switch a gruppo** (se hai creato via SQL)
3. **Verifica**: La spesa personale NON appare più
4. **Switch back a Personal**
5. **Verifica**: La spesa personale riappare

### Test 6: Logout/Login
1. **Fai logout**
2. **Verifica console**: Vedi `🔧 User logged out, clearing ContextManager...`
3. **Fai login**
4. **Verifica console**: Vedi `🔧 User logged in, initializing ContextManager...`
5. **Verifica**: Context Switcher inizia su "Personale"

## 📊 Console Output Atteso

Quando tutto funziona correttamente, dovresti vedere:

```
🔧 Loading environment variables...
✅ Environment variables loaded successfully
🔧 Initializing Supabase...
✅ Supabase initialized successfully
🚀 Starting Solducci app...
🔧 User logged in, initializing ContextManager...
🔄 Initializing ContextManager...
✅ Loaded 1 groups
✅ ContextManager initialized with 1 groups
✅ ContextManager initialized

// Quando tap su gruppo:
🔄 Switching to Group context: Test Gruppo

// Quando tap su Personal:
🔄 Switching to Personal context
```

## ✅ Acceptance Criteria

### Must Work
- [x] Context Switcher visibile in AppBar (Home + Spese)
- [x] Tap apre BottomSheet
- [x] BottomSheet mostra "Personale" con radio button
- [x] BottomSheet mostra lista gruppi (se presenti)
- [x] Selezione cambia contesto
- [x] Switcher UI si aggiorna (mostra nuovo nome)
- [x] ExpenseList si filtra automaticamente
- [x] Bottone "Crea Nuovo Gruppo" naviga a placeholder
- [x] Logout pulisce ContextManager
- [x] Login inizializza ContextManager

### Known Limitations
- ❌ Nessuna pagina per creare gruppi (FASE 3C)
- ❌ Nessuna pagina dettaglio gruppo (FASE 3C)
- ❌ Nessuna pagina per inviti (FASE 3C)
- ❌ Expense form NON è ancora multi-user (FASE 3D)

## 🚀 Prossimo Step: FASE 3C

Ora che il Context Switcher funziona, possiamo implementare:

### **FASE 3C1: CreateGroupPage**
- Form per creare nuovo gruppo
- Input: nome, descrizione
- Opzionale: invita membri subito
- Dopo creazione → Switch automatico al nuovo gruppo

### **FASE 3C2: GroupDetailPage**
- Info gruppo (nome, descrizione, membri)
- Riepilogo debiti (usa `calculate_group_debts()`)
- Lista membri con ruoli
- Bottone "Invita Membro"
- Bottone "Lascia Gruppo"
- Bottone "Elimina Gruppo" (solo admin)

### **FASE 3C3: InviteMemberPage**
- Form: email destinatario
- Submit → Crea invite nel DB
- Torna a GroupDetailPage

### **FASE 3C4: PendingInvitesPage**
- Lista inviti pendenti
- Card per ogni invito (gruppo, inviter, scadenza)
- Bottoni "Accetta" / "Rifiuta"

## 📝 Notes

### Perché ListenableBuilder?
Usiamo `ListenableBuilder` invece di `Consumer<ContextManager>` perché:
1. ContextManager è un Singleton (non serve Provider)
2. `ListenableBuilder` è built-in in Flutter
3. Più semplice da usare

### Perché Singleton?
ContextManager è singleton perché:
1. Deve essere accessibile da tutta l'app
2. Stato globale (contesto corrente)
3. Un'unica istanza sincronizza tutto

### Performance
- BottomSheet è lazy-loaded (creato solo al tap)
- `ListenableBuilder` rebuilds solo quando necessario
- Stream filtering è server-side (RLS + app)

## 🎉 Congratulazioni!

Il sistema multi-user è ora **FUNZIONANTE**!

Puoi:
- ✅ Vedere il contesto corrente
- ✅ Switchare tra Personal e Gruppi
- ✅ Vedere spese filtrate automaticamente
- ✅ Creare gruppi (via SQL per ora)

Il prossimo step è creare l'UI per gestire i gruppi (FASE 3C)! 🚀
