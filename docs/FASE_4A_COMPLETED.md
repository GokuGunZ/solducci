# ✅ FASE 4A: Split Type Renaming - COMPLETATA

## 🎯 Obiettivo

Rinominare i tipi di split per renderli più intuitivi e implementare la logica corretta per il tipo "Presta":

1. **`full` → `lend` ("Presta")**: Chi paga anticipa per tutti e riceve l'intero importo dagli altri
2. **`none` → `offer` ("Offri")**: Chi paga offre la spesa, nessun rimborso richiesto

---

## 📝 Modifiche Implementate

### 1. [lib/models/split_type.dart](../lib/models/split_type.dart)

**Enum Values Rinominati:**

```dart
// BEFORE:
full('full', 'Una persona paga tutto', 'Un solo membro paga l\'intera spesa'),
none('none', 'Non dividere', 'Spesa di gruppo ma non divisa tra membri');

// AFTER:
lend('lend', 'Presta', 'Chi paga anticipa per tutti e verrà rimborsato'),
offer('offer', 'Offri', 'Chi paga offre la spesa, nessun rimborso');
```

**Icone Aggiornate:**

```dart
case SplitType.lend:
  return '💸';  // Money with wings (prestito/anticipo)
case SplitType.offer:
  return '🎁';  // Gift (offerta)
```

---

### 2. [lib/service/expense_service.dart](../lib/service/expense_service.dart)

#### A. Metodo `_calculateSplits()` - Nuova logica "Presta"

**Linee 318-334**: Aggiunto caso per `SplitType.lend`:

```dart
case SplitType.lend:
  // Payer advances for all members - everyone else must reimburse
  final amountPerPerson = expense.amount / members.length;
  final roundedAmount = double.parse(amountPerPerson.toStringAsFixed(2));

  for (final member in members) {
    // Create splits for ALL members except the payer
    if (member.userId != expense.paidBy) {
      splits.add({
        'expense_id': expenseId,
        'user_id': member.userId,
        'amount': roundedAmount,
        'is_paid': false,  // All others must pay
      });
    }
  }
  break;
```

**Come Funziona "Presta":**

1. **Calcola importo per persona**: `amountPerPerson = totalAmount / numberOfMembers`
2. **Crea splits SOLO per gli altri membri** (escluso chi ha pagato)
3. **Tutti gli altri membri devono rimborsare** (`is_paid: false`)
4. **Chi ha pagato riceve l'intero importo** (nessun split per lui)

**Esempio Pratico:**
- Spesa: 100€
- Gruppo: 4 persone (Alice, Bob, Carol, Dave)
- Alice paga e seleziona "Presta"
- Risultato:
  - Bob deve pagare 25€ ad Alice
  - Carol deve pagare 25€ ad Alice
  - Dave deve pagare 25€ ad Alice
  - Alice riceve 75€ totali (25€ × 3)
  - Alice ha "speso" solo la sua parte: 25€

**Linee 336-338**: Aggiunto caso per `SplitType.offer`:

```dart
case SplitType.offer:
  // Payer offers the expense - no splits, no reimbursement
  break;
```

**Come Funziona "Offri":**
- Nessun split creato
- Chi paga offre tutta la spesa
- Nessuno deve rimborsare

#### B. Condizione per creazione splits - Linee 77-79

**Prima:**
```dart
if (newExpense.groupId != null &&
    newExpense.splitType != null &&
    newExpense.splitType != SplitType.full &&
    newExpense.splitType != SplitType.none) {
```

**Dopo:**
```dart
if (newExpense.groupId != null &&
    newExpense.splitType != null &&
    newExpense.splitType != SplitType.offer) {
```

**Logica**:
- Crea splits per: `equal`, `custom`, `lend`
- **Non crea** splits per: `offer` (nessuno deve rimborsare)

---

### 3. [supabase/migrations/20250113_update_split_types.sql](../supabase/migrations/20250113_update_split_types.sql)

