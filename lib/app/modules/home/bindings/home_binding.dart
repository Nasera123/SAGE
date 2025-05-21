import 'package:get/get.dart';

import '../controllers/home_controller.dart';
import '../../../data/repositories/note_repository.dart';
import '../../../data/repositories/folder_repository.dart';
import '../../../data/repositories/tag_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/services/supabase_service.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    // SupabaseService should already be initialized in main.dart
    // No need to create a new instance
    if (!Get.isRegistered<SupabaseService>()) {
      print('WARNING: SupabaseService should be registered before HomeBinding');
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
    
    if (!Get.isRegistered<FolderRepository>()) {
      Get.put<FolderRepository>(FolderRepository());
    }
    
    if (!Get.isRegistered<TagRepository>()) {
      Get.put<TagRepository>(TagRepository());
    }
    
    // Ensure UserRepository is registered with permanent flag
    try {
      if (!Get.isRegistered<UserRepository>()) {
        print('Registering UserRepository in HomeBinding');
        Get.put<UserRepository>(UserRepository(), permanent: true);
      } else {
        print('UserRepository already registered');
        // Make sure it's marked as permanent
        UserRepository repo = Get.find<UserRepository>();
        Get.put<UserRepository>(repo, permanent: true);
      }
    } catch (e) {
      print('Error registering UserRepository: $e');
      // Attempt to register again
      Get.put<UserRepository>(UserRepository(), permanent: true);
    }
    
    // Controller - initialize after repositories
    Get.lazyPut<HomeController>(() => HomeController(), fenix: true);
  }
}
