import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../controllers/inbox_controller.dart';
import '../../../routes/app_pages.dart';

class InboxView extends GetView<InboxController> {
  const InboxView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comments Inbox'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.loadUnreadComments,
            tooltip: 'Refresh',
          ),
          Obx(() => controller.unreadComments.isNotEmpty
            ? TextButton.icon(
                onPressed: controller.markAllAsRead,
                icon: const Icon(Icons.done_all),
                label: const Text('Mark all as read'),
              )
            : const SizedBox.shrink()
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.unreadComments.isEmpty) {
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
                  'Error loading comments',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(controller.errorMessage.value),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: controller.loadUnreadComments,
                  child: const Text('Try Again'),
                ),
              ],
            ),
          );
        }
        
        if (controller.unreadComments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.mark_email_read, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'No unread comments',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text('You\'re all caught up!'),
              ],
            ),
          );
        }
        
        return RefreshIndicator(
          onRefresh: controller.loadUnreadComments,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: controller.unreadComments.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final comment = controller.unreadComments[index];
              
              return InkWell(
                onTap: () {
                  // Navigate to book reader
                  Get.toNamed(
                    Routes.PUBLIC_BOOK_READER,
                    arguments: {'bookId': comment.bookId}
                  );
                  
                  // Mark comment as read
                  controller.markAsRead(comment.id);
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // User avatar
                            CircleAvatar(
                              radius: 20,
                              backgroundImage: comment.userAvatarUrl != null && comment.userAvatarUrl!.isNotEmpty
                                  ? CachedNetworkImageProvider(comment.userAvatarUrl!)
                                  : null,
                              child: comment.userAvatarUrl == null || comment.userAvatarUrl!.isEmpty
                                  ? Text(
                                      comment.userDisplayName.isNotEmpty
                                          ? comment.userDisplayName[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            
                            // User name and timestamp
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    comment.userDisplayName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    DateFormat('MMM d, yyyy - HH:mm').format(comment.createdAt),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Mark as read button
                            IconButton(
                              icon: const Icon(Icons.done),
                              onPressed: () => controller.markAsRead(comment.id),
                              tooltip: 'Mark as read',
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        // Comment content
                        Text(
                          comment.content,
                          style: const TextStyle(fontSize: 16),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Book link
                        Row(
                          children: [
                            const Icon(Icons.book, size: 16),
                            const SizedBox(width: 8),
                            const Text(
                              'On your book:',
                              style: TextStyle(fontSize: 12),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'View book', // Ideally book title here
                                style: TextStyle(
                                  fontSize: 12, 
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
} 