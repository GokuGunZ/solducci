# 🧪 Testing Guide - FASE 3C3: Invite Member

## Quick Test Flow

Segui questa guida per testare tutte le funzionalità implementate nella FASE 3C3.

## ⚡ Quick Start

```bash
# 1. Avvia l'app
flutter run

# 2. Verifica console logs
# Dovresti vedere:
# 🔧 User logged in, initializing ContextManager...
# ✅ ContextManager initialized
```

## 🔄 Test 1: Navigazione Completa

### Setup
- Login con account esistente
- Assicurati di avere almeno un gruppo (creane uno se necessario)

### Steps

1. **ProfilePage → GroupDetailPage**
   ```
   Tap: Tab "Profilo" → Tap su un gruppo

   Console atteso:
   🔄 Navigating to group detail: {group-id}
   🔄 Loading group data for groupId: {group-id}
   📊 Fetching group and members...
   ✅ Group fetched: {group-name}
   ✅ Members count: {n}
   🔐 Checking admin status...
   ✅ Is admin: {true/false}
   ✅ Group detail page loaded successfully
   ```

2. **GroupDetailPage → InviteMemberPage**
   ```
   Verifica: Bottone "Invita Membro" visibile (solo se admin)
   Tap: "Invita Membro"

   Risultato:
   ✅ Naviga a InviteMemberPage
   ✅ Header mostra nome gruppo
   ✅ Campo email vuoto
   ✅ Info card visibile
   ```

3. **InviteMemberPage → Invio**
   ```
   Input: test@example.com
   Tap: "Invia Invito"

   Risultato:
   ✅ Loading indicator appare
   ✅ Dopo ~1 sec torna a GroupDetailPage
   ✅ SnackBar verde: "Invito inviato a test@example.com"
   ```

## 🔍 Test 2: Validazione Email

### Test Case 1: Email Vuota
```
Input: (vuoto)
Tap: "Invia Invito"
Atteso: ❌ "L'email è obbligatoria"
```

### Test Case 2: Email Senza @
```
Input: emailsenza@
Tap: "Invia Invito"
Atteso: ❌ "Email non valida"
```

### Test Case 3: Email Senza Dominio
```
Input: test@
Tap: "Invia Invito"
Atteso: ❌ "Email non valida"
```

### Test Case 4: Email Senza TLD
```
Input: test@example
Tap: "Invia Invito"
Atteso: ❌ "Email non valida"
```

### Test Case 5: Email Valida
```
Input: test@example.com
Tap: "Invia Invito"
Atteso: ✅ Invio procede
```

## 💾 Test 3: Verifica Database

### Dopo Invio Invito

```sql
-- Verifica invito creato
SELECT
  gi.*,
  g.name as group_name,
  p.nickname as inviter_nickname
FROM group_invites gi
JOIN groups g ON gi.group_id = g.id
JOIN profiles p ON gi.inviter_id = p.id
WHERE gi.invitee_email = 'test@example.com'
ORDER BY gi.created_at DESC
LIMIT 1;
```

**Verifica campi**:
- ✅ `group_id` = ID gruppo corretto
- ✅ `inviter_id` = Tuo user ID
- ✅ `invitee_email` = 'test@example.com' (lowercase!)
- ✅ `status` = 'pending'
- ✅ `expires_at` ≈ NOW() + 7 giorni
- ✅ `created_at` = NOW()

### Inviti Multipli

```sql
-- Conta inviti per gruppo
SELECT
  g.name,
  COUNT(gi.id) as invite_count
FROM groups g
LEFT JOIN group_invites gi ON g.id = gi.group_id
WHERE gi.status = 'pending'
GROUP BY g.id, g.name;
```

## 🐛 Test 4: Debug Navigation Issue

Se la navigazione non funziona, controlla console logs:

### Da ProfilePage
```
Tap su gruppo → Console deve mostrare:
🔄 Navigating to group detail: {group-id}
```

Se NON vedi questo log:
- ❌ onTap non sta scattando
- ❌ Controlla se gruppo ha `id` valido

### In GroupDetailPage
```
Dopo navigazione → Console deve mostrare:
🔄 Loading group data for groupId: {group-id}
📊 Fetching group and members...
```

Se vedi "❌ Error loading group data":
- ❌ groupId potrebbe essere null/invalid
- ❌ Controlla route parameter extraction
- ❌ Verifica DB ha gruppo con quell'ID

## 🎯 Test 5: Edge Cases

### Case 1: Gruppo Senza Admin
```sql
-- Rimuovi admin da gruppo (solo per test!)
UPDATE group_members
SET role = 'member'
WHERE group_id = 'test-group-id'
  AND user_id = 'your-user-id';
```

Risultato:
- ✅ Bottone "Invita Membro" NON visibile
- ✅ Solo icona settings scompare

