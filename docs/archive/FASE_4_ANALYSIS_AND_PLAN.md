# 🔍 FASE 4: Analisi Problemi e Piano d'Azione

**Data**: 2025-01-12
**Status**: Analisi Completa ✅
**Target**: Miglioramenti UX e Funzionalità

---

## 📋 Problemi Identificati

### 1. ❌ Metodi di Condivisione Spesa Incompleti
**Richiesta**:
- Aggiungere "Presta": Chi paga deve ricevere tutto l'importo dagli altri utenti
- Rinominare "Non dividere" in "Offri"

**Stato Attuale**:
- SplitType ha 4 opzioni: `equal`, `custom`, `full`, `none`
- `full` = "Una persona paga tutto" (semanticamente simile a "Presta" ma logica diversa)
- `none` = "Non dividere" (da rinominare in "Offri")

**Problema**:
La differenza tra `full` e il nuovo "Presta" non è chiara. Analisi semantica:

**"Presta" vs "Full"**:
- **"Presta"** (loan/lend): Chi paga anticipa per tutti, si aspetta di essere rimborsato. Debiti = importo totale per ogni altro membro.
- **"Full"** (current): Una persona paga tutto, nessuno split creato nel DB. Non c'è tracking del debito.

**Soluzione**:
- `full` → rinominare in **"Presta"** + cambiare logica splits
- `none` → rinominare in **"Offri"**

---

### 2. ❌ Manca Funzionalità "Arrotonda" negli Importi Custom
**Richiesta**:
Negli "Importi Custom", aggiungere bottone-icona per arrotondare la cifra rimanente da pagare a un membro specifico.

**Esempio**:
- Totale: 9.50€
- Attuale: 7.00€ distribuiti
- Mancano: 2.50€
- Tap bottone "Arrotonda" → attribuisce 2.50€ al membro selezionato

**Stato Attuale**:
- `CustomSplitEditor` ha bottone "Dividi equamente" che distribuisce l'importo totale
- Non c'è funzione per attribuire il rimanente a un singolo membro

**Problema**:
L'utente deve calcolare manualmente il rimanente e inserirlo.

**Soluzione**:
Aggiungere bottone "+" accanto a ogni TextField per auto-completare il rimanente.

---

### 3. ⚠️ Campo "Flusso Denaro" Obsoleto (MoneyFlow)
**Richiesta**:
Nascondere "inserisci direzione del flusso" - completa migrazione al nuovo sistema di split.

**Stato Attuale**:
- `Expense` ha ancora campo `moneyFlow` (legacy)
- ExpenseForm mostra ancora il campo "Flusso"
- MoneyFlow enum: `carlToPit`, `pitToCarl`, `carlDiv2`, `pitDiv2`, `carlucci`, `pit`

**Problema**:
Il vecchio sistema `moneyFlow` è incompatibile con il nuovo sistema multi-user:
- MoneyFlow presuppone 2 utenti hardcoded ("carl", "pit")
- Nel sistema multi-user, i flussi sono gestiti tramite `paidBy` + `splits`

**Conflitto**:
- Spese personali: ancora usano MoneyFlow (es. "carlucci" = solo Carl)
- Spese gruppo: usano paidBy + splitType (nuovo sistema)

**Soluzione**:
- **Spese gruppo**: nascondere completamente MoneyFlow
- **Spese personali**: mantenere temporaneamente per retrocompatibilità, ma nascondere UI
- **Fallback**: settare MoneyFlow a un valore default per spese gruppo (es. `carlucci`)

---

### 4. 🐛 BUG CRITICO: Non si Vedono le Spese di Gruppo
**Richiesta**:
Sistemare visibilità spese gruppo.

**Analisi del Problema**:

#### A. Stream Filtering in ExpenseService (righe 86-115)

