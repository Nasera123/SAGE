import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/models/profile_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class ProfileController extends GetxController {
  final UserRepository _userRepository = Get.find<UserRepository>();
  
  final isLoading = false.obs;
  final isSaving = false.obs;
  final isUploadingImage = false.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;
  
  final user = Rxn<User>();
  final userProfile = Rxn<Profile>();
  
  final TextEditingController fullNameController = TextEditingController();
  
  final ImagePicker _imagePicker = ImagePicker();
  final Rxn<File> selectedImage = Rxn<File>();
  
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
        fullNameController.text = userProfile.value?.fullName ?? '';
      }
    } catch (e) {
      print('Error loading user profile: $e');
    }
  }
  
  Future<void> pickImage(ImageSource source) async {
    try {
      // Most direct approach without any permission handling
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      
      if (image != null) {
        // Set the selected image
        selectedImage.value = File(image.path);
        
        // Upload the image directly without showing a dialog
        isUploadingImage.value = true;
        try {
          await uploadProfileImage();
        } finally {
          // Always ensure loading state is reset
          isUploadingImage.value = false;
        }
      }
    } catch (e) {
      print('Error picking image: $e');
      // Handle errors gracefully
      Get.snackbar(
        'Error',
        'Could not select image. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      // Ensure loading is reset
      isUploadingImage.value = false;
    }
  }
  
  Future<void> uploadProfileImage() async {
    if (selectedImage.value == null) return;
    
    try {
      // Get file name from path
      String fileName = selectedImage.value!.path.split('/').last;
      print('Uploading file: $fileName');
      
      // Upload the file
      final imageUrl = await _userRepository.uploadProfileImage(selectedImage.value!);
      print('Uploaded image URL: $imageUrl');
      
      if (imageUrl != null) {
        // Update profile with new avatar URL
        await _userRepository.updateUserProfile(avatarUrl: imageUrl);
        print('Profile updated with new avatar URL');
        
        // Force reload profile data to update UI
        await loadUserProfile();
        
        Get.snackbar(
          'Success',
          'Profile image updated successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
        
        // Clear selected image after successful upload
        selectedImage.value = null;
      } else {
        throw Exception('Failed to get image URL after upload');
      }
    } catch (e) {
      print('Error uploading profile image: $e');
      print('Stack trace: ${StackTrace.current}');
      Get.snackbar(
        'Error',
        'Failed to upload profile image. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      // Clear selected image on error
      selectedImage.value = null;
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
  
  void showImagePickerOptions() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        color: Get.theme.cardColor,
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Change Profile Photo',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take a photo'),
                onTap: () {
                  Get.back();
                  pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from gallery'),
                onTap: () {
                  Get.back();
                  pickImage(ImageSource.gallery);
                },
              ),
              if (userProfile.value?.avatarUrl != null && userProfile.value!.avatarUrl!.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Remove current photo', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Get.back();
                    _removeProfileImage();
                  },
                ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Get.back(),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Future<void> _removeProfileImage() async {
    try {
      await _userRepository.updateUserProfile(avatarUrl: '');
      await loadUserProfile();
      
      Get.snackbar(
        'Success',
        'Profile image removed',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      print('Error removing profile image: $e');
      Get.snackbar(
        'Error',
        'Failed to remove profile image: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
} 