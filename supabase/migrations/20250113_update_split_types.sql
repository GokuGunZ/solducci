-- Migration: Update split_type enum values
-- Date: 2025-01-13
-- Description: Rename 'full' → 'lend' and 'none' → 'offer'

-- ========================================
-- 1. Drop existing constraint
-- ========================================

ALTER TABLE expenses
DROP CONSTRAINT IF EXISTS expenses_split_type_check;

-- ========================================
-- 2. Add new constraint with updated values
-- ========================================

ALTER TABLE expenses
ADD CONSTRAINT expenses_split_type_check
CHECK (split_type IN ('equal', 'custom', 'lend', 'offer'));

-- ========================================
-- 3. Update existing data (if any exists with old values)
-- ========================================

-- Update 'full' → 'lend'
UPDATE expenses
SET split_type = 'lend'
WHERE split_type = 'full';

-- Update 'none' → 'offer'
UPDATE expenses
SET split_type = 'offer'
WHERE split_type = 'none';

-- ========================================
-- 4. Verification
-- ========================================

-- This query should return 0 rows (no old values remain)
-- SELECT COUNT(*) FROM expenses WHERE split_type IN ('full', 'none');

-- This query shows the constraint
-- SELECT conname, pg_get_constraintdef(oid) FROM pg_constraint WHERE conname = 'expenses_split_type_check';
