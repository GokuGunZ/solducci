# 04 — DOMAIN AND DATA MODEL SPECIFICATION

**Run ID:** `run_20261124_195200_economy_tab_group_redesign_and_expense_fixes`  
**Domain Layer:** Accounting, Context Separation, Multi-Party Balances, Filters  

---

## 1. Domain Entities & Invariants

### 1.1 Expense Model Invariants (`lib/models/expense.dart`)

```dart
class Expense {
  final int id;
  final String description;
  final double amount;
  final DateTime date;
  final Tipologia type;
  String? userId;                  // Invariant: MUST NEVER BE NULL on insert! Records auth.uid()
  String? groupId;                 // Null for personal, UUID for group
  String? paidBy;                  // UUID of the group member who actually paid
  SplitType? splitType;            // equal, custom, lend, offer
  Map<String, double>? splitData;  // Map of userId -> amount owed
  String? walletId;                // Null if paidBy != auth.uid() or no wallet selected
  String? portfolioId;
  String? recurringTransactionId;
}
```

#### Field Separation Contract:
- **`user_id` (Creator/Recorder):** Must strictly point to `Supabase.instance.client.auth.currentUser!.id`. This satisfies Postgres foreign key `expenses_user_id_fkey` and the Supabase RLS check `auth.uid() = user_id`.
- **`paid_by` (Financial Payer):** Points to the group member who incurred the financial cost. May be equal to `user_id` or any other valid member in `group_members`.
- **`wallet_id`:** Belongs exclusively to the user's personal wallets. If `paid_by != currentUserId`, `wallet_id` **must be null**, because the application cannot deduct money from another user's personal wallet.

---

### 1.2 Timeline Debt Balance Data Point Model

For the observable timeline chart, each point represents the running balance on date $t$:

```dart
class DebtTimelinePoint {
  final DateTime date;
  final double netBalance; // > 0: credit (others owe me), < 0: debt (I owe others), == 0: settled
  final double dailyChange; // Net delta introduced by transactions on this specific date
  final List<Expense> relatedExpenses; // Expenses on this date contributing to delta

  const DebtTimelinePoint({
    required this.date,
    required this.netBalance,
    required this.dailyChange,
    required this.relatedExpenses,
  });

  bool get isCredit => netBalance > 0.001;
  bool get isDebt => netBalance < -0.001;
  bool get isSettled => netBalance.abs() <= 0.001;
}
```

#### Debt Calculation Over Time Algorithm:
1. Fetch all expenses for `groupId` ordered by `date ASC`.
2. Fetch all splits for those expenses.
3. Group transactions by day $D_i \in \{D_0, \dots, D_N\}$.
4. For each day, initialize running balance $B_t = B_{t-1}$.
5. For each transaction on day $D_i$:
   - If `expense.paidBy == currentUserId`:
     - Add $\sum \text{unpaid splits for other members}$ to $B_t$ ($+\Delta$).
   - If `expense.paidBy != currentUserId`:
     - Subtract current user's unpaid split from $B_t$ ($-\Delta$).
6. If no expenses exist on a given day within the requested range, propagate $B_t = B_{t-1}$ to produce a continuous step-line graph.
7. Normalize $Y$-axis scale: $\text{maxY} = \max(|B_{\min}|, |B_{\max}|) \times 1.15$, ensuring $0$ is positioned at exact vertical center ($Y = \text{height} / 2$).

---

### 1.3 Expense Filter Criteria Model

```dart
class ExpenseFilterCriteria {
  final Set<Tipologia> categories;
  final DateTimeRange? dateRange;
  final String? paidByUserId;
  final String searchQuery;
  final double? minAmount;
  final double? maxAmount;

  const ExpenseFilterCriteria({
    this.categories = const {},
    this.dateRange,
    this.paidByUserId,
    this.searchQuery = '',
    this.minAmount,
    this.maxAmount,
  });

  bool get isEmpty =>
      categories.isEmpty &&
      dateRange == null &&
      paidByUserId == null &&
      searchQuery.trim().isEmpty &&
      minAmount == null &&
      maxAmount == null;

  int get activeFilterCount {
    int count = 0;
    if (categories.isNotEmpty) count++;
    if (dateRange != null) count++;
    if (paidByUserId != null) count++;
    if (searchQuery.trim().isNotEmpty) count++;
    if (minAmount != null || maxAmount != null) count++;
    return count;
  }

  bool matches(Expense expense) {
    // 1. Category multi-match
    if (categories.isNotEmpty && !categories.contains(expense.type)) {
      return false;
    }
    // 2. Date range match
    if (dateRange != null) {
      if (expense.date.isBefore(dateRange!.start) ||
          expense.date.isAfter(dateRange!.end.add(const Duration(days: 1)))) {
        return false;
      }
    }
    // 3. Paid by match
    if (paidByUserId != null) {
      final actualPayer = expense.paidBy ?? expense.userId;
      if (actualPayer != paidByUserId) return false;
    }
    // 4. Description query match
    if (searchQuery.trim().isNotEmpty) {
      final q = searchQuery.toLowerCase();
      if (!expense.description.toLowerCase().contains(q)) return false;
    }
    // 5. Amount range match
    if (minAmount != null && expense.amount < minAmount!) return false;
    if (maxAmount != null && expense.amount > maxAmount!) return false;

    return true;
  }
}
```

---

## 2. Row Level Security & Database Integrity

1. **`expenses` Table Constraint:**
   - `user_id UUID NOT NULL REFERENCES auth.users(id)`: Always populated with `auth.uid()`.
   - `paid_by UUID REFERENCES profiles(id)`: Points to payer profile; RLS allows insert if user is group member:
     ```sql
     CREATE POLICY "Group members can create group expenses"
       ON expenses FOR INSERT
       WITH CHECK (
         group_id IN (
           SELECT group_id FROM group_members WHERE user_id = auth.uid()
         )
       );
     ```
2. **`expense_splits` Table:**
   - Every generated split references `user_id` of members currently registered in `group_members`.
   - `is_paid` flag: set to `true` for `member.userId == expense.paidBy` and `false` for debtors.