```dart
Stream<List<Expense>> get stream {
  final context = _contextManager.currentContext;
  final userId = _supabase.auth.currentUser?.id;

  if (context.isPersonal) {
    // Personal: filtra solo user_id = userId E group_id = NULL
    return _supabase
        .from('expenses')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)  // ← PROBLEMA: spese gruppo non hanno user_id!
        .map((data) {
          final filtered = data.where((row) => row['group_id'] == null).toList();
          return _parseExpenses(filtered);
        });
  } else {
    // Group: filtra solo group_id = contextGroupId
    return _supabase
        .from('expenses')
        .stream(primaryKey: ['id'])
        .eq('group_id', context.groupId!)
        .map(_parseExpenses);
  }
}
```

**PROBLEMA NEL CODICE GROUP**:
La query `.eq('group_id', context.groupId!)` dovrebbe funzionare, MA:

1. **Possibile causa**: `group_id` nel DB è NULL anche per spese di gruppo
   - Verifica: controllo se createExpense salva correttamente `groupId`

2. **Possibile causa**: RLS policies bloccano la query
   - Verifica: controllo policy su `expenses` table

3. **Possibile causa**: ContextManager non passa correttamente il groupId
   - Verifica: debug del valore `context.groupId`

#### B. Analisi createExpense (righe 20-84)

```dart
Future<void> createExpense(Expense newExpense) async {
  // Auto-set context fields
  final context = _contextManager.currentContext;
  if (context.isGroup && newExpense.groupId == null) {
    newExpense.groupId = context.groupId;  // ← Setta groupId
  }
  if (newExpense.userId == null && context.isPersonal) {
    newExpense.userId = _supabase.auth.currentUser?.id;
  }

  final dataToInsert = newExpense.toMap();
  // ... insert expense
}
```

**POTENZIALE PROBLEMA**:
- `newExpense.groupId = context.groupId` modifica l'oggetto MA `toMap()` potrebbe non includerlo se `groupId` è già stato settato a `null` prima.

**VERIFICA NECESSARIA**:
1. Debug: stampare `dataToInsert` prima di INSERT
2. Query DB: verificare che `group_id` sia effettivamente salvato
3. RLS: verificare policy su SELECT per expenses con group_id

#### C. Analisi RLS Policies (migration v3)

```sql
-- EXPENSES POLICIES
CREATE POLICY "Users can view all expenses"
  ON expenses FOR SELECT
  USING (true);  -- ← Permette tutto, quindi RLS non è il problema

CREATE POLICY "Users can create expenses"
  ON expenses FOR INSERT
  WITH CHECK (
    user_id = auth.uid()::text
    OR paid_by = auth.uid()  -- ← OK per spese gruppo
  );
```

**RLS è OK**: Policy permette SELECT senza restrizioni.

#### D. Root Cause Analysis

**IPOTESI PRINCIPALE**:
Il problema è nel modo in cui `Expense.toMap()` serializza i campi group.

```dart
Map<String, dynamic> toMap() {
  final map = {
    'description': description,
    'amount': amount,
    'money_flow': moneyFlow.name,
    'date': date.toIso8601String(),
    'type': type.name,
  };

  if (userId != null) {
    map['user_id'] = userId!;
  }

  // NEW: Multi-user fields
  if (groupId != null) {
    map['group_id'] = groupId!;  // ← Controllo
  }
  // ...
}
```

**POSSIBILE BUG**:
Se `groupId` è una stringa vuota `""` invece di `null`, il check `if (groupId != null)` passa MA il DB lo interpreta come NULL.

**TEST NECESSARI**:
1. Debug `groupId` valore prima di toMap()
2. Debug `map['group_id']` dopo toMap()
3. Debug result dopo INSERT per verificare che group_id sia nel DB

---

## 🎯 Piano d'Azione Dettagliato

### FASE 4A: Sistemazione SplitType (Presta + Offri)
**Priority**: Medium
**Complessità**: Low
**Tempo stimato**: 30 minuti

#### File da Modificare:
1. `lib/models/split_type.dart`
2. `lib/service/expense_service.dart` (logica _calculateSplits)
3. `lib/widgets/group_expense_fields.dart` (UI)

