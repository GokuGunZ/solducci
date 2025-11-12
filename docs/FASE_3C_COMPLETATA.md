# ✅ FASE 3C COMPLETATA: Group Management (Create & Detail)

## 🎉 Cosa è Stato Implementato

Abbiamo implementato le prime due pagine fondamentali per la gestione dei gruppi:
1. **CreateGroupPage** - Crea nuovi gruppi
2. **GroupDetailPage** - Visualizza e gestisci dettagli gruppo

## 📁 File Creati

### 1. [lib/views/groups/create_group_page.dart](../lib/views/groups/create_group_page.dart)
**Pagina per creare un nuovo gruppo**

**Features**:
- ✅ Form con validazione per nome gruppo (obbligatorio, min 2 caratteri)
- ✅ Campo descrizione opzionale (max 200 caratteri)
- ✅ Info card che spiega cosa succede dopo la creazione
- ✅ Loading state durante creazione
- ✅ Error handling con SnackBar
- ✅ Dopo creazione:
  - Switch automatico al nuovo gruppo (via ContextManager)
  - Torna indietro con SnackBar di successo
  - Link ai dettagli gruppo (SnackBar action)
- ✅ Bottone "Crea Gruppo" verde con icona
- ✅ Bottone "Annulla" outlined

**UI**:
```
┌─────────────────────────────────┐
│  Crea Nuovo Gruppo         [←]  │
├─────────────────────────────────┤
│                                 │
│         [Green Circle           │
│          with + icon]           │
│                                 │
│  Nome Gruppo *                  │
│  [____________________]         │
│  Es: Coppia, Casa, Viaggio      │
│                                 │
│  Descrizione (opzionale)        │
│  [____________________]         │
│  [____________________]         │
│  [____________________]         │
│  Es: Spese di casa              │
│                                 │
│  ┌──────────────────────────┐  │
│  │ ℹ️ Cosa succede dopo?    │  │
│  │ • Diventi admin          │  │
│  │ • Context si switcha     │  │
│  │ • Puoi invitare membri   │  │
│  └──────────────────────────┘  │
│                                 │
│  [Crea Gruppo]                  │
│  [Annulla]                      │
└─────────────────────────────────┘
```

### 2. [lib/views/groups/group_detail_page.dart](../lib/views/groups/group_detail_page.dart)
**Pagina per visualizzare e gestire un gruppo**

**Features**:
- ✅ Carica gruppo dal database via `GroupService.getGroupById()`
- ✅ Carica membri via `GroupService.getGroupMembers()`
- ✅ Controlla se user è admin via `GroupService.isUserAdmin()`
- ✅ Mostra info gruppo (nome, descrizione, icona)
- ✅ Lista membri con:
  - Avatar con iniziale
  - Nickname
  - Email
  - Badge "Admin" per admin
- ✅ Bottone "Invita Membro" (solo per admin) - placeholder
- ✅ Pull-to-refresh per ricaricare dati
- ✅ Sezione "Azioni":
  - **Lascia Gruppo** (tutti) - con conferma dialog
  - **Elimina Gruppo** (solo admin) - con conferma STRONG
- ✅ Settings icon in AppBar (solo admin) - placeholder
- ✅ Error handling robusto

**UI**:
```
┌─────────────────────────────────┐
│ [←] Nome Gruppo          [⚙️]   │
├─────────────────────────────────┤
│                                 │
│  ┌───────────────────────────┐ │
│  │    [Blue Circle]          │ │
│  │    [Group Icon]           │ │
│  │                           │ │
│  │    Nome Gruppo            │ │
│  │    Descrizione gruppo     │ │
│  └───────────────────────────┘ │
│                                 │
│  MEMBRI (3)                     │
│  ┌───────────────────────────┐ │
│  │ [C] Carl (Tu) - Admin     │ │
│  └───────────────────────────┘ │
│  ┌───────────────────────────┐ │
│  │ [P] Pit - Membro          │ │
│  └───────────────────────────┘ │
│                                 │
│  [Invita Membro]  (se admin)   │
│                                 │
│  AZIONI                         │
│  ┌───────────────────────────┐ │
│  │ 🚪 Lascia Gruppo          │ │
│  └───────────────────────────┘ │
│  ┌───────────────────────────┐ │
│  │ 🗑️ Elimina Gruppo         │ │
│  └───────────────────────────┘ │
└─────────────────────────────────┘
```

