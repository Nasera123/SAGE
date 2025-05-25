import 'package:get/get.dart';
import '../controllers/inbox_controller.dart';
import '../../../data/repositories/book_comment_repository.dart';

class InboxBinding extends Bindings {
  @override
  void dependencies() {
    // Lazily register the book comment repository if not already registered
    if (!Get.isRegistered<BookCommentRepository>()) {
      Get.lazyPut<BookCommentRepository>(() => BookCommentRepository());
    }
    
    // Lazily initialize the controller
    Get.lazyPut<InboxController>(() => InboxController());
  }
} 