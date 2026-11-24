# 03 — PRODUCT BEHAVIOR SPECIFICATION

**Run ID:** `run_20261124_195200_economy_tab_group_redesign_and_expense_fixes`  
**Target Domain:** Economy Tab, Group Financial Summary, Expense Management, Transaction Filters  

---

## 1. Feature Specifications & User Stories

### Feature 1: Unified Economy Tab Header
- **As a** Solducci user navigating between tabs,
- **I want** the Economy tab header to show the current context indicator dot (`ContextSwitcher`) and omit redundant title text,
- **So that** I know at a glance which context (Personal or Group) is active without visual clutter or horizontal button crowding.

#### Acceptance Criteria:
1. `EconomyHubView` uses `SolducciAppBar` with `showContextSwitcher: true`.
2. The `title` property is set to `null` (or `SizedBox.shrink()`).
3. Action buttons (Investments, Wallets, Recurring, CSV Import, Analytics) remain fully visible and clickable without overflow.
4. Switching contexts via the dot updates the view immediately.

---

### Feature 2: Group Economics Page Restructuring
- **As a** member of a shared expense group,
- **I want** the Group Economy page to display debt balances first, followed immediately by categorized spending and group transactions, without showing personal net worth,
- **So that** the page focuses directly on shared group liabilities and settlement status.

#### Layout Specification by Context:
- **Group Context (`isGroupContext == true`):**
  1. **Top Section:** `GroupDebtsSection` (Saldo Debiti & Crediti).
  2. **Middle Section:** `CategoryBreakdownDeck` with `showTitle: false`.
  3. **Bottom Section:** `Transazioni Gruppo` (sorted newest first, with "Visualizza tutte" button).
  4. **Excluded:** `CashflowHeroCard` (Patrimonio Netto) is completely hidden in Group context.
  5. **Excluded:** `WalletsCarousel` and `InvestmentsCarousel` remain hidden.
- **Personal Context (`isGroupContext == false`):**
  1. `CashflowHeroCard` (Patrimonio Netto) preserved.
  2. `WalletsCarousel` preserved.
  3. `RealCashflowTimelineGraph` preserved.
  4. `InvestmentsCarousel` preserved.
  5. `CategoryBreakdownDeck` (with title preserved).
  6. `Transazioni` list preserved.

---

### Feature 3: Debt & Credit Detail View & Observable Timeline Chart
- **As a** group member with active pairwise debts or credits,
- **I want** to tap on "Saldo Debiti & Crediti" to open a dedicated detail view with an interactive balance timeline,
- **So that** I can track how my debt or credit evolved over time and inspect the exact balance on any given day.

#### Interaction Flow:
1. User taps anywhere on the `GroupDebtsSection` container or header.
2. The app pushes the route `/economy/debts` (`GroupDebtDetailView`).
3. **Top Section:** Displays the identical `GroupDebtsSection` summary card (showing net balances per member).
4. **Main Section:** Displays `ObservableDebtTimelineChart`:
   - Vertical $Y$-axis has $0$ centered in the middle of the graph height.
   - Positive area (above $0$) is styled with Credit Green (`#10B981`) representing "Credito" (others owe you).
   - Negative area (below $0$) is styled with Debt Amber/Red (`#F59E0B` / `#EF4444`) representing "Debito" (you owe others).
   - Horizontal line at $Y=0$ is dashed with neutral light opacity.
   - User can drag/scrub or tap along the horizontal $X$-axis (time).
   - A vertical crosshair and floating indicator card display:
     - Date: `dd MMMM yyyy`.
     - Net Balance at that date: `+€X.XX` (Credito) or `-€X.XX` (Debito).
     - Active transactions occurring on that day that shifted the curve.

---

### Feature 4: Group Transaction List Reverse Chronological Order
- **As a** user viewing group transactions,
- **I want** the newest group transactions to appear at the top of the list,
- **So that** I immediately see recent expenses without scrolling past old entries.

