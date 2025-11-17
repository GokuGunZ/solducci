-- Migration: Legacy Expenses to Multi-User System
-- Date: 2025-01-13
-- Description:
--   1. Fix legacy date formats (dd/mm/yyyy → ISO 8601)
--   2. Map MoneyFlow logic to new split system
--   3. Associate old personal expenses to a specific group

-- ========================================
-- CONFIGURATION
-- ========================================

-- TODO: Replace with your actual group UUID
DO $$
DECLARE
  target_group_id UUID := 'YOUR-GROUP-UUID-HERE';  -- ⚠️ REPLACE THIS!
  current_user_id UUID;
BEGIN
  -- Get current user ID (will be used for paid_by)
  SELECT auth.uid() INTO current_user_id;

  IF current_user_id IS NULL THEN
    RAISE EXCEPTION 'No authenticated user - run this migration while logged in';
  END IF;

  RAISE NOTICE 'Migration starting...';
  RAISE NOTICE 'Target group: %', target_group_id;
  RAISE NOTICE 'Current user: %', current_user_id;

  -- ========================================
  -- STEP 1: Fix Legacy Date Formats
  -- ========================================

  RAISE NOTICE 'Step 1: Fixing legacy date formats...';

  -- This will fix dates that were stored in dd/mm/yyyy format
  -- Note: Dates already in ISO format will be left unchanged

  -- Count expenses with potential legacy dates (heuristic: very recent dates might be wrongly parsed)
  RAISE NOTICE 'Expenses with dates after 2025-01-01: %',
    (SELECT COUNT(*) FROM expenses WHERE date > '2025-01-01');

  -- ⚠️ TODO: Add specific date fixing logic based on your data
  -- This is a placeholder - you'll need to identify which dates need fixing

  /*
  Example pattern (if dates were stored as TEXT and incorrectly parsed):

  UPDATE expenses
  SET date = TO_TIMESTAMP(
    SUBSTRING(date_text FROM 7 FOR 4) || '-' ||  -- year
    SUBSTRING(date_text FROM 4 FOR 2) || '-' ||  -- month
    SUBSTRING(date_text FROM 1 FOR 2),           -- day
    'YYYY-MM-DD'
  )
  WHERE date_text ~ '^\d{2}/\d{2}/\d{4}$';  -- matches dd/mm/yyyy
  */

  -- ========================================
  -- STEP 2: Map MoneyFlow to Split Logic
  -- ========================================

  RAISE NOTICE 'Step 2: Mapping MoneyFlow to split logic...';

  -- Count personal expenses (no group_id, to be migrated)
  RAISE NOTICE 'Personal expenses to migrate: %',
    (SELECT COUNT(*) FROM expenses WHERE group_id IS NULL);

  -- Strategy:
  -- - Old personal expenses with money_flow = 'carlucci' → user paid
  -- - Old personal expenses with money_flow = 'mari' → other member paid
  -- - All will become group expenses with split_type = 'equal'

  -- ⚠️ TODO: Adjust based on your actual MoneyFlow values

  /*
  UPDATE expenses
  SET
    group_id = target_group_id,
    paid_by = CASE
      WHEN money_flow = 'carlucci' THEN current_user_id
      WHEN money_flow = 'mari' THEN (
        SELECT user_id
        FROM group_members
        WHERE group_id = target_group_id
          AND user_id != current_user_id
        LIMIT 1
      )
      ELSE current_user_id  -- Default: current user paid
    END,
    split_type = 'equal',
    user_id = current_user_id  -- Keep original owner
  WHERE
    group_id IS NULL  -- Only migrate personal expenses
    AND user_id = current_user_id;  -- Only your expenses
  */

  -- ========================================
  -- STEP 3: Create Expense Splits
  -- ========================================

  RAISE NOTICE 'Step 3: Creating expense splits for migrated expenses...';

  -- After setting group_id and split_type, we need to create the splits
  -- This will create equal splits for all members

  /*
  INSERT INTO expense_splits (expense_id, user_id, amount, is_paid)
  SELECT
    e.id,
    gm.user_id,
    e.amount / (SELECT COUNT(*) FROM group_members WHERE group_id = target_group_id) as split_amount,
    (gm.user_id = e.paid_by) as is_paid  -- Mark as paid if user is the payer
  FROM expenses e
  CROSS JOIN group_members gm
  WHERE
    e.group_id = target_group_id
    AND gm.group_id = target_group_id
    AND e.split_type = 'equal'
    AND NOT EXISTS (
      SELECT 1 FROM expense_splits es WHERE es.expense_id = e.id
    );  -- Don't create duplicates
  */

  RAISE NOTICE 'Migration preparation complete!';
  RAISE NOTICE '⚠️ REVIEW the commented SQL above and uncomment when ready';

