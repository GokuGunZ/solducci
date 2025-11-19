# 🔧 Balance Calculation Fix - "TOT€ da recuperare"

**Data**: 2025-01-13
**Bug**: Calcolo errato del balance nella lista spese

---

## 🐛 Problema

Nella lista delle spese gruppo, ogni expense mostra un indicatore:
- `↗️ +X€ da recuperare` (se hai pagato e ti devono soldi)
- `↙️ X€ devi` (se devi pagare)

**Il valore mostrato era SBAGLIATO** per alcuni split types.

---

## 🔍 Root Cause Analysis

### Logica PRIMA (Errata)

**File**: `lib/service/expense_service.dart` → `calculateUserBalance()`

```dart
if (expense.paidBy == currentUserId) {
  // User paid, so they're owed the total minus their share
  return expense.amount - userSplit.amount;
} else {
  // User didn't pay, so they owe their share
  return -userSplit.amount;
}
```

### Perché Era Sbagliata?

Questa logica presume:
- **Se hai pagato**: ti devono = `totalAmount - yourShare`
- **Se non hai pagato**: devi = `yourShare`

**Problema**: Non considera che in alcuni split types **il payer potrebbe non avere uno split**!

---

## 📊 Esempi di Bug

### ✅ Caso 1: Split Type `equal` (Funzionava)

**Setup**:
- Spesa: 100€
- Alice paga
- Split type: `equal` (2 persone)

**Splits Creati**:
```
Alice: 50€, is_paid=true
Bob:   50€, is_paid=false
```

**Calcolo PRIMA**:
- Alice: `100 - 50 = +50€` ✅ CORRETTO
- Bob: `-50€` ✅ CORRETTO

---

### ❌ Caso 2: Split Type `lend` (BUG!)

**Setup**:
- Spesa: 100€
- Alice paga e presta
- Split type: `lend`

**Splits Creati**:
```
Bob: 50€, is_paid=false
(Alice non ha split - lei ha prestato!)
```

**Calcolo PRIMA**:
- Alice: `100 - 0 = +100€` ❌ **SBAGLIATO!** (dovrebbe essere +50€)
  - `userSplit.amount = 0` perché Alice non ha split
  - Formula errata: `100 - 0 = 100`
- Bob: `-50€` ✅ CORRETTO

**Problema**: Alice vede "+100€ da recuperare" ma in realtà le devono solo 50€!

---

### ❌ Caso 3: Split Type `offer` (BUG!)

**Setup**:
- Spesa: 100€
- Alice paga e offre
- Split type: `offer`

**Splits Creati**:
```
(Nessuno - Alice ha offerto!)
```

**Calcolo PRIMA**:
- Alice: `100 - 0 = +100€` ❌ **SBAGLIATO!** (dovrebbe essere 0€)
  - Alice ha offerto, non le devono nulla!
- Bob: `0€` ✅ CORRETTO

**Problema**: Alice vede "+100€ da recuperare" ma ha offerto la spesa!

---

### ✅ Caso 4: Split Type `custom` (Funzionava parzialmente)

**Setup**:
- Spesa: 100€
- Alice paga
- Split type: `custom`
- Splits: Alice 30€, Bob 70€

**Splits Creati**:
```
Alice: 30€, is_paid=true
Bob:   70€, is_paid=false
```

**Calcolo PRIMA**:
- Alice: `100 - 30 = +70€` ✅ CORRETTO
- Bob: `-70€` ✅ CORRETTO

**Nota**: Funzionava per caso, perché Alice aveva uno split.

---

## ✅ Soluzione

### Logica DOPO (Corretta)

**File**: `lib/service/expense_service.dart` → `calculateUserBalance()`

