import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../routes/app_pages.dart';

class SettingsController extends GetxController {
  final UserRepository _userRepository = Get.find<UserRepository>();
  
  final isLoading = false.obs;
  final isDarkMode = false.obs;
  final user = Rxn<User>();
  
  @override
  void onInit() {
    super.onInit();
    loadUser();
    loadThemePreference();
  }
  
  Future<void> loadUser() async {
    isLoading.value = true;
    try {
      user.value = await _userRepository.getCurrentUser();
    } catch (e) {
      print('Error loading user: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
  void loadThemePreference() async {
    isDarkMode.value = Get.isDarkMode;
  }
  
  void toggleTheme() {
    isDarkMode.value = !isDarkMode.value;
    Get.changeThemeMode(isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
  }
  
  Future<void> signOut() async {
    try {
      await _userRepository.signOut();
      Get.offAllNamed(Routes.AUTH);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to sign out: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
  
  void navigateToProfile() {
    Get.toNamed(Routes.PROFILE);
  }
} 