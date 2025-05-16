import 'package:get/get.dart';
import '../controllers/splash_controller.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/services/supabase_service.dart';

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    // SupabaseService is already initialized in main.dart and registered with GetX
    // Just ensure it's accessible through dependency injection
    if (!Get.isRegistered<SupabaseService>()) {
      print('WARNING: SupabaseService should be initialized before SplashBinding');
      // In case of error, attempt to find the instance
      try {
        Get.put(SupabaseService.instance, permanent: true);
      } catch (e) {
        print('Error accessing SupabaseService: $e');
      }
    }
    Get.lazyPut<UserRepository>(() => UserRepository());
    Get.lazyPut<SplashController>(() => SplashController());
  }
} 