```dart
if (expense.paidBy == currentUserId) {
  // Current user paid - calculate how much they're owed
  // Sum all unpaid splits (what others owe to payer)
  double totalOwed = 0.0;
  for (final split in splits) {
    if (!split.isPaid) {
      totalOwed += split.amount;
    }
  }
  return totalOwed; // Positive = they owe you
} else {
  // Someone else paid - check if current user has an unpaid split
  final userSplit = splits.firstWhere(
    (split) => split.userId == currentUserId,
    orElse: () => ExpenseSplit(
      id: '',
      expenseId: expense.id.toString(),
      userId: currentUserId,
      amount: 0.0,
      isPaid: true, // No split = nothing to pay
      createdAt: DateTime.now(),
    ),
  );

  // If user has unpaid split, they owe that amount
  if (!userSplit.isPaid) {
    return -userSplit.amount; // Negative = you owe
  } else {
    return 0.0; // Already paid or no split
  }
}
```

### Principio Corretto

**Se hai pagato**:
- Calcola: somma di **tutti gli splits unpaid** (indipendentemente da chi sono)
- Questo è ciò che ti devono

**Se non hai pagato**:
- Trova il **tuo split**
- Se è `unpaid`: devi quell'importo
- Se non esiste o è `paid`: non devi nulla

---

## 🧪 Verifica Fix con Esempi

### ✅ Caso 1: Split Type `equal` (Ancora Corretto)

**Splits**:
```
Alice: 50€, is_paid=true
Bob:   50€, is_paid=false
```

**Calcolo DOPO**:
- Alice (payer):
  - Somma unpaid: Bob 50€
  - Result: `+50€` ✅ CORRETTO
- Bob:
  - Suo split: 50€, unpaid
  - Result: `-50€` ✅ CORRETTO

---

### ✅ Caso 2: Split Type `lend` (FIX!)

**Splits**:
```
Bob: 50€, is_paid=false
```

**Calcolo DOPO**:
- Alice (payer):
  - Somma unpaid: Bob 50€
  - Result: `+50€` ✅ **FIXED!** (prima era +100€)
- Bob:
  - Suo split: 50€, unpaid
  - Result: `-50€` ✅ CORRETTO

---

### ✅ Caso 3: Split Type `offer` (FIX!)

**Splits**:
```
(Nessuno)
```

**Calcolo DOPO**:
- Alice (payer):
  - Somma unpaid: 0€
  - Result: `0€` ✅ **FIXED!** (prima era +100€)
- Bob:
  - Nessun split
  - Result: `0€` ✅ CORRETTO

**Nota**: Con balance = 0, l'indicatore non viene mostrato (see line 195 in expense_list_item.dart: `if (balance.abs() < 0.01) return SizedBox.shrink()`).

---

### ✅ Caso 4: Split Type `custom` (Ancora Corretto)

**Splits**:
```
Alice: 30€, is_paid=true
Bob:   70€, is_paid=false
```

**Calcolo DOPO**:
- Alice (payer):
  - Somma unpaid: Bob 70€
  - Result: `+70€` ✅ CORRETTO
- Bob:
  - Suo split: 70€, unpaid
  - Result: `-70€` ✅ CORRETTO

---

## 📊 Confronto Before/After

| Scenario | Split Type | Prima | Dopo | Status |
|----------|------------|-------|------|--------|
| 100€, Alice paga, 2 persone | `equal` | Alice: +50€<br>Bob: -50€ | Alice: +50€<br>Bob: -50€ | ✅ Era già corretto |
| 100€, Alice paga e presta | `lend` | Alice: +100€ ❌<br>Bob: -50€ | Alice: +50€ ✅<br>Bob: -50€ | 🔧 **FIXED** |
| 100€, Alice paga e offre | `offer` | Alice: +100€ ❌<br>Bob: 0€ | Alice: 0€ ✅<br>Bob: 0€ | 🔧 **FIXED** |
| 100€, Alice paga, custom 30/70 | `custom` | Alice: +70€<br>Bob: -70€ | Alice: +70€<br>Bob: -70€ | ✅ Era già corretto |

---

## 🎯 Edge Cases Gestiti

