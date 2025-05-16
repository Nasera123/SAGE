import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/repositories/user_repository.dart';

class ProfileController extends GetxController {
  final UserRepository _userRepository = Get.find<UserRepository>();
  
  final isLoading = false.obs;
  final isSaving = false.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;
  
  final user = Rxn<User>();
  final userProfile = Rxn<Map<String, dynamic>>();
  
  final TextEditingController fullNameController = TextEditingController();
  
  @override
  void onInit() {
    super.onInit();
    loadUser();
  }
  
  @override
  void onClose() {
    fullNameController.dispose();
    super.onClose();
  }
  
  Future<void> loadUser() async {
    isLoading.value = true;
    hasError.value = false;
    
    try {
      user.value = await _userRepository.getCurrentUser();
      
      if (user.value != null) {
        await loadUserProfile();
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'Error loading user: ${e.toString()}';
      print('Error loading user: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> loadUserProfile() async {
    try {
      userProfile.value = await _userRepository.getUserProfile();
      
      if (userProfile.value != null) {
        fullNameController.text = userProfile.value?['full_name'] ?? '';
      }
    } catch (e) {
      print('Error loading user profile: $e');
    }
  }
  
  Future<void> updateProfile() async {
    if (fullNameController.text.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Full name cannot be empty',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    
    isSaving.value = true;
    
    try {
      await _userRepository.updateUserProfile(
        fullName: fullNameController.text.trim(),
      );
      
      Get.snackbar(
        'Success',
        'Profile updated successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      
      await loadUserProfile();
    } catch (e) {
      print('Error updating profile: $e');
      Get.snackbar(
        'Error',
        'Failed to update profile: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isSaving.value = false;
    }
  }
} 