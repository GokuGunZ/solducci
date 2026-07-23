-- Migration: Carlucci-Pit Legacy Expenses to Multi-User System
-- Date: 2025-01-13
-- Description: Migrate all personal expenses to group system with proper MoneyFlow mapping

-- ========================================
-- CONFIGURATION
-- ========================================

DO $$
DECLARE
  target_group_id TEXT := '1775bead-b76c-49c8-b8d7-620cba2758c4';
  pit_user_id TEXT := '09ace514-a951-4936-afd6-468504075542';
  carlucci_user_id TEXT := '821db3d9-f450-4c48-8844-1d649ab399ad';
  migrated_count INT := 0;
  splits_created_count INT := 0;
  rec RECORD;
BEGIN
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Migration Starting...';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Target group: %', target_group_id;
  RAISE NOTICE 'Pit user: %', pit_user_id;
  RAISE NOTICE 'Carlucci user: %', carlucci_user_id;
  RAISE NOTICE '';

  -- ========================================
  -- STEP 1: Count Current State
  -- ========================================

  RAISE NOTICE 'Step 1: Analyzing current state...';

  RAISE NOTICE 'Personal expenses to migrate: %',
    (SELECT COUNT(*) FROM expenses WHERE group_id IS NULL);

  RAISE NOTICE 'MoneyFlow distribution:';
  FOR rec IN (
    SELECT money_flow, COUNT(*) as cnt
    FROM expenses
    WHERE group_id IS NULL
    GROUP BY money_flow
    ORDER BY cnt DESC
  ) LOOP
    RAISE NOTICE '  - %: % expenses', rec.money_flow, rec.cnt;
  END LOOP;
  RAISE NOTICE '';

  -- ========================================
  -- STEP 2: Migrate Expenses - MoneyFlow Mapping
  -- ========================================

  RAISE NOTICE 'Step 2: Migrating expenses with MoneyFlow mapping...';

  -- Map MoneyFlow to new system:
  -- "carlucci" or "pit" → personal expense (offer type)
  -- "carlucci -> /2" or "pit -> /2" → equal split, paid by respective person
  -- "pit -> carl" → lend (Pit paid, Carlucci must reimburse)
  -- "carl -> pit" → lend (Carlucci paid, Pit must reimburse)

  UPDATE expenses
  SET
    group_id = target_group_id,
    split_type = CASE
      -- Personal expenses (no split)
      WHEN LOWER(money_flow) IN ('carlucci', 'pit') THEN 'offer'

      -- Equal split expenses
      WHEN LOWER(money_flow) IN ('carlucci -> /2', 'pit -> /2') THEN 'equal'

      -- Lend expenses (one person advances for both)
      WHEN LOWER(money_flow) IN ('pit -> carl', 'carl -> pit') THEN 'lend'

      -- Default fallback
      ELSE 'offer'
    END,
    paid_by = CASE
      -- Carlucci paid
      WHEN LOWER(money_flow) IN ('carlucci', 'carlucci -> /2', 'carl -> pit') THEN carlucci_user_id

      -- Pit paid
      WHEN LOWER(money_flow) IN ('pit', 'pit -> /2', 'pit -> carl') THEN pit_user_id

      -- Default: original user_id (fallback)
      ELSE user_id
    END
  WHERE
    group_id IS NULL;  -- Only migrate personal expenses

  GET DIAGNOSTICS migrated_count = ROW_COUNT;
  RAISE NOTICE '✅ Migrated % expenses to group', migrated_count;
  RAISE NOTICE '';

  -- ========================================
  -- STEP 3: Create Expense Splits
  -- ========================================

  RAISE NOTICE 'Step 3: Creating expense splits...';

  -- For split_type = 'equal': create splits for both members
  INSERT INTO expense_splits (expense_id, user_id, amount, is_paid)
  SELECT
    e.id,
    gm.user_id,
    ROUND(CAST(e.amount / 2.0 AS numeric), 2) as split_amount,
    (gm.user_id = e.paid_by) as is_paid
  FROM expenses e
  CROSS JOIN group_members gm
  WHERE
    e.group_id = target_group_id
    AND gm.group_id = target_group_id
    AND e.split_type = 'equal'
    AND NOT EXISTS (
      SELECT 1 FROM expense_splits es WHERE es.expense_id = e.id
    );

  GET DIAGNOSTICS splits_created_count = ROW_COUNT;
  RAISE NOTICE '✅ Created % splits for "equal" expenses', splits_created_count;

  -- For split_type = 'lend': create split only for the person who must pay back
  INSERT INTO expense_splits (expense_id, user_id, amount, is_paid)
  SELECT
    e.id,
    CASE
      WHEN e.paid_by = pit_user_id THEN carlucci_user_id  -- Pit paid, Carlucci owes
      WHEN e.paid_by = carlucci_user_id THEN pit_user_id  -- Carlucci paid, Pit owes
      ELSE NULL  -- Should not happen
    END as debtor_user_id,
    ROUND(CAST(e.amount / 2.0 AS numeric), 2) as split_amount,  -- Each person owes half
    false as is_paid  -- Debtor hasn't paid yet
  FROM expenses e
  WHERE
    e.group_id = target_group_id
    AND e.split_type = 'lend'
    AND NOT EXISTS (
      SELECT 1 FROM expense_splits es WHERE es.expense_id = e.id
    );

  GET DIAGNOSTICS splits_created_count = ROW_COUNT;
  RAISE NOTICE '✅ Created % splits for "lend" expenses', splits_created_count;

  -- For split_type = 'offer': no splits needed (personal expense)
  RAISE NOTICE 'ℹ️  "offer" expenses have no splits (personal expenses)';
  RAISE NOTICE '';

  -- ========================================
  -- STEP 4: Verification
  -- ========================================

  RAISE NOTICE 'Step 4: Verification...';

  RAISE NOTICE 'Migrated expenses by split_type:';
  FOR rec IN (
    SELECT split_type, COUNT(*) as cnt
    FROM expenses
    WHERE group_id = target_group_id
    GROUP BY split_type
    ORDER BY cnt DESC
  ) LOOP
    RAISE NOTICE '  - %: % expenses', rec.split_type, rec.cnt;
  END LOOP;

  RAISE NOTICE 'Total expense splits created: %',
    (SELECT COUNT(*) FROM expense_splits es
     JOIN expenses e ON e.id = es.expense_id
     WHERE e.group_id = target_group_id);

  RAISE NOTICE '';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Migration Complete!';
  RAISE NOTICE '========================================';
  RAISE NOTICE '⚠️  Run verification queries below to confirm';

