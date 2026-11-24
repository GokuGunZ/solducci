# 02 — REPOSITORY REALITY & AUDIT FINDINGS

**Run ID:** `run_20261124_194300_audit_debt_credit_calculation_chain`  
**Git Branch:** `test`  
**Git HEAD SHA:** `47c2544ab35105d6601cd29d5470719348b71d7a`  
**Operating System:** Windows  
**Engine Base:** `C:\AI\DevelopmentEngine` (v1.0 active)  

---

## 1. Concrete Repository Inspection

The audit examined every module touching multi-user expenses, splits, and debt/credit balance calculation.

### A. Architectural Split: Service Dualism (`ExpenseService` vs `ExpenseServiceCached`)
There are two parallel implementations of expense management and split generation:
1. `lib/service/expense_service.dart`: The original service communicating directly with Supabase.
2. `lib/service/expense_service_cached.dart`: The cached singleton with local in-memory indices (`_splitsCache`, `_userBalanceCache`) and invalidation streams.

#### Critical Divergence in `_calculateSplits`:
- In `lib/service/expense_service.dart:343-377`:
  ```dart
  case SplitType.equal:
    if (expense.splitData != null && expense.splitData!.isNotEmpty) {
      // Correctly respects selective member subsets
      for (final entry in expense.splitData!.entries) {
        final userId = entry.key;
        final amount = entry.value;
        if (amount > 0) {
          splits.add({
            'expense_id': expenseId,
            'user_id': userId,
            'amount': amount,
            'is_paid': userId == expense.paidBy,
          });
        }
      }
    } else {
      // Divides by members.length
    }
  ```
- In `lib/service/expense_service_cached.dart:856-869`:
  ```dart
  case SplitType.equal:
    final amountPerPerson = expense.amount / members.length;
    final roundedAmount = double.parse(amountPerPerson.toStringAsFixed(2));

    for (final member in members) {
      splits.add({
        'expense_id': expenseId,
        'user_id': member.userId,
        'amount': roundedAmount,
        'is_paid': member.userId == expense.paidBy,
      });
    }
    break;
  ```
**Flaw:** In `ExpenseServiceCached`, `_calculateSplits` completely ignores `expense.splitData` for `SplitType.equal`! If a user in `UnifiedTransactionModal` deselects one member of a 3-person group, `_includedMemberIds` is 2, `splitData` contains 2 entries of `amount/2`, but `splitType` is `SplitType.equal`. When `ExpenseServiceCached.insert` or `update` runs, it recalculates splits dividing by `members.length` (3), generating splits for all 3 members and attributing only 33% per person instead of 50%, diluting the credit!

---

### B. Fatal Null-Safety Cast Crash in `calculateGroupBalance`
In `lib/service/expense_service.dart:532` and `lib/service/expense_service_cached.dart:560`:
```dart
final response = await _supabase
    .from('expense_splits')
    .select('''
      *,
      expenses!inner(group_id, paid_by)
    ''')
    .eq('expenses.group_id', groupId);

for (final splitData in response as List) {
  final split = ExpenseSplit.fromMap(splitData);
  final expense = splitData['expenses'] as Map<String, dynamic>;
  final paidBy = expense['paid_by'] as String; // <--- CRASH HERE IF NULL!
```
- **Observed Bug:** If even a single expense in the group has `paid_by == null` (which occurs in legacy data or expenses converted between contexts), `expense['paid_by'] as String` throws a runtime `TypeError` (`Null is not a subtype of type String in type cast`).
- The entire method is wrapped in `try ... catch (e) { return {}; }`.
- When an exception occurs, the function swallows it and returns `{}` (empty map).
- `DebtBalance.fromBalanceMap` and `BalancePillWidget` receive an empty map and set the balance to `0.00 €` ("Saldo in pareggio").
- **Impact on User:** Adding an expense that fails or causes a null field instantly causes their existing credit to drop to zero!
- **Contrast:** `calculateGroupBalanceMultiPerson` (line 630) contains the correct defensive code:
  `final paidBy = (expense['paid_by'] as String?) ?? (expense['user_id'] as String?);`

---

### C. Sign Convention Divergence Across Models
Three core models calculate or store net balance with contradictory sign semantics:

| Model / Widget | Field | Definition | Positive Meaning | Negative Meaning |
|---|---|---|---|---|
| `DebtBalance` (`lib/models/dashboard_data.dart:39,87,92`) | `netBalance` | `carlOwes - pitOwes` | **You owe (DEBT)** | **They owe you (CREDIT)** |
| `GroupedDebtBalance` (`lib/models/dashboard_data.dart:187`) | `netBalance` | `totalYouOwe - totalTheyOweYou` | **You owe (DEBT)** | **They owe you (CREDIT)** |
| `PeerDebtsWidget` (`lib/widgets/dashboard/widgets/peer_debts_widget.dart:334-342`) | `netTotal` | `sum(credits) - sum(debts)` | **They owe you (CREDIT)** | **You owe (DEBT)** |
| `PairwiseDebtBalance` (`lib/models/dashboard_data.dart:126,136-137`) | `amount` | Positive = they owe you | **They owe you (CREDIT)** | **You owe (DEBT)** |
| `BalancePillWidget` (`lib/widgets/dashboard/widgets/balance_pill_widget.dart:606`) | `balance` | Positive = green (+€X) | **They owe you (CREDIT)** | **You owe (DEBT)** |

**Cognitive & Programmatic Hazard:**  
In `DebtBalance`, when a user is owed 100€, `theyOwe = 100.0`, but `netBalance = -100.0`!  
If any widget, debug print, or consumer inspects `netBalance`, increasing credit makes `netBalance` become more negative (e.g. going from `-50` to `-100`), which appears as a decrease if read without knowing the inverted sign rule.

---

### D. Payer Attribution Ambiguity in UI Modals
In `lib/widgets/quick_add/unified_transaction_modal.dart:372`:
```dart
paidBy: isGroup ? (_selectedPayerId ?? currentUserId) : null,
```
- In the UI (line 980-990), group members are displayed horizontally with avatar chips.
- Tapping an avatar selects that member as `_selectedPayerId`.
- **User Mental Model vs System State:** If a user enters an expense and taps the other person's avatar thinking "I'm entering the expense for [Other Person]", the system assigns `paidBy = otherPerson`.
- When `paidBy = otherPerson` and split is 50/50, the math dictates:
  `balances[otherPerson] -= expense.amount / 2;`
- **Result:** Instead of gaining credit, the user is recorded as owing the other person half the amount, decreasing their net balance!

---

### E. Wallet Liquidity vs Peer Credit Decoupling
In `lib/service/wallet_service.dart:209`:
```dart
final walletExpenses = expenses.where((e) => e.walletId == wallet.id);
for (final exp in walletExpenses) {
  balance -= exp.amount;
}
```
- When a user pays 100€ for a group dinner:
  1. Cash in wallet decreases by `100.00 €`.
  2. Peer credit increases by `50.00 €`.
- Users viewing the top-level liquidity cards on the dashboard see their primary balance drop by 100€, which can easily be conflated with the peer balance if the context pill is in personal or view mode.

---

### F. Testing Reality
- Current `test/` suite has 0 unit tests validating `calculateGroupBalanceMultiPerson`, `_calculateSplits`, or `PairwiseDebtBalance`.
- Existing tests cover LifeOS, Markdown, CSV import, and in-memory tasks, leaving the core economy debt/credit accounting chain completely unverified by CI.
