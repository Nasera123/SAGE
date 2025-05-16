import 'package:get/get.dart';
import '../controllers/note_editor_controller.dart';
import '../../../data/repositories/note_repository.dart';
import '../../../data/repositories/tag_repository.dart';
import '../../../data/services/supabase_service.dart';

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
    
    // Controller - must be initialized after repositories
    Get.lazyPut<NoteEditorController>(() => NoteEditorController(), fenix: true);
  }
} 