#### Azioni:
1. **Rinominare `none` → `offer`**:
   ```dart
   // split_type.dart
   enum SplitType {
     equal('equal', 'Equamente tra tutti', '...'),
     custom('custom', 'Importi custom', '...'),
     lend('lend', 'Presta', 'Chi paga anticipa per tutti e verrà rimborsato'),  // NEW
     offer('offer', 'Offri', 'Chi paga offre la spesa, nessun rimborso'),  // RENAMED from 'none'
   }
   ```

2. **Aggiornare icone**:
   ```dart
   String get icon {
     switch (this) {
       case SplitType.equal: return '⚖️';
       case SplitType.custom: return '✏️';
       case SplitType.lend: return '💸';  // NEW
       case SplitType.offer: return '🎁';  // CHANGED from 🚫
     }
   }
   ```

3. **Modificare logica _calculateSplits**:
   ```dart
   List<Map<String, dynamic>> _calculateSplits(...) {
     final splits = <Map<String, dynamic>>[];

     switch (expense.splitType) {
       case SplitType.equal:
         // ... logica esistente ...
         break;

       case SplitType.custom:
         // ... logica esistente ...
         break;

       case SplitType.lend:  // NEW
         // Chi paga anticipa per tutti gli altri
         final amountPerPerson = expense.amount / members.length;
         for (final member in members) {
           if (member.userId != expense.paidBy) {  // Solo altri membri
             splits.add({
               'expense_id': expenseId,
               'user_id': member.userId,
               'amount': amountPerPerson,
               'is_paid': false,  // Tutti devono pagare
             });
           }
         }
         break;

       case SplitType.offer:  // RENAMED from none
         // Nessuno split, chi paga offre
         break;
     }

     return splits;
   }
   ```

4. **Aggiornare createExpense per gestire lend**:
   ```dart
   if (newExpense.splitType != SplitType.offer) {  // Changed from none
     // Create splits
   }
   ```

5. **Migration SQL**: Aggiornare constraint
   ```sql
   ALTER TABLE expenses
   DROP CONSTRAINT IF EXISTS expenses_split_type_check;

   ALTER TABLE expenses
   ADD CONSTRAINT expenses_split_type_check
   CHECK (split_type IN ('equal', 'custom', 'lend', 'offer'));
   ```

---

### FASE 4B: Bottone "Arrotonda" in CustomSplitEditor
**Priority**: Low
**Complessità**: Low
**Tempo stimato**: 20 minuti

#### File da Modificare:
1. `lib/widgets/custom_split_editor.dart`

#### Azioni:
1. **Aggiungere bottone "+" accanto a ogni TextField**:
   ```dart
   // Dentro il Row per ogni membro
   Row(
     children: [
       CircleAvatar(...),
       Expanded(child: Text(member.nickname)),
       SizedBox(
         width: 100,
         child: TextField(...),
       ),
       // NEW: Round-up button
       IconButton(
         icon: Icon(Icons.add_circle, size: 20),
         tooltip: 'Arrotonda qui',
         onPressed: () => _roundUpToMember(member.userId),
         padding: EdgeInsets.zero,
         constraints: BoxConstraints(minWidth: 32, minHeight: 32),
       ),
     ],
   )
   ```

2. **Implementare metodo _roundUpToMember**:
   ```dart
   void _roundUpToMember(String userId) {
     final remaining = widget.totalAmount - _currentTotal;

     if (remaining <= 0) {
       // Already complete or over, don't do anything
       return;
     }

     setState(() {
       final currentAmount = _splits[userId] ?? 0.0;
       final newAmount = currentAmount + remaining;
       _splits[userId] = double.parse(newAmount.toStringAsFixed(2));
       _controllers[userId]!.text = _splits[userId]!.toStringAsFixed(2);
     });

     widget.onSplitsChanged(_splits);
   }
   ```

3. **Aggiungere tooltip/feedback**:
   ```dart
   // Opzionale: mostrare SnackBar quando si arrotonda
   ScaffoldMessenger.of(context).showSnackBar(
     SnackBar(
       content: Text('Aggiunti ${remaining.toStringAsFixed(2)}€ a ${member.nickname}'),
       duration: Duration(seconds: 1),
     ),
   );
   ```

