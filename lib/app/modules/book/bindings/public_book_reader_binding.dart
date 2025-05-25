import 'package:get/get.dart';
import '../controllers/public_book_reader_controller.dart';
import '../../../data/repositories/book_repository.dart';
import '../../../data/repositories/readlist_repository.dart';

class PublicBookReaderBinding extends Bindings {
  @override
  void dependencies() {
    // Make sure repositories are available
    if (!Get.isRegistered<BookRepository>()) {
      Get.lazyPut<BookRepository>(() => BookRepository());
    }
    
    if (!Get.isRegistered<ReadlistRepository>()) {
      Get.lazyPut<ReadlistRepository>(() => ReadlistRepository());
    }
    
    // Initialize the controller
    Get.lazyPut<PublicBookReaderController>(
      () => PublicBookReaderController(),
    );
  }
} 