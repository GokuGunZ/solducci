-- ============================================================================
-- Migration: Life OS Core Schema (Living Core Step 1)
-- Description: Establishes database foundation for Life OS within Solducci:
--              1. Extends documents table to support 'life_entity' document_type
--              2. Creates entity_relations with typed target integrity & triggers
--              3. Creates life_sessions with strict author privacy and GIN indexing
--              4. Creates user_entity_overlays for user-specific state
--              5. Enforces comprehensive Row Level Security (RLS) policies
-- Created: 2026-10-25
-- ============================================================================

-- 1. Extend documents.document_type constraint to include 'life_entity'
ALTER TABLE documents DROP CONSTRAINT IF EXISTS documents_document_type_check;
ALTER TABLE documents ADD CONSTRAINT documents_document_type_check 
  CHECK (document_type IN (
    'todo', 'shopping_list', 'dispensa', 'generic_list', 
    'note', 'asterisk', 'resource_list', 'time_scenario',
    'life_entity'
  ));

COMMENT ON COLUMN documents.document_type IS 
  'Type of document: todo, shopping_list, dispensa, generic_list, note, asterisk, resource_list, time_scenario, life_entity';

-- ============================================================================
-- 2. TABLE: entity_relations
-- Description: Directed semantic connections from LifeEntity to any supported target
-- Note: target_id is TEXT because targets are polymorphic:
--       documents, tasks, time_scenarios have UUID ids, while expenses have BIGINT ids.
-- ============================================================================
CREATE TABLE IF NOT EXISTS entity_relations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  source_id UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
  source_type TEXT NOT NULL DEFAULT 'entity' CHECK (source_type = 'entity'),
  target_id TEXT NOT NULL,
  target_type TEXT NOT NULL CHECK (target_type IN ('entity', 'task', 'expense', 'time_scenario')),
  relation_type TEXT NOT NULL CHECK (relation_type IN ('requires', 'influences', 'part_of', 'context_for', 'funded_by', 'relates_to')),
  context_status TEXT CHECK (context_status IS NULL OR context_status IN ('blocker', 'active', 'resolved', 'reference')),
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

  -- Unique constraint: prevent duplicate edges of the same type between source and target
  CONSTRAINT uq_entity_relation_edge UNIQUE (source_id, target_id, target_type, relation_type)
);

-- Ensure target_id is TEXT if table was previously created with UUID
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
      AND table_name = 'entity_relations' 
      AND column_name = 'target_id' 
      AND data_type = 'uuid'
  ) THEN
    ALTER TABLE entity_relations ALTER COLUMN target_id TYPE TEXT USING target_id::text;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_entity_relations_source 
  ON entity_relations(source_id, source_type);

CREATE INDEX IF NOT EXISTS idx_entity_relations_target 
  ON entity_relations(target_id, target_type);

CREATE INDEX IF NOT EXISTS idx_entity_relations_user 
  ON entity_relations(user_id);

-- ============================================================================
-- 3. TABLE: life_sessions
-- Description: Lived activity sampling with primary entity and optional related entities
-- ============================================================================
CREATE TABLE IF NOT EXISTS life_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  primary_entity_id UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
  related_entity_ids UUID[] NOT NULL DEFAULT '{}',
  started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  duration_minutes INTEGER NOT NULL CHECK (duration_minutes >= 0),
  activity_summary TEXT NOT NULL,
  metrics JSONB NOT NULL DEFAULT '{}'::jsonb,
  observations TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_life_sessions_primary 
  ON life_sessions(primary_entity_id);

CREATE INDEX IF NOT EXISTS idx_life_sessions_user 
  ON life_sessions(user_id);

CREATE INDEX IF NOT EXISTS idx_life_sessions_started 
  ON life_sessions(started_at DESC);

-- GIN index for inverse queries (finding sessions touching a related entity)
CREATE INDEX IF NOT EXISTS idx_life_sessions_related 
  ON life_sessions USING GIN(related_entity_ids);

-- ============================================================================
-- 4. TABLE: user_entity_overlays
-- Description: User-specific operational state (Weekly rails, commitment, snoozes)
--              Strictly 1:1 per (user, entity), lazy-created.
-- ============================================================================
CREATE TABLE IF NOT EXISTS user_entity_overlays (
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  entity_id UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
  is_in_weekly_rail BOOLEAN NOT NULL DEFAULT FALSE,
  commitment_weight TEXT CHECK (commitment_weight IS NULL OR commitment_weight IN ('low', 'medium', 'high')),
  snoozed_signals JSONB NOT NULL DEFAULT '{}'::jsonb,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, entity_id)
);

