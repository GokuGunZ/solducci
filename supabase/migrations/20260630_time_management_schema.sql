-- ============================================================================
-- Migration: Time Management Feature (Events, Trips, Outings, Routines, Polls)
-- Description: Creates tables for the Time Management macro-section
-- Created: 2026-06-30
-- ============================================================================

-- 1. Update document_type constraint to allow 'time_scenario'
ALTER TABLE documents DROP CONSTRAINT IF EXISTS documents_document_type_check;
ALTER TABLE documents ADD CONSTRAINT documents_document_type_check 
  CHECK (document_type IN ('todo', 'shopping_list', 'dispensa', 'generic_list', 'note', 'asterisk', 'resource_list', 'time_scenario'));

COMMENT ON COLUMN documents.document_type IS 'Type of document: todo, shopping_list, dispensa, generic_list, note, asterisk, resource_list, time_scenario';

-- ============================================================================
-- MACRO-SCENARI TEMPORALI (Viaggi, Eventi, Uscite, Radar, Focus)
-- ============================================================================

CREATE TABLE IF NOT EXISTS time_scenarios (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  document_id UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
  scenario_type TEXT NOT NULL CHECK (scenario_type IN ('event', 'trip', 'outing', 'availability', 'focus_mode')),
  start_date TIMESTAMPTZ NOT NULL,
  end_date TIMESTAMPTZ, 
  location TEXT,
  visibility_scope JSONB DEFAULT '{}'::jsonb, -- Usato per "Radar" e Focus Mode per decidere i target
  has_countdown BOOLEAN DEFAULT false,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- RSVP e Partecipanti
CREATE TABLE IF NOT EXISTS time_scenario_participants (
  time_scenario_id UUID NOT NULL REFERENCES time_scenarios(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  rsvp_status TEXT NOT NULL DEFAULT 'pending' CHECK (rsvp_status IN ('pending', 'attending', 'declined', 'maybe')),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (time_scenario_id, user_id)
);

-- Connessione tra Spese e Scenario (Per bilanci isolati, es. Bilancio Viaggio)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_name='expenses' AND column_name='time_scenario_id') THEN
    ALTER TABLE expenses ADD COLUMN time_scenario_id UUID REFERENCES time_scenarios(id) ON DELETE SET NULL;
  END IF;
END $$;
CREATE INDEX IF NOT EXISTS idx_expenses_time_scenario ON expenses(time_scenario_id);

-- ============================================================================
-- HUB ROUTINE E SVEGLIE (Promemoria basati su Ora X)
-- ============================================================================

CREATE TABLE IF NOT EXISTS routine_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  group_id UUID REFERENCES groups(id) ON DELETE CASCADE, -- Valorizzato se è una sveglia "di gruppo"
  name TEXT NOT NULL,
  description TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS routine_alarms (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  routine_template_id UUID NOT NULL REFERENCES routine_templates(id) ON DELETE CASCADE,
  offset_minutes INTEGER NOT NULL, -- Minuti rispetto al Target (es. -30, +15)
  label TEXT NOT NULL,
  alarm_type TEXT NOT NULL DEFAULT 'push' CHECK (alarm_type IN ('push', 'native_aggressive')),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS routine_schedules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  routine_template_id UUID NOT NULL REFERENCES routine_templates(id) ON DELETE CASCADE,
  target_time TIME NOT NULL, -- L'Ora X
  day_of_week INTEGER NOT NULL CHECK (day_of_week BETWEEN 1 AND 7), -- 1=Lun, 7=Dom
  
  -- Deroghe (Overrides) per sospendere temporaneamente o deviare
  is_paused_for_today DATE, 
  custom_target_time_override TIME,
  override_expiry DATE,
  
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================================
-- TIME POLLING (Sondaggi orari per le Uscite)
-- ============================================================================

CREATE TABLE IF NOT EXISTS time_polls (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  document_id UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  is_closed BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS time_poll_options (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  poll_id UUID NOT NULL REFERENCES time_polls(id) ON DELETE CASCADE,
  proposed_start_time TIMESTAMPTZ NOT NULL,
  proposed_end_time TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS time_poll_votes (
  option_id UUID NOT NULL REFERENCES time_poll_options(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (option_id, user_id)
);

-- ============================================================================
-- ROW LEVEL SECURITY (RLS) - "Zero Recursion" Style come da V3
-- ============================================================================

ALTER TABLE time_scenarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE time_scenario_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE routine_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE routine_alarms ENABLE ROW LEVEL SECURITY;
ALTER TABLE routine_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE time_polls ENABLE ROW LEVEL SECURITY;
ALTER TABLE time_poll_options ENABLE ROW LEVEL SECURITY;
ALTER TABLE time_poll_votes ENABLE ROW LEVEL SECURITY;

-- time_scenarios (Filter by app logic via context)
CREATE POLICY "Users can view all time_scenarios" ON time_scenarios FOR SELECT USING (true);
CREATE POLICY "Users can insert time_scenarios" ON time_scenarios FOR INSERT WITH CHECK (true);
CREATE POLICY "Users can update time_scenarios" ON time_scenarios FOR UPDATE USING (true);
CREATE POLICY "Users can delete time_scenarios" ON time_scenarios FOR DELETE USING (true);

-- time_scenario_participants
CREATE POLICY "Users can view all time_scenario_participants" ON time_scenario_participants FOR SELECT USING (true);
CREATE POLICY "Users can insert time_scenario_participants" ON time_scenario_participants FOR INSERT WITH CHECK (true);
CREATE POLICY "Users can update time_scenario_participants" ON time_scenario_participants FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY "Users can delete time_scenario_participants" ON time_scenario_participants FOR DELETE USING (user_id = auth.uid());

-- routine_templates
CREATE POLICY "Users can view all routine_templates" ON routine_templates FOR SELECT USING (true);
CREATE POLICY "Users can insert routine_templates" ON routine_templates FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "Users can update routine_templates" ON routine_templates FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY "Users can delete routine_templates" ON routine_templates FOR DELETE USING (user_id = auth.uid());

-- routine_alarms
CREATE POLICY "Users can view all routine_alarms" ON routine_alarms FOR SELECT USING (true);
CREATE POLICY "Users can insert routine_alarms" ON routine_alarms FOR INSERT WITH CHECK (true);
CREATE POLICY "Users can update routine_alarms" ON routine_alarms FOR UPDATE USING (true);
CREATE POLICY "Users can delete routine_alarms" ON routine_alarms FOR DELETE USING (true);

-- routine_schedules
CREATE POLICY "Users can view all routine_schedules" ON routine_schedules FOR SELECT USING (true);
CREATE POLICY "Users can insert routine_schedules" ON routine_schedules FOR INSERT WITH CHECK (true);
CREATE POLICY "Users can update routine_schedules" ON routine_schedules FOR UPDATE USING (true);
CREATE POLICY "Users can delete routine_schedules" ON routine_schedules FOR DELETE USING (true);

-- time_polls
CREATE POLICY "Users can view all time_polls" ON time_polls FOR SELECT USING (true);
CREATE POLICY "Users can insert time_polls" ON time_polls FOR INSERT WITH CHECK (true);
CREATE POLICY "Users can update time_polls" ON time_polls FOR UPDATE USING (true);
CREATE POLICY "Users can delete time_polls" ON time_polls FOR DELETE USING (true);

-- time_poll_options
CREATE POLICY "Users can view all time_poll_options" ON time_poll_options FOR SELECT USING (true);
CREATE POLICY "Users can insert time_poll_options" ON time_poll_options FOR INSERT WITH CHECK (true);
CREATE POLICY "Users can update time_poll_options" ON time_poll_options FOR UPDATE USING (true);
CREATE POLICY "Users can delete time_poll_options" ON time_poll_options FOR DELETE USING (true);

-- time_poll_votes
CREATE POLICY "Users can view all time_poll_votes" ON time_poll_votes FOR SELECT USING (true);
CREATE POLICY "Users can insert time_poll_votes" ON time_poll_votes FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "Users can delete time_poll_votes" ON time_poll_votes FOR DELETE USING (user_id = auth.uid());

-- ============================================================================
-- TRIGGERS for updated_at
-- ============================================================================
CREATE TRIGGER time_scenarios_updated_at BEFORE UPDATE ON time_scenarios FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER time_scenario_participants_updated_at BEFORE UPDATE ON time_scenario_participants FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER routine_templates_updated_at BEFORE UPDATE ON routine_templates FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER routine_alarms_updated_at BEFORE UPDATE ON routine_alarms FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER routine_schedules_updated_at BEFORE UPDATE ON routine_schedules FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER time_polls_updated_at BEFORE UPDATE ON time_polls FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
