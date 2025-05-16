import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/tag_model.dart';
import '../services/supabase_service.dart';
import 'package:get/get.dart';

class TagRepository {
  final SupabaseService _supabaseService = Get.find<SupabaseService>();

  Future<List<Tag>> getTags() async {
    try {
      final response = await _supabaseService.client
          .from('tags')
          .select()
          .eq('user_id', _supabaseService.currentUser!.id)
          .order('name', ascending: true);

      return (response as List).map((data) => Tag.fromJson(data)).toList();
    } catch (e) {
      print('Error getting tags: $e');
      rethrow;
    }
  }

  Future<Tag> createTag({required String name}) async {
    try {
      final userId = _supabaseService.currentUser!.id;
      final data = {
        'name': name,
        'user_id': userId,
      };

      final response = await _supabaseService.client
          .from('tags')
          .insert(data)
          .select()
          .single();

      return Tag.fromJson(response);
    } catch (e) {
      print('Error creating tag: $e');
      rethrow;
    }
  }

  Future<Tag> updateTag({required Tag tag}) async {
    try {
      final response = await _supabaseService.client
          .from('tags')
          .update({'name': tag.name})
          .eq('id', tag.id)
          .select()
          .single();

      return Tag.fromJson(response);
    } catch (e) {
      print('Error updating tag: $e');
      rethrow;
    }
  }

  Future<void> deleteTag({required String id}) async {
    try {
      // First delete all note-tag associations for this tag
      await _supabaseService.client
          .from('note_tags')
          .delete()
          .eq('tag_id', id);
      
      // Then delete the tag itself
      await _supabaseService.client
          .from('tags')
          .delete()
          .eq('id', id);
    } catch (e) {
      print('Error deleting tag: $e');
      rethrow;
    }
  }

  Future<Tag?> getTagByName({required String name}) async {
    try {
      final response = await _supabaseService.client
          .from('tags')
          .select()
          .eq('user_id', _supabaseService.currentUser!.id)
          .eq('name', name)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return Tag.fromJson(response);
    } catch (e) {
      print('Error getting tag by name: $e');
      rethrow;
    }
  }

  Future<Tag> getOrCreateTag({required String name}) async {
    try {
      final existingTag = await getTagByName(name: name);
      if (existingTag != null) {
        return existingTag;
      }

      return await createTag(name: name);
    } catch (e) {
      print('Error getting or creating tag: $e');
      rethrow;
    }
  }

  RealtimeChannel subscribeTagChanges({Function(PostgresChangePayload)? onTagChange}) {
    final userId = _supabaseService.currentUser!.id;
    return _supabaseService.subscribeTagChanges(
      userId: userId,
      callback: onTagChange
    );
  }
} 