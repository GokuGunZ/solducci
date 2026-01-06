-- ============================================================================
-- Migration: Documents and ToDo Lists Feature
-- Description: Creates tables for polymorphic document system with tasks,
--              tags, recurrences, and hierarchical structures
-- Created: 2024-12-04
-- ============================================================================

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- TABLE: documents
-- Description: Base table for all document types (polymorphic design)
-- ============================================================================
CREATE TABLE IF NOT EXISTS documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  group_id UUID REFERENCES groups(id) ON DELETE CASCADE,
  document_type TEXT NOT NULL CHECK (document_type IN ('todo', 'shopping_list', 'dispensa', 'generic_list')),
  title TEXT NOT NULL,
  description TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- Extensible metadata as JSONB for future flexibility
  metadata JSONB DEFAULT '{}'::jsonb,

  -- Constraint: document must belong to either user OR group, not both
  CONSTRAINT personal_or_group CHECK (
    (user_id IS NOT NULL AND group_id IS NULL) OR
    (user_id IS NULL AND group_id IS NOT NULL)
  )
);

-- ============================================================================
-- TABLE: tags
-- Description: Tags with hierarchy support and UI configuration
-- ============================================================================
CREATE TABLE IF NOT EXISTS tags (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  color TEXT, -- Hex color (e.g., 'FF5733')
  icon TEXT,  -- Icon identifier (e.g., 'work', 'home', 'shopping')
  parent_tag_id UUID REFERENCES tags(id) ON DELETE SET NULL, -- Hierarchy support

  -- Tag-specific configurations
  use_advanced_states BOOLEAN NOT NULL DEFAULT FALSE, -- Enable assigned/in_progress states
  show_completed BOOLEAN NOT NULL DEFAULT FALSE, -- Show completed tasks by default

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- Unique constraint: user cannot have duplicate tag names
  CONSTRAINT unique_user_tag_name UNIQUE(user_id, name)
);

-- ============================================================================
-- TABLE: tasks
-- Description: Tasks with hierarchical support (parent-child relationships)
-- ============================================================================
CREATE TABLE IF NOT EXISTS tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  document_id UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
  parent_task_id UUID REFERENCES tasks(id) ON DELETE CASCADE, -- Sub-tasks support

  title TEXT NOT NULL,
  description TEXT,

  -- Task states
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'assigned', 'in_progress')),
  completed_at TIMESTAMPTZ,

  -- Priority and sizing
  priority TEXT CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
  t_shirt_size TEXT CHECK (t_shirt_size IN ('xs', 's', 'm', 'l', 'xl')),
  due_date TIMESTAMPTZ,

  -- Ordering within parent/document
  position INTEGER NOT NULL DEFAULT 0,

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================================
-- TABLE: task_tags
-- Description: Many-to-many relationship between tasks and tags
-- ============================================================================
CREATE TABLE IF NOT EXISTS task_tags (
  task_id UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  tag_id UUID NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
  assigned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  PRIMARY KEY (task_id, tag_id)
);

-- ============================================================================
-- TABLE: recurrences
-- Description: Recurrence configuration for tasks or tags
-- ============================================================================
CREATE TABLE IF NOT EXISTS recurrences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Applicable to either task OR tag
  task_id UUID REFERENCES tasks(id) ON DELETE CASCADE,
  tag_id UUID REFERENCES tags(id) ON DELETE CASCADE,

  -- Level 1: Intra-day frequency
  hourly_frequency INTEGER CHECK (hourly_frequency > 0), -- Every N hours
  specific_times TIME[], -- Array of specific times (e.g., ['08:00', '14:00', '20:00'])

  -- Level 2: Inter-day frequency
  daily_frequency INTEGER CHECK (daily_frequency > 0), -- Every N days
  weekly_days INTEGER[] CHECK (array_length(weekly_days, 1) IS NULL OR
                                (weekly_days <@ ARRAY[0,1,2,3,4,5,6] AND
                                 cardinality(weekly_days) > 0)), -- Days of week (0=Sunday, 6=Saturday)
  monthly_days INTEGER[] CHECK (array_length(monthly_days, 1) IS NULL OR
                                (monthly_days <@ ARRAY[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31] AND
                                 cardinality(monthly_days) > 0)), -- Days of month (1-31)
  yearly_dates TEXT[] CHECK (array_length(yearly_dates, 1) IS NULL OR
                              cardinality(yearly_dates) > 0), -- Dates in 'MM-DD' format

  -- Recurrence period
  start_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  end_date TIMESTAMPTZ, -- NULL = infinite

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- Constraint: recurrence must belong to either task OR tag, not both
  CONSTRAINT task_or_tag CHECK (
    (task_id IS NOT NULL AND tag_id IS NULL) OR
    (task_id IS NULL AND tag_id IS NOT NULL)
  ),

  -- Constraint: must have at least one intra-day frequency option
  CONSTRAINT has_intraday_frequency CHECK (
    hourly_frequency IS NOT NULL OR
    specific_times IS NOT NULL
  ),

  -- Constraint: must have at least one inter-day frequency option
  CONSTRAINT has_interday_frequency CHECK (
    daily_frequency IS NOT NULL OR
    weekly_days IS NOT NULL OR
    monthly_days IS NOT NULL OR
    yearly_dates IS NOT NULL
  )
);

