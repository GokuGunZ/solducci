# 📋 FASE 3D: Multi-User Expense Form - Piano di Implementazione

## 🎯 Obiettivo

Rendere l'Expense Form **context-aware** in modo che:
- **In contesto Personal**: Funziona come ora (nessun campo gruppo)
- **In contesto Group**: Mostra campi aggiuntivi per split tra membri

## 📊 Analisi Attuale

### Struttura ExpenseForm
Il form attuale ha:
- `descriptionField` (String)
- `moneyField` (double)
- `flowField` (MoneyFlow: entrata/uscita)
- `dateField` (DateTime)
- `typeField` (Tipologia: cibo, trasporto, etc.)

### Model Expense
```dart
class Expense {
  String id;
  String description;
  double amount;
  DateTime date;
  MoneyFlow moneyFlow;
  Tipologia type;
  String userId;  // Current user
}
```

## 🔄 Modifiche Necessarie

### 1. Model Expense - Aggiungere Campi Gruppo

```dart
class Expense {
  // ... campi esistenti ...

  // NEW: Multi-user fields
  String? groupId;           // null = personal expense
  String? paidBy;            // UUID of who paid (null = current user for personal)
  SplitType? splitType;      // equal, custom, full, none

  // Computed from expense_splits
  List<ExpenseSplit>? splits;
}

enum SplitType {
  equal,    // Diviso equamente tra tutti
  custom,   // Custom amount per persona
  full,     // Una persona paga tutto (no split)
  none,     // Nessuno split (spesa di gruppo ma non split)
}
```

### 2. Model ExpenseSplit (Nuovo)

```dart
class ExpenseSplit {
  String id;
  String expenseId;
  String userId;
  double amount;
  bool isPaid;
  DateTime createdAt;

  // Joined data
  String? userName;
  String? userEmail;
}
```

### 3. ExpenseForm - Aggiungere Campi Condizionali

```dart
class ExpenseForm {
  // ... campi esistenti ...

  // NEW: Only shown in group context
  final ExpenseField? paidByField;     // Dropdown membri
  final ExpenseField? splitTypeField;  // Dropdown split type
  final Map<String, double>? customSplits;  // Custom amounts per user

  factory ExpenseForm.forGroup({
    required String groupId,
    required List<GroupMember> members,
  }) {
    // Return form with group fields
  }
}
```

### 4. ExpenseService - Create/Update con Splits

```dart
class ExpenseService {
  Future<void> createExpense(Expense expense) async {
    // Insert expense
    final expenseId = await _supabase.from('expenses').insert(...);

    // If group expense with splits
    if (expense.groupId != null && expense.splitType != SplitType.full) {
      final splits = _calculateSplits(expense);
      await _supabase.from('expense_splits').insert(splits);
    }
  }

  List<Map<String, dynamic>> _calculateSplits(Expense expense) {
    switch (expense.splitType) {
      case SplitType.equal:
        // Divide equally
        final amountPerPerson = expense.amount / members.length;
        return members.map((m) => {
          'expense_id': expense.id,
          'user_id': m.userId,
          'amount': amountPerPerson,
          'is_paid': m.userId == expense.paidBy,
        }).toList();

      case SplitType.custom:
        // Use custom amounts
        return expense.customSplits!.entries.map((e) => {
          'expense_id': expense.id,
          'user_id': e.key,
          'amount': e.value,
          'is_paid': e.key == expense.paidBy,
        }).toList();

      // ... other cases
    }
  }
}
```

## 🎨 UI Changes

### ExpenseForm UI (in group context)

```
┌─────────────────────────────────┐
│  Nuova Spesa (👥 Gruppo)   [X]  │
├─────────────────────────────────┤
│                                 │
│  Descrizione *                  │
│  [____________________]         │
│                                 │
│  Importo *                      │
│  [____________________] €       │
│                                 │
│  Data                           │
│  [____________________] 📅      │
│                                 │
│  Tipologia                      │
│  [____________________] ▼       │
│                                 │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
│  SPLIT TRA MEMBRI               │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
│                                 │
│  Chi ha pagato? *               │
│  [____________________] ▼       │
│  • Tu                           │
│  • Alice                        │
│  • Bob                          │
│                                 │
│  Come dividere?                 │
│  ○ Equamente tra tutti          │
│  ○ Importi custom              │
│  ● Una persona paga tutto       │
│  ○ Non dividere                 │
│                                 │
│  [if splitType == custom]       │
│  ┌──────────────────────────┐  │
│  │ Tu:     [______] € ✓     │  │
│  │ Alice:  [______] €       │  │
│  │ Bob:    [______] €       │  │
│  │                          │  │
│  │ Totale: 45.00 / 50.00 € │  │
│  └──────────────────────────┘  │
│                                 │
│  [Salva Spesa]                  │
│  [Annulla]                      │
└─────────────────────────────────┘
```

### ExpenseListItem UI Update

