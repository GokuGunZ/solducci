# 🗄️ Database Migration Instructions

## 📋 Overview

Questa guida ti aiuterà a migrare le tue vecchie spese personali (logica MoneyFlow) al nuovo sistema multi-user con split logic.

**File Migration**: [supabase/migrations/20250113_migrate_legacy_expenses.sql](../supabase/migrations/20250113_migrate_legacy_expenses.sql)

---

## ⚠️ IMPORTANTE: Prima di Iniziare

### 1. Backup Database

**OBBLIGATORIO**: Esegui backup completo prima della migration.

In Supabase Dashboard:
1. Settings → Database
2. Backups → Create backup
3. Oppure esporta dati manualmente:

```sql
-- Export expenses
COPY (SELECT * FROM expenses) TO '/tmp/expenses_backup.csv' CSV HEADER;

-- Export expense_splits
COPY (SELECT * FROM expense_splits) TO '/tmp/splits_backup.csv' CSV HEADER;
```

### 2. Verifica Requisiti

- [ ] Hai accesso a Supabase Dashboard
- [ ] Sei autenticato come utente del gruppo target
- [ ] Hai l'UUID del gruppo al quale associare le spese
- [ ] Conosci i membri del gruppo (per split distribution)

---

## 📊 Step 1: Analisi Dati Esistenti

Prima di configurare la migration, analizza i tuoi dati.

### 1.1 Conta Spese Personali

```sql
-- Quante spese personali hai?
SELECT COUNT(*) as personal_expenses_count
FROM expenses
WHERE group_id IS NULL;
```

**Output Esempio**: `personal_expenses_count: 150`

---

### 1.2 Distribuzione MoneyFlow

```sql
-- Quali valori di MoneyFlow esistono?
SELECT
  money_flow,
  COUNT(*) as count
FROM expenses
WHERE group_id IS NULL
GROUP BY money_flow
ORDER BY count DESC;
```

**Output Esempio**:
```
money_flow | count
-----------|------
carlucci   | 90
mari       | 60
```

---

### 1.3 Trova UUID Gruppo

```sql
-- Lista i tuoi gruppi
SELECT
  g.id,
  g.name,
  g.description,
  COUNT(gm.user_id) as member_count
FROM groups g
JOIN group_members gm ON gm.group_id = g.id
WHERE g.id IN (
  SELECT group_id
  FROM group_members
  WHERE user_id = auth.uid()
)
GROUP BY g.id, g.name, g.description;
```

**Output Esempio**:
```
id                                   | name   | description | member_count
-------------------------------------|--------|-------------|-------------
d585824d-83cf-4654-9e6d-5d1eacd32608 | Coppia | Io e Mari   | 2
```

**📝 Annota l'UUID**: `d585824d-83cf-4654-9e6d-5d1eacd32608`

---

### 1.4 Lista Membri Gruppo

```sql
-- Chi sono i membri del gruppo target?
SELECT
  gm.user_id,
  p.nickname,
  p.email
FROM group_members gm
JOIN profiles p ON p.id = gm.user_id
WHERE gm.group_id = 'd585824d-83cf-4654-9e6d-5d1eacd32608';  -- ⚠️ REPLACE!
```

**Output Esempio**:
```
user_id                              | nickname | email
-------------------------------------|----------|------------------
09ace514-a951-4936-afd6-468504075542 | Alessio  | alessio@...
7c9e6679-7425-40de-944b-e07fc1f90ae7 | Mari     | mari@...
```

**📝 Annota**:
- User ID Alessio: `09ace514-a951-4936-afd6-468504075542`
- User ID Mari: `7c9e6679-7425-40de-944b-e07fc1f90ae7`

---

### 1.5 Check Date Formats (Optional)

```sql
-- Ci sono date con formato legacy?
SELECT
  id,
  description,
  date,
  TO_CHAR(date, 'YYYY-MM-DD') as formatted_date
FROM expenses
WHERE date > '2025-01-01'  -- Date suspiciously in the future
ORDER BY date DESC
LIMIT 20;
```

