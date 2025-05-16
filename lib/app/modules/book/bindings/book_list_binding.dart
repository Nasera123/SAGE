import 'package:get/get.dart';
import '../controllers/book_list_controller.dart';
import '../../../data/repositories/book_repository.dart';

class BookListBinding extends Bindings {
  @override
  void dependencies() {
    // Register book repository if not already registered
    if (!Get.isRegistered<BookRepository>()) {
      Get.put(BookRepository());
    }
    
    Get.lazyPut<BookListController>(
      () => BookListController(),
    );
  }
} 