import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../routes/app_pages.dart';

class SplashController extends GetxController with GetSingleTickerProviderStateMixin {
  final UserRepository _userRepository = Get.find<UserRepository>();
  final isLoading = true.obs;
  
  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> logoAnimation;
  late Animation<double> titleAnimation;
  late Animation<double> subtitleAnimation;
  late Animation<double> loaderAnimation;
  
  @override
  void onInit() {
    super.onInit();
    _initAnimations();
    checkAuthStatus();
  }
  
  void _initAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    // Logo animation (0-0.5)
    logoAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    
    // Title animation (0.2-0.7)
    titleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.7, curve: Curves.easeOut),
      ),
    );
    
    // Subtitle animation (0.4-0.9)
    subtitleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.4, 0.9, curve: Curves.easeOut),
      ),
    );
    
    // Loader animation (0.6-1.0)
    loaderAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );
    
    // Start the animation
    _animationController.forward();
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
  
  @override
  void onClose() {
    _animationController.dispose();
    super.onClose();
  }
} 