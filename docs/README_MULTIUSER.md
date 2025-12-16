# 🎯 Solducci Multi-User System

## 📖 Overview

Solducci è stato trasformato da un'app single-user a un sistema multi-user che permette di:
- Gestire spese personali
- Creare gruppi/coppie per condividere spese
- Dividere spese tra membri del gruppo
- Invitare altri utenti via email
- Switchare facilmente tra contesto personale e gruppi


ciao pitucciii <3

## 🏗️ Architettura

### Context-Based Architecture

Il cuore del sistema è il **ContextManager**, un singleton con `ChangeNotifier` che gestisce il contesto corrente (Personal o Group).

```
┌─────────────────────────────────────────┐
│         ContextManager (Singleton)      │
│                                         │
│  _currentContext: ExpenseContext        │
│  - Personal                             │
│  - Group (with ExpenseGroup data)      │
│                                         │
│  Methods:                               │
│  - switchToPersonal()                   │
│  - switchToGroup(group)                 │
│  - initialize() // load groups          │
└─────────────────┬───────────────────────┘
                  │ notifyListeners()
                  ↓
    ┌─────────────────────────────┐
    │    ExpenseService.stream    │
    │  (auto-filtered by context) │
    └──────────────┬──────────────┘
                   │
                   ↓
          ┌────────────────┐
          │   ExpenseList   │
          │  (rebuilds auto) │
          └────────────────┘
```

## 🗄️ Database Schema

### Nuove Tabelle

1. **profiles**
   - `id` (UUID) - FK to auth.users
   - `email` (TEXT)
   - `nickname` (TEXT) - Nome/soprannome utente
   - `avatar_url` (TEXT) - URL avatar (opzionale)

2. **groups**
   - `id` (UUID)
   - `name` (TEXT) - Nome gruppo
   - `description` (TEXT)
   - `created_by` (UUID) - FK to profiles

3. **group_members**
   - `id` (UUID)
   - `group_id` (UUID) - FK to groups
   - `user_id` (UUID) - FK to profiles
   - `role` (TEXT) - 'admin' o 'member'
   - `joined_at` (TIMESTAMPTZ)

4. **group_invites**
   - `id` (UUID)
   - `group_id` (UUID) - FK to groups
   - `inviter_id` (UUID) - FK to profiles
   - `invitee_email` (TEXT) - Email destinatario
   - `invitee_id` (UUID) - FK to profiles (dopo accettazione)
   - `status` (TEXT) - 'pending', 'accepted', 'rejected', 'expired'
   - `expires_at` (TIMESTAMPTZ) - Scade dopo 7 giorni

5. **expense_splits**
   - `id` (UUID)
   - `expense_id` (INT) - FK to expenses
   - `user_id` (UUID) - FK to profiles
   - `amount` (NUMERIC) - Importo da pagare
   - `paid` (BOOLEAN) - Se pagato
   - `paid_at` (TIMESTAMPTZ)

### Modifiche alla Tabella `expenses`

Nuove colonne aggiunte:
- `group_id` (UUID) - FK to groups (NULL per spese personali)
- `paid_by` (UUID) - FK to profiles (chi ha pagato)
- `split_type` (TEXT) - 'equal', 'custom', 'full', 'none'
- `split_data` (JSONB) - Dati split personalizzato

### Row Level Security (RLS)

Tutte le tabelle hanno RLS abilitato con policy che:
- Limitano l'accesso solo ai dati dell'utente
- Permettono la visualizzazione solo dei gruppi di appartenenza
- Controllano chi può modificare/eliminare

**File Migration**: `supabase/migrations/001_multi_user_setup_v2.sql`

## 🔧 Dart Models

### UserProfile
```dart
class UserProfile {
  final String id;           // UUID auth.users
  final String email;
  String nickname;           // Editabile
  String? avatarUrl;

  String get initials;       // Es: "Carl" → "C", "Maria Rossi" → "MR"
}
```

