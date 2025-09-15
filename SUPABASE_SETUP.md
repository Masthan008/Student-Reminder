# Supabase Integration Setup Guide

This guide will help you set up Supabase as an alternative backend for your Student Reminder App by **Masthan Valli**.

## 🚀 **1. Create Supabase Project**

1. Go to [Supabase](https://supabase.com) and create an account
2. Create a new project
3. Note down your:
   - **Project URL**: `https://your-project-id.supabase.co`
   - **Anon Public Key**: `eyJhbGciOiJIUzI1...`

## 🗄️ **2. Database Schema Setup**

Execute these SQL commands in your Supabase SQL Editor:

### Users Table
```sql
-- Create users table
CREATE TABLE users (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  email TEXT NOT NULL,
  display_name TEXT NOT NULL,
  photo_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Enable RLS (Row Level Security)
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Users can only see their own data
CREATE POLICY "Users can view own profile" ON users FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON users FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can insert own profile" ON users FOR INSERT WITH CHECK (auth.uid() = id);
```

### Reminders Table
```sql
-- Create reminders table
CREATE TABLE reminders (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  date_time TIMESTAMP WITH TIME ZONE NOT NULL,
  priority INTEGER DEFAULT 1,
  is_completed BOOLEAN DEFAULT FALSE,
  category TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Enable RLS
ALTER TABLE reminders ENABLE ROW LEVEL SECURITY;

-- Users can only access their own reminders
CREATE POLICY "Users can view own reminders" ON reminders FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own reminders" ON reminders FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own reminders" ON reminders FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own reminders" ON reminders FOR DELETE USING (auth.uid() = user_id);

-- Create index for better performance
CREATE INDEX idx_reminders_user_id ON reminders(user_id);
CREATE INDEX idx_reminders_date_time ON reminders(date_time);
```

### Update Triggers
```sql
-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = TIMEZONE('utc'::text, NOW());
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply to tables
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_reminders_updated_at BEFORE UPDATE ON reminders
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

## 🔊 **3. Storage Setup for Custom Sounds**

Due to permission restrictions in Supabase, it's recommended to set up storage through the dashboard UI rather than SQL scripts to avoid ownership errors:

### Method 1: Dashboard UI Setup (Recommended)
1. Go to your Supabase project dashboard
2. Navigate to **Storage** → **Buckets**
3. Click **New Bucket**
4. Name it **sounds**
5. Set it as **Public**
6. Click **Create**

### Method 2: SQL Setup (If you have proper permissions)
If you have the necessary permissions, you can run the script in `SUPABASE_STORAGE_SETUP_FIXED.sql`:

```sql
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

-- Enable RLS on storage.objects
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;
```

## 🔧 **4. Configure Your App**

Update the Supabase service configuration:

1. Open `lib/shared/services/supabase_service.dart`
2. Replace the placeholder values:

```dart
static const String _supabaseUrl = 'https://your-project-id.supabase.co';
static const String _supabaseAnonKey = 'your-anon-public-key';
```

## 🔐 **5. Authentication Setup**

### Email/Password Authentication
Already configured! Email/password authentication will work out of the box.

### Google Authentication (Optional)
1. Go to Supabase Dashboard → Authentication → Providers
2. Enable Google provider
3. Add your Google OAuth credentials
4. Update the redirect URL in the Supabase service

## 📱 **6. Testing the Integration**

1. **Install dependencies**:
   ```bash
   flutter pub get
   ```

2. **Run the app**:
   ```bash
   flutter run
   ```

3. **Switch to Supabase**:
   - Go to Settings → Data & Sync → Backend Service
   - Select "Supabase"
   - Sign in with a new account

4. **Test features**:
   - Create reminders
   - Verify real-time sync
   - Test offline/online sync
   - Upload custom sounds

## 🎯 **7. Features You Get with Supabase**

✅ **Real-time Updates**: Changes sync instantly across devices  
✅ **PostgreSQL Database**: More powerful than Firestore  
✅ **Row Level Security**: Built-in data security  
✅ **RESTful API**: Easy to extend and customize  
✅ **Built-in Auth**: Email, OAuth, magic links  
✅ **Edge Functions**: Serverless functions when needed  
✅ **Storage**: File uploads for custom sounds  

## 🔄 **8. Migration Strategy**

The app now supports **dual backend mode**:

1. **Keep Firebase**: Existing users continue with Firebase
2. **New Users**: Can choose Supabase for better performance
3. **Gradual Migration**: Users can switch backends in settings
4. **Data Export**: Plan data migration tools (future enhancement)

## 🛠️ **9. Backend Comparison**

| Feature | Firebase | Supabase |
|---------|----------|----------|
| Database | NoSQL (Firestore) | PostgreSQL |
| Real-time | Yes | Yes |
| Authentication | Yes | Yes |
| Pricing | Pay per operation | Pay per compute |
| Offline Support | Excellent | Good |
| Query Flexibility | Limited | SQL queries |
| Open Source | No | Yes |

## 🐛 **10. Troubleshooting**

### Common Issues:

1. **"Invalid API Key"**: Check your Supabase URL and anon key
2. **RLS Policy Errors**: Ensure Row Level Security policies are correctly set
3. **Connection Timeout**: Check your internet connection and Supabase status
4. **Storage Permission Errors**: Use the dashboard UI method for storage setup
5. **Ownership Errors**: When running SQL scripts, make sure you have proper permissions

### Debug Mode:
The app includes debug logging. Check console for Supabase connection status.

## 📞 **11. Support**

- **Supabase Documentation**: [docs.supabase.com](https://docs.supabase.com)
- **Flutter Supabase Docs**: [supabase.com/docs/guides/getting-started/tutorials/with-flutter](https://supabase.com/docs/guides/getting-started/tutorials/with-flutter)
- **Project Owner**: Masthan Valli (masthanvallibaba009@gmail.com)

---

**Note**: This integration maintains full compatibility with your existing Firebase setup. Users can switch between backends seamlessly!