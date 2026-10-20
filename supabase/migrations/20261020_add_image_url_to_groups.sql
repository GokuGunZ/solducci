-- =====================================================
-- Migration: Add image_url to groups table
-- Date: 2026-10-20
-- Description: Adds image_url column to groups table for custom group avatar support
-- =====================================================

ALTER TABLE IF EXISTS groups 
ADD COLUMN IF NOT EXISTS image_url TEXT;

COMMENT ON COLUMN groups.image_url IS 'Custom avatar/image URL or data URI for the expense group';

-- Force PostgREST schema cache reload
NOTIFY pgrst, 'reload schema';
