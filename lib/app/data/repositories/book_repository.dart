import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import 'package:get/get.dart';
import '../models/book_model.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

class BookRepository {
  final SupabaseService _supabaseService = Get.find<SupabaseService>();
  
  SupabaseClient get client => _supabaseService.client;
  
  // Get all books for current user
  Future<List<Book>> getBooks({bool includeDeleted = false}) async {
    final User? currentUser = _supabaseService.client.auth.currentUser;
    if (currentUser == null) return [];
    
    try {
      var query = _supabaseService.client
          .from('books')
          .select('*')
          .eq('user_id', currentUser.id);
          
      // Exclude deleted books by default
      if (!includeDeleted) {
        query = query.eq('is_deleted', false);
      }
      
      final response = await query.order('updated_at', ascending: false);
      
      return response.map<Book>((book) => Book.fromJson(book)).toList();
    } catch (e) {
      print('Error getting books: $e');
      return [];
    }
  }
  
  // Get all trashed books
  Future<List<Book>> getTrashedBooks() async {
    final User? currentUser = _supabaseService.client.auth.currentUser;
    if (currentUser == null) return [];
    
    try {
      final response = await _supabaseService.client
          .from('books')
          .select('*')
          .eq('user_id', currentUser.id)
          .eq('is_deleted', true)
          .order('deleted_at', ascending: false);
      
      return response.map<Book>((book) => Book.fromJson(book)).toList();
    } catch (e) {
      print('Error getting trashed books: $e');
      return [];
    }
  }
  
  // Get single book by ID
  Future<Book?> getBook(String id, {bool includeDeleted = false}) async {
    final User? currentUser = _supabaseService.client.auth.currentUser;
    if (currentUser == null) return null;
    
    try {
      var query = _supabaseService.client
          .from('books')
          .select('*')
          .eq('id', id)
          .eq('user_id', currentUser.id);
          
      // Only check for deletion status if requested
      if (!includeDeleted) {
        query = query.eq('is_deleted', false);
      }
      
      final response = await query.single();
      
      return Book.fromJson(response);
    } catch (e) {
      print('Error getting book: $e');
      return null;
    }
  }
  
  // Create a new book
  Future<Book?> createBook({required String title, String? coverUrl}) async {
    final User? currentUser = _supabaseService.client.auth.currentUser;
    if (currentUser == null) return null;
    
    try {
      final book = Book(
        title: title,
        coverUrl: coverUrl,
        userId: currentUser.id,
      );
      
      // Insert dan langsung select hasilnya untuk mendapatkan timestamp dari server
      final response = await _supabaseService.client
          .from('books')
          .insert(book.toJson())
          .select()
          .single();
      
      // Return book dari hasil create dengan timestamp yang akurat
      return Book.fromJson(response);
    } catch (e) {
      print('Error creating book: $e');
      return null;
    }
  }
  
  // Update a book
  Future<bool> updateBook(Book book) async {
    final User? currentUser = _supabaseService.client.auth.currentUser;
    if (currentUser == null) return false;
    
    try {
      // Perbarui timestamp di sisi klien untuk dipastikan terupdate
      book.updatedAt = DateTime.now();

      final response = await _supabaseService.client
          .from('books')
          .update(book.toJson())
          .eq('id', book.id)
          .eq('user_id', currentUser.id);
      
      // Broadcast event update ke semua klien
      try {
        // Trigger manual broadcast untuk memastikan realtime update
        await _supabaseService.client.rpc('notify_book_update', 
          params: {'book_id': book.id});
      } catch (e) {
        // Jika fungsi RPC belum ada, jangan gagalkan seluruh operasi
        print('notify_book_update RPC tidak ditemukan: $e');
      }
      
      return true;
    } catch (e) {
      print('Error updating book: $e');
      return false;
    }
  }
  
