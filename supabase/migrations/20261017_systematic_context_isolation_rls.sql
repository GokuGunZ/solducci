-- ==============================================================================
-- Migration: Systematic Context Isolation & Defense-in-Depth RLS
-- Date: 2026-10-17
-- Description:
--   1. Creates non-recursive SECURITY DEFINER helper function is_group_member
--   2. Adds group_id support to wallets and incomes for shared group funds
--   3. Restores strict Row Level Security across all application tables,
--      permanently closing cross-user and cross-group data leaks.
-- ==============================================================================

-- ==============================================================================
-- STEP 1: SECURITY DEFINER Helper Function (Zero Recursion!)
-- ==============================================================================

CREATE OR REPLACE FUNCTION public.is_group_member(p_group_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.group_members 
    WHERE group_id = p_group_id AND user_id = auth.uid()
  );
$$;

COMMENT ON FUNCTION public.is_group_member(UUID) IS 
  'Verifies if current authenticated user is a member of the group without triggering RLS recursion';

-- ==============================================================================
-- STEP 2: Support for Shared / Group Wallets and Incomes
-- ==============================================================================

ALTER TABLE public.wallets 
  ADD COLUMN IF NOT EXISTS group_id UUID REFERENCES public.groups(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_wallets_group ON public.wallets(group_id);

ALTER TABLE public.incomes 
  ADD COLUMN IF NOT EXISTS group_id UUID REFERENCES public.groups(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_incomes_group ON public.incomes(group_id);

-- ==============================================================================
-- STEP 3: RLS on Wallets, Incomes and Transfers
-- ==============================================================================

DROP POLICY IF EXISTS "Users can manage their own wallets" ON public.wallets;
DROP POLICY IF EXISTS "Users can manage own or group wallets" ON public.wallets;

CREATE POLICY "Users can manage own or group wallets"
  ON public.wallets
  FOR ALL
  USING (
    user_id = auth.uid()
    OR (group_id IS NOT NULL AND public.is_group_member(group_id))
  )
  WITH CHECK (
    user_id = auth.uid()
    OR (group_id IS NOT NULL AND public.is_group_member(group_id))
  );

DROP POLICY IF EXISTS "Users can manage their own incomes" ON public.incomes;
DROP POLICY IF EXISTS "Users can manage own or group incomes" ON public.incomes;

CREATE POLICY "Users can manage own or group incomes"
  ON public.incomes
  FOR ALL
  USING (
    user_id = auth.uid()
    OR (group_id IS NOT NULL AND public.is_group_member(group_id))
  )
  WITH CHECK (
    user_id = auth.uid()
    OR (group_id IS NOT NULL AND public.is_group_member(group_id))
  );

DROP POLICY IF EXISTS "Users can manage their own wallet transfers" ON public.wallet_transfers;
DROP POLICY IF EXISTS "Users can manage wallet transfers" ON public.wallet_transfers;

CREATE POLICY "Users can manage wallet transfers"
  ON public.wallet_transfers
  FOR ALL
  USING (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.wallets w 
      WHERE (w.id = wallet_transfers.from_wallet_id OR w.id = wallet_transfers.to_wallet_id)
      AND w.group_id IS NOT NULL AND public.is_group_member(w.group_id)
    )
  )
  WITH CHECK (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.wallets w 
      WHERE (w.id = wallet_transfers.from_wallet_id OR w.id = wallet_transfers.to_wallet_id)
      AND w.group_id IS NOT NULL AND public.is_group_member(w.group_id)
    )
  );

-- ==============================================================================
-- STEP 4: RLS on Expenses & Splits (Restore isolation)
-- ==============================================================================

DROP POLICY IF EXISTS "Users can view all expenses" ON public.expenses;
DROP POLICY IF EXISTS "Users can view expenses" ON public.expenses;
DROP POLICY IF EXISTS "Users can manage expenses" ON public.expenses;

CREATE POLICY "Users can view expenses"
  ON public.expenses
  FOR SELECT
  USING (
    user_id = auth.uid()::text
    OR (group_id IS NOT NULL AND public.is_group_member(group_id))
  );

DROP POLICY IF EXISTS "Users can view all splits" ON public.expense_splits;
DROP POLICY IF EXISTS "Users can view splits" ON public.expense_splits;

CREATE POLICY "Users can view splits"
  ON public.expense_splits
  FOR SELECT
  USING (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.expenses e
      WHERE e.id = expense_splits.expense_id
      AND (e.user_id = auth.uid()::text OR (e.group_id IS NOT NULL AND public.is_group_member(e.group_id)))
    )
  );

-- ==============================================================================
-- STEP 5: RLS on Documents & Tasks (Zero Open Access)
-- ==============================================================================

