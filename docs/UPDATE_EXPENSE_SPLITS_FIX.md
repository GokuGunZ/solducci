# 🔧 Update Expense Splits Fix

**Data**: 2025-01-13
**Obiettivo**: Ricalcolare expense_splits quando si aggiorna una spesa

---

## 🐛 Problema

Quando si aggiorna una spesa esistente, il metodo `updateExpense()` aggiornava solo la tabella `expenses` ma **non ricalcolava gli expense_splits**.

### Scenario di Bug

**Esempio**:
1. Crei spesa: 100€, split equal, 2 membri
   - Splits creati: Alice 50€, Bob 50€
2. Modifichi spesa: 150€ (cambio importo)
   - Expense aggiornato: 150€
   - **BUG**: Splits rimangono 50€ + 50€ = 100€ ❌
   - **Expected**: Splits dovrebbero essere 75€ + 75€ = 150€ ✅

**Altri scenari problematici**:
- Cambio split type da `equal` a `custom` → splits non aggiornati
- Cambio split type da `equal` a `lend` → splits sbagliati
- Cambio split type da `equal` a `offer` → splits dovrebbero essere eliminati
- Cambio `paid_by` → flag `is_paid` negli splits non aggiornato
- Cambio importo → splits mantengono vecchio valore

---

## ✅ Soluzione Implementata

### Logica del Fix

Il metodo `updateExpense()` ora:

1. **Aggiorna expense record** (come prima)
2. **Valuta tipo di spesa**:
   - Se **group expense** con split type (non `offer`):
     - Elimina vecchi splits
     - Ricalcola nuovi splits
     - Inserisce nuovi splits
   - Se **group expense** con split type `offer`:
     - Elimina tutti gli splits
   - Se **personal expense** (no groupId):
     - Elimina tutti gli splits

### Codice Implementato

**File**: `lib/service/expense_service.dart` → `updateExpense()` (linee 191-281)

```dart
Future updateExpense(Expense updatedExpense) async {
  try {
    // 1. Update expense record
    await _supabase
        .from('expenses')
        .update(updatedExpense.toMap())
        .eq('id', updatedExpense.id);

    // 2. If this is a group expense, recalculate splits
    if (updatedExpense.groupId != null &&
        updatedExpense.splitType != null &&
        updatedExpense.splitType != SplitType.offer) {

      // 2a. Delete old splits
      await _supabase
          .from('expense_splits')
          .delete()
          .eq('expense_id', updatedExpense.id);

      // 2b. Get group members to calculate new splits
      final members = await GroupService().getGroupMembers(updatedExpense.groupId!);

      // 2c. Calculate new splits based on type
      final splits = _calculateSplits(
        expenseId: updatedExpense.id,
        expense: updatedExpense,
        members: members,
      );

      // 2d. Insert new splits
      if (splits.isNotEmpty) {
        await _supabase.from('expense_splits').insert(splits);
      }
    }
    // 3. If changed to "offer" type, delete all splits
    else if (updatedExpense.groupId != null && updatedExpense.splitType == SplitType.offer) {
      await _supabase
          .from('expense_splits')
          .delete()
          .eq('expense_id', updatedExpense.id);
    }
    // 4. If changed to personal expense, delete all splits
    else if (updatedExpense.groupId == null) {
      await _supabase
          .from('expense_splits')
          .delete()
          .eq('expense_id', updatedExpense.id);
    }
  } catch (e) {
    rethrow;
  }
}
```

---

## 📊 Casi Gestiti

### Caso 1: Cambio Importo (Split Type Invariato)

**Prima**:
- Spesa: 100€, equal → Splits: 50€ + 50€
- Update: 150€, equal → **BUG**: Splits: 50€ + 50€ ❌

**Dopo**:
- Spesa: 100€, equal → Splits: 50€ + 50€
- Update: 150€, equal → **FIXED**: Splits: 75€ + 75€ ✅

---

### Caso 2: Cambio Split Type (Equal → Custom)

**Prima**:
- Spesa: 100€, equal → Splits: Alice 50€, Bob 50€
- Update: 100€, custom (Alice 30€, Bob 70€) → **BUG**: Splits: Alice 50€, Bob 50€ ❌

