# Guida: Applicare Migrazioni per FASE 3D
prova

## Migrazioni Necessarie

Per far funzionare le spese di gruppo (FASE 3D), devi applicare queste migrazioni al tuo database Supabase:

### 1. Migrazione Base Multi-User (se non ancora applicata)

**File**: `001_multi_user_setup_v3.sql`

Questa migrazione crea:
- Tabella `profiles` (profili utente)
- Tabella `groups` (gruppi)
- Tabella `group_members` (membri dei gruppi)
- Tabella `group_invites` (inviti)
- Tabella `expense_splits` (split delle spese)
- Aggiunge campi `group_id`, `paid_by`, `split_type`, `split_data` alla tabella `expenses`
- RLS policies per tutte le tabelle
- Funzioni helper per calcolare i debiti

**Come applicare**:
1. Vai su [Supabase Dashboard](https://supabase.com/dashboard)
2. Apri il progetto Solducci
3. Vai su **SQL Editor** (icona database nella sidebar)
4. Crea una nuova query
5. Copia e incolla il contenuto di `001_multi_user_setup_v3.sql`
6. Clicca **Run** (o Ctrl/Cmd + Enter)
7. Verifica che non ci siano errori (potrebbero esserci NOTICE, va bene)

### 2. Fix Colonna expense_splits

**File**: `20250112_fix_expense_splits_column.sql`

Questa migrazione:
- Rinomina la colonna `paid` in `is_paid` (compatibile con il modello Dart)
- Aggiunge la colonna `paid_at` se mancante

**Come applicare**:
1. Vai su **SQL Editor** in Supabase Dashboard
2. Crea una nuova query
3. Copia e incolla il contenuto di `20250112_fix_expense_splits_column.sql`
4. Clicca **Run**
5. Verifica il messaggio di successo

---

## Verifica che le Migrazioni Siano State Applicate

Dopo aver applicato entrambe le migrazioni, verifica che tutto sia corretto:

### Verifica Tabelle

Esegui questa query nel SQL Editor:

```sql
-- Verifica che tutte le tabelle esistano
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN (
    'profiles',
    'groups',
    'group_members',
    'group_invites',
    'expenses',
    'expense_splits'
  )
ORDER BY table_name;
```

**Risultato atteso**: 6 righe con i nomi delle tabelle

### Verifica Colonne expenses

```sql
-- Verifica colonne nella tabella expenses
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'expenses'
  AND column_name IN ('group_id', 'paid_by', 'split_type', 'split_data')
ORDER BY column_name;
```

**Risultato atteso**:
- `group_id` (uuid, YES)
- `paid_by` (uuid, YES)
- `split_data` (jsonb, YES)
- `split_type` (text, YES)

### Verifica Colonne expense_splits

```sql
-- Verifica colonne nella tabella expense_splits
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'expense_splits'
ORDER BY ordinal_position;
```

**Risultato atteso** (almeno queste colonne):
- `id` (uuid, NO)
- `expense_id` (integer, YES)
- `user_id` (uuid, YES)
- `amount` (numeric, NO)
- `is_paid` (boolean, YES) ← **IMPORTANTE**: deve essere `is_paid`, NON `paid`
- `created_at` (timestamp with time zone, YES)
- `paid_at` (timestamp with time zone, YES)

### Verifica RLS Policies

```sql
-- Verifica che RLS sia abilitato
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN ('expenses', 'expense_splits', 'groups', 'group_members')
ORDER BY tablename;
```

**Risultato atteso**: Tutte le tabelle devono avere `rowsecurity = true`

---

## Test Funzionalità

Dopo aver applicato le migrazioni, testa la funzionalità:

### Test 1: Crea una Spesa Personale (sanity check)
1. Apri l'app
2. Assicurati di essere in contesto "Personale"
3. Crea una spesa normale
4. Verifica che venga salvata correttamente

### Test 2: Crea un Gruppo
1. Vai alla pagina Gruppi
2. Crea un nuovo gruppo (es. "Test Gruppo")
3. Invita un altro utente (se disponibile)
4. Verifica che il gruppo appaia nella lista

### Test 3: Crea una Spesa di Gruppo
1. Cambia contesto al gruppo appena creato
2. Tap "Nuova Spesa"
3. Verifica che appaiano i campi:
   - "Chi ha pagato?" (dropdown con membri)
   - "Come dividere?" (radio buttons)
4. Compila:
   - Descrizione: "Test Pizza"
   - Importo: 50€
   - Split: "Equamente tra tutti"
5. Salva
6. Verifica che la spesa appaia con:
   - Badge "👥 Gruppo"
   - "💰 Hai pagato tu"
   - Indicatore debito (es. "↗️ +25.00€ da recuperare")

### Test 4: Verifica nel Database

Esegui questa query per verificare che tutto sia stato salvato:

```sql
-- Ultima spesa creata con i dettagli
SELECT
  e.id,
  e.description,
  e.amount,
  e.group_id,
  g.name as group_name,
  e.paid_by,
  p.nickname as paid_by_name,
  e.split_type,
  e.split_data
FROM expenses e
LEFT JOIN groups g ON e.group_id = g.id
LEFT JOIN profiles p ON e.paid_by = p.id
ORDER BY e.created_at DESC
LIMIT 1;
```

**Risultato atteso**: Dovresti vedere la spesa con `group_id` popolato e `split_type = 'equal'`

```sql
-- Verifica che gli splits siano stati creati
SELECT
  es.id,
  es.expense_id,
  es.user_id,
  p.nickname as user_name,
  es.amount,
  es.is_paid
FROM expense_splits es
JOIN profiles p ON es.user_id = p.id
WHERE es.expense_id = (
  SELECT id FROM expenses
  ORDER BY created_at DESC
  LIMIT 1
);
```

**Risultato atteso**: Dovresti vedere N righe (dove N = numero membri del gruppo), ognuna con l'importo diviso equamente

---

## Troubleshooting

### Problema: "relation 'expense_splits' does not exist"
**Soluzione**: La migrazione `001_multi_user_setup_v3.sql` non è stata applicata. Applica quella prima.

### Problema: "column 'is_paid' does not exist"
**Soluzione**: Applica la migrazione `20250112_fix_expense_splits_column.sql`

### Problema: "permission denied for table expense_splits"
**Soluzione**: Verifica che i GRANTS siano stati applicati. Riesegui la sezione STEP 6 della migrazione v3:
```sql
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO anon, authenticated;
```

### Problema: "infinite recursion detected in policy"
**Soluzione**: Questo problema è stato risolto nella v3. Se ancora lo vedi:
1. Verifica di aver applicato `001_multi_user_setup_v3.sql` (NON v1 o v2)
2. Controlla le policy nel dashboard Supabase
3. Assicurati che le policy usino `USING (true)` per SELECT, non subquery su group_members

### Problema: L'app si blocca quando creo una spesa di gruppo
**Soluzione**:
1. Verifica che le migrazioni siano state applicate
2. Controlla la console Flutter per errori
3. Verifica che le RLS policy permettano INSERT su expense_splits
4. Controlla che il gruppo abbia membri

### Problema: Non vedo il debito (balance) nella lista
**Soluzione**:
1. Verifica che gli `expense_splits` siano stati creati nel database
2. Controlla che il metodo `calculateUserBalance()` funzioni
3. Verifica che la colonna si chiami `is_paid` (non `paid`)

---

## Rollback (in caso di problemi)

Se qualcosa va storto, puoi fare rollback:

```sql
-- ATTENZIONE: Questo eliminerà TUTTI i dati multi-user!
-- Usa solo se necessario

DROP TABLE IF EXISTS expense_splits CASCADE;
DROP TABLE IF EXISTS group_invites CASCADE;
DROP TABLE IF EXISTS group_members CASCADE;
DROP TABLE IF EXISTS groups CASCADE;
DROP TABLE IF EXISTS profiles CASCADE;

-- Rimuovi colonne da expenses
ALTER TABLE expenses DROP COLUMN IF EXISTS group_id;
ALTER TABLE expenses DROP COLUMN IF EXISTS paid_by;
ALTER TABLE expenses DROP COLUMN IF EXISTS split_type;
ALTER TABLE expenses DROP COLUMN IF EXISTS split_data;

-- Riapplica poi le migrazioni da capo
```

---

## Status Migrazioni

- [x] `001_multi_user_setup_v3.sql` - Setup completo multi-user
- [x] `20250112_fix_expense_splits_column.sql` - Fix colonna is_paid
- [ ] Da applicare al database Supabase

**Prossimo passo**: Applica le migrazioni seguendo la guida sopra, poi testa l'app!