CREATE INDEX IF NOT EXISTS idx_user_entity_overlays_user_rail 
  ON user_entity_overlays(user_id, is_in_weekly_rail) 
  WHERE is_in_weekly_rail = TRUE;

-- ============================================================================
-- 5. CLEANUP TRIGGERS (Amendment C: Target-Type-Discriminated Cleanup)
-- Description: Prevents dangling polymorphic references when target objects are deleted
-- ============================================================================

-- Function to clean up entity_relations when target documents are deleted
CREATE OR REPLACE FUNCTION public.trg_cleanup_entity_target()
RETURNS TRIGGER AS $$
BEGIN
  DELETE FROM entity_relations
  WHERE target_type = 'entity'
    AND target_id = OLD.id::text;
  RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to clean up entity_relations when tasks are deleted
CREATE OR REPLACE FUNCTION public.trg_cleanup_task_target()
RETURNS TRIGGER AS $$
BEGIN
  DELETE FROM entity_relations
  WHERE target_type = 'task'
    AND target_id = OLD.id::text;
  RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to clean up entity_relations when expenses are deleted
CREATE OR REPLACE FUNCTION public.trg_cleanup_expense_target()
RETURNS TRIGGER AS $$
BEGIN
  DELETE FROM entity_relations
  WHERE target_type = 'expense'
    AND target_id = OLD.id::text;
  RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to clean up entity_relations when time_scenarios are deleted
CREATE OR REPLACE FUNCTION public.trg_cleanup_time_scenario_target()
RETURNS TRIGGER AS $$
BEGIN
  DELETE FROM entity_relations
  WHERE target_type = 'time_scenario'
    AND target_id = OLD.id::text;
  RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Attach triggers
DROP TRIGGER IF EXISTS trg_cleanup_entity_relations_doc ON documents;
CREATE TRIGGER trg_cleanup_entity_relations_doc
  AFTER DELETE ON documents
  FOR EACH ROW
  EXECUTE FUNCTION public.trg_cleanup_entity_target();

DROP TRIGGER IF EXISTS trg_cleanup_entity_relations_task ON tasks;
CREATE TRIGGER trg_cleanup_entity_relations_task
  AFTER DELETE ON tasks
  FOR EACH ROW
  EXECUTE FUNCTION public.trg_cleanup_task_target();

DROP TRIGGER IF EXISTS trg_cleanup_entity_relations_expense ON expenses;
CREATE TRIGGER trg_cleanup_entity_relations_expense
  AFTER DELETE ON expenses
  FOR EACH ROW
  EXECUTE FUNCTION public.trg_cleanup_expense_target();

DROP TRIGGER IF EXISTS trg_cleanup_entity_relations_scenario ON time_scenarios;
CREATE TRIGGER trg_cleanup_entity_relations_scenario
  AFTER DELETE ON time_scenarios
  FOR EACH ROW
  EXECUTE FUNCTION public.trg_cleanup_time_scenario_target();

-- ============================================================================
-- 6. ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================

-- Enable RLS on all new tables
ALTER TABLE entity_relations ENABLE ROW LEVEL SECURITY;
ALTER TABLE life_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_entity_overlays ENABLE ROW LEVEL SECURITY;

-- ----------------------------------------------------------------------------
-- 6.1 entity_relations RLS Policies
-- Source must be visible to the user, and user must own the relation row
-- Insert also checks target visibility to prevent blind link creation
-- ----------------------------------------------------------------------------

-- SELECT: User can read relations if they have read access to the source document
DROP POLICY IF EXISTS entity_relations_select_policy ON entity_relations;
CREATE POLICY entity_relations_select_policy ON entity_relations
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM documents d
      WHERE d.id = source_id
        AND (d.user_id = auth.uid() OR (d.group_id IS NOT NULL AND public.is_group_member(d.group_id)))
    )
  );