### Edge Case 1: Payer non ha split (lend, offer)

**Prima**: Calcolo errato (userSplit.amount = 0)

**Dopo**: ✅ Calcolo basato su somma unpaid splits degli altri

---

### Edge Case 2: Nessuno split creato (offer)

**Prima**: Calcolo mostrava +totalAmount

**Dopo**: ✅ Calcolo = 0, indicatore nascosto

---

### Edge Case 3: Tutti gli splits sono paid

**Setup**:
- Spesa: 100€
- Alice paga
- Bob ha già pagato il suo split

**Splits**:
```
Alice: 50€, is_paid=true
Bob:   50€, is_paid=true
```

**Calcolo DOPO**:
- Alice: Somma unpaid = 0€ → `0€` (indicatore nascosto)
- Bob: Suo split paid → `0€` (indicatore nascosto)

✅ **CORRETTO**: Se tutti hanno pagato, nessuno deve nulla.

---

### Edge Case 4: User non è nel gruppo ma vede la spesa

**Setup**:
- Spesa di gruppo a cui user non appartiene
- User visualizza la spesa (es. admin)

**Calcolo DOPO**:
- User non è payer: cerca suo split
- Non trova split → `orElse` ritorna split con amount=0, paid=true
- Result: `0€`

✅ **CORRETTO**: User esterno non vede indicatori debiti.

---

## 🧪 Testing Checklist

### Test Case 1: Split Equal (2 persone)
- [ ] Crea spesa 100€, split equal, Alice paga
- [ ] Alice vede: "+50€ da recuperare"
- [ ] Bob vede: "50€ devi"

### Test Case 2: Split Lend
- [ ] Crea spesa 100€, split lend, Alice paga
- [ ] Alice vede: "+50€ da recuperare" (non +100€!)
- [ ] Bob vede: "50€ devi"

### Test Case 3: Split Offer
- [ ] Crea spesa 100€, split offer, Alice paga
- [ ] Alice: **nessun indicatore** (0€)
- [ ] Bob: **nessun indicatore** (0€)

### Test Case 4: Split Custom
- [ ] Crea spesa 100€, split custom (Alice 30€, Bob 70€), Alice paga
- [ ] Alice vede: "+70€ da recuperare"
- [ ] Bob vede: "70€ devi"

### Test Case 5: Già Pagato
- [ ] Crea spesa con split, poi marca split come paid
- [ ] Entrambi: **nessun indicatore** (tutti paid)

---

## 📝 Code Changes Summary

### File Modificato

**File**: [lib/service/expense_service.dart](../lib/service/expense_service.dart)

**Funzione**: `calculateUserBalance(Expense expense)`

**Lines**: 383-425

**Changes**:
- **Removed**: Logica `expense.amount - userSplit.amount`
- **Added**: Loop per sommare splits unpaid quando user è payer
- **Changed**: Gestione caso nessuno split per payer

**Impact**:
- ✅ Fix calcolo per split type `lend`
- ✅ Fix calcolo per split type `offer`
- ✅ Mantiene correttezza per `equal` e `custom`

---

## 🎉 Benefits

1. **Accuratezza**: Calcolo corretto per TUTTI i split types
2. **Consistenza**: Logica basata sempre sugli splits (non su assunzioni)
3. **Robustezza**: Gestisce edge cases (nessun split, tutti paid, etc.)
4. **Trasparenza**: Calcolo chiaro: "somma ciò che è unpaid"

---

## ✅ Completion Status

- [x] Identificato bug nella logica
- [x] Analizzati tutti i casi (equal, lend, offer, custom)
- [x] Implementato fix corretto
- [x] Verificato edge cases
- [x] Compilation check: ✅ 0 errors
- [x] Documentazione completa
- [ ] Manual testing (pending)

---

**Status**: ✅ BUG FIXED
**Impact**: HIGH - Corregge visualizzazione debiti per tutti gli utenti
**Testing**: 🟡 Pending manual verification
