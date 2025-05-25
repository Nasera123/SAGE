import 'package:get/get.dart';
import '../../../data/models/book_comment_model.dart';
import '../../../data/repositories/book_comment_repository.dart';

class InboxController extends GetxController {
  final BookCommentRepository _commentRepository = Get.find<BookCommentRepository>();
  
  final unreadComments = <BookComment>[].obs;
  final isLoading = false.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;
  final unreadCount = 0.obs;
  
  @override
  void onInit() {
    super.onInit();
    loadUnreadComments();
  }
  
  Future<void> loadUnreadComments() async {
    try {
      isLoading.value = true;
      hasError.value = false;
      errorMessage.value = '';
      
      final comments = await _commentRepository.getUnreadComments();
      unreadComments.assignAll(comments);
      unreadCount.value = comments.length;
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'Failed to load unread comments: $e';
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> markAsRead(String commentId) async {
    try {
      final success = await _commentRepository.markCommentAsRead(commentId);
      if (success) {
        unreadComments.removeWhere((comment) => comment.id == commentId);
        unreadCount.value = unreadComments.length;
      }
    } catch (e) {
      print('Error marking comment as read: $e');
    }
  }
  
  Future<void> markAllAsRead() async {
    try {
      isLoading.value = true;
      
      for (final comment in unreadComments) {
        await _commentRepository.markCommentAsRead(comment.id);
      }
      
      unreadComments.clear();
      unreadCount.value = 0;
    } catch (e) {
      print('Error marking all comments as read: $e');
    } finally {
      isLoading.value = false;
    }
  }
} 