import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';

class ForgotPasswordView extends GetView<AuthController> {
  const ForgotPasswordView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Password'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Reset your password',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Enter your email address and we\'ll send you a link to reset your password.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            TextField(
              controller: controller.forgotPasswordEmailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => controller.forgotPassword(),
            ),
            const SizedBox(height: 24),
            Obx(() {
              return ElevatedButton(
                onPressed: controller.isLoading.value ? null : controller.forgotPassword,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: controller.isLoading.value
                      ? const CircularProgressIndicator()
                      : const Text('Reset Password', style: TextStyle(fontSize: 16)),
                ),
              );
            }),
            const SizedBox(height: 24),
            Obx(() {
              return controller.errorMessage.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        controller.errorMessage.value,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : const SizedBox.shrink();
            }),
          ],
        ),
      ),
    );
  }
} 