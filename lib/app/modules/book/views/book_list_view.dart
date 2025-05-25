import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/book_list_controller.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../routes/app_pages.dart';
import 'package:flutter/services.dart';
import '../../../data/models/book_model.dart';

class BookListView extends GetView<BookListController> {
  const BookListView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Setup focus detector for app lifecycle changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Initial refresh
      controller.refreshData();
      
      // Setup a focus detector to check when app is resumed from background
      SystemChannels.lifecycle.setMessageHandler((msg) async {
        print('BookListView lifecycle event: $msg');
        if (msg == AppLifecycleState.resumed.toString() && 
            ModalRoute.of(context)?.isCurrent == true) {
          print('BookListView: app resumed and is current route, refreshing data');
          controller.refreshData();
        }
        return null;
      });
      
      // Setup a focus detector for when this page becomes visible
      // (e.g., when returning from another screen within the app)
      FocusManager.instance.primaryFocus?.addListener(() {
        if (ModalRoute.of(context)?.isCurrent == true) {
          print('BookListView: regained focus, refreshing data');
          controller.refreshData();
        }
      });
    });
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Books'),
        actions: [
          // Explore public books button
          IconButton(
            icon: const Icon(Icons.public),
            onPressed: controller.goToPublicLibrary,
            tooltip: 'Explore Public Books',
          ),
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.refreshData(),
            tooltip: 'Refresh',
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
                  'Error loading books',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(controller.errorMessage.value),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: controller.loadBooks,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        
        if (controller.books.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.menu_book,
                  size: 80,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No books yet',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Create your first book to get started',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Create Book'),
                  onPressed: () => Get.toNamed(Routes.BOOK),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  icon: const Icon(Icons.public),
                  label: const Text('Explore Public Books'),
                  onPressed: controller.goToPublicLibrary,
                ),
              ],
            ),
          );
        }
        
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.7,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: controller.books.length,
          itemBuilder: (context, index) {
            final book = controller.books[index];
            
            return GestureDetector(
              onTap: () => Get.toNamed(
                Routes.BOOK,
                arguments: {'bookId': book.id},
              ),
              onLongPress: () => _showBookOptionsDialog(context, book),
              child: Card(
                clipBehavior: Clip.antiAlias,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Book cover
                    Expanded(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Book cover image or placeholder
                          book.coverUrl != null && book.coverUrl!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: book.coverUrl!,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: Theme.of(context).colorScheme.surfaceVariant,
                                  child: Center(
                                    child: Icon(
                                      Icons.book,
                                      size: 48,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              )
                            : Container(
                                color: Theme.of(context).colorScheme.surfaceVariant,
                                child: Center(
                                  child: Icon(
                                    Icons.book,
                                    size: 48,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              
                          // Public indicator badge
                          if (book.isPublic)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.public,
                                      size: 14,
                                      color: Theme.of(context).colorScheme.onPrimary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Public',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.onPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    
                    // Book title and info
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            book.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Obx(() {
                            final pageCount = controller.books.firstWhere(
                              (b) => b.id == book.id, 
                              orElse: () => book
                            ).pageIds.length;
                            
                            return Text(
                              '$pageCount ${pageCount == 1 ? 'page' : 'pages'}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.toNamed(Routes.BOOK),
        child: const Icon(Icons.add),
      ),
    );
  }
  
  void _showBookOptionsDialog(BuildContext context, Book book) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Open Book'),
                onTap: () {
                  Navigator.pop(context);
                  Get.toNamed(
                    Routes.BOOK,
                    arguments: {'bookId': book.id},
                  );
                },
              ),
              if (book.isPublic)
                ListTile(
                  leading: const Icon(Icons.unpublished),
                  title: const Text('Unpublish Book'),
                  subtitle: const Text('Make this book private'),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmUnpublish(context, book);
                  },
                )
              else
                ListTile(
                  leading: const Icon(Icons.public),
                  title: const Text('Publish Book'),
                  subtitle: const Text('Share with other users'),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmPublish(context, book);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Move to Trash'),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(context, book);
                },
              ),
            ],
          ),
        );
      },
    );
  }
  
  void _confirmPublish(BuildContext context, Book book) {
    // Check if book has content
    if (book.pageIds.isEmpty) {
      Get.snackbar(
        'Cannot Publish',
        'You need to add content to your book before publishing',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
      return;
    }
    
    Get.defaultDialog(
      title: 'Publish Book',
      middleText: 'Are you sure you want to publish "${book.title}"? '
          'This will make your book visible to all users.',
      textConfirm: 'Publish',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      onConfirm: () async {
        Get.back();
        final success = await controller.publishBook(book.id);
        if (success) {
          Get.snackbar(
            'Book Published',
            'Your book "${book.title}" is now public',
            snackPosition: SnackPosition.BOTTOM,
          );
        } else {
          Get.snackbar(
            'Error',
            'Failed to publish book. Please try again.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      },
    );
  }
  
  void _confirmUnpublish(BuildContext context, Book book) {
    Get.defaultDialog(
      title: 'Unpublish Book',
      middleText: 'Are you sure you want to unpublish "${book.title}"? '
          'It will no longer be visible to other users.',
      textConfirm: 'Unpublish',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      onConfirm: () async {
        Get.back();
        final success = await controller.unpublishBook(book.id);
        if (success) {
          Get.snackbar(
            'Book Unpublished',
            'Your book "${book.title}" is now private',
            snackPosition: SnackPosition.BOTTOM,
          );
        } else {
          Get.snackbar(
            'Error',
            'Failed to unpublish book. Please try again.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      },
    );
  }
  
  void _confirmDelete(BuildContext context, Book book) {
    Get.defaultDialog(
      title: 'Move to Trash',
      middleText: 'Are you sure you want to move "${book.title}" to trash?',
      textConfirm: 'Move to Trash',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      onConfirm: () async {
        Get.back();
        // Use the loadBooks method to refresh the list after deletion
        await controller.loadBooks();
      },
    );
  }
} 