-- ============================================================================
-- Migration: Add is_enabled column to recurrences table
-- Description: Adds a boolean column to enable/disable recurrences without deleting them
-- Created: 2024-12-20
-- ============================================================================

-- Add is_enabled column with default value TRUE
ALTER TABLE recurrences
ADD COLUMN is_enabled BOOLEAN NOT NULL DEFAULT TRUE;

-- Add comment for documentation
COMMENT ON COLUMN recurrences.is_enabled IS 'Toggle to enable/disable the recurrence without deleting it';

-- Create index for better query performance when filtering active recurrences
CREATE INDEX IF NOT EXISTS idx_recurrences_is_enabled ON recurrences(is_enabled);
