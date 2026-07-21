-- Add onboarded_features array to profiles to keep track of feature enrollments
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS onboarded_features text[] DEFAULT '{}'::text[];
