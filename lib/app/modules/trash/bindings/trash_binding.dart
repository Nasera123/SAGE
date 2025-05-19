import 'package:get/get.dart';
import '../controllers/trash_controller.dart';
import '../../../data/repositories/trash_repository.dart';
import '../../../data/repositories/note_repository.dart';
import '../../../data/repositories/book_repository.dart';

class TrashBinding extends Bindings {
  @override
  void dependencies() {
    // Ensure repositories are available
    if (!Get.isRegistered<NoteRepository>()) {
      Get.lazyPut<NoteRepository>(() => NoteRepository());
    }
    
    if (!Get.isRegistered<BookRepository>()) {
      Get.lazyPut<BookRepository>(() => BookRepository());
    }
    
    // Register trash repository if not already registered
    if (!Get.isRegistered<TrashRepository>()) {
      Get.lazyPut<TrashRepository>(() => TrashRepository());
    }
    
    // Register controller
    Get.lazyPut<TrashController>(() => TrashController());
  }
} 