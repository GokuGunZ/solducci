-- 20260722_dashboard_redesign_schema.sql
-- Create table for storing Bento Grid dashboard configurations per users

CREATE TABLE IF NOT EXISTS public.user_dashboards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    device_type TEXT NOT NULL DEFAULT 'mobile' CHECK (device_type IN ('mobile', 'tablet', 'desktop')),
    layout_json JSONB NOT NULL DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, device_type)
);

COMMENT ON TABLE public.user_dashboards IS 'Stores the Bento Grid layout configuration for a users dashboard';

-- Set up Row Level Security (RLS)
ALTER TABLE public.user_dashboards ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own dashboards" 
    ON public.user_dashboards FOR SELECT 
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own dashboards" 
    ON public.user_dashboards FOR INSERT 
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own dashboards" 
    ON public.user_dashboards FOR UPDATE 
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own dashboards" 
    ON public.user_dashboards FOR DELETE 
    USING (auth.uid() = user_id);
