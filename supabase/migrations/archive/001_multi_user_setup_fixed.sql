-- =====================================================
-- SOLDUCCI MULTI-USER MIGRATION (FIXED)
-- Fase 1: Database Setup
-- =====================================================
-- FIXED: Tutte le tabelle create PRIMA, poi RLS policies
-- =====================================================

-- =====================================================
-- STEP 1: CREATE ALL TABLES (without RLS)
-- =====================================================

-- 1. PROFILES TABLE
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL UNIQUE,
  nickname TEXT NOT NULL DEFAULT 'Utente',
  avatar_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_profiles_email ON profiles(email);
COMMENT ON TABLE profiles IS 'User profiles with nickname and avatar';

-- 2. GROUPS TABLE
CREATE TABLE IF NOT EXISTS groups (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  created_by UUID REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE groups IS 'Expense groups (couples, roommates, etc.)';

-- 3. GROUP_MEMBERS TABLE
CREATE TABLE IF NOT EXISTS group_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID REFERENCES groups(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  role TEXT DEFAULT 'member' CHECK (role IN ('admin', 'member')),
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(group_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_group_members_group_id ON group_members(group_id);
CREATE INDEX IF NOT EXISTS idx_group_members_user_id ON group_members(user_id);
COMMENT ON TABLE group_members IS 'Members of expense groups';

-- 4. GROUP_INVITES TABLE
CREATE TABLE IF NOT EXISTS group_invites (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID REFERENCES groups(id) ON DELETE CASCADE,
  inviter_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  invitee_email TEXT NOT NULL,
  invitee_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected', 'expired')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '7 days'),
  responded_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_group_invites_email ON group_invites(invitee_email);
CREATE INDEX IF NOT EXISTS idx_group_invites_status ON group_invites(status);
COMMENT ON TABLE group_invites IS 'Invitations to join expense groups';

-- 5. EXPENSE_SPLITS TABLE
CREATE TABLE IF NOT EXISTS expense_splits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  expense_id INT REFERENCES expenses(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  amount NUMERIC(10, 2) NOT NULL CHECK (amount >= 0),
  paid BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  paid_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_expense_splits_expense_id ON expense_splits(expense_id);
CREATE INDEX IF NOT EXISTS idx_expense_splits_user_id ON expense_splits(user_id);
COMMENT ON TABLE expense_splits IS 'Expense split details for group expenses';

-- 6. MODIFY EXPENSES TABLE (Add Multi-User Support)
DO $$
BEGIN
  -- Add columns only if they don't exist
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_name='expenses' AND column_name='group_id') THEN
    ALTER TABLE expenses ADD COLUMN group_id UUID REFERENCES groups(id) ON DELETE CASCADE;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_name='expenses' AND column_name='paid_by') THEN
    ALTER TABLE expenses ADD COLUMN paid_by UUID REFERENCES profiles(id) ON DELETE SET NULL;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_name='expenses' AND column_name='split_type') THEN
    ALTER TABLE expenses ADD COLUMN split_type TEXT DEFAULT 'equal' CHECK (split_type IN ('equal', 'custom', 'full', 'none'));
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_name='expenses' AND column_name='split_data') THEN
    ALTER TABLE expenses ADD COLUMN split_data JSONB;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_expenses_user_id ON expenses(user_id);
CREATE INDEX IF NOT EXISTS idx_expenses_group_id ON expenses(group_id);
CREATE INDEX IF NOT EXISTS idx_expenses_paid_by ON expenses(paid_by);

-- =====================================================
-- STEP 2: ENABLE RLS ON ALL TABLES
-- =====================================================

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_invites ENABLE ROW LEVEL SECURITY;
ALTER TABLE expense_splits ENABLE ROW LEVEL SECURITY;
ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- STEP 3: CREATE RLS POLICIES
-- =====================================================

-- PROFILES POLICIES
DROP POLICY IF EXISTS "Users can view all profiles" ON profiles;
DROP POLICY IF EXISTS "Users can view their own profile details" ON profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can insert their own profile" ON profiles;

CREATE POLICY "Users can view all profiles"
  ON profiles FOR SELECT
  USING (true);

CREATE POLICY "Users can update their own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id);

CREATE POLICY "Users can insert their own profile"
  ON profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

-- GROUPS POLICIES
DROP POLICY IF EXISTS "Users can view groups they belong to" ON groups;
DROP POLICY IF EXISTS "Users can create groups" ON groups;
DROP POLICY IF EXISTS "Group creators can update their groups" ON groups;
DROP POLICY IF EXISTS "Group creators can delete their groups" ON groups;

CREATE POLICY "Users can view groups they belong to"
  ON groups FOR SELECT
  USING (
    id IN (
      SELECT group_id FROM group_members WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Users can create groups"
  ON groups FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Group creators can update their groups"
  ON groups FOR UPDATE
  USING (created_by = auth.uid());

CREATE POLICY "Group creators can delete their groups"
  ON groups FOR DELETE
  USING (created_by = auth.uid());

-- GROUP_MEMBERS POLICIES
DROP POLICY IF EXISTS "Users can view members of their groups" ON group_members;
DROP POLICY IF EXISTS "Group admins can add members" ON group_members;
DROP POLICY IF EXISTS "Group admins can remove members" ON group_members;
DROP POLICY IF EXISTS "Users can leave groups" ON group_members;

CREATE POLICY "Users can view members of their groups"
  ON group_members FOR SELECT
  USING (
    group_id IN (
      SELECT group_id FROM group_members WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Group admins can add members"
  ON group_members FOR INSERT
  WITH CHECK (
    group_id IN (
      SELECT group_id FROM group_members
      WHERE user_id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "Group admins can remove members"
  ON group_members FOR DELETE
  USING (
    group_id IN (
      SELECT group_id FROM group_members
      WHERE user_id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "Users can leave groups"
  ON group_members FOR DELETE
  USING (user_id = auth.uid());

-- GROUP_INVITES POLICIES
DROP POLICY IF EXISTS "Users can view invites sent to them" ON group_invites;
DROP POLICY IF EXISTS "Group members can create invites" ON group_invites;
DROP POLICY IF EXISTS "Invitees can update their invites" ON group_invites;

CREATE POLICY "Users can view invites sent to them"
  ON group_invites FOR SELECT
  USING (
    invitee_email = (SELECT email FROM profiles WHERE id = auth.uid())
    OR inviter_id = auth.uid()
    OR group_id IN (
      SELECT group_id FROM group_members WHERE user_id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "Group members can create invites"
  ON group_invites FOR INSERT
  WITH CHECK (
    inviter_id = auth.uid()
    AND group_id IN (
      SELECT group_id FROM group_members WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Invitees can update their invites"
  ON group_invites FOR UPDATE
  USING (
    invitee_email = (SELECT email FROM profiles WHERE id = auth.uid())
    OR invitee_id = auth.uid()
  );

-- EXPENSE_SPLITS POLICIES
DROP POLICY IF EXISTS "Users can view splits of their expenses" ON expense_splits;
DROP POLICY IF EXISTS "Expense creators can create splits" ON expense_splits;
DROP POLICY IF EXISTS "Users can update their own splits" ON expense_splits;

CREATE POLICY "Users can view splits of their expenses"
  ON expense_splits FOR SELECT
  USING (
    user_id = auth.uid()
    OR expense_id IN (
      SELECT id FROM expenses WHERE
        user_id = auth.uid()::text
        OR group_id IN (
          SELECT group_id FROM group_members WHERE user_id = auth.uid()
        )
    )
  );

CREATE POLICY "Expense creators can create splits"
  ON expense_splits FOR INSERT
  WITH CHECK (
    expense_id IN (
      SELECT id FROM expenses WHERE
        user_id = auth.uid()::text
        OR paid_by = auth.uid()
    )
  );

CREATE POLICY "Users can update their own splits"
  ON expense_splits FOR UPDATE
  USING (user_id = auth.uid());

-- EXPENSES POLICIES
DROP POLICY IF EXISTS "Users can view their own expenses" ON expenses;
DROP POLICY IF EXISTS "Users can create personal expenses" ON expenses;
DROP POLICY IF EXISTS "Group members can create group expenses" ON expenses;
DROP POLICY IF EXISTS "Users can update their own expenses" ON expenses;
DROP POLICY IF EXISTS "Users can delete their own expenses" ON expenses;

CREATE POLICY "Users can view their own expenses"
  ON expenses FOR SELECT
  USING (
    user_id = auth.uid()::text
    OR
    group_id IN (
      SELECT group_id FROM group_members WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Users can create personal expenses"
  ON expenses FOR INSERT
  WITH CHECK (
    user_id = auth.uid()::text
    AND group_id IS NULL
  );

CREATE POLICY "Group members can create group expenses"
  ON expenses FOR INSERT
  WITH CHECK (
    group_id IN (
      SELECT group_id FROM group_members WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update their own expenses"
  ON expenses FOR UPDATE
  USING (
    user_id = auth.uid()::text
    OR
    (group_id IN (
      SELECT group_id FROM group_members WHERE user_id = auth.uid()
    ) AND paid_by = auth.uid())
  );

CREATE POLICY "Users can delete their own expenses"
  ON expenses FOR DELETE
  USING (
    user_id = auth.uid()::text
    OR
    (group_id IN (
      SELECT group_id FROM group_members WHERE user_id = auth.uid() AND role = 'admin'
    ))
  );

-- =====================================================
-- STEP 4: TRIGGER for Auto-create profile
-- =====================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, nickname)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'nickname', 'Utente')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

COMMENT ON FUNCTION handle_new_user IS 'Automatically creates a profile when a new user signs up';

-- =====================================================
-- STEP 5: HELPER FUNCTIONS
-- =====================================================

CREATE OR REPLACE FUNCTION get_user_groups(user_uuid UUID)
RETURNS TABLE (
  group_id UUID,
  group_name TEXT,
  role TEXT,
  member_count BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    g.id as group_id,
    g.name as group_name,
    gm.role,
    (SELECT COUNT(*) FROM group_members WHERE group_id = g.id) as member_count
  FROM groups g
  JOIN group_members gm ON g.id = gm.group_id
  WHERE gm.user_id = user_uuid
  ORDER BY gm.joined_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION calculate_group_debts(group_uuid UUID)
RETURNS TABLE (
  user_id UUID,
  user_nickname TEXT,
  balance NUMERIC(10, 2)
) AS $$
BEGIN
  RETURN QUERY
  WITH paid_amounts AS (
    SELECT
      e.paid_by as user_id,
      SUM(e.amount) as total_paid
    FROM expenses e
    WHERE e.group_id = group_uuid
      AND e.paid_by IS NOT NULL
    GROUP BY e.paid_by
  ),
  owed_amounts AS (
    SELECT
      es.user_id,
      SUM(es.amount) as total_owed
    FROM expense_splits es
    JOIN expenses e ON es.expense_id = e.id
    WHERE e.group_id = group_uuid
    GROUP BY es.user_id
  )
  SELECT
    COALESCE(pa.user_id, oa.user_id) as user_id,
    p.nickname as user_nickname,
    (COALESCE(pa.total_paid, 0) - COALESCE(oa.total_owed, 0)) as balance
  FROM paid_amounts pa
  FULL OUTER JOIN owed_amounts oa ON pa.user_id = oa.user_id
  JOIN profiles p ON COALESCE(pa.user_id, oa.user_id) = p.id
  ORDER BY balance DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- STEP 6: GRANTS
-- =====================================================

GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO anon, authenticated;

-- =====================================================
-- MIGRATION COMPLETE ✅
-- =====================================================
