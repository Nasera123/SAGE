import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/book_list_controller.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../routes/app_pages.dart';
import 'package:flutter/services.dart';

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
          // Tambahkan tombol refresh manual
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
                      child: book.coverUrl != null && book.coverUrl!.isNotEmpty
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
} 