**Migration completa** per aggiornare il database:

```sql
-- 1. Rimuove vecchio constraint
ALTER TABLE expenses
DROP CONSTRAINT IF EXISTS expenses_split_type_check;

-- 2. Aggiunge nuovo constraint con valori aggiornati
ALTER TABLE expenses
ADD CONSTRAINT expenses_split_type_check
CHECK (split_type IN ('equal', 'custom', 'lend', 'offer'));

-- 3. Aggiorna dati esistenti (se ci sono)
UPDATE expenses SET split_type = 'lend' WHERE split_type = 'full';
UPDATE expenses SET split_type = 'offer' WHERE split_type = 'none';
```

---

## 🧪 Testing

### Test Case 1: Presta (Lend)

**Setup:**
- Gruppo "Coppia": Alice (ID: aaa-111), Bob (ID: bbb-222)
- Alice crea spesa: 100€ per pizza
- Alice paga
- Split type: "Presta" (lend)

**Azione:**
1. Switch a contesto gruppo "Coppia"
2. Tap "+" per nuova spesa
3. Compila:
   - Descrizione: "Pizza"
   - Importo: 100
   - Chi ha pagato: Alice
   - **Split type: "💸 Presta"**
4. Tap "Aggiungi Spesa"

**Risultato Atteso:**

Database `expenses`:
```
id: 123
description: "Pizza"
amount: 100.0
group_id: coppia-id
paid_by: aaa-111
split_type: 'lend'
```

Database `expense_splits`:
```
expense_id: 123, user_id: bbb-222, amount: 50.0, is_paid: false
```

**Nota**: Solo Bob ha uno split. Alice NO (perché ha pagato).

**UI Vista di Bob:**
- Vede spesa "Pizza" nella lista
- Badge: "👥 Gruppo"
- Debt indicator: "Devi pagare 50€"

**UI Vista di Alice:**
- Vede spesa "Pizza" nella lista
- Badge: "👥 Gruppo"
- "Hai pagato tu"
- Debt indicator: "Ti devono 50€" (Bob deve rimborsare)

---

### Test Case 2: Offri (Offer)

**Setup:**
- Stesso gruppo: Alice, Bob
- Alice crea spesa: 30€ per caffè
- Alice paga
- Split type: "Offri" (offer)

**Azione:**
1. Compila spesa come sopra
2. **Split type: "🎁 Offri"**

**Risultato Atteso:**

Database `expenses`:
```
id: 124
description: "Caffè"
amount: 30.0
group_id: coppia-id
paid_by: aaa-111
split_type: 'offer'
```

Database `expense_splits`:
```
(nessun record creato)
```

**UI Vista di Bob:**
- Vede spesa "Caffè" nella lista
- Badge: "👥 Gruppo"
- Nessun debt indicator (Alice ha offerto)

**UI Vista di Alice:**
- Vede spesa "Caffè" nella lista
- Badge: "👥 Gruppo"
- "Hai pagato tu"
- "🎁 Hai offerto questa spesa"

---

### Test Case 3: Gruppo con 4 Persone

**Setup:**
- Gruppo "Viaggio": Alice, Bob, Carol, Dave (4 persone)
- Carol crea spesa: 200€ per cena
- Carol paga
- Split type: "Presta"

**Risultato Atteso:**

Database `expense_splits` (3 record):
```
expense_id: 125, user_id: alice-id, amount: 50.0, is_paid: false
expense_id: 125, user_id: bob-id,   amount: 50.0, is_paid: false
expense_id: 125, user_id: dave-id,  amount: 50.0, is_paid: false
(nessuno per Carol - lei ha pagato)
```

**Logica**:
- Importo per persona: 200€ / 4 = 50€
- Carol anticipa 200€
- Carol riceve 150€ dagli altri (50€ × 3)
- Carol "spende" solo 50€ (la sua parte)

---

## 🔄 Confronto Before/After

