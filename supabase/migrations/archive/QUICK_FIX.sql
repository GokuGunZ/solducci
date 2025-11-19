-- =====================================================
-- QUICK FIX: Reset + Migration V3 Completa
-- =====================================================
-- Esegui tutto questo file in UN COLPO SOLO
-- =====================================================

-- =====================================================
-- PARTE 1: RESET COMPLETO
-- =====================================================

-- Drop tutte le policy esistenti
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN (
    SELECT tablename, policyname
    FROM pg_policies
    WHERE schemaname = 'public'
    AND tablename IN ('profiles', 'groups', 'group_members', 'group_invites', 'expense_splits', 'expenses')
  )
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON %I', r.policyname, r.tablename);
  END LOOP;
END $$;

-- Drop trigger e functions
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();
DROP FUNCTION IF EXISTS get_user_groups(UUID);
DROP FUNCTION IF EXISTS calculate_group_debts(UUID);

-- Drop tabelle (in ordine per FK)
DROP TABLE IF EXISTS expense_splits CASCADE;
DROP TABLE IF EXISTS group_invites CASCADE;
DROP TABLE IF EXISTS group_members CASCADE;
DROP TABLE IF EXISTS groups CASCADE;
DROP TABLE IF EXISTS profiles CASCADE;

-- Rimuovi colonne da expenses
ALTER TABLE expenses DROP COLUMN IF EXISTS group_id;
ALTER TABLE expenses DROP COLUMN IF EXISTS paid_by;
ALTER TABLE expenses DROP COLUMN IF EXISTS split_type;
ALTER TABLE expenses DROP COLUMN IF EXISTS split_data;

-- Disabilita RLS su expenses temporaneamente
ALTER TABLE expenses DISABLE ROW LEVEL SECURITY;

-- Rimuovi indici
DROP INDEX IF EXISTS idx_expenses_user_id;
DROP INDEX IF EXISTS idx_expenses_group_id;
DROP INDEX IF EXISTS idx_expenses_paid_by;

-- =====================================================
-- PARTE 2: MIGRATION V3 PULITA
-- =====================================================

-- 1. PROFILES TABLE
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL UNIQUE,
  nickname TEXT NOT NULL DEFAULT 'Utente',
  avatar_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_profiles_email ON profiles(email);
COMMENT ON TABLE profiles IS 'User profiles with nickname and avatar';

