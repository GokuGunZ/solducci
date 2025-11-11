-- =====================================================
-- ROLLBACK SCRIPT for Multi-User Migration
-- Use this ONLY if you need to undo the migration
-- =====================================================
-- WARNING: This will delete all groups, invites, and splits!
-- Expenses data will be preserved but group associations will be lost.
-- =====================================================

-- Drop helper functions
DROP FUNCTION IF EXISTS calculate_group_debts(UUID);
DROP FUNCTION IF EXISTS get_user_groups(UUID);

-- Drop trigger and function
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS handle_new_user();

-- Drop tables in reverse dependency order
DROP TABLE IF EXISTS expense_splits CASCADE;
DROP TABLE IF EXISTS group_invites CASCADE;
DROP TABLE IF EXISTS group_members CASCADE;
DROP TABLE IF EXISTS groups CASCADE;
DROP TABLE IF EXISTS profiles CASCADE;

-- Remove columns from expenses table
ALTER TABLE expenses
  DROP COLUMN IF EXISTS split_data,
  DROP COLUMN IF EXISTS split_type,
  DROP COLUMN IF EXISTS paid_by,
  DROP COLUMN IF EXISTS group_id;

-- Note: Old RLS policies will need to be recreated manually
-- if you had custom policies before this migration

-- =====================================================
-- ROLLBACK COMPLETE
-- =====================================================
