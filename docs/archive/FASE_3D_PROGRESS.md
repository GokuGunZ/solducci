# 📊 FASE 3D: Multi-User Expense Form - Progress Report

## ✅ Completato Finora

### 1. Models ✅

#### [split_type.dart](../lib/models/split_type.dart) - Creato
Enum ricco per i tipi di split:
- `equal` - Diviso equamente tra tutti
- `custom` - Importi custom per persona
- `full` - Una persona paga tutto
- `none` - Non dividere

**Features**:
- Label e description per UI
- Icon emoji per ogni tipo
- `fromValue()` per deserializzazione DB
- Ready per uso in dropdown/radio buttons

```dart
enum SplitType {
  equal('equal', 'Equamente tra tutti', 'Dividi l\'importo...'),
  custom('custom', 'Importi custom', 'Specifica quanto...'),
  full('full', 'Una persona paga tutto', 'Un solo membro...'),
  none('none', 'Non dividere', 'Spesa di gruppo...');

  String get icon => '⚖️' | '✏️' | '💰' | '🚫';
}
```

#### [expense_split.dart](../lib/models/expense_split.dart) - Creato
Model per rappresentare un singolo split:

```dart
class ExpenseSplit {
  final String id;
  final String expenseId;
  final String userId;
  final double amount;
  final bool isPaid;
  final DateTime createdAt;

  // Joined data
  final String? userName;
  final String? userEmail;
  final String? userAvatarUrl;

  String get userInitials; // Helper per avatar
}
```

**Features**:
- `fromMap()` per Supabase
- `toMap()` per insert/update
- `copyWith()` per immutability
- Helper `userInitials` per UI

#### [expense.dart](../lib/models/expense.dart) - Aggiornato
Rimosso vecchio enum `SplitType` duplicato e aggiunto import del nuovo:

```dart
import 'package:solducci/models/split_type.dart';

class Expense {
  // ... campi esistenti ...

  // Campi multi-user (già presenti, solo pulizia import)
  String? groupId;
  String? paidBy;
  SplitType? splitType;
  Map<String, double>? splitData;

  bool get isPersonal => groupId == null;
  bool get isGroup => groupId != null;
}
```

### 2. UI Widgets ✅

#### [group_expense_fields.dart](../lib/widgets/group_expense_fields.dart) - Creato (222 righe)
Widget per campi gruppo nell'expense form:

**Features**:
- ✅ Divider con titolo "SPLIT TRA MEMBRI"
- ✅ Dropdown "Chi ha pagato?" con lista membri
- ✅ Avatar e nome per ogni membro
- ✅ Badge "Admin" per admin
- ✅ Validazione required per paidBy
- ✅ Radio buttons per SplitType con icon + descrizione
- ✅ Callbacks `onPaidByChanged` e `onSplitTypeChanged`
- ✅ State management interno + propagazione parent

**UI Preview**:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━
SPLIT TRA MEMBRI
━━━━━━━━━━━━━━━━━━━━━━━━━━━

Chi ha pagato? *
[👤 Tu                    ▼]
[👤 Alice                 ▼]
[👤 Bob           [Admin] ▼]

Come dividere?
○ ⚖️ Equamente tra tutti
  Dividi l'importo equamente...
○ ✏️ Importi custom
  Specifica quanto deve pagare...
● 💰 Una persona paga tutto
  Un solo membro paga l'intera...
○ 🚫 Non dividere
  Spesa di gruppo ma non divisa...
```

#### [custom_split_editor.dart](../lib/widgets/custom_split_editor.dart) - Creato (233 righe)
Widget per editare importi custom per membro:

**Features**:
- ✅ Lista membri con avatar + nome
- ✅ TextField amount per ogni membro (max 2 decimali)
- ✅ Bottone "Dividi equamente" (calcolo automatico)
- ✅ Validazione real-time: sum == totalAmount
- ✅ Indicatore visuale: verde (OK) / rosso (errore)
- ✅ Messaggio errore: "Mancano X€" o "Supera X€"
- ✅ Callback `onSplitsChanged` con Map<userId, amount>
- ✅ Border color cambia: blu → verde quando valid

**UI Preview**:
```
┌────────────────────────────────────┐
│ Importi per membro  [≡ Dividi eq.] │
├────────────────────────────────────┤
│                                    │
│ [👤] Tu         [____25.00___] €  │
│ [👤] Alice      [____12.50___] €  │
│ [👤] Bob        [____12.50___] €  │
│                                    │
│ ──────────────────────────────────│
│ ✅ Totale: 50.00 / 50.00 €        │
└────────────────────────────────────┘

