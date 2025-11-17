# 🧪 FASE 4D: Guida Testing Visibilità Spese Gruppo

## 📋 Debug Logging Implementato

Ho aggiunto logging completo in tutta l'applicazione per diagnosticare il problema. Ecco cosa traccia ogni sezione:

### 1. ContextManager (context_manager.dart)

**Tag**: `[CONTEXT]`

Traccia i cambi di contesto:

```
🔄 [CONTEXT] Switching to Group context: Coppia (ID: abc-123)
✅ [CONTEXT] Now in: Group Context: Coppia
✅ [CONTEXT] Group ID: abc-123
```

### 2. ExpenseService - CREATE (expense_service.dart)

**Tag**: `[CREATE]`

Traccia la creazione di spese:

```
🔍 [CREATE] Context: Group (abc-123)
🔍 [CREATE] Expense before context set:
   - groupId: null
   - userId: xyz-456
   - paidBy: xyz-456
   - splitType: equal
🔧 [CREATE] FORCED groupId from context: abc-123
📤 [CREATE] Data being sent to Supabase:
   description: Pizza
   amount: 50.0
   group_id: abc-123
   paid_by: xyz-456
   split_type: equal
✅ [CREATE] Expense created successfully: Pizza (ID: 789)
🔍 [CREATE] Result from DB:
   id: 789
   group_id: abc-123  ← VERIFICA QUESTO!
```

### 3. Expense.toMap() (expense.dart)

**Tag**: `[EXPENSE.toMap]`

Traccia la serializzazione:

```
🔍 [EXPENSE.toMap] Serialized expense:
   - user_id: xyz-456
   - group_id: abc-123  ← VERIFICA QUESTO!
   - paid_by: xyz-456
   - split_type: equal
```

### 4. ExpenseService - STREAM (expense_service.dart)

**Tag**: `[STREAM]`

Traccia le query dello stream:

```
🔍 [STREAM] Creating stream for context: Group (abc-123)
🔍 [STREAM] Current user ID: xyz-456
🔍 [STREAM] Setting up GROUP stream: group_id=abc-123
📊 [STREAM] Group received 0 rows from DB  ← SE 0 = PROBLEMA!
```

### 5. ExpenseList UI (expense_list.dart)

**Tag**: `[UI]`

Traccia lo stato del widget:

```
🔍 [UI] StreamBuilder state: ConnectionState.active
🔍 [UI] Has error: false
🔍 [UI] Has data: true
🔍 [UI] Expenses count: 0  ← SE 0 = PROBLEMA!
```

---

## 🧪 Procedura di Testing

### Step 1: Avvia l'App in Debug Mode

1. Assicurati di essere in debug mode (non release)
2. Apri la console/terminale per vedere i log
3. Avvia l'app: `flutter run`

### Step 2: Test Cambio Contesto

1. **Apri l'app** → Dovresti vedere in console:

   ```
   🔍 [STREAM] Creating stream for context: Personal
   ```

2. **Tap sul ContextSwitcher** (top della schermata)
3. **Seleziona un gruppo** (es. "Coppia")
4. **Verifica console**:
   ```
   🔄 [CONTEXT] Switching to Group context: Coppia (ID: ...)
   ✅ [CONTEXT] Now in: Group Context: Coppia
   ✅ [CONTEXT] Group ID: ...
   🔍 [STREAM] Creating stream for context: Group (...)
   🔍 [STREAM] Setting up GROUP stream: group_id=...
   ```

**✅ CHECKPOINT 1**: Il group ID appare correttamente nei log?

- [ ] Sì → Continua
- [ ] No → PROBLEMA nel ContextManager

### Step 3: Test Creazione Spesa

1. **Tap "+"** (FloatingActionButton)
2. **Compila il form**:
   - Descrizione: "Test Pizza"
   - Importo: 50€
   - Categoria: Ristorante
   - **Verifica** che appaiono i campi gruppo:
     - "Chi ha pagato?" dropdown
     - Radio buttons split type
3. **Seleziona split type**: "Equamente tra tutti"
4. **Tap "Aggiungi Spesa"**

### Step 4: Analizza i Log della Creazione

Dovresti vedere questa sequenza:

```
🔍 [CREATE] Context: Group (abc-123)
🔍 [CREATE] Expense before context set:
   - groupId: abc-123  ← IMPORTANTE: è già settato?
   - userId: xyz-456
   - paidBy: xyz-456
   - splitType: equal

🔧 [CREATE] FORCED groupId from context: abc-123

🔍 [EXPENSE.toMap] Serialized expense:
   - user_id: xyz-456
   - group_id: abc-123  ← VERIFICA QUESTO!
   - paid_by: xyz-456
   - split_type: equal

📤 [CREATE] Data being sent to Supabase:
   description: Test Pizza
   amount: 50.0
   money_flow: carlucci
   date: 2025-01-12T...
   type: ristorante
   user_id: xyz-456
   group_id: abc-123  ← VERIFICA QUESTO!
   paid_by: xyz-456
   split_type: equal

✅ [CREATE] Expense created successfully: Test Pizza (ID: 789)

🔍 [CREATE] Result from DB:
   id: 789
   description: Test Pizza
   amount: 50.0
   group_id: abc-123  ← VERIFICA QUESTO!
   paid_by: xyz-456
   split_type: equal
   ...

💰 Creating splits for expense 789 (type: Equamente tra tutti)
✅ Created 2 expense splits
```

**✅ CHECKPOINT 2**: Verifica questi punti critici:

- [ ] `group_id` appare in `toMap()` output?
- [ ] `group_id` appare in "Data being sent to Supabase"?
- [ ] `group_id` appare in "Result from DB"?

**Se NO a uno qualsiasi**:

- **NO in toMap()**: Problema nella serializzazione (Expense.toMap)
- **NO in Data sent**: Problema nel mapping (unlikely con fix)
- **NO in Result**: Problema nel DB (RLS policy o constraint)

### Step 5: Analizza i Log dello Stream

Subito dopo la creazione, lo stream dovrebbe aggiornarsi:

```
📊 [STREAM] Group received 1 rows from DB  ← IMPORTANTE: dovrebbe essere ≥ 1!
📊 [STREAM] Sample rows:
   [1] id=789, desc="Test Pizza", group_id=abc-123

📊 Received 1 expenses from stream
🔍 [UI] StreamBuilder state: ConnectionState.active
🔍 [UI] Has data: true
🔍 [UI] Expenses count: 1  ← IMPORTANTE: dovrebbe essere ≥ 1!
```

**✅ CHECKPOINT 3**: Verifica:

- [ ] Stream riceve rows dal DB? (conta > 0)
- [ ] `group_id` nelle rows corrisponde al contesto?
- [ ] UI riceve i dati? (Expenses count > 0)

**Se NO**:

- **Stream riceve 0 rows**: Query .eq('group_id', ...) non matcha → Problema nella query o nel DB
- **UI non riceve dati**: Problema nel parsing o nel StreamBuilder

---

## 🔍 Scenari Diagnostici

### Scenario A: group_id = null nel DB

**Sintomi**:

```
✅ [CREATE] Result from DB:
   group_id: null  ← PROBLEMA!
```

**Causa**: Il database non salva group_id (possibili motivi):

1. Constraint check fallisce
2. RLS policy blocca INSERT
3. Column non esiste

**Fix**:

1. Verifica migration applicata: `SELECT * FROM information_schema.columns WHERE table_name='expenses' AND column_name='group_id';`
2. Verifica constraint: `\d expenses` (in psql) o Supabase Dashboard
3. Verifica RLS: Controlla policy INSERT su expenses

### Scenario B: Stream non ritorna rows

**Sintomi**:

```
📊 [STREAM] Group received 0 rows from DB
```

**Ma nel DB la spesa esiste con group_id corretto**.

**Causa**: Query `.eq('group_id', context.groupId)` non matcha

1. Type mismatch: `group_id` è TEXT ma `context.groupId` è UUID?
2. Valore diverso: `group_id` salvato è diverso da quello nel contesto?

**Fix**:

```sql
-- Test manuale in Supabase SQL Editor
SELECT id, description, group_id, paid_by
FROM expenses
WHERE group_id IS NOT NULL
ORDER BY created_at DESC
LIMIT 5;
```

Confronta `group_id` nel DB con quello nei log `[STREAM]`.

### Scenario C: Parsing fallisce

**Sintomi**:

```
📊 [STREAM] Group received 1 rows from DB
❌ ERROR parsing expense from row: ...
```

**Causa**: `Expense.fromMap()` fallisce su qualche campo

**Fix**: Controlla errore specifico e verifica che tutti i campi abbiano valori validi.

### Scenario D: Stream si aggiorna ma UI no

**Sintomi**:

```
📊 [STREAM] Group received 1 rows from DB
🔍 [UI] Expenses count: 0  ← Discrepanza!
```

**Causa**: StreamBuilder non riceve update

**Fix**: Forza rebuild widget o verifica che stream sia subscribed correttamente.

---

## 🎯 Checklist Diagnosi Completa

### Prima di Creare la Spesa

- [ ] Console aperta e visibile
- [ ] App in debug mode
- [ ] Context switcher funziona
- [ ] Nel gruppo corretto (log conferma group ID)

### Durante la Creazione

- [ ] Form mostra campi gruppo
- [ ] Dropdown "Chi ha pagato?" popolato
- [ ] Split type selezionato

### Dopo Submit