### ExpenseGroup
```dart
class ExpenseGroup {
  final String id;
  String name;               // Nome gruppo
  String? description;
  final String createdBy;    // Creator = admin
  List<GroupMember>? members;
  int? memberCount;
}
```

### GroupMember
```dart
class GroupMember {
  final String id;
  final String groupId;
  final String userId;
  final GroupRole role;      // admin | member
  String? nickname;          // Denormalized per UI
  String? email;
}

enum GroupRole { admin, member }
```

### GroupInvite
```dart
class GroupInvite {
  final String id;
  final String groupId;
  final String inviterId;
  final String inviteeEmail; // Invitato via email
  String? inviteeId;         // Collegato dopo signup
  InviteStatus status;
  final DateTime expiresAt;

  bool get isExpired;
  bool get isPending;
}

enum InviteStatus { pending, accepted, rejected, expired }
```

### Expense (Modificato)
```dart
class Expense {
  // ... campi esistenti ...

  // NEW: Multi-user support
  String? groupId;           // Group expense (NULL = personal)
  String? paidBy;            // UUID chi ha pagato
  SplitType? splitType;      // Come dividere
  Map<String, double>? splitData; // Split custom

  bool get isPersonal => groupId == null;
  bool get isGroup => groupId != null;
}

enum SplitType {
  equal,    // Diviso equamente
  custom,   // Importi custom per persona
  full,     // Una persona paga tutto
  none      // Non dividere
}
```

## 🛠️ Services

### 1. ProfileService

Gestisce i profili utente.

```dart
// Get current user profile
final profile = await ProfileService().getCurrentUserProfile();

// Update nickname
await ProfileService().updateNickname('Carl');

// Search user by email (for invites)
final user = await ProfileService().searchByEmail('friend@email.com');

// Update avatar
await ProfileService().updateAvatarUrl('https://...');
```

### 2. GroupService

Gestisce gruppi, membri e inviti.

```dart
final groupService = GroupService();

// Create group
final group = await groupService.createGroup(
  name: 'Coppia Carl & Pit',
  description: 'Spese di casa',
);

// Get user's groups
final myGroups = await groupService.getUserGroups();

// Get group members
final members = await groupService.getGroupMembers(groupId);

// Send invite
await groupService.sendInvite(
  groupId: groupId,
  inviteeEmail: 'friend@email.com',
);

// Get pending invites for current user
final invites = await groupService.getPendingInvites();

// Accept invite
await groupService.acceptInvite(inviteId);

// Leave group
await groupService.leaveGroup(groupId);

// Delete group (admin only)
await groupService.deleteGroup(groupId);
```

### 3. ContextManager ⭐ (CORE)

Il cuore del sistema multi-user!

```dart
final contextManager = ContextManager(); // Singleton

// Initialize (call in main.dart after login)
await contextManager.initialize();

// Switch to personal context
contextManager.switchToPersonal();

// Switch to group context
contextManager.switchToGroup(selectedGroup);

// Get current context
final context = contextManager.currentContext;
print(context.displayName); // "Personale" o "Nome Gruppo"
print(context.isPersonal);  // true/false
print(context.groupId);     // UUID o null

// Get user's groups
final groups = contextManager.userGroups;

// Create and switch to new group
final newGroup = await contextManager.createAndSwitchToGroup(
  name: 'Nuovo Gruppo',
);

// Listen to context changes
contextManager.addListener(() {
  print('Context changed to: ${contextManager.contextDisplayName}');
});
```

### 4. ExpenseService (Context-Aware)

Ora filtra automaticamente in base al contesto!

```dart
final expenseService = ExpenseService();

// Stream auto-filtered by context!
StreamBuilder<List<Expense>>(
  stream: expenseService.stream,
  // Se context è Personal → solo spese user_id senza group_id
  // Se context è Group → solo spese del group_id corrente
  builder: (context, snapshot) {
    // ...
  },
)

// Create expense (auto-set groupId or userId)
await expenseService.createExpense(expense);
// Se in contesto Group → imposta expense.groupId automaticamente
// Se in contesto Personal → imposta expense.userId

// Get specific group expenses
final groupExpenses = await expenseService.getGroupExpenses(groupId);

// Get only personal expenses
final personalExpenses = await expenseService.getPersonalExpenses();
```

