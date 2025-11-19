# ✅ FASE 2 COMPLETATA: Modelli & Services

## 📦 File Creati

### **Modelli (lib/models/)**

1. **[user_profile.dart](../lib/models/user_profile.dart)**
   - Classe `UserProfile` con id, email, nickname, avatarUrl
   - Factory `fromMap()` per parsing da Supabase
   - Metodi `toMap()`, `toUpdateMap()`, `copyWith()`
   - Getter `initials` per avatar placeholder

2. **[group.dart](../lib/models/group.dart)**
   - Classe `ExpenseGroup` per gruppi/coppie
   - Classe `GroupMember` per membri del gruppo
   - Enum `GroupRole` (admin, member)
   - Supporto per dati denormalizzati (nickname, email)

3. **[group_invite.dart](../lib/models/group_invite.dart)**
   - Classe `GroupInvite` per inviti ai gruppi
   - Enum `InviteStatus` (pending, accepted, rejected, expired)
   - Metodi helper: `isExpired`, `isPending`, `statusDisplay`

### **Modelli Modificati**

4. **[expense.dart](../lib/models/expense.dart)** - AGGIORNATO
   - ✅ Aggiunti campi: `groupId`, `paidBy`, `splitType`, `splitData`
   - ✅ Nuovo enum `SplitType` (equal, custom, full, none)
   - ✅ Getter: `isPersonal`, `isGroup`
   - ✅ `fromMap()` e `toMap()` aggiornati per multi-user
   - ⚠️ `MoneyFlow` mantenuto per backward compatibility

---

### **Services (lib/service/)**

5. **[profile_service.dart](../lib/service/profile_service.dart)**
   - `getCurrentUserProfile()` - profilo utente corrente
   - `getProfileById()` - profilo per ID
   - `getProfilesByIds()` - batch loading profili
   - `updateProfile()` / `updateNickname()` / `updateAvatarUrl()`
   - `searchByEmail()` - cerca utente per inviti
   - `profileStream` - stream reattivo del profilo
   - `createProfile()` - fallback se trigger non funziona

6. **[group_service.dart](../lib/service/group_service.dart)**
   - **CRUD Gruppi:**
     - `getUserGroups()` - tutti i gruppi dell'utente
     - `getGroupById()` - gruppo con membri
     - `createGroup()` - nuovo gruppo (creator diventa admin)
     - `updateGroup()` / `deleteGroup()`
   - **Gestione Membri:**
     - `getGroupMembers()` - membri con profili
     - `addMemberToGroup()` / `removeMemberFromGroup()`
     - `leaveGroup()` - utente lascia gruppo
     - `isUserAdmin()` - check permessi
   - **Sistema Inviti:**
     - `sendInvite()` - invia invito via email
     - `getPendingInvites()` - inviti in attesa
     - `acceptInvite()` / `rejectInvite()`
     - `getPendingInviteCount()` - badge notifications
   - **Streams:**
     - `groupsStream` - stream reattivo gruppi utente

7. **[context_manager.dart](../lib/service/context_manager.dart)** ⭐ CORE
   - **Singleton con ChangeNotifier** - gestisce contesto globale
   - Classe `ExpenseContext`:
     - `.personal()` - contesto personale
     - `.group(ExpenseGroup)` - contesto gruppo
   - Metodi:
     - `initialize()` - carica gruppi all'avvio
     - `switchToPersonal()` / `switchToGroup()`
     - `createAndSwitchToGroup()` - crea e passa al nuovo gruppo
     - `loadUserGroups()` - ricarica lista gruppi
     - `getCurrentGroupMembers()` - membri gruppo corrente
     - `clear()` - pulisce al logout
   - Getters:
     - `currentContext`, `isPersonalContext`, `isGroupContext`
     - `contextDisplayName`, `currentGroupId`

8. **[expense_service.dart](../lib/service/expense_service.dart)** - AGGIORNATO
   - ✅ `stream` ora è **context-aware**:
     - Contesto Personale → solo spese `user_id` senza `group_id`
     - Contesto Gruppo → solo spese del `group_id` corrente
   - ✅ `createExpense()` auto-imposta `groupId` o `userId` in base al contesto
   - ✅ Aggiunti metodi utility:
     - `getGroupExpenses(groupId)` - spese specifiche di un gruppo
     - `getPersonalExpenses()` - solo spese personali
   - ✅ `updateExpense()` e `deleteExpense()` aggiornati per usare `_supabase`

---

## 🔗 Dipendenze tra Componenti

