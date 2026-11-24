# 01 — ORIGINAL INTENT & USER DIRECTIVES

**Run ID:** `run_20261124_194300_audit_debt_credit_calculation_chain`  
**Timestamp:** `2026-11-24T19:43:00+01:00`  
**Target Domain:** Economy & Multi-User Debt/Credit Accounting Engine  
**Mode:** `SPEC_ONLY`  

---

## 1. Verbatim User Input

```text
Ho aggiunto delle spese che dovevano farmi aumentare il mio credito (quindi il debito dell'altra persona verso di me) ma mi sembra essere sceso, non vorrei che ci sia qualche problema con il calcolo o con qualche altro pezzo che porta ad avere quel numero. Tutta la catena di gestione di debito/credito fa affidamento sul fatto che quel calcolo sia esatto. Facciamo un controllo approfondito della situazione
```

---

## 2. Intent Deconstruction: Explicit vs. Inferred

### A. Explicit Intent
1. **Reported Anomaly:** The user added one or more group expenses intended to increase their credit balance (i.e. increasing what the other peer owes to the user). Instead, the user observed the balance figure decrease (or move in an unexpected direction).
2. **Core Concern:** Anxiety regarding systemic correctness: the entire peer-to-peer debt/credit management chain relies on mathematical and operational infallibility.
3. **Mandate:** Perform a thorough, root-cause audit of the entire debt/credit calculation chain across data ingestion, split generation, database queries, caching, arithmetic sign conventions, and UI presentation widgets.

### B. Inferred Product & Engineering Needs
1. **Trace Every Link in the Chain:**
   - Transaction capture forms (`UnifiedTransactionModal`, `ExpenseForm`, `QuickExpenseWidget`).
   - Split generator logic (`_calculateSplits` in `ExpenseService` vs `ExpenseServiceCached`).
   - Database schema & Supabase RLS policies (`expenses`, `expense_splits`).
   - Balance query aggregators (`calculateGroupBalance`, `calculateGroupBalanceMultiPerson`, `calculateUserBalance`, `calculateBulkUserBalances`).
   - Models & sign conventions (`DebtBalance`, `PairwiseDebtBalance`, `GroupedDebtBalance`).
   - UI consumer widgets (`PeerDebtsWidget`, `BalancePillWidget`, `GroupDebtsSection`, `EconomyHubView`, `ExpenseListItem`).
2. **Identify Concrete Flaws & Traps:**
   - Uncover any sign inversions, arithmetic mismatches, missing null-guards, cache desynchronization, or divergent implementations between services.
3. **Provide Comprehensive Test Coverage & Invariant Matrix:**
   - Specify mathematical invariants and unit tests that ensure debt/credit can never drift, invert, or crash under null fields.

---

## 3. Scope Boundaries & Policy Compliance
- **SPEC_ONLY Mode:** This protocol performs grounded discovery, architectural audit, mathematical verification, independent review, and implementation planning. It will NOT modify source code or commit changes in this turn.
- **Evidence Anchor:** All claims cite concrete file paths, method names, and line numbers observed in the current repository checkout.
