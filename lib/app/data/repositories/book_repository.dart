import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import 'package:get/get.dart';
import '../models/book_model.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import '../models/note_model.dart';

class BookRepository extends GetxService {
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
  
  // Get all published books
  Future<List<Book>> getPublishedBooks({int limit = 20, int offset = 0}) async {
    try {
      final response = await _supabaseService.client
          .from('books')
          .select()
          .eq('is_public', true)
          .eq('is_deleted', false)
          .order('updated_at', ascending: false)
          .range(offset, offset + limit - 1);
      
      return response.map<Book>((json) => Book.fromJson(json)).toList();
    } catch (e) {
      print('Error getting published books: $e');
      return [];
    }
  }
  
  // Get published books by a specific user
  Future<List<Book>> getUserPublishedBooks(String userId) async {
    try {
      final response = await _supabaseService.client
          .from('books')
          .select()
          .eq('user_id', userId)
          .eq('is_public', true)
          .eq('is_deleted', false)
          .order('updated_at', ascending: false);
      
      return response.map<Book>((json) => Book.fromJson(json)).toList();
    } catch (e) {
      print('Error getting user published books: $e');
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
  
  // Get a public book by ID (can be accessed by any user)
  Future<Book?> getPublicBook(String id) async {
    try {
      final response = await _supabaseService.client
          .from('books')
          .select('*')
          .eq('id', id)
          .eq('is_public', true)
          .eq('is_deleted', false)
          .single();
      
      return Book.fromJson(response);
    } catch (e) {
      print('Error getting public book: $e');
      return null;
    }
  }
  
  // Create a new book
  Future<Book?> createBook({
    required String title, 
    String? coverUrl,
    String? description
  }) async {
    final User? currentUser = _supabaseService.client.auth.currentUser;
    if (currentUser == null) {
      print('createBook: No authenticated user found');
      return null;
    }
    
    try {
      print('createBook: Starting book creation process for title: $title');
      print('createBook: Current user ID: ${currentUser.id}');
      
      // Check if we can connect to Supabase
      try {
        print('createBook: Testing Supabase connection...');
        final connectionTest = await _supabaseService.client
            .from('books')
            .select('count')
            .limit(1)
            .maybeSingle();
        print('createBook: Connection test successful');
      } catch (connectionError) {
        print('createBook: Connection test failed: $connectionError');
        throw Exception('Connection to database failed: $connectionError');
      }
      
      // Get user display name for denormalization
      print('createBook: Fetching user profile data...');
      Map<String, dynamic> userData;
      try {
        userData = await _supabaseService.client
            .from('profiles')
            .select('full_name')
            .eq('id', currentUser.id)
            .single();
        print('createBook: User profile data fetched successfully');
      } catch (profileError) {
        print('createBook: Error fetching profile data: $profileError');
        // Continue with a fallback display name
        userData = {'full_name': 'Unknown User'};
      }
      
      print('createBook: Creating book object...');
      // Buat book object lokal
      final book = Book(
        title: title,
        coverUrl: coverUrl,
        userId: currentUser.id,
        userDisplayName: userData['full_name'] ?? 'Unknown User',
        description: description,
      );
      
      // Kirim versi minimal ke Supabase
      print('createBook: Preparing minimal data structure for insert...');
      final Map<String, dynamic> minimalData = {
        'id': book.id,
        'title': title,
        'user_id': currentUser.id,
        'created_at': book.createdAt.toIso8601String(),
        'updated_at': book.updatedAt.toIso8601String(),
        'user_display_name': userData['full_name'] ?? 'Unknown User',
      };
      
      // Tambahkan description jika ada
      if (description != null && description.isNotEmpty) {
        minimalData['description'] = description;
      }
      
      // Tambahkan cover URL jika ada
      if (coverUrl != null && coverUrl.isNotEmpty) {
        minimalData['cover_url'] = coverUrl;
      }
      
      print('createBook: Inserting minimal book data: $minimalData');
      final response = await _supabaseService.client
          .from('books')
          .insert(minimalData)
          .select()
          .single();
      
      print('createBook: Book inserted successfully, response: $response');
      
      // Kembalikan objek book lokal kita, karena respons dari server
      // mungkin tidak memiliki semua field yang kita butuhkan
      return book;
    } catch (e) {
      print('Error creating book (detailed): $e');
      if (e.toString().contains('duplicate key')) {
        print('createBook: This appears to be a duplicate key error');
      } else if (e.toString().contains('permission denied')) {
        print('createBook: This appears to be a permissions error');
      }
      return null;
    }
  }
  
  // Update a book
  Future<bool> updateBook(Book book) async {
    final User? currentUser = _supabaseService.client.auth.currentUser;
    if (currentUser == null) return false;
    
    try {
      print('updateBook: Updating book with ID ${book.id}');
      print('updateBook: Book pageIds to save: ${book.pageIds}');
      print('updateBook: PageIds length: ${book.pageIds.length}');
      
      // Perbarui timestamp di sisi klien untuk dipastikan terupdate
      book.updatedAt = DateTime.now();

      // Gunakan struktur data minimal untuk update
      final Map<String, dynamic> minimalData = {
        'id': book.id,
        'title': book.title,
        'updated_at': book.updatedAt.toIso8601String(),
        'page_ids': book.pageIds, // Include page_ids to ensure they're updated in the database
      };
      
      // Tambahkan cover URL jika ada
      if (book.coverUrl != null && book.coverUrl!.isNotEmpty) {
        minimalData['cover_url'] = book.coverUrl!;
      }
      
      // Tambahkan description jika ada
      if (book.description != null) {
        minimalData['description'] = book.description;
      }
      
      // Include is_public status
      minimalData['is_public'] = book.isPublic;
      
      print('updateBook: Using minimal data structure: $minimalData');
      final response = await _supabaseService.client
          .from('books')
          .update(minimalData)
          .eq('id', book.id)
          .eq('user_id', currentUser.id);
      
      print('updateBook: Update completed successfully');
      
      // Verify the book data after update
      final updatedBook = await getBook(book.id);
      print('updateBook: Verified book data after update. PageIds: ${updatedBook?.pageIds}');
      
      return true;
    } catch (e) {
      print('Error updating book: $e');
      return false;
    }
  }
  
  // Publish a book
  Future<bool> publishBook(String id) async {
    final User? currentUser = _supabaseService.client.auth.currentUser;
    if (currentUser == null) return false;
    
    try {
      print('publishBook: Setting book $id as public');
      
      final book = await getBook(id);
      if (book == null) {
        print('publishBook: Book not found');
        return false;
      }
      
      // Gunakan struktur data minimal
      final Map<String, dynamic> minimalData = {
        'updated_at': DateTime.now().toIso8601String()
      };
      
      // Coba update menggunakan is_public, jika ada di database
      try {
        minimalData['is_public'] = true;
        
        // Pastikan user_display_name ada saat publikasi
        if (book.userDisplayName == null || book.userDisplayName!.isEmpty) {
          try {
            // Coba ambil nama pengguna dari profil
            final userData = await _supabaseService.client
                .from('profiles')
                .select('full_name')
                .eq('id', currentUser.id)
                .single();
                
            minimalData['user_display_name'] = userData['full_name'] ?? 'Unknown User';
          } catch (e) {
            print('Error getting user profile data: $e');
            minimalData['user_display_name'] = 'Unknown User';
          }
        } else {
          // Gunakan nama yang sudah ada
          minimalData['user_display_name'] = book.userDisplayName;
        }
        
        print('publishBook: Using minimal data structure (with is_public): $minimalData');
        
        await _supabaseService.client
            .from('books')
            .update(minimalData)
            .eq('id', book.id)
            .eq('user_id', currentUser.id);
        
        print('publishBook: Book published successfully');
        return true;
      } catch (e) {
        print('Error publishing book with is_public column: $e');
        
        // Jika gagal, kembalikan false - fitur publish tidak akan bekerja
        // sampai skema database diupdate
        return false;
      }
    } catch (e) {
      print('Error publishing book: $e');
      return false;
    }
  }
  
  // Unpublish a book
  Future<bool> unpublishBook(String id) async {
    final User? currentUser = _supabaseService.client.auth.currentUser;
    if (currentUser == null) return false;
    
    try {
      print('unpublishBook: Setting book $id as private');
      
      final book = await getBook(id);
      if (book == null) {
        print('unpublishBook: Book not found');
        return false;
      }
      
      // Gunakan struktur data minimal
      final Map<String, dynamic> minimalData = {
        'updated_at': DateTime.now().toIso8601String()
      };
      
      // Coba update menggunakan is_public, jika ada di database
      try {
        minimalData['is_public'] = false;
        
        print('unpublishBook: Using minimal data structure (with is_public): $minimalData');
        
        await _supabaseService.client
            .from('books')
            .update(minimalData)
            .eq('id', book.id)
            .eq('user_id', currentUser.id);
        
        print('unpublishBook: Book unpublished successfully');
        return true;
      } catch (e) {
        print('Error unpublishing book with is_public column: $e');
        
        // Jika gagal, kembalikan false - fitur unpublish tidak akan bekerja
        // sampai skema database diupdate
        return false;
      }
    } catch (e) {
      print('Error unpublishing book: $e');
      return false;
    }
  }
  
  // Delete a book (move to trash)
  Future<bool> deleteBook(String id) async {
    final User? currentUser = _supabaseService.client.auth.currentUser;
    if (currentUser == null) return false;
    
    try {
      print('deleteBook: Moving book $id to trash');
      
      final book = await getBook(id, includeDeleted: false);
      if (book == null) {
        print('deleteBook: Book not found');
        return false;
      }
      
      // Gunakan struktur data minimal untuk update status deleted
      final timestamp = DateTime.now().toIso8601String();
      final Map<String, dynamic> minimalData = {
        'is_deleted': true,
        'deleted_at': timestamp,
        'updated_at': timestamp
      };
      
      print('deleteBook: Using minimal data structure: $minimalData');
      
      await _supabaseService.client
          .from('books')
          .update(minimalData)
          .eq('id', id)
          .eq('user_id', currentUser.id);
      
      print('deleteBook: Book moved to trash successfully');
      return true;
    } catch (e) {
      print('Error moving book to trash: $e');
      return false;
    }
  }

  // Restore a book from trash
  Future<bool> restoreBook(String id) async {
    final User? currentUser = _supabaseService.client.auth.currentUser;
    if (currentUser == null) return false;
    
    try {
      print('restoreBook: Restoring book $id from trash');
      
      final book = await getBook(id, includeDeleted: true);
      if (book == null) {
        print('restoreBook: Book not found');
        return false;
      }
      
      // Gunakan struktur data minimal untuk restore
      final Map<String, dynamic> minimalData = {
        'is_deleted': false,
        'deleted_at': null,
        'updated_at': DateTime.now().toIso8601String()
      };
      
      print('restoreBook: Using minimal data structure: $minimalData');
      
      await _supabaseService.client
          .from('books')
          .update(minimalData)
          .eq('id', id)
          .eq('user_id', currentUser.id);
      
      print('restoreBook: Book restored successfully');
      return true;
    } catch (e) {
      print('Error restoring book: $e');
      return false;
    }
  }
  
  // Permanently delete a book
  Future<bool> permanentlyDeleteBook(String id) async {
    final User? currentUser = _supabaseService.client.auth.currentUser;
    if (currentUser == null) return false;
    
    try {
      print('permanentlyDeleteBook: Permanently deleting book $id');
      
      await _supabaseService.client
          .from('books')
          .delete()
          .eq('id', id)
          .eq('user_id', currentUser.id);
      
      print('permanentlyDeleteBook: Book deleted permanently');
      return true;
    } catch (e) {
      print('Error permanently deleting book: $e');
      return false;
    }
  }
  
  // Get all notes for a book
  Future<List<Note>> getBookNotes(String bookId) async {
    try {
      // First get the book to get pageIds
      final book = await getBook(bookId);
      if (book == null || book.pageIds.isEmpty) {
        return [];
      }
      
      // Fetch all notes that are in the pageIds
      final response = await _supabaseService.client
          .from('notes')
          .select()
          .filter('id', 'in', book.pageIds)
          .order('created_at');
      
      // Create a map of Note objects by id
      Map<String, Note> notesMap = {};
      response.forEach((json) {
        notesMap[json['id']] = Note.fromJson(json);
      });
      
      // Return notes in the correct page order
      return book.pageIds.map((id) => notesMap[id]).whereType<Note>().toList();
    } catch (e) {
      print('Error getting book notes: $e');
      return [];
    }
  }
  
  // Get all notes for a public book
  Future<List<Note>> getPublicBookNotes(String bookId) async {
    try {
      // First get the public book to get pageIds
      print('getPublicBookNotes: Mengambil data buku publik dengan ID $bookId');
      final book = await getPublicBook(bookId);
      if (book == null) {
        print('getPublicBookNotes: Buku tidak ditemukan');
        return [];
      }
      
      if (book.pageIds.isEmpty) {
        print('getPublicBookNotes: Buku tidak memiliki halaman');
        return [];
      }
      
      print('getPublicBookNotes: Buku ditemukan dengan ${book.pageIds.length} halaman: ${book.pageIds}');
      
      // Fetch all notes that are in the pageIds
      print('getPublicBookNotes: Mengambil notes dari database');
      final response = await _supabaseService.client
          .from('notes')
          .select('*')
          .filter('id', 'in', book.pageIds)
          .order('created_at');
      
      print('getPublicBookNotes: Hasil query notes: ${response.length} item');
      
      // Create a map of Note objects by id
      Map<String, Note> notesMap = {};
      response.forEach((json) {
        notesMap[json['id']] = Note.fromJson(json);
        print('getPublicBookNotes: Loaded note ${json['id']} - ${json['title']}');
      });
      
      // Return notes in the correct page order
      final orderedNotes = book.pageIds
          .map((id) => notesMap[id])
          .whereType<Note>()
          .toList();
          
      print('getPublicBookNotes: Mengembalikan ${orderedNotes.length} halaman terurut');
      return orderedNotes;
    } catch (e) {
      print('Error getting public book notes: $e');
      if (e.toString().contains('permission denied')) {
        print('getPublicBookNotes: Ini kemungkinan masalah izin RLS');
      }
      return [];
    }
  }
  
  // Search published books
  Future<List<Book>> searchPublishedBooks(String query, {int limit = 20, int offset = 0}) async {
    try {
      final response = await _supabaseService.client
          .from('books')
          .select()
          .eq('is_public', true)
          .eq('is_deleted', false)
          .or('title.ilike.%$query%,description.ilike.%$query%')
          .order('updated_at', ascending: false)
          .range(offset, offset + limit - 1);
      
      return response.map<Book>((json) => Book.fromJson(json)).toList();
    } catch (e) {
      print('Error searching published books: $e');
      return [];
    }
  }
  
  // Add page to book
  Future<bool> addPageToBook(String bookId, String pageId) async {
    final User? currentUser = _supabaseService.client.auth.currentUser;
    if (currentUser == null) return false;
    
    try {
      print('addPageToBook: Adding page $pageId to book $bookId');
      
      // Get the current book
      final book = await getBook(bookId);
      if (book == null) {
        print('addPageToBook: Book not found');
        return false;
      }
      
      // Add page to the book if it doesn't already exist
      if (!book.pageIds.contains(pageId)) {
        book.addPage(pageId);
        
        // Gunakan struktur data minimal untuk update
        final pageIdsArray = book.pageIds;
        
        print('addPageToBook: Updating book with new page_ids: $pageIdsArray');
        final Map<String, dynamic> updateData = {
          'page_ids': pageIdsArray,
          'updated_at': DateTime.now().toIso8601String(),
        };
        
        // Update book in database with minimal data
        await _supabaseService.client
            .from('books')
            .update(updateData)
            .eq('id', bookId)
            .eq('user_id', currentUser.id);
            
        print('addPageToBook: Page added successfully');
      } else {
        print('addPageToBook: Page already exists in this book');
      }
      
      return true;
    } catch (e) {
      print('Error adding page to book: $e');
      return false;
    }
  }
  
  // Remove page from book
  Future<bool> removePageFromBook(String bookId, String pageId) async {
    final User? currentUser = _supabaseService.client.auth.currentUser;
    if (currentUser == null) return false;
    
    try {
      print('removePageFromBook: Removing page $pageId from book $bookId');
      
      // Get the current book
      final book = await getBook(bookId);
      if (book == null) {
        print('removePageFromBook: Book not found');
        return false;
      }
      
      // Remove page from the book if it exists
      if (book.pageIds.contains(pageId)) {
        book.removePage(pageId);
        
        // Gunakan struktur data minimal untuk update
        final pageIdsArray = book.pageIds;
        
        print('removePageFromBook: Updating book with new page_ids: $pageIdsArray');
        final Map<String, dynamic> updateData = {
          'page_ids': pageIdsArray,
          'updated_at': DateTime.now().toIso8601String(),
        };
        
        // Update book in database with minimal data
        await _supabaseService.client
            .from('books')
            .update(updateData)
            .eq('id', bookId)
            .eq('user_id', currentUser.id);
        
        print('removePageFromBook: Page removed successfully');
      } else {
        print('removePageFromBook: Page does not exist in this book');
      }
      
      return true;
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
  
  // Subscribe to changes for a specific book
  RealtimeChannel subscribeSpecificBookChanges({
    required String bookId,
    Function(PostgresChangePayload)? onBookChange
  }) {
    final userId = _supabaseService.currentUser!.id;
    
    // Create a channel for the specific book
    final channel = _supabaseService.client.channel('book:$bookId');
    
    // Add postgres changes listener for the specific book
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
        print('Specific book change detected: ${payload.eventType}');
      },
    );
    
    // Subscribe to the channel
    channel.subscribe();
    
    return channel;
  }
  
  // Upload book cover for web platform
  Future<String?> uploadBookCoverWeb(Uint8List bytes, String bookId, String fileName) async {
    final User? currentUser = _supabaseService.client.auth.currentUser;
    if (currentUser == null) return null;
    
    try {
      // Generate a unique file name to avoid conflicts
      final fileExt = path.extension(fileName);
      final uniqueFileName = '${const Uuid().v4()}$fileExt';
      final filePath = '${currentUser.id}/$uniqueFileName';
      
      // Upload file to Supabase Storage
      final response = await _supabaseService.client
          .storage
          .from('book_covers')
          .uploadBinary(
            filePath,
            bytes,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true,
            ),
          );
      
      // Get the public URL
      final String publicUrl = _supabaseService.client
          .storage
          .from('book_covers')
          .getPublicUrl(filePath);
      
      return publicUrl;
    } catch (e) {
      print('Error uploading book cover (web): $e');
      return null;
    }
  }
  
  // Upload book cover for mobile platforms
  Future<String?> uploadBookCover(File file, String bookId) async {
    final User? currentUser = _supabaseService.client.auth.currentUser;
    if (currentUser == null) return null;
    
    try {
      // Generate a unique file name to avoid conflicts
      final fileExt = path.extension(file.path);
      final uniqueFileName = '${const Uuid().v4()}$fileExt';
      final filePath = '${currentUser.id}/$uniqueFileName';
      
      // Upload file to Supabase Storage
      final response = await _supabaseService.client
          .storage
          .from('book_covers')
          .upload(
            filePath,
            file,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true,
            ),
          );
      
      // Get the public URL
      final String publicUrl = _supabaseService.client
          .storage
          .from('book_covers')
          .getPublicUrl(filePath);
      
      return publicUrl;
    } catch (e) {
      print('Error uploading book cover: $e');
      return null;
    }
  }
} 