| Aspetto | Before | After |
|---------|--------|-------|
| **Enum Name** | `SplitType.full` | `SplitType.lend` |
| **Label** | "Una persona paga tutto" | "Presta" |
| **Icon** | 💰 | 💸 |
| **Splits Created?** | ❌ No | ✅ Sì (per altri membri) |
| **Payer Included in Splits?** | N/A | ❌ No (solo altri) |
| | | |
| **Enum Name** | `SplitType.none` | `SplitType.offer` |
| **Label** | "Non dividere" | "Offri" |
| **Icon** | 🚫 | 🎁 |
| **Splits Created?** | ❌ No | ❌ No |

---

## 📊 Impatto sul Database

### Prima della Migration:

```sql
-- Possibili valori vecchi:
SELECT split_type, COUNT(*) FROM expenses GROUP BY split_type;
-- Risultato:
-- equal: 10
-- custom: 5
-- full: 2    ← DA AGGIORNARE
-- none: 3    ← DA AGGIORNARE
```

### Dopo la Migration:

```sql
-- Valori aggiornati:
SELECT split_type, COUNT(*) FROM expenses GROUP BY split_type;
-- Risultato:
-- equal: 10
-- custom: 5
-- lend: 2    ← AGGIORNATO
-- offer: 3   ← AGGIORNATO
```

---

## 🎯 Come Applicare la Migration

1. **Apri Supabase Dashboard** → SQL Editor
2. **Copia il contenuto** di `supabase/migrations/20250113_update_split_types.sql`
3. **Esegui la query**
4. **Verifica**:
   ```sql
   -- Verifica constraint aggiornato
   SELECT conname, pg_get_constraintdef(oid)
   FROM pg_constraint
   WHERE conname = 'expenses_split_type_check';

   -- Verifica nessun valore vecchio rimane
   SELECT COUNT(*) FROM expenses WHERE split_type IN ('full', 'none');
   -- Deve ritornare 0
   ```

---

## ✅ Checklist Completamento

- [x] Enum `SplitType` rinominato in `split_type.dart`
- [x] Icone aggiornate
- [x] Logica "Presta" implementata in `_calculateSplits()`
- [x] Logica "Offri" implementata (nessun split)
- [x] Condizione creazione splits aggiornata
- [x] Migration SQL creata
- [x] Compilation check: ✅ Nessun errore
- [x] Documentazione completa

---

## 🔜 Prossimi Passi

1. **Test l'applicazione**:
   - Crea spesa con "Presta" in gruppo a 2 persone
   - Verifica splits nel database
   - Controlla UI per entrambi i membri

2. **Applica la migration** al database Supabase

3. **Se tutto funziona**: Procedi con **FASE 4B** (round-up button)

---

## 💡 Note Tecniche

### Differenza "Presta" vs "Equamente"

| | Presta (lend) | Equamente (equal) |
|---|---|---|
| **Splits creati per** | Solo altri membri | Tutti i membri (incluso payer) |
| **is_paid per payer** | N/A (no split) | `true` |
| **is_paid per altri** | `false` | `false` |
| **Chi deve pagare?** | Tutti gli altri | Tutti gli altri |
| **Importo per payer** | 0€ (riceve tutto) | La sua parte |

**Esempio 100€ con 2 persone (Alice paga):**

**Presta:**
- Splits: Bob → 50€ (is_paid: false)
- Alice riceve: 50€
- Alice ha speso: 50€ (la sua parte)

**Equamente:**
- Splits: Alice → 50€ (is_paid: true), Bob → 50€ (is_paid: false)
- Alice ha speso: 50€
- Bob deve pagare: 50€

**Outcome identico**, ma semantica diversa:
- **Presta**: "Ho anticipato, rimborsamiatemi"
- **Equamente**: "Abbiamo diviso, tu non hai ancora pagato"

---

**Status**: ✅ FASE 4A COMPLETATA
**Next**: FASE 4B - Round-up Button in Custom Splits
