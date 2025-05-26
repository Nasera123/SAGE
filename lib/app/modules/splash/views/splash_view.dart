import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/splash_controller.dart';
import '../../../core/values/assets.dart';

class SplashView extends GetView<SplashController> {
  const SplashView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: controller.logoAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: controller.logoAnimation.value,
                  child: Opacity(
                    opacity: controller.logoAnimation.value,
                    child: child,
                  ),
                );
              },
              child: Image.asset(
                AppAssets.logo,
                height: 100,
                width: 100,
              ),
            ),
            const SizedBox(height: 24),
            AnimatedBuilder(
              animation: controller.titleAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: controller.titleAnimation.value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - controller.titleAnimation.value)),
                    child: child,
                  ),
                );
              },
              child: Text(
                'SAGE',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ),
            const SizedBox(height: 12),
            AnimatedBuilder(
              animation: controller.subtitleAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: controller.subtitleAnimation.value,
                  child: child,
                );
              },
              child: Text(
                'Your modern note-taking app',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            const SizedBox(height: 48),
            AnimatedBuilder(
              animation: controller.loaderAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: controller.loaderAnimation.value,
                  child: child,
                );
              },
              child: Obx(() {
                if (controller.isLoading.value) {
                  return CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.primary,
                  );
                } else {
                  return const SizedBox.shrink();
                }
              }),
            ),
          ],
        ),
      ),
    );
  }
} 