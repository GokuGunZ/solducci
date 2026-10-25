-- 2026102501_add_preferences_to_profiles.sql
-- Add JSONB preferences column to public.profiles for cross-device user settings (INT-D016 / Step 3.2a)
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS preferences JSONB DEFAULT '{}'::jsonb;

COMMENT ON COLUMN public.profiles.preferences IS 'Cross-device user preferences (LifeOS role property packs, UI settings)';
