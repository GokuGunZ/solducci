-- =====================================================
-- FIX EXPENSE_SPLITS: Rename 'paid' to 'is_paid'
-- =====================================================
-- Fix: Il modello ExpenseSplit usa 'is_paid' ma il DB ha 'paid'
-- =====================================================

-- Rinomina la colonna 'paid' in 'is_paid'
DO $$
BEGIN
  -- Check if column 'paid' exists and 'is_paid' doesn't
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'expense_splits' AND column_name = 'paid'
  ) AND NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'expense_splits' AND column_name = 'is_paid'
  ) THEN
    ALTER TABLE expense_splits RENAME COLUMN paid TO is_paid;
    RAISE NOTICE 'Column renamed: paid -> is_paid';
  ELSIF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'expense_splits' AND column_name = 'is_paid'
  ) THEN
    RAISE NOTICE 'Column is_paid already exists, skipping';
  ELSE
    RAISE NOTICE 'Column paid does not exist, adding is_paid';
    ALTER TABLE expense_splits ADD COLUMN is_paid BOOLEAN DEFAULT FALSE;
  END IF;

  -- Ensure paid_at column exists (for future use)
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'expense_splits' AND column_name = 'paid_at'
  ) THEN
    ALTER TABLE expense_splits ADD COLUMN paid_at TIMESTAMPTZ;
    RAISE NOTICE 'Column paid_at added';
  END IF;
END $$;

-- =====================================================
-- FIX COMPLETE ✅
-- =====================================================
-- Le colonne ora corrispondono al modello Dart:
-- - is_paid (BOOLEAN)
-- - paid_at (TIMESTAMPTZ)
-- =====================================================
