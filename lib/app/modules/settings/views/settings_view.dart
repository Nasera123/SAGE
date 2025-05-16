import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/settings_controller.dart';

class SettingsView extends GetView<SettingsController> {
  const SettingsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        
        return ListView(
          children: [
            // User section
            if (controller.user.value != null) ...[
              ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.person),
                ),
                title: Text(controller.user.value!.email ?? 'No email'),
                subtitle: const Text('Your account'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: controller.navigateToProfile,
              ),
              const Divider(),
            ],
            
            // Theme settings
            ListTile(
              leading: const Icon(Icons.brightness_6),
              title: const Text('Dark Mode'),
              trailing: Switch(
                value: controller.isDarkMode.value,
                onChanged: (_) => controller.toggleTheme(),
              ),
            ),
            
            // Security
            const Divider(),
            const Padding(
              padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
              child: Text(
                'SECURITY',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign Out'),
              onTap: () {
                _showSignOutConfirmationDialog(context);
              },
            ),
          ],
        );
      }),
    );
  }

  void _showSignOutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
} 