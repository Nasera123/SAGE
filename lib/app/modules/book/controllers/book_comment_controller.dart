import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/book_comment_model.dart';
import '../../../data/repositories/book_comment_repository.dart';
import '../../../data/repositories/user_repository.dart';

class BookCommentController extends GetxController {
  final BookCommentRepository _commentRepository = Get.find<BookCommentRepository>();
  final UserRepository _userRepository = Get.find<UserRepository>();
  
  final comments = <BookComment>[].obs;
  final isLoading = false.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;
  
  final commentTextController = TextEditingController();
  final String bookId;
  
  BookCommentController({required this.bookId});
  
  @override
  void onInit() {
    super.onInit();
    loadComments();
  }
  
  @override
  void onClose() {
    commentTextController.dispose();
    super.onClose();
  }
  
  Future<void> loadComments() async {
    try {
      isLoading.value = true;
      hasError.value = false;
      errorMessage.value = '';
      
      final loadedComments = await _commentRepository.getBookComments(bookId);
      comments.assignAll(loadedComments);
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'Failed to load comments: $e';
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> addComment() async {
    final content = commentTextController.text.trim();
    if (content.isEmpty) return;
    
    try {
      isLoading.value = true;
      
      final newComment = await _commentRepository.addComment(bookId, content);
      if (newComment != null) {
        comments.insert(0, newComment);
        commentTextController.clear();
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to add comment: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> deleteComment(String commentId) async {
    try {
      isLoading.value = true;
      
      final success = await _commentRepository.deleteComment(commentId);
      if (success) {
        comments.removeWhere((comment) => comment.id == commentId);
      } else {
        Get.snackbar(
          'Error',
          'Failed to delete comment',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete comment: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }
  
  // Menentukan apakah pengguna dapat menghapus komentar tertentu
  bool canDeleteComment(BookComment comment) {
    // Dapatkan ID pengguna saat ini
    final currentUser = _userRepository.currentUser;
    
    // User dapat menghapus komentar mereka sendiri
    return currentUser != null && currentUser.id == comment.userId;
  }
} 