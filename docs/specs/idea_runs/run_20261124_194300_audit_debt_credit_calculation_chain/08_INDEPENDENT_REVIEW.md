# 08 — INDEPENDENT ARCHITECTURAL & SPEC REVIEW

**Run ID:** `run_20261124_194300_audit_debt_credit_calculation_chain`  
**Reviewer Role:** Independent Architectural & Security Reviewer (`DevelopmentEngine.IndependentReviewer`)  
**Mode:** SPEC_ONLY  
**Target Proposal:** Audit and Harmonization of Solducci Debt/Credit Calculation Chain  
**Verdict:** `APPROVED_WITH_RECOMMENDATIONS`  

---

## 1. Review Summary & Provenance
The review examined:
- Verbatim user input regarding unexpected drop in peer credit balance.
- Identified repository bugs in `ExpenseServiceCached._calculateSplits` and `calculateGroupBalance`.
- Proposed architectural decisions, domain models, UX updates, and roadmap.

The proposed solution addresses the authentic root causes (POM LIVE-V03) rather than creating cosmetic workarounds, preserves context isolation and RLS, and requires zero database migrations.

---

## 2. Review Findings & Adjudication

### Finding 1: Unsafe Non-Nullable Cast in `calculateGroupBalance`
- **Severity:** `CRITICAL`
- **Category:** `RUNTIME_CRASH / SILENT_DATA_LOSS`
- **Observation:** `expense['paid_by'] as String` inside `calculateGroupBalance` (`lib/service/expense_service.dart:532` and `lib/service/expense_service_cached.dart:560`) will unconditionally crash if any expense in the group has `paid_by == null`. Because the method swallows exceptions with `catch (e) { return {}; }`, any user experiencing this bug sees their entire group balance instantly wipe to €0.00 ("Saldo in pareggio").
- **Reviewer Recommendation:** Mandate defensive fallback `(expense['paid_by'] as String?) ?? (expense['user_id'] as String?)` and unit test with null `paid_by`.
- **Decision Agent Response:** `ACCEPTED_AND_MODIFIED` — Included in Milestone 2 with highest priority.

### Finding 2: Divergent Split Logic in `ExpenseServiceCached`
- **Severity:** `HIGH`
- **Category:** `ARITHMETIC_CORRUPTION`
- **Observation:** While `ExpenseService` has an equal-split check for `splitData` to handle selective member splits, `ExpenseServiceCached` does not. Because `UnifiedTransactionModal` and `QuickExpenseWidget` use `ExpenseServiceCached`, any expense with selective members gets incorrectly split across all members, diluting the payer's credit.
- **Reviewer Recommendation:** Align `ExpenseServiceCached._calculateSplits` identically with `ExpenseService._calculateSplits`.
- **Decision Agent Response:** `ACCEPTED_AND_MODIFIED` — Scheduled in Milestone 2.

### Finding 3: Sign Convention Inversion Trap in `DebtBalance`
- **Severity:** `MEDIUM`
- **Category:** `MAINTAINABILITY / COGNITIVE_LOAD`
- **Observation:** `DebtBalance.netBalance` has the opposite sign from `PairwiseDebtBalance.amount` and `PeerDebtsWidget.netTotal`. Having positive mean "you owe" in one model and "they owe you" in another is an ongoing bug magnet.
- **Reviewer Recommendation:** Standardize on `PairwiseDebtBalance` where `amount > 0` universally denotes credit. Clearly deprecate the inverted sign in `DebtBalance`.
- **Decision Agent Response:** `ACCEPTED_AND_MODIFIED` — Documented and incorporated in Milestone 3.

### Finding 4: Accidental Payer Inversion in User Experience
- **Severity:** `MEDIUM`
- **Category:** `HUMAN_ERROR_PREVENTION`
- **Observation:** The modal interface does not visually warn the user if they select another member as the payer. A user intending to lend money who taps the peer's avatar inadvertently records themselves as the debtor.
- **Reviewer Recommendation:** Add dynamic live preview text showing the credit/debt impact before submission.
- **Decision Agent Response:** `ACCEPTED_AND_MODIFIED` — Included in Milestone 4.

---

## 3. Final Review Verdict
**APPROVED**: The specification is complete, robust, and mathematically grounded. Proceed to readiness declaration.
