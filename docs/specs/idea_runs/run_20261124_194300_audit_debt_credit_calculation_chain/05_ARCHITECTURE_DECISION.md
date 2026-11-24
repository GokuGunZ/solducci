# 05 — ARCHITECTURE DECISION RECORD (ADR)

**Run ID:** `run_20261124_194300_audit_debt_credit_calculation_chain`  
**Title:** Harmonization, Null-Hardening, and Verification of the Multi-User Debt/Credit Calculation Chain  
**Status:** PROPOSED (SPEC_ONLY)  

---

## 1. Context and Problem Statement
Users dogfooding Solducci observed discrepancies where recording expenses expected to increase peer credit appeared to decrease the balance or reset it.
An exhaustive codebase audit revealed:
1. `ExpenseServiceCached._calculateSplits` diverges from `ExpenseService._calculateSplits`, ignoring `splitData` for equal splits and dividing by all group members rather than selected members.
2. `calculateGroupBalance` in both `ExpenseService` and `ExpenseServiceCached` performs an unsafe cast `expense['paid_by'] as String`, throwing a runtime `TypeError` when any group expense has a null `paid_by`, causing the entire method to fail and return an empty map (`{}`), which resets displayed balances to zero.
3. Three contradictory sign conventions for "net balance" exist across models (`DebtBalance` defines positive as debt, while `PeerDebtsWidget` and `PairwiseDebtBalance` define positive as credit).
4. `UnifiedTransactionModal` payer selection can be ambiguous, risking accidental payer inversion by the user.

---

## 2. Alternatives Considered

### Option A: Complete Accounting Engine Rewrite in PostgreSQL Database Functions (RPC)
- *Description:* Move all split generation, balance summation, and debt pairwise calculations into database triggers and stored procedures (`calculate_group_balance(group_id)`).
- *Pros:* Single source of truth in SQL; impervious to Dart-layer dualism.
- *Cons:* Heavy migration; breaks offline-first caching and optimistic UI capabilities; high blast radius across existing views and tests.
- *Verdict:* REJECTED as disproportionate for Pilot 03A.

### Option B: Surface-Level View Patching (Fix only `PeerDebtsWidget`)
- *Description:* Add local workarounds and sign flips inside `PeerDebtsWidget` and `BalancePillWidget`.
- *Pros:* Minimal initial code changes.
- *Cons:* Leaves root causes intact; violates POM LIVE-V03 (seek root causes); does not fix runtime crash or split calculation bugs.
- *Verdict:* REJECTED.

### Option C: Architectural Harmonization, Dual-Service Parity, and Null-Hardening (RECOMMENDED)
- *Description:*
  1. Synchronize `_calculateSplits` in `ExpenseServiceCached` with `ExpenseService` to respect `splitData` in `SplitType.equal`.
  2. Null-harden `calculateGroupBalance` with `(expense['paid_by'] as String?) ?? (expense['user_id'] as String?)`.
  3. Formalize `PairwiseDebtBalance` as the canonical domain representation across all widgets; document and deprecate contradictory legacy `DebtBalance.netBalance` signs.
  4. Clarify Payer UI in `UnifiedTransactionModal` with explicit visual callout ("Chi ha anticipato?").
  5. Add a dedicated unit test suite (`test/unit/debt_credit_calculation_chain_test.dart`) covering all invariants.
- *Pros:* Fully root-cause grounded; preserves caching and offline architecture; zero schema migrations; 100% backward compatible.
- *Verdict:* ADOPTED.

---

## 3. Decision Matrix

| Criterion | Option A (SQL RPC) | Option B (UI Patch) | Option C (Harmonization) |
|---|---|---|---|
| **Root Cause Resolution** | High | Low | **High** |
| **Blast Radius / Risk** | High (DB migration) | Medium (masking bugs) | **Low (targeted Dart fixes)** |
| **Offline / Cache Compatibility** | Poor | High | **High** |
| **Proportionality (LIVE-V03)** | Disproportionate | Insufficient | **Optimal** |
| **Testability** | Complex (DB test harness) | Fragile | **Excellent (pure unit tests)** |
