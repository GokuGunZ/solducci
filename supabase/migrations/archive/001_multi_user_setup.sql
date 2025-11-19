-- =====================================================
-- SOLDUCCI MULTI-USER MIGRATION
-- Fase 1: Database Setup
-- =====================================================
-- Esegui questo script nel SQL Editor di Supabase
-- =====================================================

-- =====================================================
-- 1. PROFILES TABLE (User Profile)
-- =====================================================
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL UNIQUE,
  nickname TEXT NOT NULL DEFAULT 'Utente',
  avatar_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- RLS Policies for profiles
CREATE POLICY "Users can view all profiles"
  ON profiles FOR SELECT
  USING (true);  -- Tutti possono vedere i profili (per nickname nei gruppi)

CREATE POLICY "Users can view their own profile details"
  ON profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id);

CREATE POLICY "Users can insert their own profile"
  ON profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

-- Index for performance
CREATE INDEX IF NOT EXISTS idx_profiles_email ON profiles(email);

COMMENT ON TABLE profiles IS 'User profiles with nickname and avatar';

-- =====================================================
-- 2. GROUPS TABLE (Gruppi/Coppie)
-- =====================================================
CREATE TABLE IF NOT EXISTS groups (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  created_by UUID REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE groups ENABLE ROW LEVEL SECURITY;

-- RLS Policies for groups
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

COMMENT ON TABLE groups IS 'Expense groups (couples, roommates, etc.)';

-- =====================================================
-- 3. GROUP_MEMBERS TABLE (Membri dei Gruppi)
-- =====================================================
CREATE TABLE IF NOT EXISTS group_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID REFERENCES groups(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  role TEXT DEFAULT 'member' CHECK (role IN ('admin', 'member')),
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(group_id, user_id)  -- Un utente può essere in un gruppo una sola volta
);

-- Enable Row Level Security
ALTER TABLE group_members ENABLE ROW LEVEL SECURITY;

-- RLS Policies for group_members
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

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_group_members_group_id ON group_members(group_id);
CREATE INDEX IF NOT EXISTS idx_group_members_user_id ON group_members(user_id);

COMMENT ON TABLE group_members IS 'Members of expense groups';

-- =====================================================
-- 4. GROUP_INVITES TABLE (Inviti ai Gruppi)
-- =====================================================
CREATE TABLE IF NOT EXISTS group_invites (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID REFERENCES groups(id) ON DELETE CASCADE,
  inviter_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  invitee_email TEXT NOT NULL,
  invitee_id UUID REFERENCES profiles(id) ON DELETE SET NULL,  -- NULL se non ancora registrato
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected', 'expired')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '7 days'),
  responded_at TIMESTAMPTZ
);

-- Enable Row Level Security
ALTER TABLE group_invites ENABLE ROW LEVEL SECURITY;

-- RLS Policies for group_invites
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

-- Index for performance
CREATE INDEX IF NOT EXISTS idx_group_invites_email ON group_invites(invitee_email);
CREATE INDEX IF NOT EXISTS idx_group_invites_status ON group_invites(status);

COMMENT ON TABLE group_invites IS 'Invitations to join expense groups';

-- =====================================================
-- 5. MODIFY EXPENSES TABLE (Add Multi-User Support)
-- =====================================================

-- Add new columns to existing expenses table
ALTER TABLE expenses
  ADD COLUMN IF NOT EXISTS group_id UUID REFERENCES groups(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS paid_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS split_type TEXT DEFAULT 'equal' CHECK (split_type IN ('equal', 'custom', 'full', 'none')),
  ADD COLUMN IF NOT EXISTS split_data JSONB;

-- Update RLS for expenses (DROP old policies if they exist)
DROP POLICY IF EXISTS "Users can view expenses in their groups" ON expenses;
DROP POLICY IF EXISTS "Users can create expenses in their groups" ON expenses;
DROP POLICY IF EXISTS "Users can update their own expenses" ON expenses;
DROP POLICY IF EXISTS "Users can delete their own expenses" ON expenses;

-- Enable RLS if not already enabled
ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;

-- New RLS Policies for expenses
CREATE POLICY "Users can view their own expenses"
  ON expenses FOR SELECT
  USING (
    -- Spese personali (user_id corrisponde)
    user_id = auth.uid()::text
    OR
    -- Spese di gruppo (utente è membro del gruppo)
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

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_expenses_user_id ON expenses(user_id);
CREATE INDEX IF NOT EXISTS idx_expenses_group_id ON expenses(group_id);
CREATE INDEX IF NOT EXISTS idx_expenses_paid_by ON expenses(paid_by);

-- =====================================================
-- 6. EXPENSE_SPLITS TABLE (Divisioni Spese)
-- =====================================================
CREATE TABLE IF NOT EXISTS expense_splits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  expense_id INT REFERENCES expenses(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  amount NUMERIC(10, 2) NOT NULL CHECK (amount >= 0),
  paid BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  paid_at TIMESTAMPTZ
);

-- Enable Row Level Security
ALTER TABLE expense_splits ENABLE ROW LEVEL SECURITY;

-- RLS Policies for expense_splits
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

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_expense_splits_expense_id ON expense_splits(expense_id);
CREATE INDEX IF NOT EXISTS idx_expense_splits_user_id ON expense_splits(user_id);

COMMENT ON TABLE expense_splits IS 'Expense split details for group expenses';

-- =====================================================
-- 7. TRIGGER: Auto-create profile on user signup
-- =====================================================

-- Function to create profile automatically
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

-- Drop trigger if exists
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Create trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

COMMENT ON FUNCTION handle_new_user IS 'Automatically creates a profile when a new user signs up';

-- =====================================================
-- 8. HELPER FUNCTIONS
-- =====================================================

-- Function to get user's groups
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

-- Function to calculate group debts
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
-- 9. SAMPLE DATA (Optional - for testing)
-- =====================================================
-- Uncomment to create sample data after first user signup

-- INSERT INTO groups (id, name, created_by) VALUES
--   ('00000000-0000-0000-0000-000000000001', 'Casa Condivisa', (SELECT id FROM profiles LIMIT 1));

-- INSERT INTO group_members (group_id, user_id, role) VALUES
--   ('00000000-0000-0000-0000-000000000001', (SELECT id FROM profiles LIMIT 1), 'admin');

-- =====================================================
-- 10. GRANTS (Ensure proper permissions)
-- =====================================================
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO anon, authenticated;

-- =====================================================
-- MIGRATION COMPLETE
-- =====================================================
-- Next steps:
-- 1. Run this script in Supabase SQL Editor
-- 2. Verify tables were created: Check "Table Editor" in Supabase Dashboard
-- 3. Test RLS: Try querying tables as authenticated user
-- 4. Create first profile: Sign up in the app
-- =====================================================