-- ============================================================================
-- TABLE: task_completions
-- Description: History of task completions (for recurring tasks)
-- ============================================================================
CREATE TABLE IF NOT EXISTS task_completions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  completed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  notes TEXT
);

-- ============================================================================
-- INDEXES for performance optimization
-- ============================================================================

-- Documents
CREATE INDEX IF NOT EXISTS idx_documents_user_id ON documents(user_id);
CREATE INDEX IF NOT EXISTS idx_documents_group_id ON documents(group_id);
CREATE INDEX IF NOT EXISTS idx_documents_type ON documents(document_type);
CREATE INDEX IF NOT EXISTS idx_documents_user_type ON documents(user_id, document_type);

-- Tags
CREATE INDEX IF NOT EXISTS idx_tags_user_id ON tags(user_id);
CREATE INDEX IF NOT EXISTS idx_tags_parent_id ON tags(parent_tag_id);
CREATE INDEX IF NOT EXISTS idx_tags_user_parent ON tags(user_id, parent_tag_id);

-- Tasks
CREATE INDEX IF NOT EXISTS idx_tasks_document_id ON tasks(document_id);
CREATE INDEX IF NOT EXISTS idx_tasks_parent_id ON tasks(parent_task_id);
CREATE INDEX IF NOT EXISTS idx_tasks_status ON tasks(status);
CREATE INDEX IF NOT EXISTS idx_tasks_document_status ON tasks(document_id, status);
CREATE INDEX IF NOT EXISTS idx_tasks_due_date ON tasks(due_date) WHERE due_date IS NOT NULL;

-- Task Tags (junction)
CREATE INDEX IF NOT EXISTS idx_task_tags_task_id ON task_tags(task_id);
CREATE INDEX IF NOT EXISTS idx_task_tags_tag_id ON task_tags(tag_id);

-- Recurrences
CREATE INDEX IF NOT EXISTS idx_recurrences_task_id ON recurrences(task_id);
CREATE INDEX IF NOT EXISTS idx_recurrences_tag_id ON recurrences(tag_id);

-- Task Completions
CREATE INDEX IF NOT EXISTS idx_task_completions_task_id ON task_completions(task_id);
CREATE INDEX IF NOT EXISTS idx_task_completions_completed_at ON task_completions(completed_at);

-- ============================================================================
-- TRIGGERS for auto-updating timestamps
-- ============================================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to documents
DROP TRIGGER IF EXISTS documents_updated_at ON documents;
CREATE TRIGGER documents_updated_at
  BEFORE UPDATE ON documents
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Apply trigger to tasks
DROP TRIGGER IF EXISTS tasks_updated_at ON tasks;
CREATE TRIGGER tasks_updated_at
  BEFORE UPDATE ON tasks
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Apply trigger to tags
DROP TRIGGER IF EXISTS tags_updated_at ON tags;
CREATE TRIGGER tags_updated_at
  BEFORE UPDATE ON tags
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- ROW LEVEL SECURITY (RLS) Policies
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE task_tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE recurrences ENABLE ROW LEVEL SECURITY;
ALTER TABLE task_completions ENABLE ROW LEVEL SECURITY;

-- Documents policies
CREATE POLICY "Users can view their own documents"
  ON documents FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own documents"
  ON documents FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own documents"
  ON documents FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own documents"
  ON documents FOR DELETE
  USING (auth.uid() = user_id);

-- Tags policies
CREATE POLICY "Users can view their own tags"
  ON tags FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own tags"
  ON tags FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own tags"
  ON tags FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own tags"
  ON tags FOR DELETE
  USING (auth.uid() = user_id);

-- Tasks policies (access through document ownership)
CREATE POLICY "Users can view tasks from their documents"
  ON tasks FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM documents
      WHERE documents.id = tasks.document_id
      AND documents.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert tasks to their documents"
  ON tasks FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM documents
      WHERE documents.id = tasks.document_id
      AND documents.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update tasks from their documents"
  ON tasks FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM documents
      WHERE documents.id = tasks.document_id
      AND documents.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can delete tasks from their documents"
  ON tasks FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM documents
      WHERE documents.id = tasks.document_id
      AND documents.user_id = auth.uid()
    )
  );

-- Task Tags policies (access through task ownership)
CREATE POLICY "Users can view task_tags for their tasks"
  ON task_tags FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM tasks
      JOIN documents ON documents.id = tasks.document_id
      WHERE tasks.id = task_tags.task_id
      AND documents.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert task_tags for their tasks"
  ON task_tags FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM tasks
      JOIN documents ON documents.id = tasks.document_id
      WHERE tasks.id = task_tags.task_id
      AND documents.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can delete task_tags from their tasks"
  ON task_tags FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM tasks
      JOIN documents ON documents.id = tasks.document_id
      WHERE tasks.id = task_tags.task_id
      AND documents.user_id = auth.uid()
    )
  );