**Personal Expense**:
```
┌─────────────────────────────────┐
│ 🍕 Pizza                  25.00€ │
│ Cibo • 12 Gen 2025              │
└─────────────────────────────────┘
```

**Group Expense - Paid by You**:
```
┌─────────────────────────────────┐
│ 🍕 Pizza                  50.00€ │
│ 👥 Gruppo • Cibo                │
│ 💰 Hai pagato tu                │
│ ↗️  +37.50€ da recuperare        │
└─────────────────────────────────┘
```

**Group Expense - Paid by Other**:
```
┌─────────────────────────────────┐
│ 🍕 Pizza                  50.00€ │
│ 👥 Gruppo • Cibo                │
│ 💰 Pagato da Alice              │
│ ↙️  -12.50€ devi ad Alice        │
└─────────────────────────────────┘
```

## 📁 File da Creare/Modificare

### Creare
1. `lib/models/expense_split.dart` - Model per splits
2. `lib/models/split_type.dart` - Enum split types
3. `lib/widgets/group_expense_fields.dart` - UI campi gruppo
4. `lib/widgets/custom_split_editor.dart` - UI custom amounts

### Modificare
1. `lib/models/expense.dart` - Add group fields
2. `lib/models/expense_form.dart` - Add group form fields
3. `lib/service/expense_service.dart` - Handle splits CRUD
4. `lib/widgets/expense_list_item.dart` - Show "Paid by" info
5. `lib/views/expense_list.dart` - Filter by group context

## 🔄 Implementation Steps

### Step 1: Models
- [x] Analizzare struttura attuale
- [ ] Creare `split_type.dart`
- [ ] Creare `expense_split.dart`
- [ ] Aggiornare `expense.dart` con campi gruppo
- [ ] Aggiornare `expense_form.dart` con factory per gruppo

### Step 2: Service Layer
- [ ] Aggiornare `expense_service.createExpense()` per gestire splits
- [ ] Aggiungere `_calculateSplits()` helper
- [ ] Aggiungere `getExpenseSplits(expenseId)` query
- [ ] Aggiornare `updateExpense()` per gestire splits
- [ ] Aggiornare `deleteExpense()` per cascade delete splits

### Step 3: UI - Form
- [ ] Creare widget `GroupExpenseFields`
- [ ] Dropdown "Chi ha pagato?" con membri gruppo
- [ ] Radio buttons per split type
- [ ] Creare widget `CustomSplitEditor`
- [ ] Validazione: sum(custom splits) == total amount
- [ ] Integrare in `ExpenseForm.showDialog()`

### Step 4: UI - List
- [ ] Aggiornare `ExpenseListItem` per mostrare info gruppo
- [ ] Badge "Hai pagato" vs "Pagato da {nome}"
- [ ] Mostrare amount owed/to collect
- [ ] Icona gruppo vs personal

### Step 5: Context Integration
- [ ] ExpenseForm: Check `ContextManager.currentContext`
- [ ] If group → show group fields + load members
- [ ] If personal → hide group fields
- [ ] Auto-set `groupId` e `paidBy` based on context

### Step 6: Testing
- [ ] Test: Create personal expense (no changes)
- [ ] Test: Create group expense with equal split
- [ ] Test: Create group expense with custom split
- [ ] Test: Validation custom split amounts
- [ ] Test: ExpenseList shows correct "paid by" info
- [ ] Test: Filter expenses by group context

## 🗄️ Database Schema (Already Exists)

```sql
-- expenses table (add columns)
ALTER TABLE expenses
ADD COLUMN group_id UUID REFERENCES groups(id) ON DELETE CASCADE,
ADD COLUMN paid_by UUID REFERENCES profiles(id),
ADD COLUMN split_type TEXT CHECK (split_type IN ('equal', 'custom', 'full', 'none'));

-- expense_splits table (already exists)
CREATE TABLE expense_splits (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  expense_id UUID REFERENCES expenses(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id),
  amount DECIMAL(10, 2) NOT NULL,
  is_paid BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW()
);
```

## ✅ Acceptance Criteria

### Must Work
- [ ] Personal expenses continue to work as before
- [ ] Group context shows group-specific fields
- [ ] "Chi ha pagato?" dropdown populated with group members
- [ ] Split type selector works (4 options)
- [ ] Equal split calculates correctly
- [ ] Custom split UI allows per-person amounts
- [ ] Custom split validation (sum == total)
- [ ] Expense splits saved to DB
- [ ] ExpenseList shows "Pagato da" info
- [ ] ExpenseList shows debt amount (+/-)
- [ ] Context switch filters expenses correctly

### Nice to Have (Future)
- [ ] Debt summary in GroupDetailPage
- [ ] "Settle debt" button
- [ ] Notification when someone adds group expense
- [ ] Filter expenses: "Only mine" vs "All group"
- [ ] Export group expenses to CSV

## 🚀 Let's Start!

Iniziamo con **Step 1: Models**!
