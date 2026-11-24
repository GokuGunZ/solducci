# 01 — ORIGINAL INTENT & PRODUCT CONTRACT

**Run ID:** `run_20261124_195200_economy_tab_group_redesign_and_expense_fixes`  
**Execution Mode:** `SPEC_ONLY`  
**Context Workspace:** `C:\Users\Aless\Documents\Projects\Solducci`  
**Target Repository:** Solducci (Flutter / Dart / Supabase)  

---

## 1. Verbatim Original User Intent

```text
Voglio modificare la tab "Economia":
- Nell'header manca il pallino del contesto corrente (uguali a quello delle altre tab). Dato che è già Crowded, puoi togliere il titolo all'header.
- Vorrei che la pagina per i gruppi fosse composta così: "togliere il patrimonio netto tolale"; mettere saldo debiti in cima, poi Spese per categoria (togliendo il titolo alla sezione), e poi a seguire la sezione Transazioni del gruppo. 
- Cliccando su Saldo Debiti e Crediti, si va in una pagina nella quale si mostrano i dettagli relativi al debito/credito: In cima si ripropone la stesso widget da cui si è entrati, poi sotto segue un grafico osservabile (cliccando ad una data data si osserva qual era il debito a quel giorno) e navigabile dell'andamento del debito nel tempo. (quindi con lo zero centrato verticalmente e l'andamento che fa su e giu di debito in credito).
- La lista della sezione "Transizioni Gruppo" è ordinata in ordine cronologico, quindi la più vecchia in cima,  dovrebe essere al contrario. 
- All'interno della pagina "lista spese", deve esserci un modo per filtrare per tipologia (selezionando anche più tipologie), per data o finestra temporale, per chi ha pagato, per nome e per importo. Inoltre, quella pagina non ha lo stesso Design UI della tab economia, risolvi e unifica la UI. 
- Quando aggiungo una spesa, non prende il punto, quindi "31.4 diventa 314". Inoltre, dato che è un modal, gli snackbar informativi (tipo quando non inserisco un campo) vengono nascosti e l'app sembra bloccarsi. 
- Ho provato ad aggiungere una spesa in un gruppo per conto di un altra persona e mi da errore che qualche kiave del database viene violata, non dovrebbe succedere.
- Il form di modifica della spesa non permette di cambiare chi ha pagato e per chi.
```

---

## 2. Intent Decomposition & Scope Mapping

The user's directive comprises 8 distinct, tightly coupled enhancements spanning UI composition, financial chart visualization, stream ordering, modal interaction patterns, and database foreign key integrity:

### Item 1: Economy Tab Header Alignment & De-cluttering
- **Explicit Requirement:** Add the active context indicator dot (`ContextSwitcher`) to the Economy tab header, matching the other application tabs. Remove the header title text ("Economy Hub • ...") because the header row is already crowded with action buttons (investments, wallets, recurring, CSV staging, analytics).
- **Inferred Need:** Use the shared `SolducciAppBar` widget with `showContextSwitcher: true` and `title: null` / `title: SizedBox.shrink()`, ensuring full consistency across the entire app shell.

### Item 2: Group Economics Page Restructuring
- **Explicit Requirement:** When the active context is a Group (or View of groups):
  1. Remove the total net worth widget (`CashflowHeroCard`).
  2. Position the debt balance widget (`GroupDebtsSection`) at the very top.
  3. Follow immediately with expenses by category (`CategoryBreakdownDeck`), with its section title removed.
  4. Follow with the group transactions list.
- **Inferred Need:** In Personal context, preserve the existing layout (Hero net worth -> Wallets carousel -> Cashflow graph -> Investments -> Categories -> Transactions).

### Item 3: Debts & Credits Interactive Detail View & Timeline Chart
- **Explicit Requirement:** Tapping on the `GroupDebtsSection` navigates to a dedicated detail page. The top of the page mirrors the entered debt/credit widget. Below it, an observable and navigable timeline chart displays the net debt balance over time:
  - Y-axis has zero centered vertically ($Y=0$ horizontal midline).
  - Positive values (+€) represent credit (others owe the user), negative values (-€) represent debt (user owes others).
  - Interactive scrubbing/tapping on a date inspects the exact balance on that day.
- **Inferred Need:** Route registration `/economy/debts` with group context awareness; running balance calculation by replay of past group transactions and splits.

### Item 4: Group Transaction List Reverse Chronological Ordering
- **Explicit Requirement:** Currently, the "Transazioni Gruppo" list displays transactions in ascending chronological order (oldest first). It must be reversed to descending chronological order (newest first).
- **Inferred Need:** Fix the root cause in `ExpenseServiceCached._groupExpensesStream` and stream combiners, ensuring all emitted lists are sorted by `date` descending (`b.date.compareTo(a.date)`).

### Item 5: Expense List Multi-Criteria Filtering & Design System Unification
- **Explicit Requirement:** In `ExpenseList` (`/expense_list`):
  1. Add filtering capabilities:
     - Multi-select category/type (`Tipologia`).
     - Date / time window (e.g., today, this week, this month, custom date range).
     - Paid by member filter.
     - Search by description / name.
     - Amount range (min / max).
  2. Redesign the page to unify its UI with the Economy tab (dark background `#09090B`, neon accents `#10B981` / `#8B5CF6`, modern glass cards, typography).

### Item 6: Number Formatting Decimal Bug & Modal Feedback Visibility
- **Explicit Requirement:**
  1. Typing a decimal with dot (e.g. `31.4`) turns into `314`. Both dot and comma must be accepted as decimal delimiters.
  2. Informational and validation SnackBars are rendered beneath modal bottom sheets, giving the user the impression that the app has frozen.
- **Inferred Need:** Replace naive `.replaceAll('.', '')` with smart locale-aware decimal parsing; render in-modal banners or top overlay toasts instead of obscured root `ScaffoldMessenger` SnackBars.

### Item 7: Group Expense Creation on Behalf of Another Member
- **Explicit Requirement:** Recording a group expense where another member paid (`paidBy != currentUserId`) causes a database key violation error.
- **Inferred Need:** Fix `ExpenseServiceCached.insert()` and `toMap()` to ensure `user_id` (the audit creator `auth.uid()`) is always populated and distinct from `paid_by` (the financial payer), avoiding `NOT NULL` or foreign key reference failures on Postgres.

### Item 8: Expense Edit Form Missing Payer & Split Controls
- **Explicit Requirement:** The expense edit sheet does not allow modifying who paid (`paidBy`) or the split distribution (`splitType`, `splitData`, member splits).
- **Inferred Need:** Extend `_EditExpenseSheet` in `expense_detail_view.dart` to include payer member chips and split type configuration identical to the creation sheet.

---

## 3. Boundaries and Invariants
- **Non-Goals:** Do not rewrite the underlying Supabase database schema or drop foreign key constraints. Do not modify personal accounting logic.
- **Compatibility:** Backward compatibility with existing personal expenses, offline Hive caching, and Supabase RLS policies must remain intact.
