# 06 — UX AND INTERACTION SPECIFICATION

**Run ID:** `run_20261124_195200_economy_tab_group_redesign_and_expense_fixes`  
**Target Views:** `EconomyHubView`, `GroupDebtDetailView`, `ExpenseList`, `UnifiedTransactionModal`, `_EditExpenseSheet`  

---

## 1. Visual Hierarchy & Screen Blueprints

### 1.1 Economy Tab Header (`EconomyHubView`)
```
+---------------------------------------------------------------+
| (o) [ContextSwitcher Dot]            (^) (W) (R) (CSV) (Chart)|
| (Leading: 80px)      (Title: empty)     (Actions: 5 Icons)    |
+---------------------------------------------------------------+
```
- **Leading:** Context switcher pill displaying the active context color dot (Purple for Group, Green for Personal) + chevron.
- **Title:** Blank (`SizedBox.shrink()`), preventing text collision with action buttons.
- **Actions:** 5 rounded icon buttons (`#10B981` emerald tint, 20px size, touch target 44px).

---

### 1.2 Group Economy Hub Page (`isGroupContext == true`)
```
+---------------------------------------------------------------+
| [Header as above]                                             |
+---------------------------------------------------------------+
|                                                               |
|  [GROUP DEBTS & CREDITS CARD] (GroupDebtsSection)             |
|  +---------------------------------------------------------+  |
|  | <-> Saldo Debiti & Crediti               3 posizioni > |  |
|  | (A) Alice: Ti deve 24.50 EUR (Green Up Arrow)           |  |
|  | (M) Marco: Devi 12.00 EUR (Amber Down Arrow)            |  |
|  | [Tap anywhere to open Debt Detail View]                 |  |
|  +---------------------------------------------------------+  |
|                                                               |
|  [CATEGORY BREAKDOWN DECK] (No section title)                 |
|  +-------+  +-------+  +-------+  +-------+                   |
|  | Cibo  |  | Svago |  | Spesa |  | Casa  |  (Horizontal list)|
|  | 145 € |  | 80 €  |  | 55 €  |  | 30 €  |                   |
|  +-------+  +-------+  +-------+  +-------+                   |
|                                                               |
|  Transazioni Gruppo                          Visualizza tutte >|
|  +---------------------------------------------------------+  |
|  | Cena Pizzeria                     Oggi, 20:15   -35.00 €|  |
|  | Spesa Supermercato                Ieri, 18:30   -62.40 €|  |
|  | Benzina Viaggio                  22 Nov, 14:00  -40.00 €|  |
|  +---------------------------------------------------------+  |
|                                                               |
|  (+) FAB (Purple #8B5CF6 for Group Context)                   |
+---------------------------------------------------------------+
```

---

### 1.3 Debt Detail View (`GroupDebtDetailView` at `/economy/debts`)
```
+---------------------------------------------------------------+
| [< Back] Dettaglio Saldo Debiti                     [Settlement]|
+---------------------------------------------------------------+
|                                                               |
|  [RE-PROPOSED SUMMARY WIDGET]                                 |
|  +---------------------------------------------------------+  |
|  | <-> Saldo Debiti & Crediti               Saldo: +12.50 €|  |
|  | (A) Alice: Ti deve 24.50 EUR                            |  |
|  | (M) Marco: Devi 12.00 EUR                               |  |
|  +---------------------------------------------------------+  |
|                                                               |
|  ANDAMENTO DEL DEBITO NEL TEMPO                               |
|  +---------------------------------------------------------+  |
|  | +50 € ------------------------------------------------  |  |
|  |        _.-^-._        [+12.50 € Credito] (Green Shade)  |  |
|  | ======+=======+================================ (0.00 €)|  |
|  |                \___.-._                 (Amber Shade)   |  |
|  | -50 € ------------------------------------------------  |  |
|  | 01 Nov         10 Nov        20 Nov         24 Nov      |  |
|  |            ^ [Tapped / Scrubbed Crosshair]              |  |
|  +---------------------------------------------------------+  |
|                                                               |
|  [OBSERVABLE DAY INSPECTION CARD] (Appears on Tap/Drag)        |
|  +---------------------------------------------------------+  |
|  | 14 Novembre 2026: Saldo Netto: +24.50 EUR (Credito)     |  |
|  | Movimento: "Cena Sushi" (Alice ha pagato per te -15.00€) |  |
|  +---------------------------------------------------------+  |
+---------------------------------------------------------------+
```

#### Observable Timeline Interaction Rules:
1. **Zero Calibration:** The baseline $Y=0$ is positioned at exact half-height of the canvas ($H/2$).
2. **Dynamic Range:** Max absolute amplitude determines vertical bounds: $[-Y_{\max}, +Y_{\max}]$.
3. **Color Transition:** The curve transitions dynamically:
   - Values $> 0$: Emerald Green (`#10B981`) with vertical gradient to zero.
   - Values $< 0$: Amber/Coral (`#F59E0B` / `#EF4444`) with vertical gradient to zero.
4. **Scrubbing/Tap Gesture:**
   - Tap or drag anywhere on the chart activates a vertical cursor line.
   - Highlights the nearest date point with a glowing dot.
   - Updates the bottom inspection card with date, net balance, and transactions that day.

---

### 1.4 Expense List Modern Redesign (`ExpenseList`)
```
+---------------------------------------------------------------+
| [< Back] Lista Spese (Filtri Attivi: 2)           [Filtra Icon]|
+---------------------------------------------------------------+
| [Search Bar: "Cerca per descrizione..."]                     |
|                                                               |
| [Filter Tray Chips (Horizontal)]:                             |
| (x) Cibo, Trasporti  (x) Questo Mese  (+) Chi ha pagato  (+) €|
|                                                               |
| TRANSAZIONI TROVATE (14)                                      |
| +---------------------------------------------------------+   |
| | (Icon Cibo) Spesa Supermercato Esselunga   -42.50 €     |   |
| | 24 Nov 2026 • Pagato da Marco              Gruppo Casa  |   |
| +---------------------------------------------------------+   |
| | (Icon Trasporti) Rifornimento Eni          -60.00 €     |   |
| | 22 Nov 2026 • Pagato da Te                 Gruppo Casa  |   |
| +---------------------------------------------------------+   |
+---------------------------------------------------------------+
```

#### Filter Sheet (`ExpenseFilterBottomSheet`):
- Multi-selection for categories (`Wrap` of chips).
- Date range quick-presets (`Oggi`, `7 gg`, `Questo Mese`, `Personalizzato`).
- Payer selector (avatar chips of group members).
- Min & Max amount sliders with real-time numeric badges.
- Buttons: "Cancella Filtri" (outlined) and "Applica (N)" (filled green).

---

### 1.5 Number Input & In-Modal Validation Surface
- **Input Field:** Accepts `31.4`, `31,4`, `1.250,50`, `1250.50`.
- **In-Modal Error Banner:**
  ```
  +-------------------------------------------------------+
  | (!) Inserisci un importo valido maggiore di 0         |
  +-------------------------------------------------------+
  ```
  Rendered at the top of the modal bottom sheet in smooth red/amber with auto-dismiss or close button. No more obscured SnackBars!

---

### 1.6 Expense Edit Sheet (`_EditExpenseSheet`)
- Adds two new interactive sections:
  1. **"Chi ha pagato":** Horizontal avatar list with checkmark on selected member.
  2. **"Divisione della spesa":** Toggle chips for `Equal`, `Custom`, `Lend`, `Offer`.
- Updates `paidBy`, `splitType`, `splitData` upon clicking "Salva Modifiche".
