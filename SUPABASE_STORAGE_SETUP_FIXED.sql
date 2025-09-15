-- Supabase Storage Setup for Custom Sounds - Fixed Version
-- This script addresses the ownership permission issue by using proper syntax

-- IMPORTANT: Run this script in the Supabase SQL Editor with a user that has proper permissions
-- If you get permission errors, use the Supabase Dashboard UI instead:
-- 1. Go to Storage → Buckets
-- 2. Create a new bucket named "sounds"
-- 3. Set it as Public

-- Check if the sounds bucket exists, if not create it
-- Note: This approach uses the Supabase storage API rather than direct table manipulation
-- which avoids ownership issues

-- First, we'll create the bucket through the Supabase API (this is typically done via UI)
-- For reference, the equivalent SQL would be handled by Supabase internally

-- Instead, we'll focus on setting up the proper policies for the sounds bucket
-- These policies should be applied AFTER creating the bucket via the Supabase Dashboard

-- Policy for authenticated users to upload sounds to their folder
CREATE POLICY "Users can upload sounds to their folder" 
ON storage.objects FOR INSERT 
TO authenticated 
WITH CHECK (
  bucket_id = 'sounds' 
  AND (storage.foldername(name))[1] = 'user_sounds'
  AND (storage.foldername(name))[2] = (auth.uid())::text
);

-- Policy for users to read their own sounds
CREATE POLICY "Users can read their own sounds" 
ON storage.objects FOR SELECT 
TO authenticated 
USING (
  bucket_id = 'sounds' 
  AND (storage.foldername(name))[1] = 'user_sounds'
  AND (storage.foldername(name))[2] = (auth.uid())::text
);

-- Policy for users to delete their own sounds
CREATE POLICY "Users can delete their own sounds" 
ON storage.objects FOR DELETE 
TO authenticated 
USING (
  bucket_id = 'sounds' 
  AND (storage.foldername(name))[1] = 'user_sounds'
  AND (storage.foldername(name))[2] = (auth.uid())::text
);

-- Policy for public to read sounds (needed for playing sounds)
CREATE POLICY "Public can read sounds" 
ON storage.objects FOR SELECT 
TO public 
USING (bucket_id = 'sounds');

-- If the above policies already exist and you get errors, drop them first:
-- DROP POLICY IF EXISTS "Users can upload sounds to their folder" ON storage.objects;
-- DROP POLICY IF EXISTS "Users can read their own sounds" ON storage.objects;
-- DROP POLICY IF EXISTS "Users can delete their own sounds" ON storage.objects;
-- DROP POLICY IF EXISTS "Public can read sounds" ON storage.objects;

-- Enable RLS on storage.objects if not already enabled
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;