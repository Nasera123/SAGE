import 'package:get/get.dart';
import '../controllers/note_editor_controller.dart';
import '../controllers/music_controller.dart';
import '../../../data/repositories/note_repository.dart';
import '../../../data/repositories/tag_repository.dart';
import '../../../data/repositories/music_repository.dart';
import '../../../data/services/supabase_service.dart';
import '../../../data/services/music_service.dart';

class NoteEditorBinding extends Bindings {
  @override
  void dependencies() {
    // SupabaseService should already be initialized in main.dart
    // No need to create a new instance
    if (!Get.isRegistered<SupabaseService>()) {
      print('WARNING: SupabaseService should be registered before NoteEditorBinding');
      try {
        // In case it's not registered but is initialized
        Get.put(SupabaseService.instance, permanent: true);
      } catch (e) {
        print('Error finding SupabaseService instance: $e');
      }
    }
    
    // Repositories
    if (!Get.isRegistered<NoteRepository>()) {
      Get.put<NoteRepository>(NoteRepository());
    }
    
    if (!Get.isRegistered<TagRepository>()) {
      Get.put<TagRepository>(TagRepository());
    }
    
    if (!Get.isRegistered<MusicRepository>()) {
      Get.put<MusicRepository>(MusicRepository());
    }
    
    // Services
    if (!Get.isRegistered<MusicService>()) {
      Get.put<MusicService>(MusicService());
    }
    
    // Controllers
    Get.lazyPut<NoteEditorController>(() => NoteEditorController(), fenix: true);
    Get.put<MusicController>(MusicController(), permanent: true);
  }
} 