-- INSERT: User must own the relation row, have write access to source, AND read access to target
DROP POLICY IF EXISTS entity_relations_insert_policy ON entity_relations;
CREATE POLICY entity_relations_insert_policy ON entity_relations
  FOR INSERT
  WITH CHECK (
    user_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM documents d
      WHERE d.id = source_id
        AND (d.user_id = auth.uid() OR (d.group_id IS NOT NULL AND public.is_group_member(d.group_id)))
    )
    AND (
      -- Target validation by type (with polymorphic id casting to text):
      (target_type = 'entity' AND EXISTS (
        SELECT 1 FROM documents td
        WHERE td.id::text = target_id
          AND (td.user_id = auth.uid() OR (td.group_id IS NOT NULL AND public.is_group_member(td.group_id)))
      ))
      OR
      (target_type = 'task' AND EXISTS (
        SELECT 1 FROM tasks t
        JOIN documents td ON t.document_id = td.id
        WHERE t.id::text = target_id
          AND (td.user_id = auth.uid() OR (td.group_id IS NOT NULL AND public.is_group_member(td.group_id)))
      ))
      OR
      (target_type = 'expense' AND EXISTS (
        SELECT 1 FROM expenses e
        WHERE e.id::text = target_id
          AND (e.user_id::text = auth.uid()::text OR (e.group_id IS NOT NULL AND public.is_group_member(e.group_id)))
      ))
      OR
      (target_type = 'time_scenario' AND EXISTS (
        SELECT 1 FROM time_scenarios ts
        JOIN documents td ON ts.document_id = td.id
        WHERE ts.id::text = target_id
          AND (td.user_id = auth.uid() OR (td.group_id IS NOT NULL AND public.is_group_member(td.group_id)))
      ))
    )
  );

-- UPDATE: User can update relations they created on accessible source documents
DROP POLICY IF EXISTS entity_relations_update_policy ON entity_relations;
CREATE POLICY entity_relations_update_policy ON entity_relations
  FOR UPDATE
  USING (
    user_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM documents d
      WHERE d.id = source_id
        AND (d.user_id = auth.uid() OR (d.group_id IS NOT NULL AND public.is_group_member(d.group_id)))
    )
  )
  WITH CHECK (
    user_id = auth.uid()
  );

-- DELETE: User can delete relations they created, or group admins on source document
DROP POLICY IF EXISTS entity_relations_delete_policy ON entity_relations;
CREATE POLICY entity_relations_delete_policy ON entity_relations
  FOR DELETE
  USING (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM documents d
      WHERE d.id = source_id
        AND d.user_id = auth.uid()
    )
  );

-- ----------------------------------------------------------------------------
-- 6.2 life_sessions RLS Policies
-- Strict Author Privacy: Lived experience and observations are strictly private
-- to the session author (user_id = auth.uid()), even if primary_entity is shared.
-- ----------------------------------------------------------------------------

DROP POLICY IF EXISTS life_sessions_select_policy ON life_sessions;
CREATE POLICY life_sessions_select_policy ON life_sessions
  FOR SELECT
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS life_sessions_insert_policy ON life_sessions;
CREATE POLICY life_sessions_insert_policy ON life_sessions
  FOR INSERT
  WITH CHECK (
    user_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM documents d
      WHERE d.id = primary_entity_id
        AND (d.user_id = auth.uid() OR (d.group_id IS NOT NULL AND public.is_group_member(d.group_id)))
    )
  );

DROP POLICY IF EXISTS life_sessions_update_policy ON life_sessions;
CREATE POLICY life_sessions_update_policy ON life_sessions
  FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS life_sessions_delete_policy ON life_sessions;
CREATE POLICY life_sessions_delete_policy ON life_sessions
  FOR DELETE
  USING (user_id = auth.uid());

-- ----------------------------------------------------------------------------
-- 6.3 user_entity_overlays RLS Policies
-- Strictly user-owned: Each user sees and modifies only their own personal overlay.
-- ----------------------------------------------------------------------------

DROP POLICY IF EXISTS user_entity_overlays_select_policy ON user_entity_overlays;
CREATE POLICY user_entity_overlays_select_policy ON user_entity_overlays
  FOR SELECT
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS user_entity_overlays_insert_policy ON user_entity_overlays;
CREATE POLICY user_entity_overlays_insert_policy ON user_entity_overlays
  FOR INSERT
  WITH CHECK (
    user_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM documents d
      WHERE d.id = entity_id
        AND (d.user_id = auth.uid() OR (d.group_id IS NOT NULL AND public.is_group_member(d.group_id)))
    )
  );

DROP POLICY IF EXISTS user_entity_overlays_update_policy ON user_entity_overlays;
CREATE POLICY user_entity_overlays_update_policy ON user_entity_overlays
  FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS user_entity_overlays_delete_policy ON user_entity_overlays;
CREATE POLICY user_entity_overlays_delete_policy ON user_entity_overlays
  FOR DELETE
  USING (user_id = auth.uid());