-- 2. GROUPS TABLE
CREATE TABLE groups (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  created_by UUID REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE groups IS 'Expense groups (couples, roommates, etc.)';

-- 3. GROUP_MEMBERS TABLE
CREATE TABLE group_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID REFERENCES groups(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  role TEXT DEFAULT 'member' CHECK (role IN ('admin', 'member')),
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(group_id, user_id)
);

CREATE INDEX idx_group_members_group_id ON group_members(group_id);
CREATE INDEX idx_group_members_user_id ON group_members(user_id);
COMMENT ON TABLE group_members IS 'Members of expense groups';

-- 4. GROUP_INVITES TABLE
CREATE TABLE group_invites (
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

CREATE INDEX idx_group_invites_email ON group_invites(invitee_email);
CREATE INDEX idx_group_invites_status ON group_invites(status);
COMMENT ON TABLE group_invites IS 'Invitations to join expense groups';

-- 5. EXPENSE_SPLITS TABLE
CREATE TABLE expense_splits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  expense_id INT REFERENCES expenses(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  amount NUMERIC(10, 2) NOT NULL CHECK (amount >= 0),
  paid BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  paid_at TIMESTAMPTZ
);

CREATE INDEX idx_expense_splits_expense_id ON expense_splits(expense_id);
CREATE INDEX idx_expense_splits_user_id ON expense_splits(user_id);
COMMENT ON TABLE expense_splits IS 'Expense split details for group expenses';

-- 6. ADD COLUMNS TO EXPENSES
ALTER TABLE expenses ADD COLUMN group_id UUID REFERENCES groups(id) ON DELETE CASCADE;
ALTER TABLE expenses ADD COLUMN paid_by UUID REFERENCES profiles(id) ON DELETE SET NULL;
ALTER TABLE expenses ADD COLUMN split_type TEXT DEFAULT 'equal' CHECK (split_type IN ('equal', 'custom', 'full', 'none'));
ALTER TABLE expenses ADD COLUMN split_data JSONB;

CREATE INDEX idx_expenses_user_id ON expenses(user_id);
CREATE INDEX idx_expenses_group_id ON expenses(group_id);
CREATE INDEX idx_expenses_paid_by ON expenses(paid_by);

-- =====================================================
-- ENABLE RLS
-- =====================================================

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_invites ENABLE ROW LEVEL SECURITY;
ALTER TABLE expense_splits ENABLE ROW LEVEL SECURITY;
ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- RLS POLICIES (ZERO RECURSION!)
-- =====================================================

-- PROFILES
CREATE POLICY "Users can view all profiles"
  ON profiles FOR SELECT USING (true);

CREATE POLICY "Users can update their own profile"
  ON profiles FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert their own profile"
  ON profiles FOR INSERT WITH CHECK (auth.uid() = id);

-- GROUP_MEMBERS (NO recursion!)
CREATE POLICY "Users can view all group memberships"
  ON group_members FOR SELECT USING (true);

CREATE POLICY "Users can insert themselves as members"
  ON group_members FOR INSERT WITH CHECK (true);

CREATE POLICY "Users can delete their own memberships"
  ON group_members FOR DELETE USING (user_id = auth.uid());

-- GROUPS (NO recursion!)
CREATE POLICY "Users can view all groups"
  ON groups FOR SELECT USING (true);

CREATE POLICY "Users can create groups"
  ON groups FOR INSERT WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update their groups"
  ON groups FOR UPDATE USING (created_by = auth.uid());

CREATE POLICY "Users can delete their groups"
  ON groups FOR DELETE USING (created_by = auth.uid());

-- GROUP_INVITES
CREATE POLICY "Users can view all invites"
  ON group_invites FOR SELECT USING (true);

CREATE POLICY "Users can create invites"
  ON group_invites FOR INSERT WITH CHECK (inviter_id = auth.uid());

CREATE POLICY "Users can update their invites"
  ON group_invites FOR UPDATE USING (inviter_id = auth.uid() OR invitee_id = auth.uid());

-- EXPENSE_SPLITS
CREATE POLICY "Users can view all splits"
  ON expense_splits FOR SELECT USING (true);

CREATE POLICY "Users can create splits"
  ON expense_splits FOR INSERT WITH CHECK (true);

CREATE POLICY "Users can update their splits"
  ON expense_splits FOR UPDATE USING (user_id = auth.uid());

-- EXPENSES
CREATE POLICY "Users can view all expenses"
  ON expenses FOR SELECT USING (true);

CREATE POLICY "Users can create expenses"
  ON expenses FOR INSERT WITH CHECK (user_id = auth.uid()::text OR paid_by = auth.uid());

CREATE POLICY "Users can update expenses"
  ON expenses FOR UPDATE USING (user_id = auth.uid()::text OR paid_by = auth.uid());

CREATE POLICY "Users can delete expenses"
  ON expenses FOR DELETE USING (user_id = auth.uid()::text);

-- =====================================================
-- TRIGGER
-- =====================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, nickname)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'nickname', 'Utente')
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- =====================================================
-- HELPER FUNCTIONS
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
-- GRANTS
-- =====================================================

GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO anon, authenticated;

-- =====================================================
-- CREA PROFILO PER UTENTE CORRENTE
-- =====================================================
-- Questo crea automaticamente il profilo per tutti gli utenti esistenti

INSERT INTO profiles (id, email, nickname)
SELECT id, email, COALESCE(raw_user_meta_data->>'nickname', 'Utente')
FROM auth.users
ON CONFLICT (id) DO NOTHING;

-- =====================================================
-- ✅ COMPLETATO!
-- =====================================================
SELECT 'Migration V3 completata con successo! ✅' as status;
