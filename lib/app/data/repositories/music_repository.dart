import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/music_model.dart';
import '../services/supabase_service.dart';

class MusicRepository {
  final SupabaseService _supabaseService = Get.find<SupabaseService>();
  
  SupabaseClient get client => _supabaseService.client;
  
  // Get all music for current user
  Future<List<Music>> getMusic({bool includeDeleted = false}) async {
    final User? currentUser = _supabaseService.client.auth.currentUser;
    if (currentUser == null) return [];
    
    try {
      var query = _supabaseService.client
          .from('music')
          .select('*')
          .eq('user_id', currentUser.id);
          
      // Exclude deleted music by default
      if (!includeDeleted) {
        query = query.eq('is_deleted', false);
      }
      
      final response = await query.order('created_at', ascending: false);
      
      return response.map<Music>((music) => Music.fromJson(music)).toList();
    } catch (e) {
      print('Error getting music: $e');
      return [];
    }
  }
  
  // Get single music by ID
  Future<Music?> getMusicById(String id, {bool includeDeleted = false}) async {
    final User? currentUser = _supabaseService.client.auth.currentUser;
    if (currentUser == null) return null;
    
    try {
      var query = _supabaseService.client
          .from('music')
          .select('*')
          .eq('id', id)
          .eq('user_id', currentUser.id);
          
      // Only check for deletion status if requested
      if (!includeDeleted) {
        query = query.eq('is_deleted', false);
      }
      
      final response = await query.single();
      
      return Music.fromJson(response);
    } catch (e) {
      print('Error getting music: $e');
      return null;
    }
  }
  
  // Create a new music entry
  Future<Music?> createMusic({
    required String title,
    required String artist,
    required String url,
  }) async {
    final User? currentUser = _supabaseService.client.auth.currentUser;
    if (currentUser == null) return null;
    
    try {
      final music = Music(
        userId: currentUser.id,
        title: title,
        artist: artist,
        url: url,
      );
      
      final response = await _supabaseService.client
          .from('music')
          .insert(music.toJsonForCreate())
          .select()
          .single();
      
      return Music.fromJson(response);
    } catch (e) {
      print('Error creating music: $e');
      return null;
    }
  }
  
  // Update a music
  Future<Music?> updateMusic(Music music) async {
    final User? currentUser = _supabaseService.client.auth.currentUser;
    if (currentUser == null) return null;
    
    try {
      final response = await _supabaseService.client
          .from('music')
          .update({
            'title': music.title,
            'artist': music.artist,
            'url': music.url,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', music.id)
          .select()
          .single();
      
      return Music.fromJson(response);
    } catch (e) {
      print('Error updating music: $e');
      return null;
    }
  }
  
  // Move music to trash
  Future<bool> deleteMusic(String id) async {
    final User? currentUser = _supabaseService.client.auth.currentUser;
    if (currentUser == null) return false;
    
    try {
      await _supabaseService.client
          .from('music')
          .update({
            'is_deleted': true,
            'deleted_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
      
      return true;
    } catch (e) {
      print('Error deleting music: $e');
      return false;
    }
  }
  
  // Permanently delete a music
  Future<bool> permanentlyDeleteMusic(String id) async {
    final User? currentUser = _supabaseService.client.auth.currentUser;
    if (currentUser == null) return false;
    
    try {
      await _supabaseService.client
          .from('music')
          .delete()
          .eq('id', id);
      
      return true;
    } catch (e) {
      print('Error permanently deleting music: $e');
      return false;
    }
  }
  
  // Restore music from trash
  Future<bool> restoreMusic(String id) async {
    final User? currentUser = _supabaseService.client.auth.currentUser;
    if (currentUser == null) return false;
    
    try {
      await _supabaseService.client
          .from('music')
          .update({
            'is_deleted': false,
            'deleted_at': null,
          })
          .eq('id', id);
      
      return true;
    } catch (e) {
      print('Error restoring music: $e');
      return false;
    }
  }
  
  // Get music for a note
  Future<Music?> getMusicForNote(String noteId) async {
    final User? currentUser = _supabaseService.client.auth.currentUser;
    if (currentUser == null) return null;
    
    try {
      final join = await _supabaseService.client
          .from('note_music')
          .select('music_id')
          .eq('note_id', noteId)
          .single();
      
      if (join != null) {
        final musicId = join['music_id'];
        return await getMusicById(musicId);
      }
      
      return null;
    } catch (e) {
      print('Error getting music for note: $e');
      return null;
    }
  }
  
  // Set music for a note
  Future<bool> setMusicForNote(String noteId, String musicId) async {
    final User? currentUser = _supabaseService.client.auth.currentUser;
    if (currentUser == null) return false;
    
    try {
      // First, remove any existing music associations
      await _supabaseService.client
          .from('note_music')
          .delete()
          .eq('note_id', noteId);
      
      // Then add the new association
      await _supabaseService.client
          .from('note_music')
          .insert({
            'note_id': noteId,
            'music_id': musicId,
          });
      
      return true;
    } catch (e) {
      print('Error setting music for note: $e');
      return false;
    }
  }
  
  // Remove music from a note
  Future<bool> removeMusicFromNote(String noteId) async {
    final User? currentUser = _supabaseService.client.auth.currentUser;
    if (currentUser == null) return false;
    
    try {
      await _supabaseService.client
          .from('note_music')
          .delete()
          .eq('note_id', noteId);
      
      return true;
    } catch (e) {
      print('Error removing music from note: $e');
      return false;
    }
  }
  
  // Get music for a book
  Future<Music?> getMusicForBook(String bookId) async {
    final User? currentUser = _supabaseService.client.auth.currentUser;
    if (currentUser == null) return null;
    
    try {
      final join = await _supabaseService.client
          .from('book_music')
          .select('music_id')
          .eq('book_id', bookId)
          .single();
      
      if (join != null) {
        final musicId = join['music_id'];
        return await getMusicById(musicId);
      }
      
      return null;
    } catch (e) {
      print('Error getting music for book: $e');
      return null;
    }
  }
  
  // Set music for a book
  Future<bool> setMusicForBook(String bookId, String musicId) async {
    final User? currentUser = _supabaseService.client.auth.currentUser;
    if (currentUser == null) return false;
    
    try {
      // First, remove any existing music associations
      await _supabaseService.client
          .from('book_music')
          .delete()
          .eq('book_id', bookId);
      
      // Then add the new association
      await _supabaseService.client
          .from('book_music')
          .insert({
            'book_id': bookId,
            'music_id': musicId,
          });
      
      return true;
    } catch (e) {
      print('Error setting music for book: $e');
      return false;
    }
  }
  
  // Remove music from a book
  Future<bool> removeMusicFromBook(String bookId) async {
    final User? currentUser = _supabaseService.client.auth.currentUser;
    if (currentUser == null) return false;
    
    try {
      await _supabaseService.client
          .from('book_music')
          .delete()
          .eq('book_id', bookId);
      
      return true;
    } catch (e) {
      print('Error removing music from book: $e');
      return false;
    }
  }
} 