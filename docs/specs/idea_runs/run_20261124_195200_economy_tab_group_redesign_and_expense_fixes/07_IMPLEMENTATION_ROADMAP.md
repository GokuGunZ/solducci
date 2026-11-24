# 07 — IMPLEMENTATION ROADMAP & TEST PLAN

**Run ID:** `run_20261124_195200_economy_tab_group_redesign_and_expense_fixes`  
**Target Environment:** Solducci Workspace (`C:\Users\Aless\Documents\Projects\Solducci`)  
**Proposed Builder Worktree:** `builder_economy_group_overhaul`  

---

## 1. Milestone Dependency Graph (DAG)

```
[M1: Core Data & Input Fixes] 
      │
      ├──> [M2: Group Stream Sort & Hub Re-Layout] ──> [M3: Group Debt Detail & Timeline Chart]
      │
      ├──> [M4: Expense Detail Edit Sheet Parity]
      │
      └──> [M5: Expense List Filter Engine & Modern UI] ──> [M6: Integration & Regression Suite]
```

---

## 2. Milestone Breakdown

### Milestone 1: Core Input Helper, Database Invariants & In-Modal Feedback
- **Files Modified:**
  - `lib/utils/currency_input_helper.dart` (New helper: locale-aware decimal parsing).
  - `lib/widgets/quick_add/unified_transaction_modal.dart` (Adopt helper, add in-modal error banner, guarantee `userId` assignment).
  - `lib/service/expense_service_cached.dart` (Ensure `item.userId ??= auth.currentUser?.id` in `insert()`).
- **Validation Criteria:**
  - Entering `31.4` parses to `31.40`.
  - Missing field displays visible red banner inside modal.
  - Adding group expense where `paidBy != currentUserId` creates row in Postgres without constraint violation.

### Milestone 2: Group Stream Sorting & Economy Hub Header / Layout
- **Files Modified:**
  - `lib/service/expense_service_cached.dart` (`_groupExpensesStream` and `_mergeStreams` sort descending).
  - `lib/widgets/economy/category_breakdown_deck.dart` (Add `final bool showTitle = true;`).
  - `lib/views/hubs/economy_hub_view.dart`:
    - Switch to `SolducciAppBar` with `showContextSwitcher: true`, `title: SizedBox.shrink()`.
    - Group layout reordering: `GroupDebtsSection` -> `CategoryBreakdownDeck(showTitle: false)` -> Group Transactions.
- **Validation Criteria:**
  - Context indicator dot visible in Economy tab header without title text.
  - Group page shows debts at top, category deck without title below, recent transactions in newest-first order.

### Milestone 3: Debt Detail View & Observable Timeline Chart
- **Files Created/Modified:**
  - `lib/views/economy/group_debt_detail_view.dart` (New view).
  - `lib/widgets/economy/observable_debt_timeline_chart.dart` (New CustomPainter zero-centered chart).
  - `lib/widgets/economy/group_debts_section.dart` (Add tap handler navigating to `/economy/debts`).
  - `lib/routes/app_router.dart` (Register route `/economy/debts`).
- **Validation Criteria:**
  - Tapping debt card navigates to `/economy/debts`.
  - Chart has $Y=0$ centered; tapping/dragging shows running balance and transactions for that date.

### Milestone 4: Expense Detail Edit Sheet Parity
- **Files Modified:**
  - `lib/views/economy/expense_detail_view.dart` (`_EditExpenseSheetState`).
- **Validation Criteria:**
  - User can change `paidBy` to another member.
  - User can adjust split mode and member allocations.
  - Changes persist to `expenses` and `expense_splits`.

### Milestone 5: Expense List Filter Engine & Modern Dark UI
- **Files Created/Modified:**
  - `lib/models/expense_filter_criteria.dart` (Filter model).
  - `lib/views/expense_list.dart` (Redesigned with `#09090B` theme, search bar, active filter chips, glass cards).
  - `lib/widgets/economy/expense_filter_bottom_sheet.dart` (Multi-category, date range, payer, amount).
- **Validation Criteria:**
  - Multi-category filtering works seamlessly.
  - Search query filters real-time.
  - UI matches Economy tab aesthetics.

### Milestone 6: Verification & Test Suite
- **Automated Tests:**
  - `test/utils/currency_input_helper_test.dart` (Tests `31.4`, `31,4`, `1.250,50`, `1250.50`, etc.).
  - `test/features/economy/group_debt_timeline_test.dart` (Tests step-line balance calculation with zero center).
  - `test/features/economy/expense_filter_criteria_test.dart` (Tests multi-category and amount filters).
  - `test/features/economy/expense_service_sorting_test.dart` (Tests descending sort).
- **Verification Command:**
  - `flutter test test/features/economy/`