Se vedi date nel futuro (es. 2025-06-07 quando siamo a 2025-01-13), significa che le date erano in formato dd/mm/yyyy e sono state parsate come mm/dd/yyyy.

---

## 🔧 Step 2: Configurazione Migration

Ora modifica il file [20250113_migrate_legacy_expenses.sql](../supabase/migrations/20250113_migrate_legacy_expenses.sql).

### 2.1 Imposta UUID Gruppo

**Riga 13**, sostituisci:
```sql
DECLARE
  target_group_id UUID := 'YOUR-GROUP-UUID-HERE';  -- ⚠️ REPLACE THIS!
```

Con:
```sql
DECLARE
  target_group_id UUID := 'd585824d-83cf-4654-9e6d-5d1eacd32608';  -- ✅ TUO UUID
```

---

### 2.2 Configura Mapping MoneyFlow

**Righe 63-76**, personalizza la logica:

#### Esempio A: Due Membri (Tu + Partner)

```sql
UPDATE expenses
SET
  group_id = target_group_id,
  paid_by = CASE
    WHEN money_flow = 'carlucci' THEN '09ace514-a951-4936-afd6-468504075542'  -- Tu
    WHEN money_flow = 'mari' THEN '7c9e6679-7425-40de-944b-e07fc1f90ae7'      -- Partner
    ELSE current_user_id  -- Default: tu hai pagato
  END,
  split_type = 'equal',  -- Split equamente
  user_id = current_user_id  -- Mantieni owner originale
WHERE
  group_id IS NULL  -- Solo spese personali
  AND user_id = current_user_id;  -- Solo tue spese
```

**Logica**:
- `money_flow = 'carlucci'` → Tu hai pagato (`paid_by = YOUR_USER_ID`)
- `money_flow = 'mari'` → Partner ha pagato (`paid_by = PARTNER_USER_ID`)
- Split type: sempre `equal` (equo tra tutti i membri)

---

#### Esempio B: Più di Due Membri

Se il gruppo ha >2 membri e il pagatore può variare:

```sql
UPDATE expenses
SET
  group_id = target_group_id,
  paid_by = CASE
    WHEN money_flow = 'carlucci' THEN '09ace514-...'  -- Member 1
    WHEN money_flow = 'mari' THEN '7c9e6679-...'      -- Member 2
    WHEN money_flow = 'alice' THEN 'alice-uuid-...'   -- Member 3
    ELSE current_user_id  -- Default
  END,
  split_type = 'equal',
  user_id = current_user_id
WHERE
  group_id IS NULL
  AND user_id = current_user_id;
```

---

### 2.3 Crea Expense Splits

**Righe 85-103**, uncomment e verifica:

```sql
INSERT INTO expense_splits (expense_id, user_id, amount, is_paid)
SELECT
  e.id,
  gm.user_id,
  ROUND(
    e.amount / (SELECT COUNT(*) FROM group_members WHERE group_id = target_group_id),
    2
  ) as split_amount,
  (gm.user_id = e.paid_by) as is_paid  -- Paid if user is payer
FROM expenses e
CROSS JOIN group_members gm
WHERE
  e.group_id = target_group_id
  AND gm.group_id = target_group_id
  AND e.split_type = 'equal'
  AND NOT EXISTS (
    SELECT 1 FROM expense_splits es WHERE es.expense_id = e.id
  );  -- No duplicates
```

**Come Funziona**:
1. Per ogni spesa migrata (`e.group_id = target_group_id`)
2. Crea split per ogni membro del gruppo (`CROSS JOIN group_members`)
3. Importo split = `amount / member_count` (arrotondato a 2 decimali)
4. `is_paid = true` se user è il payer, `false` altrimenti

---

### 2.4 Date Format Fix (Optional)

Se hai date con formato legacy, uncomment e personalizza **righe 40-52**:

