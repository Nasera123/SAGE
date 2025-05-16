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
  Future<List<Book>> getBooks() async {
    final User? currentUser = _supabaseService.client.auth.currentUser;
    if (currentUser == null) return [];
    
    try {
      final response = await _supabaseService.client
          .from('books')
          .select('*')
          .eq('user_id', currentUser.id)
          .order('updated_at', ascending: false);
      
      return response.map<Book>((book) => Book.fromJson(book)).toList();
    } catch (e) {
      print('Error getting books: $e');
      return [];
    }
  }
  
  // Get single book by ID
  Future<Book?> getBook(String id) async {
    final User? currentUser = _supabaseService.client.auth.currentUser;
    if (currentUser == null) return null;
    
    try {
      final response = await _supabaseService.client
          .from('books')
          .select('*')
          .eq('id', id)
          .eq('user_id', currentUser.id)
          .single();
      
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
      
      await _supabaseService.client
          .from('books')
          .insert(book.toJson());
      
      return book;
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
      await _supabaseService.client
          .from('books')
          .update(book.toJson())
          .eq('id', book.id)
          .eq('user_id', currentUser.id);
      
      return true;
    } catch (e) {
      print('Error updating book: $e');
      return false;
    }
  }
  
  // Delete a book
  Future<bool> deleteBook(String id) async {
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
      print('Error deleting book: $e');
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
} 