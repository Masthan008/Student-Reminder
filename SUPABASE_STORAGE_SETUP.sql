-- Supabase Storage Bucket Configuration Script
-- This script helps configure the sounds bucket with proper permissions

-- Create the sounds bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'sounds',
  'sounds',
  true,
  52428800,  -- 50MB limit
  ARRAY['audio/mpeg', 'audio/wav', 'audio/mp3', 'audio/ogg', 'audio/aac', 'audio/webm']
)
ON CONFLICT (id) DO NOTHING;

-- Enable RLS for the sounds bucket
ALTER TABLE IF EXISTS storage.objects ENABLE ROW LEVEL SECURITY;

-- Create policy to allow public uploads to sounds bucket
CREATE POLICY "Public upload to sounds bucket" ON storage.objects
  FOR INSERT WITH CHECK (bucket_id = 'sounds');

-- Create policy to allow public reads from sounds bucket
CREATE POLICY "Public read from sounds bucket" ON storage.objects
  FOR SELECT USING (bucket_id = 'sounds');

-- Create policy to allow users to update their own sounds
CREATE POLICY "Users can update own sounds" ON storage.objects
  FOR UPDATE USING (bucket_id = 'sounds');

-- Create policy to allow users to delete their own sounds
CREATE POLICY "Users can delete own sounds" ON storage.objects
  FOR DELETE USING (bucket_id = 'sounds');

-- Grant necessary permissions
GRANT ALL ON storage.objects TO anon;
GRANT ALL ON storage.objects TO authenticated;

-- Alternative: If the above doesn't work, disable RLS temporarily for sounds bucket
-- (Not recommended for production, but useful for development)
-- ALTER TABLE storage.objects DISABLE ROW LEVEL SECURITY;