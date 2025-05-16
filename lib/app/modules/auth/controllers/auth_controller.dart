import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../routes/app_pages.dart';

class AuthController extends GetxController {
  final UserRepository _userRepository = Get.find<UserRepository>();
  
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  
  // Text controllers for login
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  
  // Text controllers for registration
  final registerEmailController = TextEditingController();
  final registerPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  
  final forgotPasswordEmailController = TextEditingController();
  
  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    registerEmailController.dispose();
    registerPasswordController.dispose();
    confirmPasswordController.dispose();
    forgotPasswordEmailController.dispose();
    super.onClose();
  }
  
  Future<void> login() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      errorMessage.value = 'Please enter both email and password';
      return;
    }
    
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      await _userRepository.signIn(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
      
      // Clear fields after successful login
      emailController.clear();
      passwordController.clear();
      
      Get.offAllNamed(Routes.HOME);
    } catch (e) {
      errorMessage.value = 'Login failed: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> register() async {
    if (registerEmailController.text.isEmpty ||
        registerPasswordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      errorMessage.value = 'Please fill in all fields';
      return;
    }
    
    if (registerPasswordController.text != confirmPasswordController.text) {
      errorMessage.value = 'Passwords do not match';
      return;
    }
    
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      await _userRepository.signUp(
        email: registerEmailController.text.trim(),
        password: registerPasswordController.text,
      );
      
      // Clear fields after successful registration
      registerEmailController.clear();
      registerPasswordController.clear();
      confirmPasswordController.clear();
      
      Get.snackbar(
        'Registration Successful',
        'Please check your email to confirm your account',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      
      Get.toNamed(Routes.LOGIN);
    } catch (e) {
      errorMessage.value = 'Registration failed: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> forgotPassword() async {
    if (forgotPasswordEmailController.text.isEmpty) {
      errorMessage.value = 'Please enter your email';
      return;
    }
    
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      await _userRepository.client.auth.resetPasswordForEmail(
        forgotPasswordEmailController.text.trim(),
      );
      
      // Clear field after success
      forgotPasswordEmailController.clear();
      
      Get.snackbar(
        'Password Reset',
        'Check your email for password reset instructions',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      
      Get.back();
    } catch (e) {
      errorMessage.value = 'Password reset failed: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }
} 