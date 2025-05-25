import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'data/services/supabase_service.dart';
import 'db/migrations/003_add_book_publication.dart';
import 'db/migrations/004_fix_book_permissions.dart';
import 'db/migrations/005_fix_missing_columns.dart';

class DatabaseInitializer {
  static Future<void> initializeDatabase() async {
    try {
      final SupabaseClient client = Get.find<SupabaseService>().client;
      
      // Set up RPC functions needed for migrations if they don't exist
      await _setupRpcFunctions(client);
      
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
      
      // Check if book covers storage bucket exists and create it if it doesn't
      try {
        await client.storage.getBucket('book_covers');
        print('Book covers bucket already exists.');
      } catch (e) {
        print('Creating book covers storage bucket...');
        await _createBookCoversBucket(client);
      }
      
      // Run migration to fix missing columns first
      try {
        print('Running fix for missing columns in books table...');
        final columnFixer = FixMissingColumnsMigration(client);
        await columnFixer.migrate();
      } catch (e) {
        print('Error fixing missing columns: $e');
      }
      
      // Run migration for book publication feature
      try {
        print('Running book publication migration...');
        final migrator = AddBookPublicationMigration(client);
        await migrator.migrate();
      } catch (e) {
        print('Error running book publication migration: $e');
      }
      
      // Run migration to fix book permissions
      try {
        print('Running book permissions fix migration...');
        final permissionsFixer = FixBookPermissionsMigration(client);
        await permissionsFixer.migrate();
        print('Book permissions have been fixed successfully');
      } catch (e) {
        print('Error fixing book permissions: $e');
      }
      
      print('Database initialization completed successfully.');
    } catch (e) {
      print('Error initializing database: $e');
    }
  }
  
  static Future<void> _setupRpcFunctions(SupabaseClient client) async {
    // Create RPC functions to help with migrations
    
    // Function to add column if it doesn't exist
    final addColumnSql = '''
    CREATE OR REPLACE FUNCTION add_column_if_not_exists(
      table_name text, column_name text, column_type text
    ) RETURNS void AS \$\$
    BEGIN
      IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_name = \$1
        AND column_name = \$2
      ) THEN
        EXECUTE format('ALTER TABLE %I ADD COLUMN %I %s', table_name, column_name, column_type);
      END IF;
    END;
    \$\$ LANGUAGE plpgsql SECURITY DEFINER;
    ''';
    
    // Function to create RLS policy if it doesn't exist
    final createPolicySql = '''
    CREATE OR REPLACE FUNCTION create_rls_policy_if_not_exists(
      table_name text, policy_name text, policy_definition text, policy_action text, policy_role text, policy_command text
    ) RETURNS void AS \$\$
    BEGIN
      IF NOT EXISTS (
        SELECT 1
        FROM pg_policies
        WHERE tablename = \$1
        AND policyname = \$2
      ) THEN
        EXECUTE format('CREATE POLICY %I ON %I FOR %s TO %I USING (%s) WITH CHECK (%s)', 
          policy_name, table_name, policy_action, policy_role, 
          CASE WHEN policy_command = 'PERMISSIVE' THEN policy_definition ELSE 'true' END,
          CASE WHEN policy_command = 'RESTRICTIVE' THEN policy_definition ELSE 'true' END);
      END IF;
    END;
    \$\$ LANGUAGE plpgsql SECURITY DEFINER;
    ''';
    
    // Execute SQL via RPC
    try {
      await client.rpc('pgcode', params: {'code': addColumnSql});
      await client.rpc('pgcode', params: {'code': createPolicySql});
      print('RPC migration functions created successfully.');
    } catch (e) {
      print('Error creating RPC functions: $e');
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
  
  static Future<void> _createBookCoversBucket(SupabaseClient client) async {
    try {
      // Create book_covers bucket
      await client.storage.createBucket('book_covers', const BucketOptions(
        public: true,
      ));
      
      print('Book covers bucket created successfully.');
      print('Please set up appropriate bucket policies manually in the Supabase dashboard.');
    } catch (e) {
      print('Error creating book covers bucket: $e');
      print('Please create the book_covers bucket manually in the Supabase dashboard.');
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

-- Add columns for book publication feature
ALTER TABLE public.books ADD COLUMN IF NOT EXISTS is_public BOOLEAN DEFAULT false;
ALTER TABLE public.books ADD COLUMN IF NOT EXISTS user_display_name TEXT;
ALTER TABLE public.books ADD COLUMN IF NOT EXISTS description TEXT;

-- Create RLS policy to allow reading of public books
CREATE POLICY "Public books are viewable by all"
  ON public.books
  FOR SELECT
  USING (is_public = true);

-- Create RLS policy to allow reading notes in public books
CREATE POLICY "Notes in public books are viewable"
  ON public.notes
  FOR SELECT
  USING (id IN (SELECT unnest(page_ids) FROM books WHERE is_public = true));

3. CREATE STORAGE BUCKETS
   - Navigate to Storage in your Supabase dashboard
   - Create buckets named 'avatars' and 'book_covers'
   - Make sure they're set to public access
   - Set appropriate policies to allow authenticated users to upload files

*/ 