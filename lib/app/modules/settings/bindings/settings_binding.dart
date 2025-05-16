import 'package:get/get.dart';
import '../controllers/settings_controller.dart';
import '../../../data/repositories/user_repository.dart';

class SettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<UserRepository>(() => UserRepository());
    Get.lazyPut<SettingsController>(() => SettingsController());
  }
} 