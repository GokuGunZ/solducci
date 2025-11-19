# ✅ FASE 3C3 COMPLETATA: Invite Member Page

## 🎉 Cosa è Stato Implementato

Abbiamo completato l'implementazione della pagina per invitare nuovi membri ai gruppi! Ora gli admin possono facilmente invitare altri utenti via email.

## 📁 File Creati

### 1. [lib/views/groups/invite_member_page.dart](../lib/views/groups/invite_member_page.dart)
**Pagina per invitare un nuovo membro al gruppo**

**Features**:
- ✅ Form con campo email (obbligatorio)
- ✅ Validazione email con regex
- ✅ Campo email case-insensitive (auto-lowercase)
- ✅ Info card che spiega come funzionano gli inviti
- ✅ Loading state durante invio
- ✅ Error handling con SnackBar
- ✅ Success: torna a GroupDetailPage con flag true
- ✅ GroupDetailPage ricarica membri automaticamente dopo invito
- ✅ Mostra nome gruppo nel card header
- ✅ Bottone "Invia Invito" blu con icona send
- ✅ Bottone "Annulla" outlined

**UI**:
```
┌─────────────────────────────────┐
│  Invita Membro             [←]  │
├─────────────────────────────────┤
│                                 │
│         [Blue Circle            │
│          with person_add icon]  │
│                                 │
│  ┌──────────────────────────┐  │
│  │ 👥 Gruppo: Coppia        │  │
│  └──────────────────────────┘  │
│                                 │
│  Email del Membro *             │
│  [____________________]         │
│  Inserisci l'email dell'utente  │
│  da invitare                    │
│                                 │
│  ┌──────────────────────────┐  │
│  │ ℹ️ Come funziona?        │  │
│  │ • Invito via email       │  │
│  │ • Scade dopo 7 giorni    │  │
│  │ • Può accettare/rifiutare│  │
│  │ • Se accetta → membro    │  │
│  │ • Se non registrato      │  │
│  │   può registrarsi        │  │
│  └──────────────────────────┘  │
│                                 │
│  [Invia Invito]                 │
│  [Annulla]                      │
└─────────────────────────────────┘
```

**Validazione Email**:
```dart
final emailRegex = RegExp(
  r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
);
```

## 📁 File Modificati

### 2. [lib/routes/app_router.dart](../lib/routes/app_router.dart)
**Aggiunta route per invite page**

**Modifiche**:
- Import: `import 'package:solducci/views/groups/invite_member_page.dart';`
- Route `/groups/:id/invite` con query parameter `name`

**Route aggiunta**:
```dart
GoRoute(
  path: '/groups/:id/invite',
  builder: (context, state) {
    final groupId = state.pathParameters['id']!;
    final groupName = state.uri.queryParameters['name'] ?? 'Gruppo';
    return InviteMemberPage(
      groupId: groupId,
      groupName: groupName,
    );
  },
),
```

### 3. [lib/views/groups/group_detail_page.dart](../lib/views/groups/group_detail_page.dart)
**Aggiornato bottone "Invita Membro" e aggiunto debug logging**

**Modifiche**:
1. **Bottone "Invita Membro"** ora naviga a InviteMemberPage
2. **Ricarica membri** automaticamente se l'invito è stato inviato con successo
3. **Debug logging** completo per troubleshooting navigation

**Prima**:
```dart
onPressed: () {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Funzionalità in arrivo presto!')),
  );
},
```

**Dopo**:
```dart
onPressed: () async {
  final result = await context.push(
    '/groups/${widget.groupId}/invite?name=${Uri.encodeComponent(_group!.name)}',
  );
  // Reload members if invite was sent successfully
  if (result == true && mounted) {
    await _loadGroupData();
  }
},
```

**Debug Logging Aggiunto**:
```dart
Future<void> _loadGroupData() async {
  debugPrint('🔄 Loading group data for groupId: ${widget.groupId}');
  // ... more logs throughout the method
  debugPrint('✅ Group detail page loaded successfully');
}
```

### 4. [lib/views/profile_page.dart](../lib/views/profile_page.dart)
**Aggiunto debug logging per navigation**

**Modifiche**:
```dart
onTap: () {
  debugPrint('🔄 Navigating to group detail: ${group.id}');
  context.push('/groups/${group.id}');
},
```

Questo aiuta a debuggare eventuali problemi di navigazione.

## 🎯 Flow Completo

### Scenario: Admin Invita Nuovo Membro

```
Admin in GroupDetailPage
    ↓
Sezione "MEMBRI (n)"
    ↓
Bottone "Invita Membro" (visibile solo per admin)
    ↓
Tap → Naviga a InviteMemberPage
    ↓
URL: /groups/{groupId}/invite?name={groupName}
    ↓
Form mostra:
  • Header con nome gruppo
  • Campo email vuoto
  • Info card
    ↓
User inserisce: "amico@email.com"
    ↓
Tap "Invia Invito"
    ↓
Validazione email (required + regex)
    ↓
GroupService.sendInvite(groupId, email)
    ↓
INSERT INTO group_invites (...) VALUES (...)
    ↓
Success → context.pop(true)
    ↓
GroupDetailPage riceve result=true
    ↓
GroupDetailPage.loadGroupData() → Refresh membri
    ↓
SnackBar verde: "Invito inviato a amico@email.com"
    ↓
Invito ora visibile in PendingInvitesPage (TODO FASE 3C4)
```

