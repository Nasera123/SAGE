import 'package:get/get.dart';
import '../controllers/book_controller.dart';
import '../../../data/repositories/book_repository.dart';
import '../../../data/repositories/music_repository.dart';
import '../../../data/services/music_service.dart';
import '../../note_editor/controllers/music_controller.dart';

class BookBinding extends Bindings {
  @override
  void dependencies() {
    // Register repositories if not already registered
    if (!Get.isRegistered<BookRepository>()) {
      Get.put(BookRepository());
    }
    
    if (!Get.isRegistered<MusicRepository>()) {
      Get.put(MusicRepository());
    }
    
    // Register services if not already registered
    if (!Get.isRegistered<MusicService>()) {
      Get.put(MusicService());
    }
    
    // Register controllers
    Get.lazyPut<BookController>(() => BookController());
    Get.put<MusicController>(MusicController(), permanent: true);
  }
} 