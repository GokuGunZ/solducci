-- =====================================================
-- FIX EXPENSES ID CONSTRAINT ISSUE
-- =====================================================
-- This script fixes the duplicate key constraint error
-- when inserting new expenses
-- =====================================================

-- Step 1: Check current constraints on expenses table
SELECT conname, contype, pg_get_constraintdef(oid) as definition
FROM pg_constraint
WHERE conrelid = 'expenses'::regclass;

-- Step 2: Check the current sequence value
SELECT last_value FROM expenses_id_seq;

-- Step 3: Check the max ID in the table
SELECT MAX(id) FROM expenses;

-- Step 4: Fix the foreign key dependency and constraint
-- The foreign key is using the UNIQUE constraint instead of the PRIMARY KEY
DO $$
BEGIN
  -- First, drop the foreign key constraint that depends on the UNIQUE index
  IF EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'expense_splits_expense_id_fkey'
    AND conrelid = 'expense_splits'::regclass
  ) THEN
    ALTER TABLE expense_splits DROP CONSTRAINT expense_splits_expense_id_fkey;
    RAISE NOTICE 'Dropped foreign key: expense_splits_expense_id_fkey';
  END IF;

  -- Now drop the problematic unique constraint
  IF EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'expenses_id_key'
    AND contype = 'u'  -- 'u' means UNIQUE constraint
    AND conrelid = 'expenses'::regclass
  ) THEN
    ALTER TABLE expenses DROP CONSTRAINT expenses_id_key CASCADE;
    RAISE NOTICE 'Dropped duplicate UNIQUE constraint: expenses_id_key';
  END IF;

  -- Recreate the foreign key pointing to the PRIMARY KEY instead
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'expense_splits_expense_id_fkey'
    AND conrelid = 'expense_splits'::regclass
  ) THEN
    ALTER TABLE expense_splits
      ADD CONSTRAINT expense_splits_expense_id_fkey
      FOREIGN KEY (expense_id)
      REFERENCES expenses(id)
      ON DELETE CASCADE;
    RAISE NOTICE 'Recreated foreign key pointing to PRIMARY KEY';
  END IF;
END $$;

-- Step 5: Reset the sequence to the correct value
-- This ensures the next auto-generated ID won't conflict
SELECT setval('expenses_id_seq', COALESCE((SELECT MAX(id) FROM expenses), 1), true);

-- Step 6: Verify the fix
SELECT
  'Sequence current value: ' || last_value as info
FROM expenses_id_seq
UNION ALL
SELECT
  'Max ID in table: ' || COALESCE(MAX(id)::text, 'NULL')
FROM expenses
UNION ALL
SELECT
  'Constraints on expenses: ' || string_agg(conname, ', ')
FROM pg_constraint
WHERE conrelid = 'expenses'::regclass;

-- =====================================================
-- DONE!
-- =====================================================
-- After running this script:
-- 1. The duplicate UNIQUE constraint should be removed
-- 2. The sequence should be synchronized with the table
-- 3. New inserts should work correctly
-- =====================================================