### Case 2: Gruppo Con Solo Admin
```
Setup: Crea nuovo gruppo
Verifica:
  ✅ Membri (1)
  ✅ Solo tu con badge "Admin"
  ✅ Bottone "Invita Membro" visibile
```

### Case 3: Email Case Insensitive
```
Input: TEST@EXAMPLE.COM (maiuscolo)
Tap: "Invia Invito"

Verifica DB:
SELECT invitee_email FROM group_invites
WHERE id = (SELECT MAX(id) FROM group_invites);

Atteso: "test@example.com" (lowercase)
```

## 🧹 Test 6: Cleanup

### Rimuovi Inviti Test

```sql
DELETE FROM group_invites
WHERE invitee_email LIKE '%test%'
  OR invitee_email LIKE '%example.com';
```

## ⚠️ Known Issues & Workarounds

### Issue 1: GroupDetailPage Non Carica

**Sintomo**: Page mostra "Caricamento..." infinito

**Debug**:
```
Console logs:
🔄 Loading group data for groupId: {id}
📊 Fetching group and members...
❌ Error loading group data: ...
```

**Possibili cause**:
1. Gruppo non esiste nel DB
2. RLS policies bloccano query
3. User non è membro del gruppo

**Fix**:
```sql
-- Verifica gruppo esiste
SELECT * FROM groups WHERE id = 'group-id';

-- Verifica sei membro
SELECT * FROM group_members
WHERE group_id = 'group-id'
  AND user_id = 'your-user-id';

-- Se manca, aggiungi membership
INSERT INTO group_members (group_id, user_id, role)
VALUES ('group-id', 'your-user-id', 'member');
```

### Issue 2: Bottone "Invita" Placeholder

**Sintomo**: Tap mostra "Funzionalità in arrivo presto!"

**Causa**: Codice vecchio non aggiornato

**Fix**: Hot reload/restart app
```bash
# In VS Code: R (hot reload)
# O: flutter run
```

### Issue 3: Email Già Invitata

**Sintomo**: Error quando reinviti stessa email

**Causa**: DB constraint impedisce duplicati

**Workaround**:
1. Elimina invito vecchio dal DB
2. Oppure usa email diversa
3. Oppure implementa "Reinvia Invito" feature

## 📱 Test 7: UI/UX Checks

### InviteMemberPage UI

Verifica visualmente:

**Header**:
- ✅ AppBar title: "Invita Membro"
- ✅ Back button presente

**Icona**:
- ✅ Cerchio blu con icona person_add
- ✅ Size appropriata (100x100)

**Gruppo Info Card**:
- ✅ Sfondo azzurro chiaro
- ✅ Icona gruppo
- ✅ "Gruppo: {nome}"

**Email Field**:
- ✅ Label: "Email del Membro *"
- ✅ Hint: "esempio@email.com"
- ✅ Icona email a sinistra
- ✅ Helper text visibile
- ✅ Keyboard type: email

**Info Card**:
- ✅ Sfondo arancione chiaro
- ✅ Icona info
- ✅ Titolo: "Come funziona?"
- ✅ 5 bullet points

**Buttons**:
- ✅ "Invia Invito": Blu, con icona send
- ✅ "Annulla": Outlined
- ✅ Padding appropriato
- ✅ Responsive a tap

## ✅ Success Checklist

Dopo tutti i test, dovresti avere:

- [x] Navigation ProfilePage → GroupDetailPage funziona
- [x] Console logs visibili per debug
- [x] GroupDetailPage carica dati correttamente
- [x] Bottone "Invita Membro" visibile solo per admin
- [x] Navigation GroupDetailPage → InviteMemberPage funziona
- [x] InviteMemberPage UI corretta
- [x] Validazione email funziona (5 test cases)
- [x] Email salvata lowercase nel DB
- [x] Invito creato con campi corretti
- [x] SnackBar successo appare
- [x] Return to GroupDetailPage con reload
- [x] Bottone "Annulla" funziona
- [x] Loading state visibile

## 🚀 Next Steps

Se tutti i test passano, sei pronto per:

**FASE 3C4: PendingInvitesPage**
- Visualizzare inviti ricevuti
- Accettare/rifiutare inviti
- Badge count in ProfilePage

**FASE 3D: Expense Form Multi-User**
- "Chi ha pagato?" dropdown
- Split type selector
- Custom split UI

## 📞 Troubleshooting

Se hai problemi:

1. **Check console logs** - I debug print ti diranno esattamente cosa sta succedendo
2. **Verify DB state** - Usa query SQL per vedere dati reali
3. **Hot reload** - A volte basta ricaricare l'app
4. **Clean build** - `flutter clean && flutter pub get && flutter run`

## 🎉 Happy Testing!

Se tutti i test passano, la FASE 3C3 è completa! 🚀