## 📁 File Modificati

### 3. [lib/routes/app_router.dart](../lib/routes/app_router.dart)
**Aggiornate le routes per i gruppi**

**Modifiche**:
- Import: `CreateGroupPage` e `GroupDetailPage`
- Route `/groups/create` → `CreateGroupPage()`
- Route `/groups/:id` → `GroupDetailPage(groupId: id)`

### 4. [lib/views/profile_page.dart](../lib/views/profile_page.dart)
**Aggiornati i link di navigazione**

**Modifiche**:
- "Nessun gruppo" card → naviga a `/groups/create`
- Click su gruppo → naviga a `/groups/${group.id}`

## 🎯 Flow Completo

### Scenario 1: Crea Primo Gruppo

```
User in ProfilePage (tab Profilo)
    ↓
Vede "Nessun gruppo" + "Crea un gruppo..."
    ↓
Tap sulla card
    ↓
Naviga a CreateGroupPage
    ↓
Compila form: nome="Coppia", descrizione="Spese di casa"
    ↓
Tap "Crea Gruppo"
    ↓
ContextManager.createAndSwitchToGroup()
    ↓
GroupService.createGroup() → DB insert
    ↓
GroupService aggiunge creator come admin in group_members
    ↓
ContextManager.loadUserGroups() → Refresh lista gruppi
    ↓
ContextManager.switchToGroup(newGroup) → Switch contesto
    ↓
Pop con SnackBar "Gruppo 'Coppia' creato con successo!"
    ↓
Context Switcher ora mostra "👥 Coppia ▼"
    ↓
ExpenseList mostra spese del gruppo (vuoto per ora)
```

### Scenario 2: Visualizza Dettagli Gruppo

```
User in ProfilePage
    ↓
Sezione "I MIEI GRUPPI" mostra "Coppia" (1 membro)
    ↓
Tap su "Coppia"
    ↓
Naviga a GroupDetailPage(groupId: xxx)
    ↓
Carica gruppo + membri dal DB
    ↓
Mostra:
  • Info gruppo
  • Carl (Tu) - Admin
  • Sezione Azioni
    ↓
User può:
  • [Invita Membro] → TODO (FASE 3C3)
  • [Lascia Gruppo] → Conferma → leave → torna a Personal
  • [Elimina Gruppo] → Conferma STRONG → delete → torna a Personal
```

### Scenario 3: Elimina Gruppo

```
User admin in GroupDetailPage
    ↓
Scroll a "AZIONI"
    ↓
Tap "Elimina Gruppo"
    ↓
Dialog conferma con warning:
  "ATTENZIONE: Questa azione è irreversibile!
   Eliminando il gruppo verranno rimosse:
   • Tutte le spese del gruppo
   • Tutti i membri
   • Tutti gli inviti pendenti

   Vuoi continuare?"
    ↓
User tap "Elimina"
    ↓
ContextManager.deleteCurrentGroup()
    ↓
GroupService.deleteGroup(id) → DB delete CASCADE
    ↓
ContextManager.loadUserGroups() → Refresh
    ↓
ContextManager.switchToPersonal() → Back to personal
    ↓
Pop con SnackBar "Gruppo eliminato"
    ↓
Context Switcher mostra "👤 Personale ▼"
```

## 🔄 Database Operations

### CreateGroupPage

**INSERT in `groups`**:
```sql
INSERT INTO groups (name, description, created_by)
VALUES ('Coppia', 'Spese di casa', 'user-uuid');
```

