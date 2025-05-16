import 'package:get/get.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../routes/app_pages.dart';

class SplashController extends GetxController {
  final UserRepository _userRepository = Get.find<UserRepository>();
  final isLoading = true.obs;
  
  @override
  void onInit() {
    super.onInit();
    checkAuthStatus();
  }
  
  void checkAuthStatus() async {
    await Future.delayed(const Duration(seconds: 2)); // Display splash for 2 seconds
    
    if (_userRepository.isAuthenticated) {
      Get.offAllNamed(Routes.HOME);
    } else {
      Get.offAllNamed(Routes.AUTH);
    }
    
    isLoading.value = false;
  }
} 