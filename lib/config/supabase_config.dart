class SupabaseConfig {
  // Centralized Supabase instance by Masthan Valli
  // All users' data will be stored in this shared Supabase project
  static const String supabaseUrl = 'https://forbzrjseqldtsuebelq.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZvcmJ6cmpzZXFsZHRzdWViZWxxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc4NDEzNTEsImV4cCI6MjA3MzQxNzM1MX0.jnzG7jV5gSn3BMD6JuRtrstWxIFFBCz1s0N-VeRLWAg'; // You need to provide this
  
  // Storage bucket name for sound files
  static const String soundsBucketName = 'sounds';
  
  // Validation
  static bool get isConfigured {
    return supabaseUrl != 'YOUR_SUPABASE_URL' && 
           supabaseAnonKey != 'YOUR_SUPABASE_ANON_KEY' &&
           supabaseAnonKey != 'YOUR_ANON_PUBLIC_KEY_HERE' &&
           supabaseUrl.isNotEmpty && 
           supabaseAnonKey.isNotEmpty;
  }
  
  static String get configurationMessage {
    if (!isConfigured) {
      return '''
⚠️ Missing Anon Public Key

The Supabase URL is configured, but the anon public key is needed.
Please provide the anon public key for your Supabase project:
https://forbzrjseqldtsuebelq.supabase.co

Get it from: Supabase Dashboard → Settings → API → anon public key
      ''';
    }
    return 'Supabase is properly configured ✅';
  }
}