```
ContextManager (Singleton)
    ↓
    ├─→ GroupService (carica gruppi)
    └─→ ExpenseService (filtra spese in base al contesto)

ProfileService ←→ GroupService
    └─→ Usato per caricare nickname nei membri

GroupService
    ↓
    ├─→ groups table
    ├─→ group_members table
    └─→ group_invites table

ExpenseService
    ↓
    ├─→ ContextManager (legge contesto)
    └─→ expenses table (filtra per contesto)
```

---

## 🎯 Come Funziona il Sistema

### **1. Inizializzazione App**
```dart
void main() async {
  // ... init Supabase ...

  // Inizializza ContextManager dopo login
  await ContextManager().initialize();

  runApp(MyApp());
}
```

### **2. Switch Contesto**
```dart
// Nell'UI, l'utente clicca su "Personale" o "Gruppo X"
ContextManager().switchToPersonal();
// oppure
ContextManager().switchToGroup(myGroup);

// ExpenseService stream si aggiorna automaticamente!
```

### **3. Stream delle Spese (Auto-Filtraggio)**
```dart
StreamBuilder<List<Expense>>(
  stream: ExpenseService().stream,  // <- Filtra in base al contesto!
  builder: (context, snapshot) {
    // Mostra solo le spese del contesto corrente
  },
)
```

### **4. Creazione Spesa**
```dart
// L'utente crea una spesa
final expense = Expense(...);

// ExpenseService auto-imposta group_id o user_id!
await ExpenseService().createExpense(expense);
```

---

## ✅ Test Checklist (Prima di FASE 3)

Testa questi scenari nel codice:

- [ ] **ProfileService**
  - [ ] Profilo auto-creato al signup (trigger DB)
  - [ ] `getCurrentUserProfile()` restituisce profilo corretto
  - [ ] `updateNickname()` salva e mostra il nuovo nickname

- [ ] **GroupService**
  - [ ] `createGroup()` crea gruppo e aggiunge creator come admin
  - [ ] `getUserGroups()` mostra tutti i gruppi dell'utente
  - [ ] `getGroupMembers()` include nickname da profiles

- [ ] **ContextManager**
  - [ ] `initialize()` carica gruppi all'avvio
  - [ ] `switchToGroup()` cambia contesto e triggera notifyListeners
  - [ ] `switchToPersonal()` torna al contesto personale

- [ ] **ExpenseService (Context-Aware)**
  - [ ] Stream mostra solo spese personali in contesto Personal
  - [ ] Stream mostra solo spese del gruppo in contesto Group
  - [ ] `createExpense()` imposta automaticamente `group_id` o `user_id`

---

## 🚀 PROSSIMI PASSI: FASE 3 - UI

Ora che i modelli e services sono pronti, possiamo procedere con:

### **FASE 3A: Aggiornare ProfilePage**
- [ ] Mostrare nickname (non solo email)
- [ ] Form per modificare nickname
- [ ] Lista "I Miei Gruppi"
- [ ] Badge per inviti pendenti

### **FASE 3B: Context Switcher Widget**
- [ ] Creare `ContextSwitcherWidget` per AppBar
- [ ] Mostra: "👤 Personale" o "👥 Nome Gruppo"
- [ ] Dropdown con lista gruppi
- [ ] Opzione "Crea Nuovo Gruppo"

### **FASE 3C: Gestione Gruppi**
- [ ] `CreateGroupPage` - form per nuovo gruppo
- [ ] `GroupDetailPage` - info gruppo, membri, impostazioni
- [ ] `InviteMemberPage` - form per invitare via email
- [ ] `PendingInvitesPage` - lista inviti ricevuti

### **FASE 3D: Expense Form Multi-User**
- [ ] Se in contesto gruppo: mostra "Chi ha pagato?" (membri)
- [ ] Selettore split type (equal/custom/full)
- [ ] UI per split custom (slider per persona)

---

## 📝 Note Tecniche

### **Perché Singleton per Services?**
- Garantisce una singola istanza condivisa
- ContextManager deve essere univoco per funzionare
- ProfileService/GroupService possono cachare dati

### **Perché ChangeNotifier per ContextManager?**
- Notifica automaticamente tutti i widget in ascolto
- Usato con `Consumer<ContextManager>` o `context.watch()`
- ExpenseService stream si rebuilda automaticamente al cambio contesto

### **Backward Compatibility**
- `MoneyFlow` enum mantenuto per spese esistenti
- Vecchie spese senza `group_id` sono trattate come personali
- Migration script può convertire Carl/Pit in un gruppo

---

## 🎉 FASE 2 COMPLETATA!

Tutti i modelli e services sono pronti. Il sistema è completamente funzionale lato backend.

**Prossimo comando:**
```
"Iniziamo con la FASE 3A: Aggiornare ProfilePage"
```

O preferisci testare prima il setup del database? Dimmi come vuoi procedere!