DROP POLICY IF EXISTS "Users can view all documents" ON public.documents;
DROP POLICY IF EXISTS "Users can insert any document" ON public.documents;
DROP POLICY IF EXISTS "Users can update any document" ON public.documents;
DROP POLICY IF EXISTS "Users can delete any document" ON public.documents;

CREATE POLICY "Users can access documents"
  ON public.documents
  FOR ALL
  USING (
    user_id = auth.uid()
    OR (group_id IS NOT NULL AND public.is_group_member(group_id))
  )
  WITH CHECK (
    user_id = auth.uid()
    OR (group_id IS NOT NULL AND public.is_group_member(group_id))
  );

DROP POLICY IF EXISTS "Users can view all tasks" ON public.tasks;
DROP POLICY IF EXISTS "Users can insert any task" ON public.tasks;
DROP POLICY IF EXISTS "Users can update any task" ON tasks;
DROP POLICY IF EXISTS "Users can delete any task" ON tasks;

CREATE POLICY "Users can access tasks"
  ON public.tasks
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.documents d
      WHERE d.id = tasks.document_id
      AND (d.user_id = auth.uid() OR (d.group_id IS NOT NULL AND public.is_group_member(d.group_id)))
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.documents d
      WHERE d.id = tasks.document_id
      AND (d.user_id = auth.uid() OR (d.group_id IS NOT NULL AND public.is_group_member(d.group_id)))
    )
  );

DROP POLICY IF EXISTS "Users can view all task_tags" ON public.task_tags;
DROP POLICY IF EXISTS "Users can insert any task_tag" ON public.task_tags;
DROP POLICY IF EXISTS "Users can delete any task_tag" ON public.task_tags;

CREATE POLICY "Users can access task_tags"
  ON public.task_tags
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.tasks t
      JOIN public.documents d ON d.id = t.document_id
      WHERE t.id = task_tags.task_id
      AND (d.user_id = auth.uid() OR (d.group_id IS NOT NULL AND public.is_group_member(d.group_id)))
    )
  );

-- ==============================================================================
-- STEP 6: RLS on Space Items (Notes, Asterisks, Pantry, Shopping, Resources)
-- ==============================================================================

DROP POLICY IF EXISTS "Users can view all note_items" ON public.note_items;
DROP POLICY IF EXISTS "Users can insert any note_item" ON public.note_items;
DROP POLICY IF EXISTS "Users can update any note_item" ON public.note_items;
DROP POLICY IF EXISTS "Users can delete any note_item" ON public.note_items;

CREATE POLICY "Users can access note_items"
  ON public.note_items
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.documents d
      WHERE d.id = note_items.document_id
      AND (d.user_id = auth.uid() OR (d.group_id IS NOT NULL AND public.is_group_member(d.group_id)))
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.documents d
      WHERE d.id = note_items.document_id
      AND (d.user_id = auth.uid() OR (d.group_id IS NOT NULL AND public.is_group_member(d.group_id)))
    )
  );

DROP POLICY IF EXISTS "Users can view all asterisk_items" ON public.asterisk_items;
DROP POLICY IF EXISTS "Access asterisk_items via document" ON public.asterisk_items;

CREATE POLICY "Users can access asterisk_items"
  ON public.asterisk_items
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.documents d
      WHERE d.id = asterisk_items.document_id
      AND (d.user_id = auth.uid() OR (d.group_id IS NOT NULL AND public.is_group_member(d.group_id)))
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.documents d
      WHERE d.id = asterisk_items.document_id
      AND (d.user_id = auth.uid() OR (d.group_id IS NOT NULL AND public.is_group_member(d.group_id)))
    )
  );

DROP POLICY IF EXISTS "Users can view all pantry_items" ON public.pantry_items;
CREATE POLICY "Users can access pantry_items"
  ON public.pantry_items
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.documents d
      WHERE d.id = pantry_items.document_id
      AND (d.user_id = auth.uid() OR (d.group_id IS NOT NULL AND public.is_group_member(d.group_id)))
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.documents d
      WHERE d.id = pantry_items.document_id
      AND (d.user_id = auth.uid() OR (d.group_id IS NOT NULL AND public.is_group_member(d.group_id)))
    )
  );

DROP POLICY IF EXISTS "Users can view all pantry_quantities" ON public.pantry_quantities;
CREATE POLICY "Users can access pantry_quantities"
  ON public.pantry_quantities
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.pantry_items pi
      JOIN public.documents d ON d.id = pi.document_id
      WHERE pi.id = pantry_quantities.pantry_item_id
      AND (d.user_id = auth.uid() OR (d.group_id IS NOT NULL AND public.is_group_member(d.group_id)))
    )
  );