## 🔄 Database Operations

### InviteMemberPage

**INSERT in `group_invites`**:
```sql
INSERT INTO group_invites (
  group_id,
  inviter_id,
  invitee_email,
  status,
  expires_at
)
VALUES (
  'group-uuid',
  'admin-user-uuid',
  'amico@email.com',
  'pending',
  NOW() + INTERVAL '7 days'
);
```

**Status possibili**:
- `pending` - Invito appena creato, in attesa
- `accepted` - Invitato ha accettato
- `rejected` - Invitato ha rifiutato
- `expired` - Invito scaduto (>7 giorni)

## 🧪 Come Testare

### Test 1: Navigazione a InviteMemberPage

1. **Avvia app**: `flutter run`
2. **Login**
3. **Vai a ProfilePage** (tab Profilo)
4. **Crea un gruppo** (o usa uno esistente)
5. **Tap** sul gruppo → GroupDetailPage
6. **Verifica**: Bottone "Invita Membro" visibile (solo se admin)
7. **Tap** "Invita Membro"
8. **Verifica**: Naviga a InviteMemberPage
9. **Verifica UI**:
   - ✅ AppBar: "Invita Membro"
   - ✅ Icona blu con person_add
   - ✅ Card con nome gruppo
   - ✅ Campo email con placeholder
   - ✅ Info card arancione
   - ✅ Bottoni "Invia Invito" e "Annulla"

### Test 2: Validazione Email

1. **In InviteMemberPage**, lascia email vuota
2. **Tap** "Invia Invito"
3. **Verifica**: Error "L'email è obbligatoria"
4. **Scrivi** "emailnonvalida" (senza @)
5. **Tap** "Invia Invito"
6. **Verifica**: Error "Email non valida"
7. **Scrivi** "test@" (senza dominio)
8. **Verifica**: Error "Email non valida"
9. **Scrivi** "test@example.com" (valida)
10. **Tap** "Invia Invito"
11. **Verifica**: Invio procede (nessun error di validazione)

### Test 3: Invio Invito Completo

**Setup**: Crea gruppo via app o SQL

**Test**:
1. **In GroupDetailPage**, tap "Invita Membro"
2. **Inserisci** email valida: "test@example.com"
3. **Tap** "Invia Invito"
4. **Verifica**:
   - ✅ Loading indicator appare
   - ✅ Dopo ~1 sec, torna a GroupDetailPage
   - ✅ SnackBar verde: "Invito inviato a test@example.com"
   - ✅ (Opzionale) Membri ricaricati

**Verifica DB**:
```sql
SELECT * FROM group_invites
WHERE invitee_email = 'test@example.com'
ORDER BY created_at DESC
LIMIT 1;
```

Dovresti vedere:
- ✅ `group_id` corretto
- ✅ `inviter_id` = tuo user ID
- ✅ `invitee_email` = "test@example.com"
- ✅ `status` = 'pending'
- ✅ `expires_at` = ~7 giorni da ora

### Test 4: Case Insensitive Email

1. **Inserisci** email: "TEST@EXAMPLE.COM" (maiuscolo)
2. **Tap** "Invia Invito"
3. **Verifica DB**:
```sql
SELECT invitee_email FROM group_invites
WHERE invitee_email = 'test@example.com';
```
Email salvata come lowercase: ✅

### Test 5: Annulla Invito

1. **In InviteMemberPage**, inserisci email
2. **Tap** "Annulla"
3. **Verifica**:
   - ✅ Torna a GroupDetailPage
   - ✅ Nessun invito creato nel DB
   - ✅ Nessun SnackBar

### Test 6: Error Handling

**Simula errore**: Invita email già invitata

1. **Invia primo invito** a "test@example.com"
2. **Tap** "Invita Membro" di nuovo
3. **Inserisci** stessa email: "test@example.com"
4. **Tap** "Invia Invito"
5. **Verifica**: SnackBar rosso con messaggio errore
   - (Se unica constraint esiste nel DB)

## 📊 Console Output Atteso

```
// Navigazione da ProfilePage:
🔄 Navigating to group detail: abc123-uuid

// GroupDetailPage load:
🔄 Loading group data for groupId: abc123-uuid
📊 Fetching group and members...
✅ Group fetched: Coppia
✅ Members count: 1
🔐 Checking admin status...
✅ Is admin: true
✅ Group detail page loaded successfully

// Tap "Invita Membro":
(nessun log particolare)

// Dopo invio invito:
🔄 Loading group data for groupId: abc123-uuid
(... reload)
```