```sql
-- Example: Fix dates that were dd/mm/yyyy parsed as mm/dd/yyyy
UPDATE expenses
SET date = date - INTERVAL '1 month'  -- Shift month/day swap
WHERE
  group_id IS NULL  -- Only personal expenses
  AND date > '2025-01-01'  -- Suspiciously in future
  AND EXTRACT(DAY FROM date) <= 12;  -- Could be swapped (dd <= 12)
```

**⚠️ ATTENZIONE**: Questo è un esempio semplificato. Le date potrebbero richiedere logica più complessa. Se non sei sicuro, **salta questo step** e chiedi supporto.

---

## ▶️ Step 3: Test Migration (Subset)

Prima di migrare tutto, testa su un subset piccolo.

### 3.1 Aggiungi LIMIT

Modifica la UPDATE query:

```sql
UPDATE expenses
SET
  group_id = target_group_id,
  -- ... resto del query
WHERE
  group_id IS NULL
  AND user_id = current_user_id
  AND date > '2024-12-01'  -- ← Solo spese recenti
LIMIT 10;  -- ← Solo 10 spese
```

### 3.2 Esegui Migration di Test

1. Apri **Supabase Dashboard** → SQL Editor
2. Copia il contenuto di [20250113_migrate_legacy_expenses.sql](../supabase/migrations/20250113_migrate_legacy_expenses.sql)
3. Click **Run**
4. Verifica output:
   ```
   NOTICE: Migration starting...
   NOTICE: Target group: d585824d-...
   NOTICE: Personal expenses to migrate: 10
   ```

### 3.3 Verifica Test

```sql
-- Check migrated expenses
SELECT
  id,
  description,
  amount,
  money_flow,
  group_id,
  paid_by,
  split_type
FROM expenses
WHERE group_id = 'd585824d-83cf-4654-9e6d-5d1eacd32608'  -- ⚠️ REPLACE
ORDER BY date DESC
LIMIT 10;
```

**Verifica**:
- [ ] `group_id` è il tuo gruppo UUID
- [ ] `paid_by` corrisponde al mapping MoneyFlow
- [ ] `split_type = 'equal'`

```sql
-- Check expense splits created
SELECT
  e.id,
  e.description,
  e.amount,
  es.user_id,
  es.amount as split_amount,
  es.is_paid,
  p.nickname
FROM expenses e
JOIN expense_splits es ON es.expense_id = e.id
JOIN profiles p ON p.id = es.user_id
WHERE e.group_id = 'd585824d-83cf-4654-9e6d-5d1eacd32608'  -- ⚠️ REPLACE
ORDER BY e.id, es.user_id;
```

**Verifica**:
- [ ] Ogni spesa ha 2 (o più) splits (uno per membro)
- [ ] Somma split amounts = expense amount
- [ ] `is_paid = true` per chi ha pagato, `false` per altri

---

## 🚀 Step 4: Full Migration

Se il test ha successo, rimuovi LIMIT e riesegui.

### 4.1 Rimuovi LIMIT

```sql
UPDATE expenses
SET
  group_id = target_group_id,
  -- ... resto del query
WHERE
  group_id IS NULL
  AND user_id = current_user_id;
  -- ← Nessun LIMIT, nessun date filter
```

### 4.2 Esegui Full Migration

1. Supabase Dashboard → SQL Editor
2. Paste migration SQL (senza LIMIT)
3. **Double-check UUID e mapping**
4. Click **Run**
5. **Attendi** (potrebbe richiedere qualche secondo per molte spese)

### 4.3 Verifica Totali

```sql
-- Count personal expenses (should be 0 or near 0)
SELECT COUNT(*) as remaining_personal
FROM expenses
WHERE group_id IS NULL
  AND user_id = auth.uid();

-- Count group expenses (should match migrated count)
SELECT COUNT(*) as migrated_expenses
FROM expenses
WHERE group_id = 'd585824d-83cf-4654-9e6d-5d1eacd32608';  -- ⚠️ REPLACE

-- Count expense splits
SELECT COUNT(*) as total_splits
FROM expense_splits;

-- Expected: total_splits = migrated_expenses × member_count
```