## 📱 UI Components

### ProfilePage (✅ Completato - Fase 3A)

Mostra:
- Avatar con iniziali
- Nickname (editabile)
- Email
- Lista gruppi utente
- Badge inviti pendenti
- Pull-to-refresh

**Features**:
- Click edit nickname → Dialog per modificare
- Click gruppo → Vai a dettagli (TODO)
- Click inviti → Vai a lista inviti (TODO)

**File**: `lib/views/profile_page.dart`

### Context Switcher Widget (⏳ Fase 3B - Prossima)

Widget per switchare tra Personal e Group contexts.

**Posizionamento**: AppBar di `NewHomepage`

**UI Proposta**:
```dart
// In AppBar
actions: [
  ContextSwitcher(), // Widget da creare
]

// Mostra: "👤 Personale" o "👥 Nome Gruppo"
// Tap → BottomSheet con:
//   • Personale (radio)
//   • Gruppo 1 (radio)
//   • Gruppo 2 (radio)
//   • ────────────
//   • ➕ Crea Nuovo Gruppo
```

**Funzionamento**:
1. Mostra contesto corrente
2. Tap → Apre BottomSheet
3. Selezione → Chiama `ContextManager.switchToXXX()`
4. ContextManager notifyListeners()
5. ExpenseList rebuilds con nuovi dati!

## 🔄 Data Flow

### Scenario: User Switcha da Personal a Group

```
1. User tap su Context Switcher
   ↓
2. Apre BottomSheet con lista gruppi
   ↓
3. User seleziona "Gruppo Carl & Pit"
   ↓
4. UI chiama: ContextManager().switchToGroup(selectedGroup)
   ↓
5. ContextManager:
   - _currentContext = ExpenseContext.group(selectedGroup)
   - notifyListeners() ← Trigger rebuild
   ↓
6. ExpenseService.stream rebuilds:
   - Legge nuovo context
   - Filtra .eq('group_id', context.groupId)
   - Emette nuovi dati
   ↓
7. ExpenseList (StreamBuilder) rebuilds
   ↓
8. UI mostra solo spese del gruppo! ✨
```

### Scenario: User Crea Nuova Spesa

```
1. User in contesto "Gruppo Carl & Pit"
   ↓
2. User clicca "Aggiungi Spesa"
   ↓
3. Compila form (amount, description, etc.)
   ↓
4. Submit → ExpenseService.createExpense(newExpense)
   ↓
5. ExpenseService:
   - Legge context = ContextManager().currentContext
   - Se context.isGroup → imposta expense.groupId = context.groupId
   - Se context.isPersonal → imposta expense.userId = auth.uid()
   ↓
6. Insert nel DB con RLS policy che verifica ownership
   ↓
7. Stream emette nuovo evento
   ↓
8. ExpenseList rebuilds con la nuova spesa ✨
```

## 🧪 Testing

### Manual Testing Checklist

#### Database Setup
- [ ] Esegui migration v2 in Supabase SQL Editor
- [ ] Verifica tabelle create: `SELECT * FROM profiles;`
- [ ] Verifica RLS abilitato: Query da Supabase Dashboard
- [ ] Signup nuovo utente → Verifica profilo auto-creato

#### ProfilePage
- [ ] Apri tab Profilo
- [ ] Verifica nickname mostrato
- [ ] Click edit → Modifica nickname → Salva
- [ ] Verifica aggiornamento UI
- [ ] Pull-to-refresh funziona

#### Context Switching (Manuale per ora)
```dart
// Nel debug/dev tools
ContextManager().switchToPersonal();
// Verifica expense_list mostra solo personali

ContextManager().switchToGroup(myGroup);
// Verifica expense_list mostra solo gruppo
```

#### Group Creation
```dart
final group = await GroupService().createGroup(name: 'Test Group');
// Verifica gruppo creato nel DB
// Verifica creator aggiunto come admin in group_members
```