-- Recurrences policies
CREATE POLICY "Users can view recurrences for their tasks"
  ON recurrences FOR SELECT
  USING (
    (task_id IS NOT NULL AND EXISTS (
      SELECT 1 FROM tasks
      JOIN documents ON documents.id = tasks.document_id
      WHERE tasks.id = recurrences.task_id
      AND documents.user_id = auth.uid()
    ))
    OR
    (tag_id IS NOT NULL AND EXISTS (
      SELECT 1 FROM tags
      WHERE tags.id = recurrences.tag_id
      AND tags.user_id = auth.uid()
    ))
  );

CREATE POLICY "Users can insert recurrences for their tasks/tags"
  ON recurrences FOR INSERT
  WITH CHECK (
    (task_id IS NOT NULL AND EXISTS (
      SELECT 1 FROM tasks
      JOIN documents ON documents.id = tasks.document_id
      WHERE tasks.id = recurrences.task_id
      AND documents.user_id = auth.uid()
    ))
    OR
    (tag_id IS NOT NULL AND EXISTS (
      SELECT 1 FROM tags
      WHERE tags.id = recurrences.tag_id
      AND tags.user_id = auth.uid()
    ))
  );

CREATE POLICY "Users can update recurrences for their tasks/tags"
  ON recurrences FOR UPDATE
  USING (
    (task_id IS NOT NULL AND EXISTS (
      SELECT 1 FROM tasks
      JOIN documents ON documents.id = tasks.document_id
      WHERE tasks.id = recurrences.task_id
      AND documents.user_id = auth.uid()
    ))
    OR
    (tag_id IS NOT NULL AND EXISTS (
      SELECT 1 FROM tags
      WHERE tags.id = recurrences.tag_id
      AND tags.user_id = auth.uid()
    ))
  );

CREATE POLICY "Users can delete recurrences for their tasks/tags"
  ON recurrences FOR DELETE
  USING (
    (task_id IS NOT NULL AND EXISTS (
      SELECT 1 FROM tasks
      JOIN documents ON documents.id = tasks.document_id
      WHERE tasks.id = recurrences.task_id
      AND documents.user_id = auth.uid()
    ))
    OR
    (tag_id IS NOT NULL AND EXISTS (
      SELECT 1 FROM tags
      WHERE tags.id = recurrences.tag_id
      AND tags.user_id = auth.uid()
    ))
  );

-- Task Completions policies
CREATE POLICY "Users can view completions for their tasks"
  ON task_completions FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM tasks
      JOIN documents ON documents.id = tasks.document_id
      WHERE tasks.id = task_completions.task_id
      AND documents.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert completions for their tasks"
  ON task_completions FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM tasks
      JOIN documents ON documents.id = tasks.document_id
      WHERE tasks.id = task_completions.task_id
      AND documents.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can delete completions for their tasks"
  ON task_completions FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM tasks
      JOIN documents ON documents.id = tasks.document_id
      WHERE tasks.id = task_completions.task_id
      AND documents.user_id = auth.uid()
    )
  );

-- ============================================================================
-- COMMENTS for documentation
-- ============================================================================

COMMENT ON TABLE documents IS 'Base table for all document types with polymorphic design';
COMMENT ON TABLE tags IS 'Tags with hierarchical support and UI configurations';
COMMENT ON TABLE tasks IS 'Tasks with parent-child relationships for sub-tasks';
COMMENT ON TABLE task_tags IS 'Many-to-many relationship between tasks and tags';
COMMENT ON TABLE recurrences IS 'Recurrence configuration for tasks or tags with two-level frequency';
COMMENT ON TABLE task_completions IS 'History of task completions for recurring tasks';

COMMENT ON COLUMN documents.document_type IS 'Type of document: todo, shopping_list, dispensa, generic_list';
COMMENT ON COLUMN documents.metadata IS 'Extensible JSONB field for type-specific data';
COMMENT ON COLUMN tags.parent_tag_id IS 'Parent tag ID for hierarchical tags';
COMMENT ON COLUMN tags.use_advanced_states IS 'Enable assigned/in_progress states for tasks with this tag';
COMMENT ON COLUMN tags.show_completed IS 'Show completed tasks by default in this tag view';
COMMENT ON COLUMN tasks.parent_task_id IS 'Parent task ID for sub-tasks (hierarchical)';
COMMENT ON COLUMN tasks.position IS 'Order position within parent/document';
COMMENT ON COLUMN recurrences.hourly_frequency IS 'Repeat every N hours (intra-day level 1)';
COMMENT ON COLUMN recurrences.specific_times IS 'Specific times of day to repeat (intra-day level 1)';
COMMENT ON COLUMN recurrences.daily_frequency IS 'Repeat every N days (inter-day level 2)';
COMMENT ON COLUMN recurrences.weekly_days IS 'Days of week to repeat (0=Sunday, 6=Saturday) (inter-day level 2)';
COMMENT ON COLUMN recurrences.monthly_days IS 'Days of month to repeat (1-31) (inter-day level 2)';
COMMENT ON COLUMN recurrences.yearly_dates IS 'Dates in MM-DD format to repeat yearly (inter-day level 2)';