- [ ] Log `[CREATE]` appare
- [ ] `group_id` presente in tutti i log
- [ ] `Result from DB` mostra `group_id` corretto
- [ ] Splits creati (se split type ≠ none)

### Stream Update

- [ ] Log `[STREAM]` con "received X rows"
- [ ] X ≥ 1
- [ ] Sample rows mostrano group_id
- [ ] Log `[UI]` con "Expenses count: X"
- [ ] X ≥ 1

### UI Finale

- [ ] Spesa appare nella lista
- [ ] Badge "👥 Gruppo" visibile
- [ ] "Hai pagato tu" visibile
- [ ] Debt indicator visibile

---

## 📊 Esempio Output Completo (SUCCESSO)

```
🔄 [CONTEXT] Switching to Group context: Coppia (ID: 550e8400-e29b-41d4-a716-446655440000)
✅ [CONTEXT] Now in: Group Context: Coppia
✅ [CONTEXT] Group ID: 550e8400-e29b-41d4-a716-446655440000
🔍 [STREAM] Creating stream for context: Group (550e8400-e29b-41d4-a716-446655440000)
🔍 [STREAM] Setting up GROUP stream: group_id=550e8400-e29b-41d4-a716-446655440000

[User creates expense...]

🔍 [CREATE] Context: Group (550e8400-e29b-41d4-a716-446655440000)
🔍 [CREATE] Expense before context set:
   - groupId: 550e8400-e29b-41d4-a716-446655440000
   - userId: 7c9e6679-7425-40de-944b-e07fc1f90ae7
   - paidBy: 7c9e6679-7425-40de-944b-e07fc1f90ae7
   - splitType: equal
🔧 [CREATE] FORCED groupId from context: 550e8400-e29b-41d4-a716-446655440000

🔍 [EXPENSE.toMap] Serialized expense:
   - user_id: 7c9e6679-7425-40de-944b-e07fc1f90ae7
   - group_id: 550e8400-e29b-41d4-a716-446655440000
   - paid_by: 7c9e6679-7425-40de-944b-e07fc1f90ae7
   - split_type: equal

📤 [CREATE] Data being sent to Supabase:
   description: Test Pizza
   amount: 50.0
   money_flow: carlucci
   date: 2025-01-12T15:30:00.000Z
   type: ristorante
   user_id: 7c9e6679-7425-40de-944b-e07fc1f90ae7
   group_id: 550e8400-e29b-41d4-a716-446655440000
   paid_by: 7c9e6679-7425-40de-944b-e07fc1f90ae7
   split_type: equal

✅ [CREATE] Expense created successfully: Test Pizza (ID: 123)
🔍 [CREATE] Result from DB:
   id: 123
   description: Test Pizza
   amount: 50.0
   money_flow: carlucci
   date: 2025-01-12T15:30:00.000Z
   type: ristorante
   user_id: 7c9e6679-7425-40de-944b-e07fc1f90ae7
   group_id: 550e8400-e29b-41d4-a716-446655440000
   paid_by: 7c9e6679-7425-40de-944b-e07fc1f90ae7
   split_type: equal
🔍 [CREATE] Verifying group_id in DB: 550e8400-e29b-41d4-a716-446655440000

💰 Creating splits for expense 123 (type: Equamente tra tutti)
✅ Created 2 expense splits

📊 [STREAM] Group received 1 rows from DB
📊 [STREAM] Sample rows:
   [1] id=123, desc="Test Pizza", group_id=550e8400-e29b-41d4-a716-446655440000
📊 Received 1 expenses from stream

🔍 [UI] StreamBuilder state: ConnectionState.active
🔍 [UI] Has error: false
🔍 [UI] Has data: true
🔍 [UI] Expenses count: 1
```

---

## 🚨 Se Tutto Fallisce: SQL Diretto

Se i log mostrano che `group_id` è salvato correttamente nel DB ma lo stream non lo vede:

```sql
-- 1. Verifica spese nel DB
SELECT id, description, amount, user_id, group_id, paid_by, split_type
FROM expenses
WHERE group_id = 'TUO-GROUP-ID-QUI'
ORDER BY created_at DESC;

-- 2. Verifica tipo di colonna
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'expenses' AND column_name IN ('group_id', 'user_id');

-- 3. Verifica RLS policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies
WHERE tablename = 'expenses';
```

---

## ✅ Prossimi Passi

1. **Esegui il test** seguendo questa guida
2. **Copia tutti i log** dalla console
3. **Identifica a quale checkpoint fallisce**
4. **Controlla lo scenario corrispondente**
5. **Riportami i risultati** così posso implementare il fix specifico

**Nota**: Con il fix preventivo già implementato (FORCED groupId), il problema dovrebbe essere risolto. Se persiste, avremo log dettagliati per identificare esattamente dove fallisce.
