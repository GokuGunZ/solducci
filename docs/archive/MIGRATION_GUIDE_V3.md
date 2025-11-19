# 🔧 Database Migration Guide V3

## ⚠️ Important: Migration V3 Changes

**Version 3** completely eliminates RLS policy recursion by:
1. Making RLS policies permissive (allow viewing all data)
2. Moving ALL filtering logic to the application layer
3. Using separate queries instead of JOINs in policy checks

This approach is **more performant** and **eliminates recursion errors**.

## 📋 Pre-Migration Checklist

- [ ] Backup your current database (Supabase Dashboard → Database → Backups)
- [ ] Close all app instances
- [ ] Have Supabase Dashboard open
- [ ] Read this guide completely before starting

## 🚀 Step 1: Apply Migration

### Option A: Via Supabase Dashboard (Recommended)

1. Go to Supabase Dashboard
2. Navigate to **SQL Editor**
3. Click **New Query**
4. Copy the entire content of `supabase/migrations/001_multi_user_setup_v3.sql`
5. Paste into the editor
6. Click **Run** (or press Cmd/Ctrl + Enter)

### Option B: Via Supabase CLI

```bash
# If you have Supabase CLI installed
supabase db push
```

## ✅ Step 2: Verify Migration

Run these queries in SQL Editor to verify everything was created:

### Check Tables Exist
```sql
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_name IN ('profiles', 'groups', 'group_members', 'group_invites', 'expense_splits');
```

**Expected**: 5 rows

### Check Expenses Columns Added
```sql
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'expenses'
AND column_name IN ('group_id', 'paid_by', 'split_type', 'split_data');
```

**Expected**: 4 rows

### Check RLS Enabled
```sql
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
AND tablename IN ('profiles', 'groups', 'group_members', 'group_invites', 'expense_splits', 'expenses');
```

**Expected**: All rows show `rowsecurity = true`

### Check Policies Created
```sql
SELECT tablename, policyname, cmd
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;
```

**Expected**: Multiple policies (15+) across all tables

### Check Trigger Exists
```sql
SELECT trigger_name, event_object_table, action_timing, event_manipulation
FROM information_schema.triggers
WHERE trigger_schema = 'public'
AND trigger_name = 'on_auth_user_created';
```

**Expected**: 1 row showing trigger on `auth.users` table

## 🧪 Step 3: Test with Current User

### Create Profile for Existing User (if needed)

If you already have a user account but no profile:

```sql
-- Replace 'your-user-id' with your actual auth.users id
-- Replace 'your@email.com' with your email
INSERT INTO profiles (id, email, nickname)
VALUES (
  'your-user-id'::uuid,
  'your@email.com',
  'Your Nickname'
)
ON CONFLICT (id) DO UPDATE SET
  nickname = EXCLUDED.nickname;
```

To find your user ID:
```sql
SELECT id, email FROM auth.users WHERE email = 'your@email.com';
```

### Verify Profile Created
```sql
SELECT * FROM profiles WHERE email = 'your@email.com';
```

## 🧪 Step 4: Test App Functionality

### Test 1: Profile Loading

1. **Start the app**: `flutter run`
2. **Login** with your account
3. **Navigate to Profile tab**
4. **Expected behavior**:
   - ✅ Profile loads without errors
   - ✅ Shows your nickname
   - ✅ Shows "Nessun gruppo" if you have no groups
   - ✅ No console errors about recursion

**If you see errors**, check console output and share the error message.

### Test 2: Edit Nickname

1. **In Profile tab**, click the **edit icon** next to nickname
2. **Change nickname** to something new
3. **Click "Salva"**
4. **Expected behavior**:
   - ✅ Shows "Nickname aggiornato!" snackbar
   - ✅ Nickname updates in UI
   - ✅ No errors in console

### Test 3: Create First Group

Run this SQL to create a test group:

```sql
-- Get your user ID first
SELECT id, email FROM auth.users WHERE email = 'your@email.com';

-- Replace 'your-user-id' with the ID from above
DO $$
DECLARE
  user_uuid UUID := 'your-user-id'::uuid;
  new_group_id UUID;
BEGIN
  -- Create group
  INSERT INTO groups (name, description, created_by)
  VALUES ('Test Gruppo', 'Gruppo di test', user_uuid)
  RETURNING id INTO new_group_id;

  -- Add creator as admin
  INSERT INTO group_members (group_id, user_id, role)
  VALUES (new_group_id, user_uuid, 'admin');

  RAISE NOTICE 'Group created with ID: %', new_group_id;
END $$;
```

**Then in app**:
1. **Pull down to refresh** in Profile tab
2. **Expected behavior**:
   - ✅ "Test Gruppo" appears in "I Miei Gruppi" section
   - ✅ Shows "1 membri"
   - ✅ No errors

### Test 4: Test Invite System

Create a test invite:

```sql
-- Get your user ID
SELECT id FROM auth.users WHERE email = 'your@email.com';

-- Get your test group ID
SELECT id FROM groups WHERE created_by = 'your-user-id'::uuid;

-- Create invite to yourself (for testing)
INSERT INTO group_invites (group_id, inviter_id, invitee_email)
VALUES (
  'your-group-id'::uuid,
  'your-user-id'::uuid,
  'your@email.com'
);
```

**Then in app**:
1. **Pull down to refresh** in Profile tab
2. **Expected behavior**:
   - ✅ Red "Inviti Pendenti" card appears
   - ✅ Shows "Hai 1 inviti in attesa"
   - ✅ No errors

## 🐛 Troubleshooting

### Error: "infinite recursion detected"

**Cause**: Old v2 policies still active

**Fix**:
```sql
-- Drop ALL old policies
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN (SELECT tablename, policyname FROM pg_policies WHERE schemaname = 'public')
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON %I', r.policyname, r.tablename);
  END LOOP;
END $$;

-- Then re-run the v3 migration
```

### Error: "Cannot coerce result to single JSON object"

**Cause**: No profile exists for user

**Fix**:
```sql
-- Manually create profile
INSERT INTO profiles (id, email, nickname)
SELECT id, email, 'Utente'
FROM auth.users
WHERE email = 'your@email.com'
ON CONFLICT (id) DO NOTHING;
```

### Error: "relation does not exist"

**Cause**: Tables not created

**Fix**: Re-run the migration script from Step 1

### Profile Loads but Groups Don't

**Debug query**:
```sql
-- Check if you have any groups
SELECT g.*, gm.role
FROM groups g
JOIN group_members gm ON g.id = gm.group_id
WHERE gm.user_id = 'your-user-id'::uuid;
```

If no results → You have no groups (expected for new user)

### Console Shows "ERROR loading groups"

**Check**:
1. Are you logged in? `_supabase.auth.currentUser` should not be null
2. Does your profile exist? Run: `SELECT * FROM profiles WHERE id = 'your-user-id'::uuid;`
3. Check browser console for detailed error

## 📊 Verify Data Integrity

After migration, run this comprehensive check:

```sql
-- Summary of all data
SELECT
  'profiles' as table_name, COUNT(*) as count FROM profiles
UNION ALL
SELECT 'groups', COUNT(*) FROM groups
UNION ALL
SELECT 'group_members', COUNT(*) FROM group_members
UNION ALL
SELECT 'group_invites', COUNT(*) FROM group_invites
UNION ALL
SELECT 'expense_splits', COUNT(*) FROM expense_splits
UNION ALL
SELECT 'expenses (with group_id)', COUNT(*) FROM expenses WHERE group_id IS NOT NULL;
```

## 🎯 Next Steps After Successful Migration

Once everything works:

1. **Test creating a group** via app (Phase 3B - Context Switcher)
2. **Test inviting another user** (Phase 3C - Group Management)
3. **Test creating group expenses** (Phase 3D - Expense Form)

## 🔄 Rollback (If Needed)

If something goes wrong and you want to rollback:

```sql
-- WARNING: This will delete all multi-user data!
DROP TABLE IF EXISTS expense_splits CASCADE;
DROP TABLE IF EXISTS group_invites CASCADE;
DROP TABLE IF EXISTS group_members CASCADE;
DROP TABLE IF EXISTS groups CASCADE;
DROP TABLE IF EXISTS profiles CASCADE;

-- Remove expenses columns
ALTER TABLE expenses DROP COLUMN IF EXISTS group_id;
ALTER TABLE expenses DROP COLUMN IF EXISTS paid_by;
ALTER TABLE expenses DROP COLUMN IF EXISTS split_type;
ALTER TABLE expenses DROP COLUMN IF EXISTS split_data;

-- Drop trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();
```

## 📝 Migration Checklist Summary

- [ ] Backup database
- [ ] Run v3 migration SQL
- [ ] Verify tables created (5 new tables)
- [ ] Verify expenses columns added (4 columns)
- [ ] Verify RLS enabled on all tables
- [ ] Verify policies created (15+)
- [ ] Verify trigger created
- [ ] Create/verify profile for current user
- [ ] Test app: Profile loads
- [ ] Test app: Edit nickname works
- [ ] Test app: Groups section visible
- [ ] (Optional) Create test group via SQL
- [ ] (Optional) Test invite system

## ✅ Success Indicators

You'll know the migration succeeded when:

1. ✅ App starts without console errors
2. ✅ Profile page loads and shows nickname
3. ✅ No "infinite recursion" errors
4. ✅ Groups section shows (even if empty)
5. ✅ Pull-to-refresh works
6. ✅ Edit nickname works

## 📞 Getting Help

If you encounter issues:

1. Check console output for specific error messages
2. Run verification queries from Step 2
3. Check [CURRENT_STATUS.md](CURRENT_STATUS.md) for system architecture
4. Share specific error messages for debugging

---

**Good luck with the migration! 🚀**
