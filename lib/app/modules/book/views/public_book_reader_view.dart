import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/public_book_reader_controller.dart';
import '../controllers/readlist_controller.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:cached_network_image/cached_network_image.dart';
import '../../../data/models/note_model.dart';
import '../../../routes/app_pages.dart';

class PublicBookReaderView extends GetView<PublicBookReaderController> {
  const PublicBookReaderView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(controller.book.value?.title ?? 'Book Reader')),
        actions: [
          // Comment button
          IconButton(
            icon: const Icon(Icons.comment_outlined),
            onPressed: () {
              if (controller.book.value != null) {
                Get.toNamed(
                  Routes.BOOK_COMMENTS,
                  arguments: {'bookId': controller.book.value!.id}
                );
              }
            },
            tooltip: 'Comments',
          ),
          // Reading List button
          Obx(() {
            if (controller.book.value == null) {
              return const SizedBox.shrink();
            }
            
            final bookId = controller.book.value!.id;
            return FutureBuilder<bool>(
              future: controller.isInReadlist(bookId),
              builder: (context, snapshot) {
                final isInReadlist = snapshot.data ?? false;
                return IconButton(
                  icon: Icon(isInReadlist ? Icons.bookmark : Icons.bookmark_outline),
                  onPressed: () => _toggleReadlistStatus(context, bookId, isInReadlist),
                  tooltip: isInReadlist ? 'Remove from Reading List' : 'Add to Reading List',
                );
              },
            );
          }),
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () => _showContentsDialog(context),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (controller.hasError.value) {
          return _buildErrorState(context);
        }
        
        if (controller.notes.isEmpty) {
          return _buildEmptyState(context);
        }
        
        // Book header and content
        return Column(
          children: [
            // Book info header
            _buildBookInfoHeader(context),
            
            // Page content with pagination
            Expanded(
              child: PageView.builder(
                controller: controller.pageController,
                itemCount: controller.notes.length,
                onPageChanged: (index) {
                  controller.currentPageIndex.value = index;
                },
                itemBuilder: (context, index) {
                  final note = controller.notes[index];
                  return _buildPageContent(context, note);
                },
              ),
            ),
            
            // Navigation controls
            _buildPageNavigationBar(context),
          ],
        );
      }),
    );
  }

  Widget _buildBookInfoHeader(BuildContext context) {
    final book = controller.book.value!;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Book cover or placeholder
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: book.coverUrl != null
                ? CachedNetworkImage(
                    imageUrl: book.coverUrl!,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 60,
                      height: 60,
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 60,
                      height: 60,
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      child: Center(
                        child: Icon(
                          Icons.book,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  )
                : Container(
                    width: 60,
                    height: 60,
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    child: Center(
                      child: Icon(
                        Icons.book,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 16),
          
          // Book info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  book.title,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 10,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Text(
                        controller.getUserInitials(),
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'By ${book.userDisplayName ?? 'Unknown'}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageContent(BuildContext context, Note note) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page title if available
          if (note.title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                note.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          
          // Page content
          quill.QuillEditor(
            controller: controller.getQuillControllerForNote(note.id),
            scrollController: ScrollController(),
            focusNode: FocusNode(),
            config: quill.QuillEditorConfig(
              scrollable: true,
              placeholder: 'No content',
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageNavigationBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, -1),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous button
          ElevatedButton.icon(
            onPressed: controller.currentPageIndex.value > 0
                ? controller.previousPage
                : null,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Previous'),
          ),
          // Page indicator
          Text(
            '${controller.currentPageIndex.value + 1} / ${controller.notes.length}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          // Next button
          ElevatedButton.icon(
            onPressed: controller.currentPageIndex.value < controller.notes.length - 1
                ? controller.nextPage
                : null,
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Next'),
          ),
        ],
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
            'Error loading book',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(controller.errorMessage.value),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              if (Get.arguments != null && Get.arguments['bookId'] != null) {
                controller.loadBook(Get.arguments['bookId'] as String);
              } else {
                Get.back();
              }
            },
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
            Icons.menu_book,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'This book has no pages yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Get.back(),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  void _showContentsDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'Contents',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              itemCount: controller.notes.length,
              itemBuilder: (context, index) {
                final isCurrentPage = controller.currentPageIndex.value == index;
                final note = controller.notes[index];
                
                return ListTile(
                  title: Text(
                    note.title.isNotEmpty ? note.title : 'Page ${index + 1}',
                    style: TextStyle(
                      fontWeight: isCurrentPage ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  leading: CircleAvatar(
                    backgroundColor: isCurrentPage 
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surfaceVariant,
                    foregroundColor: isCurrentPage
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    child: Text('${index + 1}'),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    controller.goToPage(index);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Helper function to toggle readlist status
  void _toggleReadlistStatus(BuildContext context, String bookId, bool isInReadlist) async {
    try {
      final readlistController = Get.find<ReadlistController>(tag: 'global_readlist');
      
      if (isInReadlist) {
        await readlistController.removeFromReadlist(bookId);
        Get.snackbar(
          'Removed from Reading List',
          'Book has been removed from your reading list',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      } else {
        await readlistController.addToReadlist(bookId);
        Get.snackbar(
          'Added to Reading List',
          'Book has been added to your reading list',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
      // Force UI update
      controller.update();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update reading list: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
} 