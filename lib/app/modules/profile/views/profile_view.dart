import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/profile_controller.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: controller.updateProfile,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (controller.hasError.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error loading profile',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(controller.errorMessage.value),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: controller.loadUser,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        
        if (controller.user.value == null) {
          return const Center(child: Text('User not logged in'));
        }
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User avatar and image selection
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        // Profile image
                        GestureDetector(
                          onTap: () {
                            // Direct camera button
                            controller.pickImage(ImageSource.gallery);
                          },
                          child: Obx(() {
                            final hasSelectedImage = controller.selectedImage.value != null;
                            final hasProfileImage = controller.userProfile.value?.avatarUrl != null && 
                                                   controller.userProfile.value!.avatarUrl!.isNotEmpty;
                            
                            if (hasSelectedImage) {
                              // Show selected image that will be uploaded
                              return CircleAvatar(
                                radius: 60,
                                backgroundImage: FileImage(controller.selectedImage.value!),
                              );
                            } else if (hasProfileImage) {
                              // Show existing profile image from network
                              final timestamp = DateTime.now().millisecondsSinceEpoch;
                              final imageUrl = controller.userProfile.value!.avatarUrl!.contains('?') 
                                ? controller.userProfile.value!.avatarUrl!  // URL already has timestamp
                                : controller.userProfile.value!.avatarUrl! + '?t=$timestamp'; // Add timestamp to URL
                                
                              return CircleAvatar(
                                radius: 60,
                                backgroundImage: CachedNetworkImageProvider(imageUrl),
                                onBackgroundImageError: (exception, stackTrace) {
                                  print('Error loading profile image: $exception');
                                  // Falls back to the default avatar (handled by CircleAvatar)
                                },
                              );
                            } else {
                              // Show default avatar
                              return CircleAvatar(
                                radius: 60,
                                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                child: Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                              );
                            }
                          }),
                        ),
                        
                        // Camera icon overlay
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: GestureDetector(
                            onTap: () {
                              // Direct camera button
                              controller.pickImage(ImageSource.camera);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.camera_alt,
                                color: Theme.of(context).colorScheme.onPrimary,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    // Display loading indicator during image upload
                    Obx(() {
                      if (controller.isUploadingImage.value) {
                        return Container(
                          margin: const EdgeInsets.only(top: 16.0),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 20, 
                                height: 20, 
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Updating profile image...',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                    
                    const SizedBox(height: 16),
                    Text(
                      controller.user.value!.email ?? 'No email',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              const Text(
                'Personal Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // Full name field
              TextField(
                controller: controller.fullNameController,
                decoration: InputDecoration(
                  labelText: 'Display Name',
                  hintText: 'Enter your name',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.person),
                  helperText: 'This name will be visible to other users',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => controller.fullNameController.clear(),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              Obx(() => controller.isSaving.value
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: controller.updateProfile,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                      ),
                      child: const Text('Update Profile'),
                    ),
                  ),
              ),
              
              const SizedBox(height: 32),
              const Text(
                'Account Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Email'),
                          Text(controller.user.value!.email ?? 'No email'),
                        ],
                      ),
                      const Divider(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Member Since'),
                          Text(
                            controller.user.value!.createdAt != null
                                ? DateFormat.yMMMd().format(DateTime.parse(controller.user.value!.createdAt!))
                                : 'Unknown',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
} 