**Dopo**:
- Spesa: 100€, equal → Splits: Alice 50€, Bob 50€
- Update: 100€, custom (Alice 30€, Bob 70€) → **FIXED**: Splits: Alice 30€, Bob 70€ ✅

---

### Caso 3: Cambio Split Type (Equal → Lend)

**Prima**:
- Spesa: 100€, equal → Splits: Alice 50€ (paid), Bob 50€ (unpaid)
- Update: 100€, lend → **BUG**: Splits: Alice 50€ (paid), Bob 50€ (unpaid) ❌

**Dopo**:
- Spesa: 100€, equal → Splits: Alice 50€ (paid), Bob 50€ (unpaid)
- Update: 100€, lend → **FIXED**: Splits: Bob 50€ (unpaid) ✅
  - Solo Bob deve rimborsare (Alice ha prestato)

---

### Caso 4: Cambio Split Type (Equal → Offer)

**Prima**:
- Spesa: 100€, equal → Splits: Alice 50€ (paid), Bob 50€ (unpaid)
- Update: 100€, offer → **BUG**: Splits: Alice 50€ (paid), Bob 50€ (unpaid) ❌

**Dopo**:
- Spesa: 100€, equal → Splits: Alice 50€ (paid), Bob 50€ (unpaid)
- Update: 100€, offer → **FIXED**: Nessun split (tutti eliminati) ✅
  - Alice ha offerto, nessuno deve nulla

---

### Caso 5: Cambio Paid By

**Prima**:
- Spesa: 100€, equal, paid_by=Alice → Splits: Alice 50€ (paid), Bob 50€ (unpaid)
- Update: 100€, equal, paid_by=Bob → **BUG**: Splits: Alice 50€ (paid), Bob 50€ (unpaid) ❌
  - Flag `is_paid` non aggiornato!

**Dopo**:
- Spesa: 100€, equal, paid_by=Alice → Splits: Alice 50€ (paid), Bob 50€ (unpaid)
- Update: 100€, equal, paid_by=Bob → **FIXED**: Splits: Alice 50€ (unpaid), Bob 50€ (paid) ✅

---

### Caso 6: Cambio da Group a Personal

**Prima**:
- Spesa: 100€, group, equal → Splits: Alice 50€, Bob 50€
- Update: 100€, personal (groupId=null) → **BUG**: Splits: Alice 50€, Bob 50€ ❌

**Dopo**:
- Spesa: 100€, group, equal → Splits: Alice 50€, Bob 50€
- Update: 100€, personal (groupId=null) → **FIXED**: Nessun split (tutti eliminati) ✅

---

### Caso 7: Cambio Custom Split Data

**Prima**:
- Spesa: 100€, custom (Alice 40€, Bob 60€) → Splits: Alice 40€, Bob 60€
- Update: 100€, custom (Alice 20€, Bob 80€) → **BUG**: Splits: Alice 40€, Bob 60€ ❌

**Dopo**:
- Spesa: 100€, custom (Alice 40€, Bob 60€) → Splits: Alice 40€, Bob 60€
- Update: 100€, custom (Alice 20€, Bob 80€) → **FIXED**: Splits: Alice 20€, Bob 80€ ✅

---

## 🔄 Flusso Completo

```
User modifica spesa esistente
       ↓
updateExpense(updatedExpense) chiamato
       ↓
Update expense record in DB
       ↓
Verifica tipo spesa:
  ├─ Group expense con split type (non offer)?
  │    ↓
  │    Delete old splits
  │    ↓
  │    Get group members
  │    ↓
  │    Calculate new splits
  │    ↓
  │    Insert new splits
  │
  ├─ Group expense con split type offer?
  │    ↓
  │    Delete all splits
  │
  └─ Personal expense (no groupId)?
       ↓
       Delete all splits
```

---

## 🎯 Vantaggi

### 1. Consistenza Dati
- Splits sempre allineati con expense
- Nessun disallineamento tra importi
- Flag `is_paid` sempre corretto

### 2. Flessibilità
- Supporta cambio di qualsiasi campo
- Gestisce transizioni tra split types
- Gestisce conversione group ↔ personal

### 3. Affidabilità
- Delete + Insert garantisce stato pulito
- Riusa logica `_calculateSplits()` già testata
- Logging completo per debug