DROP POLICY IF EXISTS "Users can view all shopping_list_items" ON public.shopping_list_items;
CREATE POLICY "Users can access shopping_list_items"
  ON public.shopping_list_items
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.documents d
      WHERE d.id = shopping_list_items.document_id
      AND (d.user_id = auth.uid() OR (d.group_id IS NOT NULL AND public.is_group_member(d.group_id)))
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.documents d
      WHERE d.id = shopping_list_items.document_id
      AND (d.user_id = auth.uid() OR (d.group_id IS NOT NULL AND public.is_group_member(d.group_id)))
    )
  );

DROP POLICY IF EXISTS "Users can view all resource_items" ON public.resource_items;
CREATE POLICY "Users can access resource_items"
  ON public.resource_items
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.documents d
      WHERE d.id = resource_items.document_id
      AND (d.user_id = auth.uid() OR (d.group_id IS NOT NULL AND public.is_group_member(d.group_id)))
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.documents d
      WHERE d.id = resource_items.document_id
      AND (d.user_id = auth.uid() OR (d.group_id IS NOT NULL AND public.is_group_member(d.group_id)))
    )
  );

-- ==============================================================================
-- STEP 7: RLS on Time Management (Scenarios, Routines, Alarms, Polls)
-- ==============================================================================

DROP POLICY IF EXISTS "Users can view all time_scenarios" ON public.time_scenarios;
DROP POLICY IF EXISTS "Users can insert time_scenarios" ON public.time_scenarios;
DROP POLICY IF EXISTS "Users can update time_scenarios" ON public.time_scenarios;
DROP POLICY IF EXISTS "Users can delete time_scenarios" ON public.time_scenarios;

CREATE POLICY "Users can access time_scenarios"
  ON public.time_scenarios
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.documents d
      WHERE d.id = time_scenarios.document_id
      AND (d.user_id = auth.uid() OR (d.group_id IS NOT NULL AND public.is_group_member(d.group_id)))
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.documents d
      WHERE d.id = time_scenarios.document_id
      AND (d.user_id = auth.uid() OR (d.group_id IS NOT NULL AND public.is_group_member(d.group_id)))
    )
  );

DROP POLICY IF EXISTS "Users can view all routine_templates" ON public.routine_templates;
DROP POLICY IF EXISTS "Users can insert routine_templates" ON public.routine_templates;
DROP POLICY IF EXISTS "Users can update routine_templates" ON public.routine_templates;
DROP POLICY IF EXISTS "Users can delete routine_templates" ON public.routine_templates;

CREATE POLICY "Users can access routine_templates"
  ON public.routine_templates
  FOR ALL
  USING (
    user_id = auth.uid()
    OR (group_id IS NOT NULL AND public.is_group_member(group_id))
  )
  WITH CHECK (
    user_id = auth.uid()
    OR (group_id IS NOT NULL AND public.is_group_member(group_id))
  );

DROP POLICY IF EXISTS "Users can view all routine_alarms" ON public.routine_alarms;
DROP POLICY IF EXISTS "Users can insert routine_alarms" ON public.routine_alarms;
DROP POLICY IF EXISTS "Users can update routine_alarms" ON public.routine_alarms;
DROP POLICY IF EXISTS "Users can delete routine_alarms" ON public.routine_alarms;

CREATE POLICY "Users can access routine_alarms"
  ON public.routine_alarms
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.routine_templates rt
      WHERE rt.id = routine_alarms.routine_template_id
      AND (rt.user_id = auth.uid() OR (rt.group_id IS NOT NULL AND public.is_group_member(rt.group_id)))
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.routine_templates rt
      WHERE rt.id = routine_alarms.routine_template_id
      AND (rt.user_id = auth.uid() OR (rt.group_id IS NOT NULL AND public.is_group_member(rt.group_id)))
    )
  );

DROP POLICY IF EXISTS "Users can view all routine_schedules" ON public.routine_schedules;
DROP POLICY IF EXISTS "Users can insert routine_schedules" ON public.routine_schedules;
DROP POLICY IF EXISTS "Users can update routine_schedules" ON public.routine_schedules;
DROP POLICY IF EXISTS "Users can delete routine_schedules" ON public.routine_schedules;

CREATE POLICY "Users can access routine_schedules"
  ON public.routine_schedules
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.routine_templates rt
      WHERE rt.id = routine_schedules.routine_template_id
      AND (rt.user_id = auth.uid() OR (rt.group_id IS NOT NULL AND public.is_group_member(rt.group_id)))
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.routine_templates rt
      WHERE rt.id = routine_schedules.routine_template_id
      AND (rt.user_id = auth.uid() OR (rt.group_id IS NOT NULL AND public.is_group_member(rt.group_id)))
    )
  );
