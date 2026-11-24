# 05 — ARCHITECTURE DECISION RECORD (ADR)

**Run ID:** `run_20261124_195200_economy_tab_group_redesign_and_expense_fixes`  
**Status:** ACCEPTED  
**Applies Policies:** LIVE-V01 (Fidelity), LIVE-V02 (Non-Regression), LIVE-V03 (Root Cause Analysis), LIVE-V04 (Proportionality), LIVE-V05 (Contextual Evidence)  

---

## 1. Context & Architectural Problem Statement

The user requested 8 systemic improvements touching the Economy Tab, Group Financial Views, Interactive Debt Visualization, Stream Sort Ordering, Filtering Systems, Input Parsers, Database Invariants, and Edit Sheets.

Instead of patching isolated symptoms with ad-hoc workarounds, we evaluate structured alternatives and establish clean bounded designs.

---

## 2. Decision Log

### ADR-01: Economy Tab Header Architecture
- **Problem:** `EconomyHubView` was using standard Flutter `AppBar` with hardcoded title text, lacking `ContextSwitcher` dot and crowding the 5 trailing action buttons.
- **Alternatives Considered:**
  1. *Option A (Ad-hoc Row):* Add a custom `Row` inside `AppBar(title: ...)` holding both `ContextSwitcher` and title. -> *Rejected:* Causes overflow when screen width is under 390dp due to 5 action buttons.
  2. *Option B (Shared `SolducciAppBar` with empty title):* Use the existing `SolducciAppBar` component with `showContextSwitcher: true` and `title: const SizedBox.shrink()`. -> *Selected.*
- **Rationale:** Aligns with standard app convention used in `bento_dashboard_page.dart` and `documents_home_view.dart`, giving the context indicator 80px leading width and maximizing header space for action icons.

### ADR-02: Group Economy Page Component Topology
- **Problem:** In group context, displaying the personal net worth hero card is confusing and clutters the interface. The debt summary should be prominent.
- **Decision:**
  - Branch the body layout of `EconomyHubView` conditionally on `isGroupContext`:
    - When `true`:
      1. `GroupDebtsSection` (with tap target to detail view).
      2. `CategoryBreakdownDeck(expenses: expenses, showTitle: false)`.
      3. `Transazioni Gruppo` (sorted descending).
    - When `false`:
      1. `CashflowHeroCard` (Patrimonio Netto).
      2. `WalletsCarousel`.
      3. `RealCashflowTimelineGraph`.
      4. `InvestmentsCarousel`.
      5. `CategoryBreakdownDeck(expenses: expenses, showTitle: true)`.
      6. `Transazioni` list.
- **Tradeoff:** Minimal conditional branching in `EconomyHubView` keeps both personal and group layouts clean without code duplication.

### ADR-03: Zero-Centered Interactive Debt Timeline Chart
- **Problem:** Users need an observable and navigable representation of their running debt/credit over time with zero vertically centered.
- **Alternatives Considered:**
  1. *Option A (fl_chart library):* High complexity, zero-alignment requires manual padding recalculation on every viewport change.
  2. *Option B (CustomPainter with zero-center calibration):* Draw the timeline using Flutter's native `CustomPainter` with symmetric Y-axis ($[-Y_{\max}, +Y_{\max}]$). -> *Selected.*
- **Rationale:**
  - Guaranteed vertical center for $Y=0$ regardless of device aspect ratio.
  - Smooth Bezier or step-curve interpolation.
  - Dual-gradient fill: Green gradient above zero, Amber/Red gradient below zero.
  - Zero external package dependencies, 60fps gesture scrubbing via `GestureDetector(onHorizontalDragUpdate)`.

### ADR-04: Stream Ordering at Cache Ingress
- **Problem:** Group transactions in `EconomyHubView` were displayed in ascending chronological order because Postgres `.stream()` emits in PK order and `_groupExpensesStream` did not sort.
- **Root Cause & Fix (LIVE-V03):** Enforce sorting at the repository/service layer in `ExpenseServiceCached`:
  - `_groupExpensesStream` maps data with `expenses..sort((a, b) => b.date.compareTo(a.date))`.
  - `_mergeStreams` ensures all single and merged streams emit sorted lists.
  - `ExpenseList` and `EconomyHubView` consume sorted streams without fragile UI-level sort patches.

### ADR-05: Robust Number Parser & In-Modal Validation Surface
- **Problem:** Typing `31.4` stripped the dot and became `314` because of `.replaceAll('.', '')`. SnackBars were occluded behind the modal bottom sheet.
- **Decision:**
  - Implement `CurrencyInputHelper.parse(String text)`:
    - If string contains both `.` and `,` (e.g. `1.250,50` or `1,250.50`), identify the last separator as the decimal delimiter and strip previous group separators.
    - If string contains only one delimiter (e.g. `31.4` or `31,4`), normalize that delimiter to `.` and parse directly.
  - Introduce `ModalErrorBanner`: An animated dismissible banner rendered at the top of `UnifiedTransactionModal`'s sheet layout, completely replacing obscured `ScaffoldMessenger` calls.

### ADR-06: Database Constraint Resolution for "Paid by Other" Group Expenses
- **Problem:** Creating a group expense on behalf of another user triggered a database constraint violation.
- **Root Cause & Fix:**
  - In `UnifiedTransactionModal`, `newExp` was constructed without `userId`.
  - In `ExpenseServiceCached.insert()`, `userId` was only assigned when `context.isPersonal`.
  - When `context.isGroup`, `userId` remained `null`.
  - Fix: In `insert()`, set `item.userId ??= _supabase.auth.currentUser?.id`. The authenticated user is *always* the creator of the record, satisfying `NOT NULL` and `user_id = auth.uid()` foreign key & RLS invariants.
  - When `paidBy != currentUserId`, set `walletId = null` to prevent deducting from the current user's personal wallet.

### ADR-07: Expense Editing Sheet Parity
- **Problem:** `_EditExpenseSheet` lacked controls for `paidBy` and split configuration.
- **Decision:** Extract shared widgets:
  - `PayerSelectionChips`: Renders group member avatars/names to select payer.
  - `SplitTypeSelector`: Allows switching between equal, custom, lend, offer.
  - Wire into `_EditExpenseSheetState` to update `updatedExpense.paidBy`, `splitType`, `splitData` and recalculate splits on save.