---

### FASE 4C: Nascondere MoneyFlow per Spese Gruppo
**Priority**: High
**Complessità**: Low
**Tempo stimato**: 15 minuti

#### File da Modificare:
1. `lib/models/expense_form.dart`

#### Azioni:
1. **Trovare campo MoneyFlow in ExpenseForm**:
   - Cerca `moneyFlowField` o simile

2. **Nascondere condizionalmente**:
   ```dart
   // In getExpenseView() o _ExpenseFormWidget.build()
   if (!widget.isGroupContext) {  // Solo per spese personali
     FieldWidget(expenseField: expenseForm.moneyFlowField),
   }
   ```

3. **Settare valore default per spese gruppo**:
   ```dart
   // In Expense.toMap() o createExpense
   if (groupId != null && moneyFlow == null) {
     map['money_flow'] = 'carlucci';  // Valore default neutro
   }
   ```

4. **Documentare deprecazione**:
   ```dart
   /// MoneyFlow - DEPRECATED for group expenses
   /// Only used for personal expenses (backward compatibility)
   /// For group expenses, use paidBy + splitType instead
   MoneyFlow moneyFlow;
   ```

---

### FASE 4D: FIX CRITICO - Visibilità Spese Gruppo
**Priority**: CRITICAL 🔥
**Complessità**: Medium-High
**Tempo stimato**: 45-60 minuti

#### Step 1: Diagnosi (15 min)

**Test 1: Verifica DB dopo INSERT**
```dart
// In createExpense, dopo insert
final result = await _supabase
    .from('expenses')
    .insert(dataToInsert)
    .select()
    .single();

print('🔍 INSERTED ROW: $result');
print('🔍 group_id in DB: ${result['group_id']}');
```

**Test 2: Verifica Stream Query**
```dart
// In stream getter, context isGroup
print('🔍 Querying expenses with group_id: ${context.groupId}');

return _supabase
    .from('expenses')
    .stream(primaryKey: ['id'])
    .eq('group_id', context.groupId!)
    .map((data) {
      print('🔍 STREAM RETURNED ${data.length} rows');
      data.forEach((row) => print('  - ID: ${row['id']}, group_id: ${row['group_id']}'));
      return _parseExpenses(data);
    });
```

**Test 3: Verifica ContextManager**
```dart
// In switchToGroup
print('🔍 Context switched to group: ${group.name} (ID: ${group.id})');
print('🔍 currentContext.groupId: $_currentContext.groupId');
```

#### Step 2: Possibili Fix

**Fix A: Problema nel Filtering**
Se stream non ritorna dati ma il DB è corretto:

```dart
// Alternativa: usa OR invece di eq
Stream<List<Expense>> get stream {
  if (context.isPersonal) {
    return _supabase
        .from('expenses')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .isFilter('group_id', null)  // Explicit NULL check
        .map(_parseExpenses);
  } else {
    return _supabase
        .from('expenses')
        .stream(primaryKey: ['id'])
        .eq('group_id', context.groupId!)
        .map(_parseExpenses);
  }
}
```

**Fix B: Problema nell'INSERT**
Se group_id non viene salvato:

```dart
// In createExpense, forzare groupId prima di toMap
Future<void> createExpense(Expense newExpense) async {
  final context = _contextManager.currentContext;

  // EXPLICIT SET (not just if null)
  if (context.isGroup) {
    newExpense.groupId = context.groupId;
    print('🔍 Setting groupId: ${newExpense.groupId}');
  } else {
    newExpense.userId = _supabase.auth.currentUser?.id;
  }

  final dataToInsert = newExpense.toMap();
  print('🔍 Data to insert: $dataToInsert');

  // ... rest of code
}
```

**Fix C: Problema in Expense.toMap()**
Se serializzazione fallisce:

```dart
Map<String, dynamic> toMap() {
  final map = {
    'description': description,
    'amount': amount,
    'money_flow': moneyFlow.name,
    'date': date.toIso8601String(),
    'type': type.name,
  };

  // ALWAYS include these (even if null) to be explicit
  map['user_id'] = userId;
  map['group_id'] = groupId;
  map['paid_by'] = paidBy;

  if (splitType != null) {
    map['split_type'] = splitType!.value;
  }
  if (splitData != null) {
    map['split_data'] = splitData as Object;
  }

  if (id > 0) {
    map['id'] = id;
  }

  return map;
}
```

**Fix D: Stream non aggiorna automaticamente**
Se stream non si aggiorna dopo INSERT:

```dart
// Dopo createExpense, forza refresh dello stream
await createExpense(newExpense);
_contextManager.notifyListeners();  // Trigger rebuild
```

#### Step 3: Testing (15 min)

1. **Test manuale**:
   - Switch a gruppo
   - Crea spesa
   - Verifica console log
   - Verifica DB in Supabase Dashboard
   - Verifica lista spese si aggiorna

2. **Test SQL diretto**:
   ```sql
   -- Nel Supabase SQL Editor
   SELECT id, description, amount, user_id, group_id, paid_by, split_type
   FROM expenses
   WHERE group_id IS NOT NULL
   ORDER BY created_at DESC
   LIMIT 10;
   ```

3. **Test con debug app**:
   ```dart
   // In expense_list.dart
   StreamBuilder<List<Expense>>(
     stream: expenseService.stream,
     builder: (context, snapshot) {
       print('🔍 STREAM STATE: ${snapshot.connectionState}');
       print('🔍 HAS ERROR: ${snapshot.hasError}');
       if (snapshot.hasError) {
         print('🔍 ERROR: ${snapshot.error}');
         print('🔍 STACKTRACE: ${snapshot.stackTrace}');
       }
       print('🔍 HAS DATA: ${snapshot.hasData}');
       if (snapshot.hasData) {
         print('🔍 EXPENSES COUNT: ${snapshot.data!.length}');
       }
       // ... rest of builder
     }
   )
   ```

---

## 📊 Priorità di Implementazione

### 🔥 CRITICAL (Fare Subito)
1. **FASE 4D**: Fix visibilità spese gruppo
   - **Motivo**: Blocca completamente l'uso del sistema multi-user
   - **Impact**: ALTO - feature non funziona
   - **Effort**: 45-60 min

### 🟠 HIGH (Fare Presto)
2. **FASE 4C**: Nascondere MoneyFlow per spese gruppo
   - **Motivo**: Confonde l'utente, campo obsoleto
   - **Impact**: MEDIO - UX migliorata
   - **Effort**: 15 min

### 🟡 MEDIUM (Fare Dopo)
3. **FASE 4A**: Sistemazione SplitType (Presta + Offri)
   - **Motivo**: Migliora semantica e completezza feature
   - **Impact**: MEDIO - più opzioni per l'utente
   - **Effort**: 30 min

### 🟢 LOW (Nice to Have)
4. **FASE 4B**: Bottone "Arrotonda" in CustomSplitEditor
   - **Motivo**: UX improvement per edge case
   - **Impact**: BASSO - convenienza
   - **Effort**: 20 min

---

## 🧪 Piano di Testing

### Test 1: Spese Gruppo Visibili ✓
- [ ] Crea gruppo
- [ ] Switch a gruppo
- [ ] Crea spesa con split equal
- [ ] Verifica spesa appare nella lista
- [ ] Verifica badge "👥 Gruppo"
- [ ] Verifica "Hai pagato tu"
- [ ] Verifica debt indicator

### Test 2: Split Type "Presta" ✓
- [ ] Crea spesa gruppo con split "Presta"
- [ ] Verifica splits creati nel DB
- [ ] Verifica solo altri membri hanno debito
- [ ] Verifica chi paga non ha split
- [ ] Verifica balance calculation corretta