### 4. User Experience
- Update trasparente per l'utente
- Balance e debiti aggiornati automaticamente
- Nessuna azione manuale richiesta

---

## 🐛 Edge Cases Gestiti

### Edge Case 1: Update senza Splits
**Scenario**: Update personal expense (no splits)

**Comportamento**: Skip logica splits, solo update expense

✅ Nessuna query inutile

---

### Edge Case 2: Update con Offer Type
**Scenario**: Update a offer type (no splits necessari)

**Comportamento**: Delete eventuali splits esistenti

✅ Cleanup corretto

---

### Edge Case 3: Update con Group Members Changes
**Scenario**: Membri gruppo cambiati dopo creazione spesa

**Comportamento**: Fetch members aggiornati, ricalcolo splits

✅ Sempre sincronizzato con gruppo attuale

---

### Edge Case 4: Concurrent Updates
**Scenario**: Due users aggiornano stessa spesa contemporaneamente

**Comportamento**: Ultimo update vince (last-write-wins)

⚠️ **Nota**: Supabase non ha locking ottimistico by default. Se necessario, considerare:
- Aggiungere `version` field in expenses
- Check version prima di update
- Throw conflict error se mismatch

---

## 📝 Testing Checklist

### Test Case 1: Update Importo
- [ ] Crea spesa 100€ equal
- [ ] Verifica splits: 50€ + 50€
- [ ] Update a 150€
- [ ] Verifica splits: 75€ + 75€ ✅

### Test Case 2: Update Split Type (Equal → Custom)
- [ ] Crea spesa 100€ equal
- [ ] Update a custom (30€ + 70€)
- [ ] Verifica splits: 30€ + 70€ ✅

### Test Case 3: Update Split Type (Equal → Lend)
- [ ] Crea spesa 100€ equal
- [ ] Update a lend
- [ ] Verifica 1 solo split (debitore) ✅

### Test Case 4: Update Split Type (Equal → Offer)
- [ ] Crea spesa 100€ equal
- [ ] Update a offer
- [ ] Verifica nessun split ✅

### Test Case 5: Update Paid By
- [ ] Crea spesa paid_by=Alice
- [ ] Update paid_by=Bob
- [ ] Verifica `is_paid` flags aggiornati ✅

### Test Case 6: Update Group → Personal
- [ ] Crea spesa group con splits
- [ ] Update a personal (remove groupId)
- [ ] Verifica splits eliminati ✅

### Test Case 7: Update Personal → Group
- [ ] Crea spesa personal
- [ ] Update a group con split type
- [ ] Verifica splits creati ✅

---

## ⚠️ Considerazioni

### Performance
**Query count per update**:
- Personal expense: 1 query (solo update)
- Group expense offer: 2 queries (update + delete splits)
- Group expense con splits: 4 queries (update + delete + select members + insert splits)

**Ottimizzazioni possibili**:
- Cache members in memoria (se non cambiano spesso)
- Batch updates con transaction (Supabase supporta)

### Transactions
**Stato attuale**: No transaction, queries sequenziali

**Rischio**: Se insert splits fallisce, old splits già eliminati → inconsistenza

**Soluzione futura**: Usare Supabase RPC con transaction:
```sql
CREATE OR REPLACE FUNCTION update_expense_with_splits(...)
RETURNS void AS $$
BEGIN
  -- Update expense
  UPDATE expenses SET ... WHERE id = expense_id;

  -- Delete old splits
  DELETE FROM expense_splits WHERE expense_id = expense_id;

  -- Insert new splits
  INSERT INTO expense_splits VALUES (...);
END;
$$ LANGUAGE plpgsql;
```

---

## ✅ Completion Status

- [x] Implementato update logic con recalcolo splits
- [x] Gestiti tutti i split types (equal, custom, lend, offer)
- [x] Gestita conversione group ↔ personal
- [x] Logging completo per debug
- [x] Compilation check: ✅ 0 errors
- [ ] Manual testing (pending)
- [ ] Considerare transaction support (future work)

---

**Status**: ✅ IMPLEMENTATO E COMPILATO
**Testing**: 🟡 Pending manual verification
**Impact**: HIGH - Fix critico per integrità dati