---

## ✅ Step 5: Verification

Esegui verification queries per assicurarti che tutto sia corretto.

### 5.1 Check Split Totals

```sql
-- Verify split totals match expense amounts
SELECT
  e.id,
  e.description,
  e.amount as total_amount,
  SUM(es.amount) as splits_total,
  e.amount - SUM(es.amount) as difference
FROM expenses e
JOIN expense_splits es ON es.expense_id = e.id
WHERE e.group_id = 'd585824d-83cf-4654-9e6d-5d1eacd32608'  -- ⚠️ REPLACE
GROUP BY e.id, e.description, e.amount
HAVING ABS(e.amount - SUM(es.amount)) > 0.01  -- Show discrepancies
ORDER BY difference DESC;
```

**Expected**: Query ritorna 0 rows (nessuna discrepanza).

Se ci sono discrepanze, è dovuto ad arrotondamento. Esempio:
- Expense: 10€
- Members: 3
- Split: 3.33€ × 3 = 9.99€
- Difference: 0.01€

**Fix** (optional): Assegna il centesimo mancante a un membro random:

```sql
-- Find expenses with rounding issues
WITH discrepancies AS (
  SELECT
    e.id as expense_id,
    e.amount - SUM(es.amount) as diff
  FROM expenses e
  JOIN expense_splits es ON es.expense_id = e.id
  WHERE e.group_id = 'd585824d-...'  -- ⚠️ REPLACE
  GROUP BY e.id, e.amount
  HAVING ABS(e.amount - SUM(es.amount)) > 0.01
)
UPDATE expense_splits es
SET amount = amount + d.diff
FROM discrepancies d
WHERE es.expense_id = d.expense_id
  AND es.user_id = (
    SELECT user_id FROM expense_splits
    WHERE expense_id = d.expense_id
    ORDER BY RANDOM()
    LIMIT 1
  );
```

---

### 5.2 Check Member Distribution

```sql
-- Verify all members have splits
SELECT
  p.nickname,
  COUNT(es.id) as split_count,
  SUM(es.amount) as total_amount,
  SUM(CASE WHEN es.is_paid THEN 1 ELSE 0 END) as paid_count,
  SUM(CASE WHEN NOT es.is_paid THEN 1 ELSE 0 END) as unpaid_count
FROM expense_splits es
JOIN profiles p ON p.id = es.user_id
WHERE es.expense_id IN (
  SELECT id FROM expenses WHERE group_id = 'd585824d-...'  -- ⚠️ REPLACE
)
GROUP BY p.nickname;
```

**Expected**: Ogni membro ha:
- `split_count` ≈ uguale (differenza minima)
- `paid_count` + `unpaid_count` = split_count

---

## 🧪 Step 6: App Testing

Dopo migration, testa l'app Flutter.

### 6.1 Restart App

```bash
flutter run
```

### 6.2 Test Checklist

- [ ] Apri app e vai su Homepage
- [ ] Switch a contesto gruppo (quello migrato)
- [ ] Verifica che "Ultime Spese" mostra le spese migrate
- [ ] Verifica che le spese hanno badge "👥 Gruppo"
- [ ] Tap su una spesa migrata
- [ ] Verifica che mostra splits corretti
- [ ] Verifica che "Hai pagato tu" / "Ha pagato X" è corretto
- [ ] Verifica balance corretto nel profilo

### 6.3 Create New Expense

- [ ] Crea nuova spesa nel gruppo
- [ ] Seleziona split type "Equamente tra tutti"
- [ ] Verifica che appare immediatamente nella lista
- [ ] Verifica splits nel database

---

## 🔄 Rollback (Se Necessario)

Se qualcosa va storto, puoi rollback la migration.

### Option A: Rollback Completo

