import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'data/services/supabase_service.dart';

class DatabaseInitializer {
  static Future<void> initializeDatabase() async {
    try {
      final SupabaseClient client = Get.find<SupabaseService>().client;
      
      // Check if profiles table exists and create it if it doesn't
      try {
        await client.from('profiles').select('id').limit(1);
        print('Profiles table already exists.');
      } catch (e) {
        print('Creating profiles table...');
        await _createProfilesTable(client);
      }
      
      // Check if avatars storage bucket exists and create it if it doesn't
      try {
        await client.storage.getBucket('avatars');
        print('Avatars bucket already exists.');
      } catch (e) {
        print('Creating avatars storage bucket...');
        await _createAvatarsBucket(client);
      }
      
      print('Database initialization completed successfully.');
    } catch (e) {
      print('Error initializing database: $e');
    }
  }
  
  static Future<void> _createProfilesTable(SupabaseClient client) async {
    // SQL to create profiles table and related policies
    final String sql = '''
    -- Create profiles table for storing user profile information
    CREATE TABLE IF NOT EXISTS public.profiles (
      id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
      full_name TEXT,
      avatar_url TEXT,
      created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
      updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
    );

    -- Create security policies to restrict access to profiles
    ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

    -- Create policy to allow users to read their own profile
    CREATE POLICY "Users can read their own profile" 
      ON public.profiles
      FOR SELECT 
      USING (auth.uid() = id);

    -- Create policy to allow users to update their own profile
    CREATE POLICY "Users can update their own profile" 
      ON public.profiles 
      FOR UPDATE 
      USING (auth.uid() = id);

    -- Create policy to allow users to insert their own profile
    CREATE POLICY "Users can insert their own profile" 
      ON public.profiles 
      FOR INSERT 
      WITH CHECK (auth.uid() = id);
    ''';
    
    // Execute SQL via REST API since we can't run raw SQL directly
    try {
      await client.rpc('pgcode', params: {'code': sql});
      print('Profiles table created successfully.');
    } catch (e) {
      print('Error creating profiles table via RPC: $e');
      print('Please create the profiles table manually using the SQL instructions.');
    }
  }
  
  static Future<void> _createAvatarsBucket(SupabaseClient client) async {
    try {
      // Create avatars bucket
      await client.storage.createBucket('avatars', const BucketOptions(
        public: true,
      ));
      
      // Note: Policy creation via API might not be available in all versions
      // of the Supabase SDK, so we'll just print instructions
      print('Avatars bucket created successfully.');
      print('Please set up appropriate bucket policies manually in the Supabase dashboard.');
    } catch (e) {
      print('Error creating avatars bucket: $e');
      print('Please create the avatars bucket manually in the Supabase dashboard.');
    }
  }
}

/*
MANUAL SETUP INSTRUCTIONS:

1. ACCESS SUPABASE DASHBOARD
   - Go to your Supabase project dashboard
   - Navigate to the SQL Editor

2. RUN THE FOLLOWING SQL SCRIPT:

-- Create profiles table for storing user profile information
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT,
  avatar_url TEXT,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Create security policies to restrict access to profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Create policy to allow users to read their own profile
CREATE POLICY "Users can read their own profile" 
  ON public.profiles
  FOR SELECT 
  USING (auth.uid() = id);

-- Create policy to allow users to update their own profile
CREATE POLICY "Users can update their own profile" 
  ON public.profiles 
  FOR UPDATE 
  USING (auth.uid() = id);

-- Create policy to allow users to insert their own profile
CREATE POLICY "Users can insert their own profile" 
  ON public.profiles 
  FOR INSERT 
  WITH CHECK (auth.uid() = id);

-- Create function to handle new user profiles automatically
CREATE OR REPLACE FUNCTION public.handle_new_user() 
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, avatar_url)
  VALUES (NEW.id, NEW.raw_user_meta_data->>'full_name', NULL);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger to handle new users and create profiles
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

3. CREATE STORAGE BUCKET FOR AVATARS
   - Navigate to Storage in your Supabase dashboard
   - Create a new bucket named 'avatars'
   - Make sure it's set to public access
   - Set appropriate policies to allow authenticated users to upload files
   - Add a policy for authenticated users to upload files to this bucket

*/ 