**INSERT in `group_members`**:
```sql
INSERT INTO group_members (group_id, user_id, role)
VALUES ('new-group-uuid', 'user-uuid', 'admin');
```

### GroupDetailPage

**SELECT gruppo**:
```sql
SELECT * FROM groups WHERE id = 'group-uuid';
```

**SELECT membri**:
```sql
SELECT gm.*, p.nickname, p.email
FROM group_members gm
JOIN profiles p ON gm.user_id = p.id
WHERE gm.group_id = 'group-uuid'
ORDER BY gm.joined_at;
```

**CHECK se admin**:
```sql
SELECT EXISTS (
  SELECT 1 FROM group_members
  WHERE group_id = 'group-uuid'
    AND user_id = 'user-uuid'
    AND role = 'admin'
);
```

### Leave Group

**DELETE da `group_members`**:
```sql
DELETE FROM group_members
WHERE group_id = 'group-uuid'
  AND user_id = 'user-uuid';
```

### Delete Group

**DELETE CASCADE**:
```sql
DELETE FROM groups WHERE id = 'group-uuid';
-- CASCADE elimina anche:
-- • group_members
-- • group_invites
-- • expenses (con group_id)
-- • expense_splits (tramite expenses)
```

## 🧪 Come Testare

### Test 1: Crea Gruppo dall'App

1. **Avvia app**: `flutter run`
2. **Login**
3. **Vai a tab Profilo**
4. **Tap** su "Nessun gruppo"
5. **Compila form**:
   - Nome: "Test Gruppo"
   - Descrizione: "Gruppo di test"
6. **Tap "Crea Gruppo"**
7. **Verifica**:
   - ✅ SnackBar verde "Gruppo 'Test Gruppo' creato con successo!"
   - ✅ Torna a ProfilePage
   - ✅ Context Switcher mostra "👥 Test Gruppo ▼"
   - ✅ Console log: `🔄 Switching to Group context: Test Gruppo`

### Test 2: Visualizza Dettagli

1. **In ProfilePage**, tap su "Test Gruppo"
2. **Verifica** GroupDetailPage mostra:
   - ✅ Nome gruppo in AppBar
   - ✅ Card info con icona e descrizione
   - ✅ "MEMBRI (1)"
   - ✅ Il tuo nickname con badge "Admin"
   - ✅ Bottone "Invita Membro"
   - ✅ Sezione "AZIONI" con "Lascia" e "Elimina"

### Test 3: Pull-to-Refresh

1. **In GroupDetailPage**, pull down
2. **Verifica**: Spinner appare e dati si ricaricano

### Test 4: Lascia Gruppo

1. **In GroupDetailPage**, scroll a "AZIONI"
2. **Tap** "Lascia Gruppo"
3. **Verifica** dialog:
   - ✅ Titolo "Lascia Gruppo"
   - ✅ Messaggio warning (diverso se admin)
   - ✅ Bottoni "Annulla" e "Lascia"
4. **Tap "Lascia"**
5. **Verifica**:
   - ✅ Torna a ProfilePage
   - ✅ SnackBar arancione "Hai lasciato il gruppo"
   - ✅ Context Switcher mostra "👤 Personale ▼"
   - ✅ Gruppo NON appare più in "I MIEI GRUPPI"

### Test 5: Elimina Gruppo

1. **Crea nuovo gruppo** (Test 1)
2. **Vai a dettagli** (Test 2)
3. **Tap** "Elimina Gruppo"
4. **Verifica** dialog:
   - ✅ Titolo "Elimina Gruppo"
   - ✅ Warning ROSSO con lista conseguenze
   - ✅ Bottoni "Annulla" e "Elimina"
5. **Tap "Elimina"**
6. **Verifica**:
   - ✅ Torna a ProfilePage
   - ✅ SnackBar rosso "Gruppo eliminato"
   - ✅ Context Switcher mostra "👤 Personale ▼"
   - ✅ Gruppo NON esiste più nel DB

