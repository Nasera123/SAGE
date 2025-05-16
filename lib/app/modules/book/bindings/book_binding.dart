import 'package:get/get.dart';
import '../controllers/book_controller.dart';
import '../../../data/repositories/book_repository.dart';

class BookBinding extends Bindings {
  @override
  void dependencies() {
    // Register book repository if not already registered
    if (!Get.isRegistered<BookRepository>()) {
      Get.put(BookRepository());
    }
    
    Get.lazyPut<BookController>(
      () => BookController(),
    );
  }
} 