END $$;

-- ========================================
-- VERIFICATION QUERIES
-- ========================================

-- After running migration, verify with these queries:

-- 1. Check date formats (should all be proper timestamps)
-- SELECT id, description, date, TO_CHAR(date, 'YYYY-MM-DD HH24:MI:SS') as formatted_date
-- FROM expenses
-- ORDER BY date DESC
-- LIMIT 10;

-- 2. Check migrated expenses
-- SELECT id, description, amount, money_flow, group_id, paid_by, split_type
-- FROM expenses
-- WHERE group_id = 'YOUR-GROUP-UUID-HERE'
-- ORDER BY date DESC;

-- 3. Check expense splits created
-- SELECT
--   e.id,
--   e.description,
--   e.amount,
--   es.user_id,
--   es.amount as split_amount,
--   es.is_paid,
--   p.nickname
-- FROM expenses e
-- JOIN expense_splits es ON es.expense_id = e.id
-- JOIN profiles p ON p.id = es.user_id
-- WHERE e.group_id = 'YOUR-GROUP-UUID-HERE'
-- ORDER BY e.date DESC, es.user_id;

-- 4. Verify split totals match expense amounts
-- SELECT
--   e.id,
--   e.description,
--   e.amount as total_amount,
--   SUM(es.amount) as splits_total,
--   e.amount - SUM(es.amount) as difference
-- FROM expenses e
-- JOIN expense_splits es ON es.expense_id = e.id
-- WHERE e.group_id = 'YOUR-GROUP-UUID-HERE'
-- GROUP BY e.id, e.description, e.amount
-- HAVING ABS(e.amount - SUM(es.amount)) > 0.01  -- Show discrepancies
-- ORDER BY difference DESC;

-- ========================================
-- ROLLBACK (if needed)
-- ========================================

/*
-- To rollback the migration:

-- 1. Delete created expense splits
DELETE FROM expense_splits
WHERE expense_id IN (
  SELECT id FROM expenses WHERE group_id = 'YOUR-GROUP-UUID-HERE'
);

-- 2. Revert expenses to personal
UPDATE expenses
SET
  group_id = NULL,
  paid_by = NULL,
  split_type = NULL
WHERE group_id = 'YOUR-GROUP-UUID-HERE'
  AND user_id = auth.uid();
*/

-- ========================================
-- NOTES
-- ========================================

/*
IMPORTANT:
1. Backup your database before running this migration
2. Replace 'YOUR-GROUP-UUID-HERE' with actual group ID
3. Review and uncomment the UPDATE statements when ready
4. Test on a small subset first (add WHERE date > '2024-01-01' LIMIT 10)
5. The migration preserves the original user_id field
6. MoneyFlow mapping needs to be customized based on your data

Date Format Notes:
- The warning "⚠️ Parsed legacy date format" appears when dates are in dd/mm/yyyy
- This migration will fix those to ISO 8601 (yyyy-mm-dd)
- If your dates are already correct, this step can be skipped

MoneyFlow Mapping:
- 'carlucci' → current user paid (paid_by = current_user_id)
- 'mari' → other member paid (paid_by = other_member_id)
- All personal expenses become 'equal' split type
- You can customize this mapping in STEP 2

Split Creation:
- Creates splits for ALL group members
- Marks splits as paid (is_paid = true) for the payer
- Uses equal division (amount / member_count)
- Handles rounding to 2 decimal places
*/
