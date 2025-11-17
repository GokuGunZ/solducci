-- Add DELETE policy for expense_splits
-- This allows deleting splits when updating/deleting expenses

DROP POLICY IF EXISTS "Users can delete splits" ON expense_splits;

-- Allow deleting splits
-- We allow deletion because:
-- 1. Splits are recalculated when expense is updated
-- 2. Splits are deleted when expense is deleted (CASCADE)
-- 3. App logic controls when splits should be deleted
CREATE POLICY "Users can delete splits"
  ON expense_splits FOR DELETE
  USING (true);

-- Verify the policy was created
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
    AND tablename = 'expense_splits'
    AND policyname = 'Users can delete splits'
  ) THEN
    RAISE NOTICE 'DELETE policy created successfully for expense_splits';
  ELSE
    RAISE EXCEPTION 'Failed to create DELETE policy for expense_splits';
  END IF;
END $$;
