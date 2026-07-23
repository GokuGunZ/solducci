-- Migration: Refactor Pantry Quantities and Enable Realtime

-- 1. Update pantry_quantities schema
-- We want to track: X units of Y size each.
ALTER TABLE pantry_quantities ADD COLUMN IF NOT EXISTS size_per_unit DECIMAL DEFAULT 1;
ALTER TABLE pantry_quantities ADD COLUMN IF NOT EXISTS units_count INTEGER DEFAULT 1;

-- If 'quantity' was used, we'll keep it as a calculated field or total, 
-- but for now let's ensure the new columns exist.
-- The user said: "prodotto di quantità di quelle confezioni e dalla loro dimensione"
-- So total = units_count * size_per_unit.

-- 2. Enable Realtime for Space tables
-- This is required for StreamBuilder to react to inserts/updates from other clients or background tasks.

-- First, check if the publication exists (usually 'supabase_realtime' is the default)
-- Then add the tables to it.

DO $$
BEGIN
  -- Re-create publication if it doesn't exist or just add tables
  IF NOT EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime') THEN
    CREATE PUBLICATION supabase_realtime;
  END IF;
END $$;

ALTER PUBLICATION supabase_realtime ADD TABLE documents;
ALTER PUBLICATION supabase_realtime ADD TABLE tasks;
ALTER PUBLICATION supabase_realtime ADD TABLE note_items;
ALTER PUBLICATION supabase_realtime ADD TABLE asterisk_items;
ALTER PUBLICATION supabase_realtime ADD TABLE resource_items;
ALTER PUBLICATION supabase_realtime ADD TABLE resource_item_tags;
ALTER PUBLICATION supabase_realtime ADD TABLE pantry_items;
ALTER PUBLICATION supabase_realtime ADD TABLE pantry_quantities;
ALTER PUBLICATION supabase_realtime ADD TABLE shopping_list_items;