// Se invalid:
┌────────────────────────────────────┐
│ ⚠️ Totale: 45.00 / 50.00 €        │
│ ⚠️ Mancano 5.00€                   │
└────────────────────────────────────┘
```

## 📝 Bug Fix

### Pending Invites - Enhanced Logging
Aggiunto debug logging estensivo a `PendingInvitesPage._acceptInvite()`:

```dart
debugPrint('🔄 Accepting invite: ${invite.id}');
debugPrint('   Group: ${invite.groupName} (${invite.groupId})');
// ... dopo accept
debugPrint('✅ Invite accepted successfully');
debugPrint('🔄 Reloading ContextManager...');
debugPrint('✅ ContextManager reloaded');
debugPrint('🗑️ Removing invite from local list...');
debugPrint('✅ Invite removed from list. Remaining: ${_invites.length}');
```

Questo aiuterà a debuggare il problema degli inviti che non scompaiono dopo accept/reject.

## ⏳ Prossimi Step

### 3. ExpenseService - Handle Splits (TODO)

**Task**: Aggiornare `expense_service.dart` per gestire splits:

```dart
class ExpenseService {
  // Modificare createExpense()
  Future<void> createExpense(Expense expense) async {
    // 1. Insert expense in DB
    final result = await _supabase.from('expenses').insert(...).select().single();
    final expenseId = result['id'];

    // 2. If group expense with splits, create splits
    if (expense.groupId != null && expense.splitType != SplitType.full) {
      final splits = _calculateSplits(expense, members);
      await _supabase.from('expense_splits').insert(splits);
    }
  }

  List<Map<String, dynamic>> _calculateSplits(
    Expense expense,
    List<GroupMember> members,
  ) {
    switch (expense.splitType) {
      case SplitType.equal:
        final amountPerPerson = expense.amount / members.length;
        return members.map((m) => {
          'expense_id': expense.id,
          'user_id': m.userId,
          'amount': amountPerPerson,
          'is_paid': m.userId == expense.paidBy,
        }).toList();

      case SplitType.custom:
        return expense.splitData!.entries.map((e) => {
          'expense_id': expense.id,
          'user_id': e.key,
          'amount': e.value,
          'is_paid': e.key == expense.paidBy,
        }).toList();

      case SplitType.none:
        return []; // No splits

      default:
        return [];
    }
  }

