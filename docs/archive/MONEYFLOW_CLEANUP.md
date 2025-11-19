# 🧹 MoneyFlow Cleanup - Rimozione Vecchia Logica

**Data**: 2025-01-13
**Obiettivo**: Rimuovere tutti i riferimenti alla vecchia logica MoneyFlow dalla UI e dal codice

---

## ✅ Modifiche Completate

### 1. UI - Rimosso "Flusso" dal BottomSheet Dettagli Spesa

**File**: [lib/widgets/expense_list_item.dart](../lib/widgets/expense_list_item.dart)

**Modifiche**:
- **Riga 265**: Rimossa riga `_buildDetailRow('Flusso', expense.moneyFlow.getLabel())`
- **Righe 555-568**: Rimossa funzione `_getAmountColor(MoneyFlow flow)`
- **Riga 92**: Cambiato colore importo da dinamico (basato su MoneyFlow) a fisso `Colors.blue`

**Prima**:
```dart
_buildDetailRow('Descrizione', expense.description),
_buildDetailRow('Importo', expense.formatAmount(expense.amount)),
_buildDetailRow('Flusso', expense.moneyFlow.getLabel()),  // ← RIMOSSO
_buildDetailRow('Categoria', expense.type.label),
```

**Dopo**:
```dart
_buildDetailRow('Descrizione', expense.description),
_buildDetailRow('Importo', expense.formatAmount(expense.amount)),
_buildDetailRow('Categoria', expense.type.label),
```

---

### 2. Timeline View - Colore Importo Fisso

**File**: [lib/views/timeline_view.dart](../lib/views/timeline_view.dart)

**Modifiche**:
- **Riga 219**: Colore importo cambiato da `_getAmountColor(expense.moneyFlow)` a `Colors.blue`
- **Righe 288-301**: Rimossa funzione `_getAmountColor(MoneyFlow flow)`

---

### 3. Monthly View - Colore Importo Fisso

**File**: [lib/views/monthly_view.dart](../lib/views/monthly_view.dart)

**Modifiche**:
- **Riga 110**: Colore importo cambiato da `_getAmountColor(expense.moneyFlow)` a `Colors.blue`
- **Righe 163-176**: Rimossa funzione `_getAmountColor(MoneyFlow flow)`

---

### 4. Dashboard Data - DebtBalance Disabilitato

**File**: [lib/models/dashboard_data.dart](../lib/models/dashboard_data.dart)

**Modifiche**:
- **Righe 50-61**: Sostituita logica di calcolo debiti basata su MoneyFlow con placeholder

**Prima** (logica obsoleta):
```dart
factory DebtBalance.calculate(List<Expense> expenses) {
  double carlOwes = 0.0;
  double pitOwes = 0.0;

  for (var expense in expenses) {
    switch (expense.moneyFlow) {
      case MoneyFlow.carlToPit:
        pitOwes += expense.amount;
        break;
      case MoneyFlow.pitToCarl:
        carlOwes += expense.amount;
        break;
      // ... altri casi
    }
  }
  // ... calcolo netBalance
}
```

**Dopo** (placeholder):
```dart
factory DebtBalance.calculate(List<Expense> expenses) {
  // TODO: Reimplement using expense_splits from database
  // Old MoneyFlow-based calculation is obsolete
  // For now, return zero balance

  return DebtBalance(
    carlOwes: 0.0,
    pitOwes: 0.0,
    netBalance: 0.0,
    balanceLabel: "Calcolo debiti in manutenzione",
  );
}
```

**Nota**: Il calcolo dei debiti dovrebbe essere reimplementato usando `expense_splits` dal database, non in-memory da lista di Expenses.

---

### 5. Expense Form - MoneyFlow Non Più Popolato

**File**: [lib/models/expense_form.dart](../lib/models/expense_form.dart)

**Modifiche Precedenti** (già fatte in sessione bug fix):
- **Righe 256-260**: Rimosso campo MoneyFlow dalla UI (sia per spese personali che gruppo)
- **Righe 322, 342**: Sempre usato default `MoneyFlow.carlucci` invece di prendere valore dal form

**Stato Attuale**:
- `flowField` ancora presente nella classe `ExpenseForm` per backward compatibility
- **Non viene più mostrato** nella UI
- **Non viene più popolato** dall'utente
- Valore di default `MoneyFlow.carlucci` usato automaticamente per tutte le nuove spese

---

## 📊 Impatto

### File Modificati: 5

| File | Righe Rimosse | Righe Modificate | Descrizione |
|------|---------------|------------------|-------------|
| expense_list_item.dart | 15 | 1 | Rimosso "Flusso" da dettagli + funzione colore |
| timeline_view.dart | 14 | 1 | Colore fisso + rimossa funzione |
| monthly_view.dart | 14 | 1 | Colore fisso + rimossa funzione |
| dashboard_data.dart | 35 | 5 | DebtBalance placeholder |
| expense_form.dart | 5 | 2 | Campo non mostrato/popolato |
| **TOTALE** | **83** | **10** | |

---

## 🚫 Cosa È Stato Rimosso

### UI Elements
- ✅ Riga "Flusso: Carlucci" nel BottomSheet dettagli spesa
- ✅ Campo "Direzione del flusso" nel form creazione/modifica spesa
- ✅ Colori dinamici degli importi basati su MoneyFlow

