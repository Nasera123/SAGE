import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/folder_model.dart';
import '../services/supabase_service.dart';
import 'package:get/get.dart';

class FolderRepository {
  final SupabaseService _supabaseService = Get.find<SupabaseService>();

  Future<List<Folder>> getFolders() async {
    try {
      final response = await _supabaseService.client
          .from('folders')
          .select()
          .eq('user_id', _supabaseService.currentUser!.id)
          .order('name', ascending: true);

      return (response as List).map((data) => Folder.fromJson(data)).toList();
    } catch (e) {
      print('Error getting folders: $e');
      rethrow;
    }
  }

  Future<Folder> createFolder({required String name}) async {
    try {
      final userId = _supabaseService.currentUser!.id;
      final data = {
        'name': name,
        'user_id': userId,
      };

      final response = await _supabaseService.client
          .from('folders')
          .insert(data)
          .select()
          .single();

      return Folder.fromJson(response);
    } catch (e) {
      print('Error creating folder: $e');
      rethrow;
    }
  }

  Future<Folder> updateFolder({required Folder folder}) async {
    try {
      final response = await _supabaseService.client
          .from('folders')
          .update({'name': folder.name})
          .eq('id', folder.id)
          .select()
          .single();

      return Folder.fromJson(response);
    } catch (e) {
      print('Error updating folder: $e');
      rethrow;
    }
  }

  Future<void> deleteFolder({required String id}) async {
    try {
      await _supabaseService.client.from('folders').delete().eq('id', id);
    } catch (e) {
      print('Error deleting folder: $e');
      rethrow;
    }
  }

  RealtimeChannel subscribeFolderChanges({Function(PostgresChangePayload)? onFolderChange}) {
    final userId = _supabaseService.currentUser!.id;
    return _supabaseService.subscribeFolderChanges(
      userId: userId,
      callback: onFolderChange
    );
  }
} 