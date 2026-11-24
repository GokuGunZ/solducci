# 03 — PRODUCT BEHAVIOR SPECIFICATION

**Run ID:** `run_20261124_194300_audit_debt_credit_calculation_chain`  
**Domain:** Peer-to-Peer Debt/Credit Accounting Engine  
**Status:** Grounded Spec  

---

## 1. User Stories & Invariant Contracts

### Story 1: Equal Split Paid by Current User (Nominal Case)
- **As** Carl (current user),
- **When** I record a group expense of 80.00 € in a 2-person group (Carl & Pit) marked as "Diviso equamente" and paid by me,
- **Then**:
  1. Pit's debt to me must increase by exactly `40.00 €` (`80.00 / 2`).
  2. If Pit previously owed me `20.00 €`, the new balance must display `Pit ti deve 60.00 €` (Green, up-arrow).
  3. Under no circumstance may the credit amount decrease or flip to debt.

### Story 2: Equal Split Paid by Other Peer
- **As** Carl (current user),
- **When** Pit records a group expense of 60.00 € paid by Pit,
- **Then**:
  1. My debt to Pit increases by `30.00 €` (my share).
  2. If Pit previously owed me `60.00 €`, my credit decreases to `30.00 €` (`60.00 - 30.00`).
  3. If Pit previously owed me `10.00 €`, the net flips to `Devi 20.00 € a Pit` (Amber, down-arrow).

### Story 3: Selective Member Equal Split
- **As** Carl (in a 3-person group: Carl, Pit, Bob),
- **When** I record an expense of 90.00 € paid by me, but I exclude Bob from the split (only Carl and Pit split),
- **Then**:
  1. The split must create 2 records of `45.00 €` each (Carl: `is_paid = true`, Pit: `is_paid = false`).
  2. No split record may be created for Bob (or `amount = 0.0`).
  3. Pit's debt to Carl must increase by exactly `45.00 €` (NOT `30.00 €`).

### Story 4: Lend Split ("Prestato interamente")
- **As** Carl,
- **When** I pay 50.00 € for Pit using "Prestato interamente" (`SplitType.lend`),
- **Then**:
  1. Pit must owe Carl the entire `50.00 €` (`100%`).
  2. Carl's split is NOT generated or is 0.

### Story 5: Offer Split ("Offerto da me")
- **As** Carl,
- **When** I record an expense of 40.00 € using "Offerto da me" (`SplitType.offer`),
- **Then**:
  1. Zero peer debt is generated.
  2. The peer balance remains strictly unchanged.

---

## 2. Invariant Matrix

| Invariant ID | Rule | Mathematical Statement | Failure Mode Avoided |
|---|---|---|---|
| **INV-01** | Zero-Sum Peer Conservation | $\sum_{m \in Members} \Delta Balance_m = 0$ | Phantom money generation or loss |
| **INV-02** | Payer Credit Monotonicity | If $Payer = CurrentUser$ and $SplitType \in \{equal, custom, lend\}$ with $OtherShare > 0$, then $\Delta Credit \ge 0$ | Credit dropping after paying |
| **INV-03** | Null-Payer Defensive Fallback | If $paid\_by = null$, then $effectivePayer = user\_id$ | Fatal TypeError cast crash on null |
| **INV-04** | Sign Symmetry | $Balance(A \to B) = -Balance(B \to A)$ | Disagreement between two members on device |
| **INV-05** | Split Sum Conservation | $\sum_{s \in Splits} s.amount = expense.amount$ (within 0.02€ rounding) | Unallocated cents |
| **INV-06** | Service Parity | `ExpenseServiceCached._calculateSplits` $\equiv$ `ExpenseService._calculateSplits` | Divergence between cached & direct operations |

---

## 3. Edge Cases & Boundary Handling

1. **Member Rounding Imbalance:**
   - When 100.00 € is split 3 ways: 33.33 €, 33.33 €, 33.34 €.
   - The extra cent must be assigned deterministically (to payer or first member) to prevent floating-point drift.
2. **Expense Deletion & Recalculation:**
   - Deleting or editing an expense must completely purge old `expense_splits` and recompute balances.
   - `_needsSplitRecalculation` must trigger if `paidBy`, `amount`, or `splitData` changes.
3. **Empty Split Data / Network Failure:**
   - Network timeouts must never wipe displayed balances to 0; stale cache with `isStale: true` must be preserved.
