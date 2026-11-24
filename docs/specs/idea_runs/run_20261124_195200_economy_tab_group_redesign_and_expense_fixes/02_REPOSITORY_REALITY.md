# 02 — REPOSITORY REALITY AUDIT

**Branch:** `test`  
**HEAD Commit:** `47c2544ab35105d6601cd29d5470719348b71d7a`  
**Target Repository:** `C:\Users\Aless\Documents\Projects\Solducci`  
**Evidence Level:** Direct Static Inspection of Live Files  

---

## 1. Concrete File Paths & Line-Level Findings

### 1.1 Header in Economy Tab (`lib/views/hubs/economy_hub_view.dart`)
- **Lines 164–170:**
  ```dart
  appBar: AppBar(
    title: Text(
      isGroupContext ? 'Economy Hub • ${_contextManager.contextDisplayName}' : 'Economy Hub',
      style: const TextStyle(color: Color(0xFFE0E0E0), fontWeight: FontWeight.bold),
    ),
    backgroundColor: Colors.transparent,
    elevation: 0,
    actions: [ ... 5 action icon buttons ... ]
  )
  ```
- **Observed Defect:** Uses standard `AppBar` instead of `SolducciAppBar`. In other views (e.g. `bento_dashboard_page.dart:104`, `expense_list.dart:62`), `SolducciAppBar` renders the `ContextSwitcher` widget inside `leading` with a width of 80–132px. Because `EconomyHubView` used standard `AppBar`, it completely lacked the context switcher dot, while simultaneously crowding the top bar with a long title and 5 trailing action buttons.

### 1.2 Layout Hierarchy in Economy Hub (`lib/views/hubs/economy_hub_view.dart`)
- **Lines 403–425:**
  ```dart
  // HERO CARD PATRIMONIO
  KeyedSubtree(
    key: _heroKey,
    child: _NeonSectionWrapper(
      isHighlighted: _highlightedSection == 'hero',
      glowColor: const Color(0xFF10B981),
      child: CashflowHeroCard(isGroupContext: isGroupContext),
    ),
  ),
  if (isGroupContext) ...[
    KeyedSubtree(
      key: _debtsKey,
      child: _NeonSectionWrapper(
        isHighlighted: _highlightedSection == 'debts',
        glowColor: const Color(0xFF8B5CF6),
        child: const GroupDebtsSection(),
      ),
    ),
  ]
  ```
- **Observed Defect:** In group context, `CashflowHeroCard` ("Patrimonio Netto") is rendered at the top, preceding `GroupDebtsSection`. Furthermore, `RealCashflowTimelineGraph` (lines 476–484) appears before `CategoryBreakdownDeck` (line 504), and `CategoryBreakdownDeck` (lines 29–42 of `category_breakdown_deck.dart`) hardcodes the header `"Spese per Categoria"`.

### 1.3 Debts & Credits Click Target (`lib/widgets/economy/group_debts_section.dart`)
- **Lines 140–218:**
  `GroupDebtsSection` renders a `Container` containing pairwise debt rows (`_buildPairwiseDebtRow`), but has no `InkWell` or `GestureDetector` wrapper around the header or container to open a detailed debt history page. No dedicated route `/economy/debts` or timeline chart exists for group debt progression.

### 1.4 Group Transaction Stream Sorting (`lib/service/expense_service_cached.dart`)
- **Lines 276–297:**
  ```dart
  Stream<List<Expense>> _groupExpensesStream(List<String> groupIds) {
    final supabaseStream = _supabase
        .from('expenses')
        .stream(primaryKey: ['id'])
        .inFilter('group_id', groupIds)
        .map((data) {
          final expenses = _parseExpenses(data);
          putManyInCache(expenses);
          return expenses;
        });
    ...
  }
  ```
- **Observed Defect:** `_supabase.from('expenses').stream(primaryKey: ['id'])` returns rows ordered by primary key `id` ascending (insertion order = oldest first). Neither `_parseExpenses` nor `_groupExpensesStream` applies `.sort((a, b) => b.date.compareTo(a.date))`. Furthermore, in `_mergeStreams` (line 302), when `streams.length == 1`, the unsorted stream is emitted directly. Consequently, group transactions display oldest at the top.

### 1.5 Expense List Page UI & Filters (`lib/views/expense_list.dart`)
- **Lines 61–136:**
  - `ExpenseList` uses a plain white/grey theme without Solducci dark styling (`Color(0xFF09090B)`).
  - No filter controls exist: zero widgets for filtering by category, date range, payer, description search, or amount.
  - The UI uses default ListTile cards rather than modern glassmorphic cards.

### 1.6 Number Formatting Decimal Bug (`lib/widgets/quick_add/unified_transaction_modal.dart`)
- **Lines 235, 296, 1187, 1356, 1523:**
  ```dart
  final cleanAmt = _amountController.text.replaceAll('.', '').replaceAll(',', '.').trim();
  final amount = double.tryParse(cleanAmt);
  ```
- **Observed Defect:** Calling `.replaceAll('.', '')` unconditionally assumes `.` is a thousands separator and `,` is the decimal separator. When a user types `31.4` (using standard dot decimal), the dot is deleted, resulting in `314`.
- **Snackbar Occlusion (Lines 300, 336, 347):** `ScaffoldMessenger.of(context).showSnackBar()` is invoked inside a modal bottom sheet (`showModalBottomSheet`), rendering the SnackBar behind the modal dialog, leaving the user with an unresponsive screen.

### 1.7 Adding Group Expense on Behalf of Another Member
- **`lib/service/expense_service_cached.dart:106–125`:**
  ```dart
  @override
  Future<Expense> insert(Expense item) async {
    final context = _contextManager.currentContext;
    if (context.isGroup) {
      item.groupId = context.groupId;
    }
    if (context.isPersonal) {
      item.userId = _supabase.auth.currentUser?.id;
      item.groupId = null;
    }
    final dataToInsert = item.toMap();
    ...
  }
  ```
- **Observed Defect:** When in group context, `item.userId` is NOT assigned by `insert()`. In `UnifiedTransactionModal:363`, `newExp` is constructed without `userId`. In Postgres `expenses`, `user_id` has a `NOT NULL` constraint or foreign key to `auth.users(id)`. Attempting to insert a row with `user_id = null` fails with a constraint violation. In addition, `paid_by` represents the financial payer (another group member), whereas `user_id` must always record the authenticated creator (`auth.uid()`).

### 1.8 Expense Edit Sheet Missing Payer & Split Controls (`lib/views/economy/expense_detail_view.dart`)
- **Lines 826–1113 (`_EditExpenseSheetState`):**
  Declares `String? _selectedPayerId;` (line 831), but never renders a payer selection dropdown or chip list in `build()`. It also omits all split management controls (`splitType`, `splitData`, member inclusion).

---

## 2. Invariants & Technical Constraints

1. **Database Schema:** Postgres table `expenses` columns `id` (int), `user_id` (UUID NOT NULL), `group_id` (UUID nullable), `paid_by` (UUID nullable), `amount` (numeric), `date` (timestamptz), `type` (text), `split_type` (text), `split_data` (jsonb).
2. **Table `expense_splits`:** Columns `id` (UUID), `expense_id` (int FK), `user_id` (UUID FK profiles), `amount` (numeric), `paid` / `is_paid` (boolean).
3. **Context Model:** `ContextManager` drives state changes via `ExpenseContext` (`isPersonal`, `isGroup`, `isView`).
