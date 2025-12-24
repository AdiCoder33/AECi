-- Create storage bucket for profile photos
INSERT INTO storage.buckets (id, name, public)
VALUES ('profiles', 'profiles', true)
ON CONFLICT (id) DO NOTHING;

-- Set up storage policies for profile photos
CREATE POLICY "Anyone can view profile photos"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'profiles');

CREATE POLICY "Users can upload their own profile photo"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'profiles' AND
  (storage.foldername(name))[1] = concat('profile_', auth.uid()::text, '.jpg')
);

CREATE POLICY "Users can update their own profile photo"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'profiles' AND
  (storage.foldername(name))[1] = concat('profile_', auth.uid()::text, '.jpg')
);

CREATE POLICY "Users can delete their own profile photo"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'profiles' AND
  (storage.foldername(name))[1] = concat('profile_', auth.uid()::text, '.jpg')
);

-- Add profile_photo_url column to profiles table if not exists
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS profile_photo_url text;

-- Add comment
COMMENT ON COLUMN public.profiles.profile_photo_url IS 'URL to user profile photo in Supabase storage';
