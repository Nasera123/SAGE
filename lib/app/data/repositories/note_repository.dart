import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/note_model.dart';
import '../models/tag_model.dart' as tag_lib;
import '../services/supabase_service.dart';
import 'package:get/get.dart';

class NoteRepository {
  final SupabaseService _supabaseService = Get.find<SupabaseService>();

  Future<List<Note>> getNotes({String? folderId}) async {
    try {
      var query = _supabaseService.client
          .from('notes')
          .select();

      if (folderId != null) {
        query = query.eq('folder_id', folderId);
      } else {
        query = query.eq('user_id', _supabaseService.currentUser!.id);
      }

      final response = await query.order('updated_at', ascending: false);
      final notesList = (response as List).map((data) => Note.fromJson(data)).toList();

      // Fetch tags for each note
      for (var i = 0; i < notesList.length; i++) {
        final tags = await getTagsForNote(notesList[i].id);
        notesList[i] = notesList[i].copyWith(tags: tags);
      }

      return notesList;
    } catch (e) {
      print('Error getting notes: $e');
      rethrow;
    }
  }

  Future<List<Note>> getNotesByTag(String tagId) async {
    try {
      final response = await _supabaseService.client
          .from('note_tags')
          .select('note_id')
          .eq('tag_id', tagId);

      final noteIds = (response as List).map((item) => item['note_id'] as String).toList();

      if (noteIds.isEmpty) {
        return [];
      }

      final notesResponse = await _supabaseService.client
          .from('notes')
          .select()
          .eq('user_id', _supabaseService.currentUser!.id)
          .inFilter('id', noteIds)
          .order('updated_at', ascending: false);

      final notesList = (notesResponse as List).map((data) => Note.fromJson(data)).toList();

      // Fetch tags for each note
      for (var i = 0; i < notesList.length; i++) {
        final tags = await getTagsForNote(notesList[i].id);
        notesList[i] = notesList[i].copyWith(tags: tags);
      }

      return notesList;
    } catch (e) {
      print('Error getting notes by tag: $e');
      rethrow;
    }
  }

  Future<Note> getNote(String id) async {
    try {
      final response = await _supabaseService.client
          .from('notes')
          .select()
          .eq('id', id)
          .single();

      final note = Note.fromJson(response);
      final tags = await getTagsForNote(id);

      return note.copyWith(tags: tags);
    } catch (e) {
      print('Error getting note: $e');
      rethrow;
    }
  }

  Future<Note> createNote({
    required String title,
    required String content,
    String? folderId,
  }) async {
    try {
      final userId = _supabaseService.currentUser!.id;
      final data = {
        'title': title,
        'content': content,
        'user_id': userId,
        'folder_id': folderId,
      };

      final response = await _supabaseService.client
          .from('notes')
          .insert(data)
          .select()
          .single();

      return Note.fromJson(response);
    } catch (e) {
      print('Error creating note: $e');
      rethrow;
    }
  }

  Future<Note> updateNote({
    required Note note,
  }) async {
    try {
      final data = {
        'title': note.title,
        'content': note.content,
        'folder_id': note.folderId,
      };

      final response = await _supabaseService.client
          .from('notes')
          .update(data)
          .eq('id', note.id)
          .select()
          .single();

      final updatedNote = Note.fromJson(response);
      final tags = await getTagsForNote(updatedNote.id);

      return updatedNote.copyWith(tags: tags);
    } catch (e) {
      print('Error updating note: $e');
      rethrow;
    }
  }

  Future<void> deleteNote({required String id}) async {
    try {
      await _supabaseService.client.from('notes').delete().eq('id', id);
    } catch (e) {
      print('Error deleting note: $e');
      rethrow;
    }
  }

  Future<void> moveNoteToFolder({required String noteId, String? folderId}) async {
    try {
      await _supabaseService.client
          .from('notes')
          .update({'folder_id': folderId})
          .eq('id', noteId);
    } catch (e) {
      print('Error moving note to folder: $e');
      rethrow;
    }
  }

  Future<List<tag_lib.Tag>> getTagsForNote(String noteId) async {
    try {
      final response = await _supabaseService.client
          .from('note_tags')
          .select('tag_id')
          .eq('note_id', noteId);

      final tagIds = (response as List).map((item) => item['tag_id'] as String).toList();

      if (tagIds.isEmpty) {
        return [];
      }

      final tagsResponse = await _supabaseService.client
          .from('tags')
          .select()
          .inFilter('id', tagIds);

      return (tagsResponse as List).map((data) => tag_lib.Tag.fromJson(data)).toList();
    } catch (e) {
      print('Error getting tags for note: $e');
      rethrow;
    }
  }

  Future<void> addTagToNote({required String noteId, required String tagId}) async {
    try {
      await _supabaseService.client.from('note_tags').insert({
        'note_id': noteId,
        'tag_id': tagId,
      });
    } catch (e) {
      print('Error adding tag to note: $e');
      rethrow;
    }
  }

  Future<void> removeTagFromNote({required String noteId, required String tagId}) async {
    try {
      await _supabaseService.client
          .from('note_tags')
          .delete()
          .eq('note_id', noteId)
          .eq('tag_id', tagId);
    } catch (e) {
      print('Error removing tag from note: $e');
      rethrow;
    }
  }

  // Subscribe to all user's notes changes
  RealtimeChannel subscribeNoteChanges({Function(PostgresChangePayload)? onNoteChange}) {
    final userId = _supabaseService.currentUser!.id;
    return _supabaseService.subscribeNoteChanges(
      userId: userId, 
      callback: onNoteChange
    );
  }

  // Subscribe to specific note changes
  RealtimeChannel subscribeSpecificNoteChanges({
    required String noteId, 
    Function(PostgresChangePayload)? onNoteChange
  }) {
    // Create a channel specifically for this note
    final channel = _supabaseService.client.channel('note:$noteId');
    
    // Add postgres changes listener
    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'notes',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'id',
        value: noteId,
      ),
      callback: onNoteChange ?? (payload) {
        print('Note change detected for note: $noteId - ${payload.eventType}');
      },
    );
    
    // Subscribe to the channel
    channel.subscribe();
    
    return channel;
  }

  RealtimeChannel subscribeNoteTagChanges({Function(PostgresChangePayload)? onNoteTagChange}) {
    return _supabaseService.subscribeNoteTagChanges(
      callback: onNoteTagChange
    );
  }
} 