### Test 6: Validazione Form

1. **Vai a CreateGroupPage**
2. **Lascia nome vuoto**, tap "Crea Gruppo"
3. **Verifica**: Error "Il nome del gruppo è obbligatorio"
4. **Scrivi "A"** (1 carattere), tap "Crea Gruppo"
5. **Verifica**: Error "Il nome deve essere di almeno 2 caratteri"
6. **Scrivi nome valido**, tap "Crea Gruppo"
7. **Verifica**: Crea con successo

## 📊 Console Output Atteso

```
// Crea gruppo:
🔄 Initializing ContextManager...
✅ Loaded 0 groups
✅ ContextManager initialized with 0 groups
🔄 Switching to Group context: Test Gruppo

// Visualizza dettagli:
(nessun log particolare, solo query DB)

// Lascia gruppo:
🔄 Initializing ContextManager...
✅ Loaded 0 groups
⚠️ Current group no longer exists, switching to personal
🔄 Switching to Personal context

// Elimina gruppo:
(stesso di "Lascia")
```

## ✅ Acceptance Criteria

### Must Work
- [x] CreateGroupPage form funziona
- [x] Validazione nome obbligatorio
- [x] Gruppo creato nel DB
- [x] Creator aggiunto come admin
- [x] Context switcha automaticamente al nuovo gruppo
- [x] GroupDetailPage carica dati
- [x] Mostra membri correttamente
- [x] Badge "Admin" visibile
- [x] Bottone "Invita" presente (placeholder)
- [x] "Lascia Gruppo" funziona
- [x] "Elimina Gruppo" funziona (solo admin)
- [x] Dialog conferme funzionano
- [x] Pull-to-refresh funziona
- [x] Error handling robusto

### Known Limitations (TODO Fase 3C3-3C4)
- ❌ Nessuna pagina per invitare membri (bottone placeholder)
- ❌ Nessuna pagina per gestire inviti pendenti
- ❌ Nessuna pagina settings gruppo
- ❌ Nessun calcolo debiti visualizzato (funzione DB pronta)

## 🚀 Prossimo: FASE 3C3 & 3C4

### **FASE 3C3: InviteMemberPage**
- Form con campo email
- Validazione email
- Submit → `GroupService.sendInvite()`
- Success → Torna a GroupDetail

### **FASE 3C4: PendingInvitesPage**
- Lista inviti pendenti (via `GroupService.getPendingInvites()`)
- Card per ogni invito (gruppo, inviter, scadenza)
- Bottoni "Accetta" / "Rifiuta"
- Accetta → `GroupService.acceptInvite()` → Gruppo appare in lista
- Badge count in ProfilePage

## 📝 Notes

### Perché deleteCurrentGroup usa ContextManager?
Perché dopo eliminazione vogliamo:
1. Switchare a Personal automaticamente
2. Ricaricare lista gruppi
3. Notificare UI del cambio

Tutto questo è incapsulato in `ContextManager`.

### Perché ON DELETE CASCADE?
Nel DB schema:
```sql
CREATE TABLE group_members (
  group_id UUID REFERENCES groups(id) ON DELETE CASCADE
);
```

Quando elimini un gruppo, PostgreSQL elimina automaticamente:
- Tutti i `group_members`
- Tutti i `group_invites`
- Tutte le `expenses` con quel `group_id`
- Tutti gli `expense_splits` (via CASCADE da expenses)

## 🎉 Congratulazioni!

Ora puoi:
- ✅ Creare gruppi dall'app
- ✅ Visualizzare dettagli gruppi
- ✅ Vedere membri
- ✅ Lasciare gruppi
- ✅ Eliminare gruppi (se admin)
- ✅ Navigazione completa tra Profile → Create → Detail

Mancano solo:
- Invitare membri (FASE 3C3)
- Gestire inviti (FASE 3C4)
- Expense form multi-user (FASE 3D)

**Quasi completato il sistema multi-user! 🚀**
