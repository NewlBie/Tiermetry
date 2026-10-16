-- Migration 20260814000000: Storage Schema for Avatars
-- Creates the avatars bucket and defines RLS policies for secure profile image management.

-- 1. Create the bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO NOTHING;

-- 2. Storage Policies

-- Allow public read access to all files in the 'public/' folder
CREATE POLICY "Public Access"
ON storage.objects FOR SELECT
USING (bucket_id = 'avatars' AND (storage.foldername(name))[1] = 'public');

-- Allow authenticated users to upload files to 'public/'
-- if the filename starts with their own user ID.
-- Example path: public/uuid-timestamp.png
CREATE POLICY "Users can upload their own avatar"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'avatars' AND
  (storage.foldername(name))[1] = 'public' AND
  (storage.filename(name)) LIKE (auth.uid()::text || '-%')
);

-- Allow users to update their own avatar
CREATE POLICY "Users can update their own avatar"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'avatars' AND
  (storage.foldername(name))[1] = 'public' AND
  (storage.filename(name)) LIKE (auth.uid()::text || '-%')
);

-- Allow users to delete their own avatar
CREATE POLICY "Users can delete their own avatar"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'avatars' AND
  (storage.foldername(name))[1] = 'public' AND
  (storage.filename(name)) LIKE (auth.uid()::text || '-%')
);
