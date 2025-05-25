import 'package:get/get.dart';
import '../controllers/public_library_controller.dart';
import '../../../data/repositories/book_repository.dart';

class PublicLibraryBinding extends Bindings {
  @override
  void dependencies() {
    // Ensure book repository is available
    if (!Get.isRegistered<BookRepository>()) {
      Get.put(BookRepository(), permanent: true);
    }
    
    Get.lazyPut<PublicLibraryController>(
      () => PublicLibraryController(),
    );
  }
} 