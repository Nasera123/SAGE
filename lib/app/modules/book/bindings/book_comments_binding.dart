import 'package:get/get.dart';
import '../controllers/book_comment_controller.dart';
import '../../../data/repositories/book_comment_repository.dart';

class BookCommentsBinding extends Bindings {
  @override
  void dependencies() {
    // Lazily register the book comment repository if not already registered
    if (!Get.isRegistered<BookCommentRepository>()) {
      Get.lazyPut<BookCommentRepository>(() => BookCommentRepository());
    }
    
    // Lazily initialize the controller with the bookId from arguments
    Get.lazyPut<BookCommentController>(() => BookCommentController(
      bookId: Get.arguments['bookId'] as String,
    ));
  }
} 