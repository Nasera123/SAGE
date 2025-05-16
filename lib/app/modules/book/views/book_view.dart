import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';
import '../controllers/book_controller.dart';
import 'package:cached_network_image/cached_network_image.dart';

class BookView extends GetView<BookController> {
  const BookView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(controller.book.value?.title ?? 'New Book')),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: controller.saveBook,
          ),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              if (controller.book.value != null)
                PopupMenuItem(
                  child: const Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete Book', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                  onTap: () => Future.delayed(
                    const Duration(milliseconds: 100),
                    () => _showDeleteBookDialog(context),
                  ),
                ),
            ],
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
                  'Error loading book',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(controller.errorMessage.value),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => controller.loadBook(controller.book.value!.id),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Book cover and image selection
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        // Book cover
                        GestureDetector(
                          onTap: controller.showImagePickerOptions,
                          child: SizedBox(
                            width: 200,
                            height: 280,
                            child: Card(
                              elevation: 4,
                              clipBehavior: Clip.antiAlias,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Obx(() {
                                final hasSelectedNativeImage = controller.selectedCoverImage.value != null;
                                final hasSelectedWebImage = controller.selectedCoverImageWeb.value != null;
                                final hasCoverImage = controller.book.value?.coverUrl != null && 
                                                      controller.book.value!.coverUrl!.isNotEmpty;
                                
                                if (kIsWeb && hasSelectedWebImage) {
                                  // Show selected image in web
                                  return Image.memory(
                                    controller.selectedCoverImageWeb.value!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  );
                                } else if (!kIsWeb && hasSelectedNativeImage) {
                                  // Show selected image in mobile
                                  return Image.file(
                                    controller.selectedCoverImage.value!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  );
                                } else if (hasCoverImage) {
                                  // Show existing cover image
                                  return CachedNetworkImage(
                                    imageUrl: controller.book.value!.coverUrl!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                    placeholder: (context, url) => const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                    errorWidget: (context, url, error) => const Center(
                                      child: Icon(Icons.image_not_supported, size: 48),
                                    ),
                                  );
                                } else {
                                  // Show placeholder
                                  return Container(
                                    color: Theme.of(context).colorScheme.surfaceVariant,
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.add_photo_alternate,
                                            size: 48,
                                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Add Cover',
                                            style: TextStyle(
                                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }
                              }),
                            ),
                          ),
                        ),
                        
                        // Camera icon overlay
                        Positioned(
                          right: 8,
                          bottom: 8,
                          child: GestureDetector(
                            onTap: controller.showImagePickerOptions,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.camera_alt,
                                color: Theme.of(context).colorScheme.onPrimary,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    // Display loading indicator during cover upload
                    Obx(() {
                      if (controller.isUploadingCover.value) {
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
                                'Uploading cover...',
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
                    
                    const SizedBox(height: 24),
                  ],
                ),
              ),
              
              // Book title field
              const Text(
                'Book Title',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller.titleController,
                decoration: InputDecoration(
                  hintText: 'Enter book title',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => controller.titleController.clear(),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Pages section
              const Text(
                'Pages',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              if (controller.book.value == null)
                const Center(
                  child: Text('Save the book first to add pages'),
                )
              else if (controller.book.value!.pageIds.isEmpty)
                Center(
                  child: Column(
                    children: [
                      const Text('No pages yet'),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Add New Page'),
                        onPressed: controller.createNewPage,
                      ),
                    ],
                  ),
                )
              else
                _buildPagesList(context),
              
              const SizedBox(height: 24),
              
              Obx(() => controller.isSaving.value
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: controller.saveBook,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                      ),
                      child: Text(controller.book.value == null ? 'Create Book' : 'Save Changes'),
                    ),
                  ),
              ),
            ],
          ),
        );
      }),
      floatingActionButton: Obx(() {
        if (controller.book.value != null) {
          return FloatingActionButton(
            onPressed: controller.createNewPage,
            child: const Icon(Icons.add),
          );
        }
        return const SizedBox.shrink();
      }),
    );
  }
  
  Widget _buildPagesList(BuildContext context) {
    // Placeholder for the pages list
    // Will be implemented to show pages of the book
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: controller.book.value!.pageIds.length,
      itemBuilder: (context, index) {
        return ListTile(
          leading: const Icon(Icons.description),
          title: Text('Page ${index + 1}'),
          onTap: () {
            // Will implement page opening functionality
            Get.snackbar(
              'Coming Soon',
              'Page viewing functionality will be added soon',
              snackPosition: SnackPosition.BOTTOM,
            );
          },
        );
      },
    );
  }
  
  void _showDeleteBookDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Book'),
        content: Text(
          'Are you sure you want to delete "${controller.book.value!.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: controller.deleteBook,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
} 