### Codice
- ✅ 3× funzione `_getAmountColor(MoneyFlow flow)` (identica in 3 file diversi)
- ✅ Logica di calcolo debiti basata su switch su MoneyFlow

---

## 🔄 Cosa Rimane (Backward Compatibility)

### Nel Database
- ✅ Colonna `money_flow` nella tabella `expenses` (sempre popolata con default `carlucci`)
- ✅ Enum `MoneyFlow` in Dart (`expense.dart` e `expense_form.dart`)

**Perché**:
- Necessario per leggere vecchie spese migrate
- La migration popola questa colonna per compatibilità
- Rimozione completa richiederebbe migration database complessa

### Nel Codice
- ✅ `Expense.moneyFlow` field (marcato come legacy)
- ✅ `ExpenseForm.flowField` (non più usato in UI)
- ✅ Serializzazione/deserializzazione MoneyFlow in `Expense.toMap()` / `Expense.fromMap()`

**Sicuro da rimuovere in futuro**: Sì, dopo che tutte le spese sono state migrate e non ci sono più riferimenti nel DB.

---

## 🎯 Nuova Logica

### Come Funziona Ora

1. **Creazione Spesa**:
   - User compila form (senza campo MoneyFlow)
   - Sistema assegna automaticamente `moneyFlow = MoneyFlow.carlucci`
   - Spesa salvata con `group_id`, `paid_by`, `split_type`

2. **Divisione Spesa**:
   - Determinata da `split_type`: `equal`, `custom`, `lend`, `offer`
   - Splits creati in tabella `expense_splits`
   - Ogni split ha: `user_id`, `amount`, `is_paid`

3. **Visualizzazione**:
   - BottomSheet mostra: descrizione, importo, categoria, data
   - Se gruppo: mostra anche "Divisione Spesa" con lista splits
   - **Non mostra più** "Flusso"

4. **Calcolo Debiti**:
   - ~~Basato su MoneyFlow (OBSOLETO)~~
   - **TODO**: Implementare usando `expense_splits` query al database
   - Temporary: Mostra "Calcolo debiti in manutenzione"

---

## 🐛 Testing Checklist

### UI Testing
- [ ] Apri dettagli spesa (tap su lista) → NON deve mostrare riga "Flusso"
- [ ] Crea nuova spesa personale → form NON deve avere campo "Direzione del flusso"
- [ ] Crea nuova spesa gruppo → form NON deve avere campo "Direzione del flusso"
- [ ] Verifica colori importi: tutti blu (non più dinamici)

### Database Testing
- [ ] Crea nuova spesa → verifica `money_flow = 'carlucci'` nel DB
- [ ] Verifica vecchie spese migrate → hanno `split_type`, non usano più `money_flow`

### Feature Testing (Dopo Migration)
- [ ] Dashboard: "Calcolo debiti in manutenzione" visibile (temporaneo)
- [ ] Expense splits: funzionano correttamente per nuove spese gruppo
- [ ] Nessun crash o errore UI

---

## 🔮 Prossimi Passi (Opzionale)

### 1. Reimplementare Calcolo Debiti

**File**: `lib/models/dashboard_data.dart` → `DebtBalance.calculate()`

**Approccio**:
- Query `expense_splits` dal database
- Per ogni split con `is_paid = false`: somma `amount` per `user_id`
- Calcola net balance tra utenti

**Esempio**:
```dart
factory DebtBalance.calculate(List<ExpenseSplit> splits, String currentUserId, String otherUserId) {
  double currentUserOwes = 0.0;
  double otherUserOwes = 0.0;

  for (var split in splits) {
    if (!split.isPaid) {
      if (split.userId == currentUserId) {
        currentUserOwes += split.amount;
      } else if (split.userId == otherUserId) {
        otherUserOwes += split.amount;
      }
    }
  }

  final netBalance = currentUserOwes - otherUserOwes;
  // ... format label
}
```

**Nota**: Richiede di passare `ExpenseSplit[]` invece di `Expense[]`, quindi cambio firma metodo.

---

### 2. Rimuovere Completamente MoneyFlow (Long Term)

**Quando**: Dopo 6+ mesi dalla migration, quando sei sicuro che tutte le spese vecchie non servono più.

**Steps**:
1. Migration DB: `ALTER TABLE expenses DROP COLUMN money_flow;`
2. Rimuovi enum `MoneyFlow` da `expense_form.dart` e `expense.dart`
3. Rimuovi `flowField` da `ExpenseForm`
4. Rimuovi serializzazione `money_flow` in `Expense.toMap()` / `fromMap()`
5. Cleanup imports inutilizzati

**Stima**: 1-2 ore

---

## ✅ Completion Status

- [x] Rimosso "Flusso" dalla UI (BottomSheet dettagli)
- [x] Rimosso campo "Direzione del flusso" dal form
- [x] Colori importi fissi (non più dinamici)
- [x] DebtBalance disabilitato (temporaneo)
- [x] Nuove spese usano sempre default `MoneyFlow.carlucci`
- [x] Compilation check: ✅ 0 errors
- [ ] Manual UI testing (pending)
- [ ] Reimplementare DebtBalance con expense_splits (future work)

---

**Status**: ✅ CLEANUP COMPLETATO
**Next**: Testing manuale + (opzionale) reimplementare calcolo debiti con splits
