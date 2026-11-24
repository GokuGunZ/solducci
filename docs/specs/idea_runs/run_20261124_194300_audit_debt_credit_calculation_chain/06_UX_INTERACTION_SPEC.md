# 06 — UX & INTERACTION SPECIFICATION

**Run ID:** `run_20261124_194300_audit_debt_credit_calculation_chain`  
**Domain:** Modal Capture & Dashboard Debt Widget UX  

---

## 1. Payer Selection UX in `UnifiedTransactionModal`

### Problem Identified:
When recording a group transaction in `UnifiedTransactionModal` (`lib/widgets/quick_add/unified_transaction_modal.dart`), users see member avatars in the payer selector. If a user enters an expense to lend money to a peer or pay on their behalf, they often tap the peer's avatar, mistakenly assuming the avatar represents the *beneficiary* or *recipient* rather than the *payer*. This inverts the transaction: the peer is marked as `paidBy`, and the user is recorded as owing the peer half the amount!

### Solution & Visual Refinements:
1. **Explicit Role Header:**
   - Display unambiguous title: `"CHI HA ANTICIPATO IL DENARO?"` instead of generic `"Chi ha pagato?"`.
   - Add inline hint: `"Chi paga acquisisce un credito verso gli altri membri."`
2. **Current User Avatar Pre-Selection:**
   - Default avatar is permanently highlighted as `'Tu (Payer)'` with a green border and checkmark badge.
   - If the user selects another peer, a brief warning banner appears:  
     `"⚠️ Stai registrando che [Nome] ha pagato per te. Il tuo debito aumenterà."`
3. **Split Preview Pill:**
   - Directly below the split configuration, display live dynamic impact text:
     - When user is payer: `"↗️ Ti spetterà un credito di +€X.XX da [Altro Membro]"` (Color: Emerald `#10B981`).
     - When other is payer: `"↙️ Dovrai rimborsare €X.XX a [Nome]"` (Color: Amber `#F59E0B`).

---

## 2. Dashboard Widgets (`PeerDebtsWidget` & `BalancePillWidget`)

### A. `PeerDebtsWidget` (1x1, 2x1, H2, H3/H4)
- **Compact Cards (1x1 & 2x1):**
  - When credit is owed to user:
    - Label: `"TI SPETTA"`
    - Color: Emerald `#10B981`
    - Icon: `Icons.north_east_rounded`
    - Subtext: `"[Nome] ti deve €X.XX"`
  - When user owes debt:
    - Label: `"DEVI"`
    - Color: Amber `#F59E0B`
    - Icon: `Icons.south_west_rounded`
    - Subtext: `"Devi rimborsare a [Nome]"`
- **Multi-Member List (H3/H4):**
  - Top Net Bar:
    - If net is positive: `"A credito: +€X.XX"` (Color: `#10B981`).
    - If net is negative: `"A debito: -€X.XX"` (Color: `#F59E0B`).
    - Clarifying tooltip: `"Differenza netta tra crediti da riscuotere e debiti da pagare"`.

### B. `BalancePillWidget` in Group Context
- **Fix UUID Display:**
  - In `lib/widgets/dashboard/widgets/balance_pill_widget.dart:300`:
    Currently displays `item.key.toUpperCase()` which is raw Supabase UUID string!
  - Must resolve `item.key` (UUID) to group member nickname / display name using `GroupServiceCached().getGroupMembers()`.
- **Amount Formatting:**
  - Positive balance: `+€X.XX` with label `"Credito con [Nome]"`.
  - Negative balance: `-€X.XX` with label `"Debito con [Nome]"`.
