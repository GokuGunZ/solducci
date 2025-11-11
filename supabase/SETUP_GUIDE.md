# 🗄️ Supabase Database Setup Guide

## Step 1: Esegui la Migration

### Opzione A: Via Supabase Dashboard (Consigliato)
1. Vai su [app.supabase.com](https://app.supabase.com)
2. Apri il tuo progetto Solducci
3. Clicca su **SQL Editor** nella sidebar sinistra
4. Clicca su **New Query**
5. Copia e incolla il contenuto di `migrations/001_multi_user_setup.sql`
6. Clicca su **Run** (o premi Ctrl+Enter)
7. Aspetta il messaggio "Success. No rows returned"

### Opzione B: Via Supabase CLI
```bash
# Se hai Supabase CLI installato
supabase db push

# Oppure applica direttamente il file
supabase db execute -f supabase/migrations/001_multi_user_setup.sql
```

---

## Step 2: Verifica la Migration

### Controlla che le tabelle siano state create:
1. Vai su **Table Editor** in Supabase Dashboard
2. Dovresti vedere queste nuove tabelle:
   - ✅ `profiles`
   - ✅ `groups`
   - ✅ `group_members`
   - ✅ `group_invites`
   - ✅ `expense_splits`

3. La tabella `expenses` dovrebbe avere le nuove colonne:
   - ✅ `group_id`
   - ✅ `paid_by`
   - ✅ `split_type`
   - ✅ `split_data`

### Controlla le RLS Policies:
1. Clicca su una tabella (es. `profiles`)
2. Vai al tab **Policies**
3. Dovresti vedere le policy create

---

## Step 3: Testa con un Utente di Prova

### Test 1: Auto-creazione Profile
```sql
-- Esegui nel SQL Editor
SELECT * FROM profiles WHERE email = 'tuo-email@esempio.com';
```
Dopo aver fatto signup nell'app, dovresti vedere il tuo profilo automaticamente creato.

### Test 2: Crea un Gruppo di Test
```sql
-- Inserisci un gruppo di test
INSERT INTO groups (name, description, created_by)
VALUES (
  'Gruppo Test',
  'Test per multi-user',
  (SELECT id FROM profiles WHERE email = 'tuo-email@esempio.com')
)
RETURNING *;

-- Salvati il group_id restituito, poi aggiungi te stesso come admin
INSERT INTO group_members (group_id, user_id, role)
VALUES (
  'UUID-DEL-GRUPPO',  -- Sostituisci con l'id del gruppo creato sopra
  (SELECT id FROM profiles WHERE email = 'tuo-email@esempio.com'),
  'admin'
);
```

### Test 3: Verifica RLS
```sql
-- Questi dovrebbero funzionare (vedi solo i tuoi dati)
SELECT * FROM profiles WHERE id = auth.uid();
SELECT * FROM groups WHERE id IN (
  SELECT group_id FROM group_members WHERE user_id = auth.uid()
);

-- Questo dovrebbe restituire 0 righe (non puoi vedere dati di altri)
SELECT * FROM profiles WHERE id != auth.uid() AND email != '';
```

---

## Step 4: Migrazione Dati Esistenti (Se Hai Dati "Carl" e "Pit")

### Opzione: Crea un Gruppo "Carl & Pit" e Migra i Dati

```sql
-- 1. Crea profili per Carl e Pit (se non esistono già)
-- Nota: dovranno registrarsi normalmente, questo è solo un esempio

-- 2. Crea il gruppo "Carl & Pit"
INSERT INTO groups (id, name, description, created_by)
VALUES (
  gen_random_uuid(),
  'Carl & Pit',
  'Gruppo storico migratto',
  (SELECT id FROM profiles LIMIT 1)  -- Il primo utente registrato diventa admin
)
RETURNING id;  -- Salvati questo ID!

-- 3. Aggiungi membri (sostituisci gli UUID)
INSERT INTO group_members (group_id, user_id, role) VALUES
  ('GROUP-UUID-QUI', 'CARL-USER-UUID', 'admin'),
  ('GROUP-UUID-QUI', 'PIT-USER-UUID', 'member');

-- 4. Migra le spese esistenti al gruppo
UPDATE expenses
SET
  group_id = 'GROUP-UUID-QUI',
  paid_by = CASE
    WHEN money_flow IN ('carlToPit', 'carlDiv2', 'carlucci') THEN 'CARL-USER-UUID'
    WHEN money_flow IN ('pitToCarl', 'pitDiv2', 'pit') THEN 'PIT-USER-UUID'
    ELSE NULL
  END,
  split_type = CASE
    WHEN money_flow IN ('carlDiv2', 'pitDiv2') THEN 'equal'
    WHEN money_flow IN ('carlToPit', 'pitToCarl') THEN 'full'
    ELSE 'none'
  END
WHERE group_id IS NULL;  -- Solo spese non ancora migrate

-- 5. Crea gli split per le spese divise
INSERT INTO expense_splits (expense_id, user_id, amount)
SELECT
  e.id,
  gm.user_id,
  CASE
    WHEN e.split_type = 'equal' THEN e.amount / 2
    ELSE e.amount
  END
FROM expenses e
CROSS JOIN group_members gm
WHERE e.group_id = 'GROUP-UUID-QUI'
  AND e.split_type = 'equal'
  AND gm.group_id = 'GROUP-UUID-QUI';
```

---

## Step 5: Testing Checklist

Dopo la migration, testa questi scenari:

- [ ] **Signup**: Nuovo utente crea account → profilo auto-creato
- [ ] **Profile Update**: Utente modifica nickname → salvato correttamente
- [ ] **Create Group**: Utente crea gruppo → visibile nella lista
- [ ] **Invite**: Utente invita qualcuno via email → invito creato
- [ ] **Join Group**: Utente accetta invito → aggiunto al gruppo
- [ ] **Create Expense (Personal)**: Spesa personale → visibile solo all'utente
- [ ] **Create Expense (Group)**: Spesa di gruppo → visibile a tutti i membri
- [ ] **Context Switch**: Cambia contesto → vede spese diverse
- [ ] **Delete Group**: Admin cancella gruppo → spese diventano orfane (previsto)

---

## Troubleshooting

### Errore: "permission denied for table X"
- **Causa**: RLS non configurato correttamente
- **Soluzione**: Esegui di nuovo la sezione GRANTS dello script

### Errore: "duplicate key value violates unique constraint"
- **Causa**: Stai cercando di creare una tabella che già esiste
- **Soluzione**: Usa `DROP TABLE IF EXISTS` prima di CREATE

### Non vedo i profili dopo signup
- **Causa**: Trigger non funziona
- **Soluzione**:
  1. Verifica che il trigger sia stato creato: `\df handle_new_user` in psql
  2. Controlla i log di Supabase per errori

### Le query non rispettano RLS
- **Causa**: RLS disabilitato o policy errate
- **Soluzione**: Verifica con `SELECT * FROM pg_policies WHERE tablename = 'profiles';`

---

## Rollback (In Caso di Problemi)

Se qualcosa va storto e vuoi tornare indietro:

```bash
# ATTENZIONE: Questo eliminerà tutti i gruppi e inviti!
psql -f supabase/migrations/001_rollback.sql
```

Oppure esegui `001_rollback.sql` nel SQL Editor di Supabase.

---

## Next Steps

Dopo aver completato il database setup:

1. ✅ Procedi con **FASE 2**: Creare i modelli Dart
2. ✅ Implementare `ProfileService`, `GroupService`, `ContextManager`
3. ✅ Aggiornare `ExpenseService` per filtrare per contesto

Vedi `../docs/IMPLEMENTATION_ROADMAP.md` per il piano completo.
