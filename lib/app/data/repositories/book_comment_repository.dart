import 'package:get/get.dart';
import '../models/book_comment_model.dart';
import '../services/supabase_service.dart';
import '../repositories/user_repository.dart';

class BookCommentRepository {
  final SupabaseService _supabaseService = Get.find<SupabaseService>();
  final UserRepository _userRepository = Get.find<UserRepository>();
  
  // Ambil semua komentar untuk buku tertentu
  Future<List<BookComment>> getBookComments(String bookId) async {
    try {
      print('BookCommentRepository: Fetching comments for book $bookId');
      final response = await _supabaseService.client
          .from('book_comments')
          .select('*')
          .eq('book_id', bookId)
          .order('created_at', ascending: false);
      
      return (response as List)
          .map((json) => BookComment.fromJson(json))
          .toList();
    } catch (e) {
      print('BookCommentRepository: Error fetching comments: $e');
      return [];
    }
  }
  
  // Tambah komentar baru
  Future<BookComment?> addComment(String bookId, String content) async {
    try {
      print('BookCommentRepository: Adding comment to book $bookId');
      final currentUser = await _userRepository.getCurrentUser();
      
      if (currentUser == null) {
        print('BookCommentRepository: No current user found');
        return null;
      }
      
      // Ambil data profil pengguna
      final userProfileResponse = await _supabaseService.client
          .from('profiles')
          .select('full_name, avatar_url')
          .eq('id', currentUser.id)
          .single();
      
      final comment = BookComment(
        bookId: bookId,
        userId: currentUser.id,
        userDisplayName: userProfileResponse['full_name'] ?? 'Anonymous',
        userAvatarUrl: userProfileResponse['avatar_url'],
        content: content,
      );
      
      await _supabaseService.client
          .from('book_comments')
          .insert(comment.toJson());
      
      return comment;
    } catch (e) {
      print('BookCommentRepository: Error adding comment: $e');
      return null;
    }
  }
  
  // Hapus komentar
  Future<bool> deleteComment(String commentId) async {
    try {
      print('BookCommentRepository: Deleting comment $commentId');
      final currentUser = await _userRepository.getCurrentUser();
      
      if (currentUser == null) {
        print('BookCommentRepository: No current user found');
        return false;
      }
      
      await _supabaseService.client
          .from('book_comments')
          .delete()
          .eq('id', commentId)
          .eq('user_id', currentUser.id);
      
      return true;
    } catch (e) {
      print('BookCommentRepository: Error deleting comment: $e');
      return false;
    }
  }
  
  // Ambil komentar yang belum dibaca untuk penulis buku (inbox)
  Future<List<BookComment>> getUnreadComments() async {
    try {
      print('BookCommentRepository: Fetching unread comments');
      final currentUser = await _userRepository.getCurrentUser();
      
      if (currentUser == null) {
        print('BookCommentRepository: No current user found');
        return [];
      }
      
      // Dapatkan buku-buku milik pengguna saat ini
      final userBooksResponse = await _supabaseService.client
          .from('books')
          .select('id')
          .eq('user_id', currentUser.id);
      
      final userBookIds = (userBooksResponse as List)
          .map((book) => book['id'].toString())
          .toList();
      
      if (userBookIds.isEmpty) {
        return [];
      }
      
      // Dapatkan komentar untuk buku-buku tersebut yang belum dibaca
      final commentsResponse = await _supabaseService.client
          .from('book_comments')
          .select('*')
          .filter('book_id', 'in', userBookIds)
          .eq('is_read', false)
          .order('created_at', ascending: false);
      
      return (commentsResponse as List)
          .map((json) => BookComment.fromJson(json))
          .toList();
    } catch (e) {
      print('BookCommentRepository: Error fetching unread comments: $e');
      return [];
    }
  }
  
  // Tandai komentar sebagai sudah dibaca
  Future<bool> markCommentAsRead(String commentId) async {
    try {
      print('BookCommentRepository: Marking comment $commentId as read');
      await _supabaseService.client
          .from('book_comments')
          .update({'is_read': true})
          .eq('id', commentId);
      
      return true;
    } catch (e) {
      print('BookCommentRepository: Error marking comment as read: $e');
      return false;
    }
  }
} 