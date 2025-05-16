import 'package:get/get.dart';
import '../controllers/profile_controller.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/services/supabase_service.dart';

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    // Memastikan SupabaseService tersedia
    if (!Get.isRegistered<SupabaseService>()) {
      Get.put(SupabaseService(), permanent: true);
    }
    
    // Memastikan UserRepository tersedia
    if (!Get.isRegistered<UserRepository>()) {
      Get.put(UserRepository());
    }
    
    // Register ProfileController
    Get.lazyPut<ProfileController>(() => ProfileController());
  }
} 