```sql
BEGIN;

-- 1. Delete created expense splits
DELETE FROM expense_splits
WHERE expense_id IN (
  SELECT id FROM expenses WHERE group_id = 'd585824d-...'  -- ⚠️ REPLACE
);

-- 2. Revert expenses to personal
UPDATE expenses
SET
  group_id = NULL,
  paid_by = NULL,
  split_type = NULL
WHERE group_id = 'd585824d-...'  -- ⚠️ REPLACE
  AND user_id = auth.uid();

-- 3. Verify rollback
SELECT COUNT(*) as personal_expenses FROM expenses WHERE group_id IS NULL;
SELECT COUNT(*) as group_expenses FROM expenses WHERE group_id = 'd585824d-...';

COMMIT;  -- Or ROLLBACK if verification fails
```

### Option B: Partial Rollback

Se solo alcune spese sono problematiche:

```sql
-- Rollback specific expenses
WITH problem_expenses AS (
  SELECT id FROM expenses
  WHERE group_id = 'd585824d-...'  -- ⚠️ REPLACE
    AND date < '2024-01-01'  -- Example: old expenses
)
DELETE FROM expense_splits
WHERE expense_id IN (SELECT id FROM problem_expenses);

UPDATE expenses
SET group_id = NULL, paid_by = NULL, split_type = NULL
WHERE id IN (SELECT id FROM problem_expenses);
```

---

## 🆘 Troubleshooting

### Problem 1: "No authenticated user"

**Error**: `No authenticated user - run this migration while logged in`

**Cause**: La migration usa `auth.uid()` che richiede utente autenticato.

**Fix**: Esegui login nella tua app Flutter prima di eseguire migration, oppure modifica query per usare hardcoded user ID:

```sql
DECLARE
  current_user_id UUID := '09ace514-a951-4936-afd6-468504075542';  -- ⚠️ YOUR ID
```

---

### Problem 2: Split Totals Don't Match

**Symptoms**: Query verification mostra discrepanze > 0.01€

**Cause**: Arrotondamento (es. 10€ / 3 = 3.33 × 3 = 9.99)

**Fix**: Vedi sezione 5.1 sopra per query fix.

---

### Problem 3: Wrong Member Paid

**Symptoms**: `paid_by` non corrisponde a chi ha realmente pagato

**Cause**: Mapping MoneyFlow errato

**Fix**:
1. Verifica mapping in Step 2.2
2. Correggi mapping
3. Re-run migration con rollback prima

---

### Problem 4: Dates Still Wrong

**Symptoms**: Date nel futuro o sbagliate

**Cause**: Date format fix non applicato correttamente

**Fix**: Identifica pattern date errate e crea query custom. Esempio:

```sql
-- Se tutte le date del 2025-06-07 dovevano essere 2025-07-06:
UPDATE expenses
SET date = date + INTERVAL '1 month' - INTERVAL '1 day'
WHERE date BETWEEN '2025-06-01' AND '2025-06-30';
```

---

## 📞 Support

Se incontri problemi non documentati:

1. **Check logs** in Supabase Dashboard → Logs
2. **Verify queries** in Step 5
3. **Rollback** se necessario (vedi sezione Rollback)
4. **Documenta** l'errore e pattern dati che lo causano

---

## ✅ Success Criteria

La migration è **completata con successo** se:

- [ ] 0 personal expenses rimanenti (o solo quelle che volevi escludere)
- [ ] Tutte le spese hanno `group_id` corretto
- [ ] Tutte le spese hanno `paid_by` corretto secondo mapping MoneyFlow
- [ ] Tutte le spese hanno splits creati (`count(splits) = count(expenses) × member_count`)
- [ ] Split totals match expense amounts (difference < 0.01€)
- [ ] App mostra spese correttamente nel gruppo
- [ ] Nessun error nella console app

---

**Good luck with the migration! 🚀**

*Se hai domande o problemi, consulta [BUG_FIXES_SESSION.md](BUG_FIXES_SESSION.md) e [SESSION_COMPLETE_SUMMARY.md](SESSION_COMPLETE_SUMMARY.md)*