  // Delete a book (move to trash)
  Future<bool> deleteBook(String id) async {
    final User? currentUser = _supabaseService.client.auth.currentUser;
    if (currentUser == null) return false;
    
    try {
      // Instead of deleting, mark as deleted
      await _supabaseService.client
          .from('books')
          .update({
            'is_deleted': true,
            'deleted_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id)
          .eq('user_id', currentUser.id);
      
      return true;
    } catch (e) {
      print('Error moving book to trash: $e');
      return false;
    }
  }
  
  // Permanently delete a book
  Future<bool> permanentlyDeleteBook(String id) async {
    final User? currentUser = _supabaseService.client.auth.currentUser;
    if (currentUser == null) return false;
    
    try {
      await _supabaseService.client
          .from('books')
          .delete()
          .eq('id', id)
          .eq('user_id', currentUser.id);
      
      return true;
    } catch (e) {
      print('Error permanently deleting book: $e');
      return false;
    }
  }
  
  // Restore a book from trash
  Future<bool> restoreBook(String id) async {
    final User? currentUser = _supabaseService.client.auth.currentUser;
    if (currentUser == null) return false;
    
    try {
      await _supabaseService.client
          .from('books')
          .update({
            'is_deleted': false,
            'deleted_at': null,
          })
          .eq('id', id)
          .eq('user_id', currentUser.id);
      
      return true;
    } catch (e) {
      print('Error restoring book: $e');
      return false;
    }
  }
  
  // Upload book cover image for web
  Future<String?> uploadBookCoverWeb(Uint8List imageBytes, String bookId, String originalFilename) async {
    try {
      final User? currentUser = _supabaseService.client.auth.currentUser;
      if (currentUser == null) {
        print('Cannot upload image: User not logged in');
        return null;
      }
      
      print('Starting web book cover upload for book: $bookId');
      
      // Create a unique file name
      final fileExt = path.extension(originalFilename).isNotEmpty 
        ? path.extension(originalFilename) 
        : '.jpg';
      final fileName = 'book_${bookId}_cover$fileExt';
      
      // Verify bytes
      if (imageBytes.isEmpty) {
        print('Error: Image bytes are empty');
        return null;
      }
      
      if (imageBytes.lengthInBytes > 5 * 1024 * 1024) {
        print('Error: File too large (${imageBytes.lengthInBytes} bytes)');
        return null;
      }
      
      // Upload the bytes to Supabase Storage
      print('Uploading to Supabase storage from web...');
      
      await _supabaseService.client
          .storage
          .from('book_covers')
          .uploadBinary(
            fileName,
            imageBytes, 
            fileOptions: const FileOptions(
              cacheControl: '0',
              upsert: true
            )
          );
      
      // Get the public URL with a cache-busting parameter
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final String publicUrl = _supabaseService.client
          .storage
          .from('book_covers')
          .getPublicUrl(fileName) + '?t=$timestamp';
      
      return publicUrl;
    } catch (e) {
      print('Error uploading book cover from web: $e');
      return null;
    }
  }
  
  // Upload book cover image for mobile
  Future<String?> uploadBookCover(File imageFile, String bookId) async {
    try {
      final User? currentUser = _supabaseService.client.auth.currentUser;
      if (currentUser == null) {
        print('Cannot upload image: User not logged in');
        return null;
      }
      
      print('Starting book cover upload for book: $bookId');
      
      // Create a unique file name
      final fileExt = path.extension(imageFile.path);
      final fileName = 'book_${bookId}_cover$fileExt';
      
      // Verify file exists and check size
      if (!await imageFile.exists()) {
        print('Error: Image file does not exist at path: ${imageFile.path}');
        return null;
      }
      
      final fileSize = await imageFile.length();
      if (fileSize > 5 * 1024 * 1024) {
        print('Error: File too large (${fileSize} bytes)');
        return null;
      }
      
      // Upload the file to Supabase Storage
      print('Uploading to Supabase storage...');
      
      await _supabaseService.client
          .storage
          .from('book_covers')
          .upload(
            fileName,
            imageFile, 
            fileOptions: const FileOptions(
              cacheControl: '0',
              upsert: true
            )
          );
      
      // Get the public URL with a cache-busting parameter
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final String publicUrl = _supabaseService.client
          .storage
          .from('book_covers')
          .getPublicUrl(fileName) + '?t=$timestamp';
      
      return publicUrl;
    } catch (e) {
      print('Error uploading book cover: $e');
      return null;
    }
  }
  
  // Add a new page to a book
  Future<bool> addPageToBook(String bookId, String pageId) async {
    final User? currentUser = _supabaseService.client.auth.currentUser;
    if (currentUser == null) return false;
    
    try {
      // First get the current book
      final book = await getBook(bookId);
      if (book == null) return false;
      
      // Add the page ID
      book.addPage(pageId);
      
      // Update the book and return a flag whether update was successful
      return await updateBook(book);
    } catch (e) {
      print('Error adding page to book: $e');
      return false;
    }
  }
  
  // Remove a page from a book
  Future<bool> removePageFromBook(String bookId, String pageId) async {
    final User? currentUser = _supabaseService.client.auth.currentUser;
    if (currentUser == null) return false;
    
    try {
      // First get the current book
      final book = await getBook(bookId);
      if (book == null) return false;
      
      // Remove the page ID
      book.removePage(pageId);
      
      // Update the book
      return await updateBook(book);
    } catch (e) {
      print('Error removing page from book: $e');
      return false;
    }
  }
  
  // Subscribe to book changes for the current user
  RealtimeChannel subscribeBookChanges({Function(PostgresChangePayload)? onBookChange}) {
    final userId = _supabaseService.currentUser!.id;
    
    // Create a channel for user's books
    final channel = _supabaseService.client.channel('books:${userId}');
    
    // Add postgres changes listener
    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'books',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'user_id',
        value: userId,
      ),
      callback: onBookChange ?? (payload) {
        print('Book change detected: ${payload.eventType}');
      },
    );
    
    // Subscribe to the channel
    channel.subscribe();
    
    return channel;
  }
  
  // Subscribe to specific book changes
  RealtimeChannel subscribeSpecificBookChanges({
    required String bookId,
    Function(PostgresChangePayload)? onBookChange
  }) {
    // Create a channel specifically for this book
    final channel = _supabaseService.client.channel('book:$bookId');
    
    // Add postgres changes listener
    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'books',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'id',
        value: bookId,
      ),
      callback: onBookChange ?? (payload) {
        print('Book change detected for book: $bookId - ${payload.eventType}');
      },
    );
    
    // Subscribe to the channel
    channel.subscribe();
    
    return channel;
  }
} 