#### Acceptance Criteria:
1. `_groupExpensesStream` in `ExpenseServiceCached` sorts all expense lists using `b.date.compareTo(a.date)`.
2. The 5-item preview on `EconomyHubView` shows the 5 most recent transactions.
3. Full list at `/expense_list` shows all group transactions sorted descending.

---

### Feature 5: Expense List Multi-Criteria Filter Engine & UI Redesign
- **As a** user searching past expenses,
- **I want** to filter by multiple categories, date ranges, payer, description query, and amount range on a unified modern dark page,
- **So that** I can locate specific expenses quickly and enjoy a consistent visual experience.

#### Filter Capabilities:
1. **Multi-Select Categories:** Chip selector allowing selection of zero, one, or multiple `Tipologia` enums (e.g. `[Cibo, Trasporti]`).
2. **Date Window:** Preset chips (`Tutto`, `Questo Mese`, `Ultimi 30 Giorni`, `Quest'Anno`) plus custom `DateRangePicker`.
3. **Payer Filter:** When in group context, filter by who paid (`paidBy == member.userId`).
4. **Text Search:** Real-time query search matching `expense.description` (case-insensitive substring).
5. **Amount Range:** Slider or numeric inputs for Min and Max amount (€).
6. **Active Filter Badge:** Header badge showing count of active filters, with "Resetta Filtri" action.

#### UI Design Alignment:
- Background: `#09090B`.
- Surface Card: `#18181B` with `#27272A` borders and subtle neon glow.
- Typography: Inter/Roboto with explicit hierarchy (`#FFFFFF`, `#A1A1AA`).

---

### Feature 6: Locale-Aware Amount Parser & In-Modal Validation Surface
- **As a** user typing an expense amount,
- **I want** to enter numbers using either dot or comma (e.g. `31.4` or `31,4`) without having digits concatenated into `314`,
- **And I want** validation errors to be displayed directly inside the modal sheet,
- **So that** the app accepts my input smoothly and clearly shows what is missing.

#### Acceptance Criteria:
1. Smart parser `parseAmount(String input)`:
   - Replaces `,` with `.` when single separator present.
   - Handles standard formats: `31.4` $\to 31.40$, `31,4` $\to 31.40$, `1.250,50` $\to 1250.50$, `1,250.50` $\to 1250.50$.
   - Never removes decimal points indiscriminately.
2. In-modal error banners:
   - All validation messages in `UnifiedTransactionModal` are displayed in a animated banner at the top of the modal sheet.
   - SnackBars on `ScaffoldMessenger` are bypassed for modal sheets.

---

### Feature 7: Group Expense Creation on Behalf of Another Member
- **As a** user logging a shared group bill paid by a friend,
- **I want** to select that friend as payer (`paidBy`) without triggering database constraint errors,
- **So that** group debts are recorded accurately regardless of who typed the entry into Solducci.

#### Acceptance Criteria:
1. `Expense.userId` is explicitly set to `AuthService().currentUserId` (the authenticated recorder).
2. `Expense.paidBy` is set to the selected group member's ID.
3. If `paidBy != currentUserId`, `walletId` is set to `null` (preventing deduction from current user's personal wallet).
4. Database insert succeeds with HTTP 201 / OK; splits are generated with `is_paid = (member.userId == paidBy)`.

---

### Feature 8: Expense Edit Sheet with Payer & Split Controls
- **As a** user modifying an existing group expense,
- **I want** to edit who paid the expense and change the split distribution among members,
- **So that** mistakes in payer or split amounts can be corrected after creation.

#### Acceptance Criteria:
1. `_EditExpenseSheet` shows a "Chi ha pagato" horizontal selector with group member avatars.
2. `_EditExpenseSheet` provides split selection (`Equally`, `Custom`, `Lend`, `Offer`).
3. Saving recalculates splits via `ExpenseServiceCached.update()`.