END $$;

-- ========================================
-- VERIFICATION QUERIES
-- ========================================

-- 1. Check all migrated expenses
SELECT
  id,
  description,
  amount,
  date,
  money_flow as original_money_flow,
  split_type,
  CASE
    WHEN paid_by = '09ace514-a951-4936-afd6-468504075542' THEN 'Pit'
    WHEN paid_by = '821db3d9-f450-4c48-8844-1d649ab399ad' THEN 'Carlucci'
    ELSE 'Unknown'
  END as paid_by_name
FROM expenses
WHERE group_id = '1775bead-b76c-49c8-b8d7-620cba2758c4'
ORDER BY date DESC
LIMIT 20;

-- 2. Check expense splits with names
SELECT
  e.id,
  e.description,
  e.amount as total_amount,
  e.split_type,
  CASE
    WHEN e.paid_by = '09ace514-a951-4936-afd6-468504075542' THEN 'Pit'
    WHEN e.paid_by = '821db3d9-f450-4c48-8844-1d649ab399ad' THEN 'Carlucci'
  END as payer,
  es.user_id,
  CASE
    WHEN es.user_id = '09ace514-a951-4936-afd6-468504075542' THEN 'Pit'
    WHEN es.user_id = '821db3d9-f450-4c48-8844-1d649ab399ad' THEN 'Carlucci'
  END as debtor,
  es.amount as split_amount,
  es.is_paid
FROM expenses e
LEFT JOIN expense_splits es ON es.expense_id = e.id
WHERE e.group_id = '1775bead-b76c-49c8-b8d7-620cba2758c4'
ORDER BY e.date DESC, e.id, es.user_id
LIMIT 50;

