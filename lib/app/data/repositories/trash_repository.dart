import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/note_model.dart';
import '../models/book_model.dart';
import '../services/supabase_service.dart';
import 'package:get/get.dart';
import 'note_repository.dart';
import 'book_repository.dart';

class TrashRepository {
  final SupabaseService _supabaseService = Get.find<SupabaseService>();
  final NoteRepository _noteRepository = Get.find<NoteRepository>();
  final BookRepository _bookRepository = Get.find<BookRepository>();
  
  // Get all items in trash (both notes and books)
  Future<Map<String, dynamic>> getTrashItems() async {
    try {
      final trashedNotes = await _noteRepository.getTrashedNotes();
      final trashedBooks = await _bookRepository.getTrashedBooks();
      
      return {
        'notes': trashedNotes,
        'books': trashedBooks,
      };
    } catch (e) {
      print('Error getting trash items: $e');
      return {
        'notes': <Note>[],
        'books': <Book>[],
      };
    }
  }
  
  // Empty trash (permanently delete all items)
  Future<bool> emptyTrash() async {
    try {
      // Get all trashed notes
      final trashedNotes = await _noteRepository.getTrashedNotes();
      for (var note in trashedNotes) {
        await _noteRepository.permanentlyDeleteNote(id: note.id);
      }
      
      // Get all trashed books
      final trashedBooks = await _bookRepository.getTrashedBooks();
      for (var book in trashedBooks) {
        await _bookRepository.permanentlyDeleteBook(book.id);
      }
      
      return true;
    } catch (e) {
      print('Error emptying trash: $e');
      return false;
    }
  }
  
  // Restore a note from trash
  Future<bool> restoreNote(String noteId) async {
    try {
      // First, get the note to check if it was part of a book - use includeDeleted: true
      final note = await _noteRepository.getNote(noteId, includeDeleted: true);
      
      // Restore the note itself
      await _noteRepository.restoreNote(id: noteId);
      
      // Check if the note was part of a book and add it back to the book
      if (note.originalBookId != null && note.originalBookId!.isNotEmpty) {
        try {
          // Get the book to check if it exists and is not deleted
          final book = await _bookRepository.getBook(note.originalBookId!);
          
          if (book != null) {
            // Re-add the note to the book
            await _bookRepository.addPageToBook(note.originalBookId!, noteId);
            print('Restored note $noteId back to book ${note.originalBookId}');
          } else {
            // Book might have been deleted or doesn't exist anymore
            print('Original book ${note.originalBookId} for note $noteId not found or is deleted');
          }
        } catch (e) {
          print('Error restoring note to book: $e');
          // Continue anyway since at least the note is restored
        }
      }
      
      return true;
    } catch (e) {
      // Check if the error is because the note couldn't be found or is already restored
      if (e.toString().contains('multiple (or no) rows returned')) {
        print('Note $noteId might already be restored or doesn\'t exist');
        // Still return true as this is not a failure from the user perspective
        return true;
      }
      print('Error restoring note: $e');
      return false;
    }
  }
  
  // Restore a book from trash
  Future<bool> restoreBook(String bookId) async {
    try {
      return await _bookRepository.restoreBook(bookId);
    } catch (e) {
      print('Error restoring book: $e');
      return false;
    }
  }
  
  // Permanently delete a note
  Future<bool> permanentlyDeleteNote(String noteId) async {
    try {
      await _noteRepository.permanentlyDeleteNote(id: noteId);
      return true;
    } catch (e) {
      print('Error permanently deleting note: $e');
      return false;
    }
  }
  
  // Permanently delete a book
  Future<bool> permanentlyDeleteBook(String bookId) async {
    try {
      return await _bookRepository.permanentlyDeleteBook(bookId);
    } catch (e) {
      print('Error permanently deleting book: $e');
      return false;
    }
  }
  
  // Run manual cleanup of old trash items (older than 30 days)
  Future<bool> cleanupOldTrashItems() async {
    try {
      await _supabaseService.client.rpc('delete_old_trash');
      return true;
    } catch (e) {
      print('Error cleaning up old trash items: $e');
      return false;
    }
  }
} 