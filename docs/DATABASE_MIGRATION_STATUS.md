# Database Migration Status

# Ciao Carlucci questo è un sync problem

## ✅ Migration Script Ready: v2

**File**: `supabase/migrations/001_multi_user_setup_v2.sql`

This version fixes the infinite recursion error by using non-recursive RLS policies.

## Quick Test After Migration

Run this SQL in Supabase SQL Editor to verify everything works:

```sql
-- 1. Check all tables exist
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_name IN ('profiles', 'groups', 'group_members', 'group_invites', 'expense_splits');

-- 2. Check expenses table has new columns
SELECT column_name
FROM information_schema.columns
WHERE table_name = 'expenses'
AND column_name IN ('group_id', 'paid_by', 'split_type', 'split_data');

-- 3. Check RLS is enabled
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
AND tablename IN ('profiles', 'groups', 'group_members', 'group_invites', 'expense_splits', 'expenses');

-- 4. Check policies exist (should return 20+ policies)
SELECT schemaname, tablename, policyname
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- 5. Check trigger exists
SELECT trigger_name, event_manipulation, event_object_table
FROM information_schema.triggers
WHERE trigger_schema = 'public'
AND trigger_name = 'on_auth_user_created';
```

Expected results:

- 5 tables found (profiles, groups, group_members, group_invites, expense_splits)
- 4 new columns in expenses table
- All 6 tables have `rowsecurity = true`
- 20+ policies listed
- 1 trigger on auth.users

## What's Next

Once migration is verified, we proceed to **Phase 3A: Update ProfilePage UI** to show:

- User nickname
- Edit nickname form
- List of user groups
- Badge for pending invites

This will be the first user-facing feature of the multi-user system!
