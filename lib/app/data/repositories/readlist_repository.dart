import 'package:get/get.dart';
import '../models/readlist_model.dart';
import '../models/book_model.dart';
import '../services/supabase_service.dart';
import '../repositories/user_repository.dart';

class ReadlistRepository {
  final SupabaseService _supabaseService = Get.find<SupabaseService>();
  final UserRepository _userRepository = Get.find<UserRepository>();
  
  // Ambil semua buku dalam readlist pengguna
  Future<List<ReadlistItem>> getReadlist() async {
    try {
      print('ReadlistRepository: Fetching readlist');
      final currentUser = await _userRepository.getCurrentUser();
      
      if (currentUser == null) {
        print('ReadlistRepository: No current user found');
        return [];
      }
      
      final response = await _supabaseService.client
          .from('readlists')
          .select('*, book:book_id(*)')
          .eq('user_id', currentUser.id)
          .order('added_at', ascending: false);
      
      return (response as List).map((item) {
        // Convert the nested book data to a Book object
        final bookData = item['book'] as Map<String, dynamic>;
        final book = Book.fromJson(bookData);
        
        // Create and return a ReadlistItem with the book data
        return ReadlistItem.fromJson(item, bookData: book);
      }).toList();
    } catch (e) {
      print('ReadlistRepository: Error fetching readlist: $e');
      return [];
    }
  }
  
  // Tambahkan buku ke readlist
  Future<bool> addToReadlist(String bookId) async {
    try {
      print('ReadlistRepository: Adding book $bookId to readlist');
      final currentUser = await _userRepository.getCurrentUser();
      
      if (currentUser == null) {
        print('ReadlistRepository: No current user found');
        return false;
      }
      
      // Cek apakah buku sudah ada di readlist
      final exists = await _supabaseService.client
          .from('readlists')
          .select('id')
          .eq('user_id', currentUser.id)
          .eq('book_id', bookId)
          .maybeSingle();
      
      if (exists != null) {
        print('ReadlistRepository: Book already in readlist');
        return true; // Buku sudah ada di readlist
      }
      
      // Tambahkan buku ke readlist
      final readlistItem = ReadlistItem(
        bookId: bookId,
        userId: currentUser.id,
      );
      
      await _supabaseService.client
          .from('readlists')
          .insert(readlistItem.toJson());
      
      return true;
    } catch (e) {
      print('ReadlistRepository: Error adding book to readlist: $e');
      return false;
    }
  }
  
  // Hapus buku dari readlist
  Future<bool> removeFromReadlist(String bookId) async {
    try {
      print('ReadlistRepository: Removing book $bookId from readlist');
      final currentUser = await _userRepository.getCurrentUser();
      
      if (currentUser == null) {
        print('ReadlistRepository: No current user found');
        return false;
      }
      
      await _supabaseService.client
          .from('readlists')
          .delete()
          .eq('user_id', currentUser.id)
          .eq('book_id', bookId);
      
      return true;
    } catch (e) {
      print('ReadlistRepository: Error removing book from readlist: $e');
      return false;
    }
  }
  
  // Cek apakah buku ada di readlist
  Future<bool> isInReadlist(String bookId) async {
    try {
      print('ReadlistRepository: Checking if book $bookId is in readlist');
      final currentUser = await _userRepository.getCurrentUser();
      
      if (currentUser == null) {
        print('ReadlistRepository: No current user found');
        return false;
      }
      
      final response = await _supabaseService.client
          .from('readlists')
          .select('id')
          .eq('user_id', currentUser.id)
          .eq('book_id', bookId)
          .maybeSingle();
      
      return response != null;
    } catch (e) {
      print('ReadlistRepository: Error checking readlist: $e');
      return false;
    }
  }
} 