### Test 3: Split Type "Offri" ✓
- [ ] Crea spesa gruppo con split "Offri"
- [ ] Verifica NO splits creati nel DB
- [ ] Verifica spesa appare senza debt indicator
- [ ] Verifica nessun debito per nessuno

### Test 4: Bottone Arrotonda ✓
- [ ] Crea spesa 10€
- [ ] Split custom: membro1=3€, membro2=4€
- [ ] Tap "+" su membro1
- [ ] Verifica membro1 ora ha 6€ (3+3 rimanente)
- [ ] Verifica totale diventa 10€ (valido)

### Test 5: MoneyFlow Nascosto ✓
- [ ] Switch a gruppo
- [ ] Tap "Nuova Spesa"
- [ ] Verifica campo "Flusso" NON appare
- [ ] Switch a personale
- [ ] Tap "Nuova Spesa"
- [ ] Verifica campo "Flusso" appare (legacy)

---

## 📝 Checklist Implementazione

### Pre-Implementation
- [x] Analisi completa dei problemi
- [x] Identificazione root cause
- [x] Stesura piano d'azione
- [x] Definizione priorità
- [ ] Review piano con utente

### Implementation Order
1. [ ] FASE 4D - Fix visibilità (CRITICAL)
2. [ ] FASE 4C - Nascondere MoneyFlow (HIGH)
3. [ ] FASE 4A - Presta + Offri (MEDIUM)
4. [ ] FASE 4B - Arrotonda (LOW)

### Post-Implementation
- [ ] Testing completo
- [ ] Update documentazione
- [ ] Commit con messaggio descrittivo
- [ ] Deploy se necessario

---

## 🎯 Obiettivi di Successo

### Must Have (Requisiti Minimi)
- ✅ Spese gruppo visibili nella lista
- ✅ MoneyFlow nascosto per spese gruppo
- ✅ Split type "Presta" funzionante
- ✅ Split type "Offri" (renamed from none)

### Should Have (Desiderabili)
- ✅ Bottone arrotonda in custom split
- ✅ Debug logging per troubleshooting
- ✅ Error handling robusto

### Nice to Have (Opzionali)
- ⬜ Animazioni per cambio split type
- ⬜ Tooltip esplicativi per ogni split type
- ⬜ Preview del balance prima di salvare

---

## 📚 Note Tecniche

### Architettura Attuale
```
User Action
  ↓
ExpenseForm (UI)
  ↓
ContextManager (determina context)
  ↓
ExpenseService.createExpense()
  ↓
  ├─> Insert expense in DB
  └─> Create splits (if needed)
      ↓
  ↓
ExpenseService.stream (filtered by context)
  ↓
ExpenseList (displays)
```

### Punti Critici
1. **Context Switching**: ContextManager notifyListeners() deve triggerare rebuild
2. **Stream Filtering**: Query Supabase deve filtrare correttamente
3. **Data Serialization**: toMap() deve includere tutti i campi necessari
4. **RLS Policies**: Non devono bloccare query valide

### Possibili Regressioni
- ⚠️ Cambiare SplitType enum potrebbe rompere dati esistenti nel DB
- ⚠️ Nascondere MoneyFlow potrebbe causare validazione errors
- ⚠️ Modificare logica splits potrebbe creare inconsistenze

### Mitigazioni
- ✅ Migration SQL per aggiornare constraint
- ✅ Fallback values per campi legacy
- ✅ Debug logging estensivo
- ✅ Testing manuale completo prima di deploy

---

## 🔄 Iterazioni Future (Post FASE 4)

### FASE 5: Gestione Debiti
- View "Chi deve a chi"
- Bottone "Salda debito"
- Storico pagamenti
- Notifiche debiti

### FASE 6: Analytics
- Statistiche spese gruppo
- Grafici per categoria
- Trend temporali
- Export CSV/PDF

### FASE 7: Social Features
- Chat gruppo
- Commenti su spese
- Reazioni
- Notifiche push

---

**Fine Analisi** ✅
**Prossimo Step**: Iniziare con FASE 4D (Fix Critico Visibilità)
