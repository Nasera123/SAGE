import 'package:supabase_flutter/supabase_flutter.dart';

class FixMissingColumnsMigration {
  final SupabaseClient client;
  
  FixMissingColumnsMigration(this.client);
  
  Future<void> migrate() async {
    try {
      print('Starting to fix missing columns migration...');
      
      // Tambahkan kolom yang hilang langsung menggunakan SQL
      await _addMissingColumns();
      
      print('Missing columns migration completed successfully');
    } catch (e) {
      print('Error during missing columns migration: $e');
      throw e;
    }
  }
  
  Future<void> _addMissingColumns() async {
    print('Adding missing columns to books table...');
    
    try {
      // Gunakan SQL langsung karena RPC function gagal
      await client.rpc('pgcode', params: {
        'code': '''
          -- Tambahkan kolom is_public jika belum ada
          DO \$\$ 
          BEGIN 
            IF NOT EXISTS(SELECT 1 FROM information_schema.columns 
                         WHERE table_name='books' AND column_name='is_public') THEN
              ALTER TABLE books ADD COLUMN is_public BOOLEAN DEFAULT false;
            END IF;
          END \$\$;
          
          -- Tambahkan kolom description jika belum ada
          DO \$\$ 
          BEGIN 
            IF NOT EXISTS(SELECT 1 FROM information_schema.columns 
                         WHERE table_name='books' AND column_name='description') THEN
              ALTER TABLE books ADD COLUMN description TEXT;
            END IF;
          END \$\$;
          
          -- Tambahkan kolom user_display_name jika belum ada
          DO \$\$ 
          BEGIN 
            IF NOT EXISTS(SELECT 1 FROM information_schema.columns 
                         WHERE table_name='books' AND column_name='user_display_name') THEN
              ALTER TABLE books ADD COLUMN user_display_name TEXT;
            END IF;
          END \$\$;
          
          -- Tambahkan kolom page_ids jika belum ada
          DO \$\$ 
          BEGIN 
            IF NOT EXISTS(SELECT 1 FROM information_schema.columns 
                         WHERE table_name='books' AND column_name='page_ids') THEN
              ALTER TABLE books ADD COLUMN page_ids TEXT[] DEFAULT '{}';
            END IF;
          END \$\$;
          
          -- Tambahkan kolom is_deleted jika belum ada
          DO \$\$ 
          BEGIN 
            IF NOT EXISTS(SELECT 1 FROM information_schema.columns 
                         WHERE table_name='books' AND column_name='is_deleted') THEN
              ALTER TABLE books ADD COLUMN is_deleted BOOLEAN DEFAULT false;
            END IF;
          END \$\$;
          
          -- Tambahkan kolom deleted_at jika belum ada
          DO \$\$ 
          BEGIN 
            IF NOT EXISTS(SELECT 1 FROM information_schema.columns 
                         WHERE table_name='books' AND column_name='deleted_at') THEN
              ALTER TABLE books ADD COLUMN deleted_at TIMESTAMP WITH TIME ZONE;
            END IF;
          END \$\$;
        '''
      });
      
      print('Columns added successfully to books table');
    } catch (e) {
      print('Error adding missing columns: $e');
      throw e;
    }
  }
} 