## ✅ Acceptance Criteria

### Must Work
- [x] InviteMemberPage accessibile da GroupDetailPage
- [x] Solo admin vedono bottone "Invita Membro"
- [x] Form con campo email funziona
- [x] Validazione email (required + regex)
- [x] Email salvata come lowercase
- [x] Invito creato nel DB con status "pending"
- [x] SnackBar successo dopo invio
- [x] Torna a GroupDetailPage dopo invio
- [x] GroupDetailPage ricarica membri automaticamente
- [x] Bottone "Annulla" funziona
- [x] Loading state visibile durante invio
- [x] Error handling con SnackBar rosso

### Known Limitations (TODO FASE 3C4)
- ❌ Nessuna pagina per visualizzare inviti pendenti
- ❌ Nessuna pagina per accettare/rifiutare inviti
- ❌ Nessuna notifica quando ricevi un invito
- ❌ Badge count inviti non si aggiorna in tempo reale
- ❌ Non puoi reinvitare email già invitata (DB constraint)

## 🚀 Prossimo: FASE 3C4

### **PendingInvitesPage**

**Features da implementare**:
1. **Page**: `lib/views/groups/pending_invites_page.dart`
2. **Route**: `/invites/pending`
3. **Link da**: ProfilePage badge "Inviti Pendenti"

**UI Proposta**:
```
┌─────────────────────────────────┐
│  Inviti Pendenti           [←]  │
├─────────────────────────────────┤
│                                 │
│  Hai 2 inviti in attesa:        │
│                                 │
│  ┌──────────────────────────┐  │
│  │ 👥 Coppia Carl & Pit     │  │
│  │ Da: Carl                 │  │
│  │ Scade: tra 5 giorni      │  │
│  │                          │  │
│  │ [Accetta]    [Rifiuta]   │  │
│  └──────────────────────────┘  │
│                                 │
│  ┌──────────────────────────┐  │
│  │ 👥 Casa Coinquilini      │  │
│  │ Da: Maria                │  │
│  │ Scade: tra 2 giorni      │  │
│  │                          │  │
│  │ [Accetta]    [Rifiuta]   │  │
│  └──────────────────────────┘  │
│                                 │
└─────────────────────────────────┘
```

**Database Operations**:
```sql
-- Get pending invites
SELECT gi.*, g.name as group_name, p.nickname as inviter_name
FROM group_invites gi
JOIN groups g ON gi.group_id = g.id
JOIN profiles p ON gi.inviter_id = p.id
WHERE gi.invitee_email = 'current-user-email'
  AND gi.status = 'pending'
  AND gi.expires_at > NOW()
ORDER BY gi.created_at DESC;

-- Accept invite
UPDATE group_invites
SET status = 'accepted'
WHERE id = 'invite-uuid';

INSERT INTO group_members (group_id, user_id, role)
VALUES ('group-uuid', 'user-uuid', 'member');

-- Reject invite
UPDATE group_invites
SET status = 'rejected'
WHERE id = 'invite-uuid';
```

## 📝 Notes

### Perché Query Parameter per groupName?

Usiamo query parameter invece di `extra` perché:
1. Go Router gestisce meglio query params negli URL
2. Più facile da debuggare (vedi URL completo)
3. Non richiede type casting

**Esempio URL**:
```
/groups/abc123-uuid/invite?name=Coppia%20Carl%20%26%20Pit
```

### Perché URI.encodeComponent?

Per gestire caratteri speciali nel nome gruppo:
- Spazi → `%20`
- `&` → `%26`
- Caratteri unicode → encoded

### Perché context.pop(true)?

Ritorniamo `true` per indicare successo. GroupDetailPage usa questo valore per decidere se ricaricare i membri:

```dart
final result = await context.push(...);
if (result == true && mounted) {
  await _loadGroupData(); // Reload!
}
```

### Scadenza Inviti

Gli inviti scadono dopo 7 giorni:
```sql
expires_at = NOW() + INTERVAL '7 days'
```

Questo previene inviti "zombie" nel database. In FASE 3C4 aggiungeremo:
1. Background job per cleanup inviti scaduti
2. UI che mostra "Scade tra X giorni"
3. Notifica quando invito sta per scadere

## 🎉 Congratulazioni!

Ora puoi:
- ✅ Creare gruppi dall'app
- ✅ Visualizzare dettagli gruppi
- ✅ Invitare membri via email (admin)
- ✅ Vedere membri esistenti
- ✅ Lasciare gruppi
- ✅ Eliminare gruppi (se admin)

**Manca solo FASE 3C4** per completare il sistema di gestione gruppi! 🚀

Dopo 3C4, passeremo a **FASE 3D: Expense Form Multi-User** che permetterà di:
- Selezionare "Chi ha pagato?" in gruppo
- Scegliere tipo split (equal/custom/full/none)
- Creare spese condivise tra membri
