import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/public_library_controller.dart';
import '../controllers/category_controller.dart';
import '../../../routes/app_pages.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'widgets/category_filter_widget.dart';

class PublicLibraryView extends GetView<PublicLibraryController> {
  const PublicLibraryView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Initialize category controller
    final categoryController = Get.put(CategoryController());
    
    // Refresh data when view is shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Pastikan data buku di-reset sepenuhnya sebelum memuat ulang
      controller.books.clear();
      controller.currentPage.value = 0;
      controller.hasMoreBooks.value = true;
      controller.loadPublishedBooks(refresh: true);
      categoryController.loadCategories();
    });
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore Books'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.bookmark),
            onPressed: () => Get.toNamed(Routes.READLIST),
            tooltip: 'My Reading List',
          ),
          IconButton(
            icon: const Icon(Icons.inbox),
            onPressed: () => Get.toNamed(Routes.INBOX),
            tooltip: 'Comments Inbox',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar at the top
          Obx(() {
            if (controller.searchQuery.isNotEmpty) {
              return Container(
                padding: const EdgeInsets.all(8.0),
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                child: Row(
                  children: [
                    const Icon(Icons.search),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Search: "${controller.searchQuery.value}"',
                        style: Theme.of(context).textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: controller.clearSearch,
                      iconSize: 20,
                    ),
                  ],
                ),
              );
            } else {
              return const SizedBox.shrink();
            }
          }),

          // Category filter
          CategoryFilterWidget(
            isPublic: true,
            categoryController: categoryController,
          ),

          // Books grid/list
          Expanded(
            child: Obx(() {
              // First check if category filter is active
              if (categoryController.selectedCategoryId.isNotEmpty) {
                // Show category-filtered books
                if (categoryController.isLoading.value) {
                  return _buildLoadingState();
                } else if (categoryController.filteredBooks.isEmpty) {
                  return _buildEmptyFilterState(context);
                }
                
                // Return filtered books grid
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: categoryController.filteredBooks.length,
                  itemBuilder: (context, index) {
                    final book = categoryController.filteredBooks[index];
                    return _buildBookCard(context, book);
                  },
                );
              } 
              // No category filter active, show regular book list
              else {
                if (controller.isLoading.value && controller.books.isEmpty) {
                  return _buildLoadingState();
                } else if (controller.hasError.value) {
                  return _buildErrorState(context);
                } else if (controller.books.isEmpty) {
                  return _buildEmptyState(context);
                }

                // Jika filter dihapus dan list controller belum diisi, muat ulang buku
                if (controller.books.isEmpty) {
                  controller.loadPublishedBooks(refresh: true);
                  return _buildLoadingState();
                }

                // Return regular books grid with pagination
                return NotificationListener<ScrollNotification>(
                  onNotification: (ScrollNotification scrollInfo) {
                    // Load more books when scrolling to the bottom
                    if (!controller.isLoading.value && 
                        controller.hasMoreBooks.value && 
                        scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
                      controller.loadPublishedBooks();
                    }
                    return false;
                  },
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: controller.books.length + (controller.hasMoreBooks.value ? 1 : 0),
                    itemBuilder: (context, index) {
                      // Show loading indicator for the last item when loading more
                      if (index == controller.books.length) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final book = controller.books[index];
                      return _buildBookCard(context, book);
                    },
                  ),
                );
              }
            }),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBookCard(BuildContext context, dynamic book) {
    return InkWell(
      onTap: () {
        Get.toNamed(
          Routes.PUBLIC_BOOK_READER,
          arguments: {'bookId': book.id}
        );
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book cover
            Expanded(
              flex: 3,
              child: book.coverUrl != null && book.coverUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: book.coverUrl!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    placeholder: (context, url) => Container(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      child: Center(
                        child: Icon(
                          Icons.book,
                          size: 48,
                          color: Theme.of(context).colorScheme.primary,
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
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
            ),
            
            // Book info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    
                    // Author
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 10,
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          child: Text(
                            controller.getUserInitials(book),
                            style: TextStyle(
                              fontSize: 10,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            book.userDisplayName ?? 'Unknown',
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Empty state specifically for when filter returns no results
  Widget _buildEmptyFilterState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.filter_list_off,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No books found in this category',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Try selecting a different category or clear the filter',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: 6,
        itemBuilder: (_, __) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error loading books',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(controller.errorMessage.value),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => controller.loadPublishedBooks(refresh: true),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            controller.searchQuery.isEmpty ? Icons.library_books : Icons.search_off,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            controller.searchQuery.isEmpty
                ? 'No published books yet'
                : 'No books found for "${controller.searchQuery.value}"',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (controller.searchQuery.isNotEmpty)
            ElevatedButton(
              onPressed: controller.clearSearch,
              child: const Text('Clear Search'),
            ),
        ],
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    final textController = TextEditingController(text: controller.searchQuery.value);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Books'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            hintText: 'Enter book title or description',
            prefixIcon: Icon(Icons.search),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final query = textController.text.trim();
              Get.back();
              if (query.isNotEmpty) {
                controller.searchBooks(query);
              }
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }
} 