#### Invites
```dart
await GroupService().sendInvite(
  groupId: groupId,
  inviteeEmail: 'test@email.com',
);
// Verifica invite creato nel DB
// Login con test@email.com
// Verifica getPendingInvites() restituisce l'invito
```

## 📦 Installation & Setup

### 1. Database Migration

```bash
# Copy content from:
cat supabase/migrations/001_multi_user_setup_v2.sql

# Paste in Supabase Dashboard → SQL Editor → Run
```

### 2. Flutter Dependencies

Già incluse in `pubspec.yaml`:
```yaml
dependencies:
  supabase_flutter: ^2.6.0
  go_router: ^14.6.2
```

### 3. Initialize ContextManager

In `lib/main.dart`:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: yourSupabaseUrl,
    anonKey: yourAnonKey,
  );

  // IMPORTANT: Initialize ContextManager after login
  final session = Supabase.instance.client.auth.currentSession;
  if (session != null) {
    await ContextManager().initialize();
  }

  runApp(const SolducciApp());
}
```

### 4. Listen to Auth State Changes

```dart
Supabase.instance.client.auth.onAuthStateChange.listen((data) {
  final session = data.session;
  if (session != null) {
    // User logged in
    ContextManager().initialize();
  } else {
    // User logged out
    ContextManager().clear();
  }
});
```

## 🚀 Roadmap

### ✅ Completato (Fase 1-3A)
- [x] Database schema multi-user
- [x] RLS policies (non-recursive)
- [x] Dart models completi
- [x] Services (Profile, Group, Context, Expense)
- [x] ProfilePage con UI multi-user

### ⏳ In Corso / Prossimi (Fase 3B-D)
- [ ] Context Switcher Widget (Fase 3B)
- [ ] CreateGroupPage (Fase 3C)
- [ ] GroupDetailPage (Fase 3C)
- [ ] InviteMemberPage (Fase 3C)
- [ ] PendingInvitesPage (Fase 3C)
- [ ] Expense Form multi-user (Fase 3D)
  - [ ] "Chi ha pagato?" dropdown
  - [ ] Split type selector
  - [ ] UI per split custom
- [ ] Debt calculation multi-user (Fase 4)
- [ ] Notifiche push per inviti (Fase 5)
- [ ] Settings avanzate gruppi (Fase 5)

## 📚 Documentation

- [FASE_2_COMPLETATA.md](docs/FASE_2_COMPLETATA.md) - Dettagli modelli e services
- [FASE_3A_COMPLETATA.md](docs/FASE_3A_COMPLETATA.md) - ProfilePage update
- [CURRENT_STATUS.md](docs/CURRENT_STATUS.md) - Status corrente del progetto
- [DATABASE_MIGRATION_STATUS.md](docs/DATABASE_MIGRATION_STATUS.md) - Guida migration

## 🤝 Contributing

Quando aggiungi nuove features:

1. Se crei una nuova tabella → Aggiungi RLS policies
2. Se crei un nuovo model → Aggiungi factory `fromMap()` e `toMap()`
3. Se crei un nuovo service → Usa singleton pattern
4. Se crei una nuova UI → Considera se deve essere context-aware

## 📞 Support

Per domande o problemi:
- Controlla [CURRENT_STATUS.md](docs/CURRENT_STATUS.md) per lo stato attuale
- Verifica [FASE_X_COMPLETATA.md](docs/) per dettagli implementazione
- Test database con query SQL in Supabase Dashboard

## 🎉 Summary

Il sistema multi-user è **tecnicamente completo** al backend:
- ✅ Database pronto
- ✅ Models pronti
- ✅ Services pronti
- ✅ Context management funzionante

Manca solo l'UI per:
- Switchare tra contexts (Context Switcher) ← NEXT
- Gestire gruppi (Create, Detail, Invites)
- Creare spese multi-user (Form con split)

Una volta completate queste UI, l'app sarà **completamente multi-user**! 🚀