  // Aggiungere getExpenseSplits()
  Future<List<ExpenseSplit>> getExpenseSplits(String expenseId) async {
    final response = await _supabase
        .from('expense_splits')
        .select('*, profiles(nickname, email)')
        .eq('expense_id', expenseId);

    return (response as List)
        .map((map) => ExpenseSplit.fromMap(map))
        .toList();
  }
}
```

### 4. ExpenseForm Integration (TODO)

**Task**: Integrare widgets gruppo in `expense_form.dart`:

**Checklist**:
- [ ] Importare `ContextManager` per check contesto
- [ ] Importare `GroupService` per caricare membri
- [ ] Aggiungere campi `paidBy` e `splitType` al form state
- [ ] Condizionalmente mostrare `GroupExpenseFields` se in gruppo
- [ ] Se `splitType == custom`, mostrare `CustomSplitEditor`
- [ ] Validazione: custom splits devono sommare a total
- [ ] Salvare `groupId`, `paidBy`, `splitType`, `splitData` in Expense
- [ ] Passare dati a `ExpenseService.createExpense()`

**Pseudo-code**:
```dart
class ExpenseFormDialog extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    final currentContext = ContextManager().currentContext;
    final isGroupContext = currentContext.isGroup;

    // Load group members if in group
    List<GroupMember> members = [];
    if (isGroupContext) {
      members = await GroupService().getGroupMembers(currentContext.groupId!);
    }

    return Form(
      child: ListView(
        children: [
          // Existing fields: description, amount, date, type

          // NEW: Show group fields if in group context
          if (isGroupContext) ...[
            GroupExpenseFields(
              members: members,
              onPaidByChanged: (userId) => setState(() => _paidBy = userId),
              onSplitTypeChanged: (type) => setState(() => _splitType = type),
            ),

            // Show custom split editor if custom split selected
            if (_splitType == SplitType.custom)
              CustomSplitEditor(
                members: members,
                totalAmount: _amount,
                onSplitsChanged: (splits) => setState(() => _customSplits = splits),
              ),
          ],

          // Save button
          ElevatedButton(
            onPressed: _saveExpense,
            child: Text('Salva Spesa'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveExpense() async {
    final expense = Expense(
      // ... existing fields ...
      groupId: currentContext.isGroup ? currentContext.groupId : null,
      paidBy: _paidBy,
      splitType: _splitType,
      splitData: _splitType == SplitType.custom ? _customSplits : null,
    );

    await ExpenseService().createExpense(expense);
  }
}
```

### 5. ExpenseListItem UI Update (TODO)

**Task**: Mostrare info gruppo in lista spese:

**Features da aggiungere**:
- Badge "👥 Gruppo" se `expense.isGroup`
- "Pagato da: {nome}" invece di solo importo
- Indicatore debito:
  - Se `paidBy == currentUser`: `↗️ +X€ da recuperare` (verde)
  - Se `paidBy != currentUser`: `↙️ -X€ devi a {nome}` (rosso)

**Pseudo-code**:
```dart
class ExpenseListItem extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Row(
        children: [
          Text(expense.description),
          if (expense.isGroup)
            Container(
              margin: EdgeInsets.only(left: 8),
              child: Text('👥', style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type + Date
          Text('${expense.type.label} • ${formatDate(expense.date)}'),

          // Group info
          if (expense.isGroup) ...[
            if (expense.paidBy == currentUserId)
              Text(
                '💰 Hai pagato tu',
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
              )
            else
              Text(
                '💰 Pagato da ${paidByName}',
                style: TextStyle(color: Colors.blue),
              ),

            // Debt indicator
            if (expense.paidBy == currentUserId)
              Text(
                '↗️ +${debtAmount.toStringAsFixed(2)}€ da recuperare',
                style: TextStyle(color: Colors.green, fontSize: 12),
              )
            else
              Text(
                '↙️ -${owedAmount.toStringAsFixed(2)}€ devi a ${paidByName}',
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
          ],
        ],
      ),
      trailing: Text(
        '${expense.amount.toStringAsFixed(2)} €',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}
```

## 🗄️ Database Schema

Le tabelle esistono già nel DB:

```sql
-- expenses table
ALTER TABLE expenses
ADD COLUMN group_id UUID REFERENCES groups(id),
ADD COLUMN paid_by UUID REFERENCES profiles(id),
ADD COLUMN split_type TEXT,
ADD COLUMN split_data JSONB;

-- expense_splits table
CREATE TABLE expense_splits (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  expense_id INT REFERENCES expenses(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id),
  amount DECIMAL(10, 2) NOT NULL,
  is_paid BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Index for performance
CREATE INDEX idx_expense_splits_expense_id ON expense_splits(expense_id);
CREATE INDEX idx_expense_splits_user_id ON expense_splits(user_id);
```

## 📊 Progress Summary

### ✅ Completato (50%)
- [x] Models: SplitType enum
- [x] Models: ExpenseSplit class
- [x] Models: Expense updated
- [x] UI: GroupExpenseFields widget
- [x] UI: CustomSplitEditor widget
- [x] Bug: Enhanced logging for invites

### ⏳ In Progress (0%)
- [ ] ExpenseService: Handle splits CRUD
- [ ] ExpenseForm: Integrate group fields
- [ ] ExpenseListItem: Show group info
- [ ] Testing: Create group expense
- [ ] Testing: Custom split validation

### 📅 Future (0%)
- [ ] GroupDetailPage: Show debts summary
- [ ] Settle debt feature
- [ ] Export group expenses
- [ ] Notifications for new group expenses

## 🎯 Next Session Goals

1. **ExpenseService**: Implementare `_calculateSplits()` e update `createExpense()`
2. **ExpenseForm**: Aggiungere check contesto + mostrare campi gruppo
3. **Test**: Creare una spesa di gruppo con split equal
4. **Test**: Creare una spesa con split custom e validazione

## 💡 Notes

### Design Decisions

1. **SplitType enum separato**: Più ricco del precedente, con labels/descriptions per UI
2. **ExpenseSplit model**: Separato da Expense per normalizzazione DB
3. **GroupExpenseFields stateful**: Gestisce proprio state ma propaga changes al parent
4. **CustomSplitEditor validazione real-time**: UX migliore, user vede subito errori
5. **Expense.splitData Map**: Backup per custom splits, usato solo se splitType=custom

### Potential Issues

⚠️ **Invites bug non risolto**: Gli inviti potrebbero non scomparire dopo accept/reject. Il logging aiuterà a debuggare.

⚠️ **Expense ID type**: Attualmente `int`, ma `expense_splits` referenzia UUID. Potrebbe servire migrazione.

⚠️ **Float precision**: Splits potrebbero non sommare esattamente (es: 10/3 = 3.33+3.33+3.34). Serve rounding logic.

## 🚀 Ready to Continue!

Quando riprendi:
1. Guarda `docs/FASE_3D_PLAN.md` per overview completa
2. Inizia con `expense_service.dart` (step 3)
3. Poi integra in `expense_form.dart` (step 4)
4. Infine aggiorna `expense_list_item.dart` (step 5)

Buon lavoro! 💪
