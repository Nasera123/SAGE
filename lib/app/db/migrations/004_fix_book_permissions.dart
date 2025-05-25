import 'package:supabase_flutter/supabase_flutter.dart';

class FixBookPermissionsMigration {
  final SupabaseClient client;
  
  FixBookPermissionsMigration(this.client);
  
  Future<void> migrate() async {
    try {
      print('Starting book permissions migration...');
      
      // Pastikan tabel books sudah benar
      await _ensureBooksTable();
      
      // Pastikan RLS diaktifkan
      await _enableRLS();
      
      // Hapus kebijakan yang mungkin konflik
      await _dropConflictingPolicies();
      
      // Buat kebijakan baru
      await _createPolicies();
      
      print('Book permissions migration completed successfully');
    } catch (e) {
      print('Error during book permissions migration: $e');
      throw e;
    }
  }
  
  Future<void> _ensureBooksTable() async {
    print('Ensuring books table is properly set up...');
    
    // Pastikan kolom yang dibutuhkan sudah ada
    try {
      await client.rpc('add_column_if_not_exists', params: {
        'table_name': 'books',
        'column_name': 'title',
        'column_type': 'text NOT NULL'
      });
      
      await client.rpc('add_column_if_not_exists', params: {
        'table_name': 'books',
        'column_name': 'user_id',
        'column_type': 'uuid NOT NULL REFERENCES auth.users(id)'
      });
      
      await client.rpc('add_column_if_not_exists', params: {
        'table_name': 'books',
        'column_name': 'created_at',
        'column_type': 'timestamp with time zone DEFAULT now() NOT NULL'
      });
      
      await client.rpc('add_column_if_not_exists', params: {
        'table_name': 'books',
        'column_name': 'updated_at',
        'column_type': 'timestamp with time zone DEFAULT now() NOT NULL'
      });
      
      print('Books table columns verified');
    } catch (e) {
      print('Error verifying book table columns: $e');
      // Lanjutkan proses, karena mungkin tabel sudah ada
    }
  }
  
  Future<void> _enableRLS() async {
    print('Enabling Row Level Security for books table...');
    
    try {
      await client.rpc('pgcode', params: {
        'code': 'ALTER TABLE public.books ENABLE ROW LEVEL SECURITY;'
      });
      print('RLS enabled for books table');
    } catch (e) {
      print('Error enabling RLS (might already be enabled): $e');
      // Lanjutkan proses
    }
  }
  
  Future<void> _dropConflictingPolicies() async {
    print('Dropping potentially conflicting policies...');
    
    try {
      final policies = [
        'books_insert_policy',
        'books_select_policy',
        'books_update_policy',
        'books_delete_policy',
        'public_books_are_viewable_by_all'
      ];
      
      for (final policy in policies) {
        await client.rpc('pgcode', params: {
          'code': 'DROP POLICY IF EXISTS $policy ON public.books;'
        });
      }
      
      print('Conflicting policies dropped');
    } catch (e) {
      print('Error dropping conflicting policies: $e');
      // Lanjutkan proses
    }
  }
  
  Future<void> _createPolicies() async {
    print('Creating new book policies...');
    
    try {
      // Kebijakan INSERT - hanya user yang terautentikasi
      await client.rpc('pgcode', params: {
        'code': '''
CREATE POLICY books_insert_policy 
  ON public.books 
  FOR INSERT 
  TO authenticated 
  WITH CHECK (auth.uid() = user_id);
        '''
      });
      
      // Kebijakan SELECT - user dapat melihat buku mereka sendiri atau buku publik
      await client.rpc('pgcode', params: {
        'code': '''
CREATE POLICY books_select_policy 
  ON public.books 
  FOR SELECT 
  TO authenticated 
  USING (auth.uid() = user_id OR is_public = true);
        '''
      });
      
      // Kebijakan UPDATE - hanya pemilik buku
      await client.rpc('pgcode', params: {
        'code': '''
CREATE POLICY books_update_policy 
  ON public.books 
  FOR UPDATE 
  TO authenticated 
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
        '''
      });
      
      // Kebijakan DELETE - hanya pemilik buku
      await client.rpc('pgcode', params: {
        'code': '''
CREATE POLICY books_delete_policy 
  ON public.books 
  FOR DELETE 
  TO authenticated 
  USING (auth.uid() = user_id);
        '''
      });
      
      print('Book policies created successfully');
    } catch (e) {
      print('Error creating book policies: $e');
      throw e;
    }
  }
} 