-- 3. Verify split totals (should have no discrepancies)
SELECT
  e.id,
  e.description,
  e.amount as total_amount,
  e.split_type,
  COALESCE(SUM(es.amount), 0) as splits_total,
  e.amount - COALESCE(SUM(es.amount), 0) as difference,
  CASE
    WHEN e.split_type = 'offer' THEN 'OK (no splits expected)'
    WHEN e.split_type = 'equal' AND COUNT(es.id) = 2 THEN 'OK (2 splits)'
    WHEN e.split_type = 'lend' AND COUNT(es.id) = 1 THEN 'OK (1 split)'
    ELSE 'CHECK!'
  END as status
FROM expenses e
LEFT JOIN expense_splits es ON es.expense_id = e.id
WHERE e.group_id = '1775bead-b76c-49c8-b8d7-620cba2758c4'
GROUP BY e.id, e.description, e.amount, e.split_type
HAVING
  (e.split_type != 'offer' AND ABS(e.amount - COALESCE(SUM(es.amount), 0)) > 0.01)
  OR (e.split_type = 'equal' AND COUNT(es.id) != 2)
  OR (e.split_type = 'lend' AND COUNT(es.id) != 1)
ORDER BY difference DESC;

-- 4. Summary statistics
SELECT
  split_type,
  COUNT(*) as expense_count,
  SUM(amount) as total_amount,
  ROUND(AVG(amount), 2) as avg_amount
FROM expenses
WHERE group_id = '1775bead-b76c-49c8-b8d7-620cba2758c4'
GROUP BY split_type
ORDER BY expense_count DESC;

-- 5. Check for any remaining personal expenses (should be 0)
SELECT COUNT(*) as remaining_personal_expenses
FROM expenses
WHERE group_id IS NULL
  AND user_id IN ('09ace514-a951-4936-afd6-468504075542', '821db3d9-f450-4c48-8844-1d649ab399ad');

-- ========================================
-- ROLLBACK (if needed)
-- ========================================

/*
-- To rollback the migration:

BEGIN;

-- 1. Delete created expense splits
DELETE FROM expense_splits
WHERE expense_id IN (
  SELECT id FROM expenses WHERE group_id = '1775bead-b76c-49c8-b8d7-620cba2758c4'
);

-- 2. Revert expenses to personal
UPDATE expenses
SET
  group_id = NULL,
  paid_by = NULL,
  split_type = NULL
WHERE group_id = '1775bead-b76c-49c8-b8d7-620cba2758c4';

-- 3. Verify rollback
SELECT COUNT(*) as personal_expenses FROM expenses WHERE group_id IS NULL;
SELECT COUNT(*) as group_expenses FROM expenses WHERE group_id = '1775bead-b76c-49c8-b8d7-620cba2758c4';

COMMIT;  -- Or ROLLBACK if something is wrong
*/

-- ========================================
-- MAPPING REFERENCE
-- ========================================

/*
MoneyFlow → Split Type Mapping:

Original MoneyFlow       | Split Type | Paid By   | Description
-------------------------|------------|-----------|----------------------------------
"carlucci"               | offer      | Carlucci  | Personal expense (Carlucci only)
"pit"                    | offer      | Pit       | Personal expense (Pit only)
"carlucci -> /2"         | equal      | Carlucci  | Carlucci paid, split equally
"pit -> /2"              | equal      | Pit       | Pit paid, split equally
"pit -> carl"            | lend       | Pit       | Pit paid, Carlucci must reimburse
"carl -> pit"            | lend       | Carlucci  | Carlucci paid, Pit must reimburse

Split Creation Rules:

- offer:  NO splits (personal expense, no reimbursement)
- equal:  2 splits (one per member, amount/2 each, payer marked is_paid=true)
- lend:   1 split (only debtor, amount/2, is_paid=false)

Examples:

1. Expense: "Pizza 50€", money_flow="carlucci -> /2"
   → split_type='equal', paid_by=Carlucci
   → Splits:
      - Carlucci: 25€, is_paid=true
      - Pit: 25€, is_paid=false

2. Expense: "Cinema 20€", money_flow="pit -> carl"
   → split_type='lend', paid_by=Pit
   → Splits:
      - Carlucci: 10€, is_paid=false  (Carlucci owes Pit 10€)

3. Expense: "Benzina 60€", money_flow="pit"
   → split_type='offer', paid_by=Pit
   → Splits: NONE (personal expense)
*/
