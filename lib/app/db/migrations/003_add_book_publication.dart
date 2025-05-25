import 'package:supabase_flutter/supabase_flutter.dart';

class AddBookPublicationMigration {
  final SupabaseClient client;
  
  AddBookPublicationMigration(this.client);
  
  Future<void> migrate() async {
    try {
      // Add is_public field to books table if it doesn't exist
      await client.rpc('add_column_if_not_exists', params: {
        'table_name': 'books',
        'column_name': 'is_public',
        'column_type': 'boolean DEFAULT false'
      });
      
      // Add user_display_name field to books table if it doesn't exist
      await client.rpc('add_column_if_not_exists', params: {
        'table_name': 'books',
        'column_name': 'user_display_name',
        'column_type': 'text'
      });
      
      // Add description field to books table if it doesn't exist
      await client.rpc('add_column_if_not_exists', params: {
        'table_name': 'books',
        'column_name': 'description',
        'column_type': 'text'
      });
      
      // Update RLS policies to allow reading of public books
      await client.rpc('create_rls_policy_if_not_exists', params: {
        'table_name': 'books',
        'policy_name': 'public_books_are_viewable_by_all',
        'policy_definition': 'is_public = true',
        'policy_action': 'SELECT',
        'policy_role': 'authenticated',
        'policy_command': 'PERMISSIVE'
      });
      
      // Update RLS policies to allow reading notes in public books
      await client.rpc('create_rls_policy_if_not_exists', params: {
        'table_name': 'notes',
        'policy_name': 'notes_in_public_books_are_viewable',
        'policy_definition': 'id IN (SELECT unnest(page_ids) FROM books WHERE is_public = true)',
        'policy_action': 'SELECT',
        'policy_role': 'authenticated',
        'policy_command': 'PERMISSIVE'
      });
      
      print('Successfully migrated database for book publication feature');
    } catch (e) {
      print('Error during book publication migration: $e');
      throw e;
    }
  }
} 