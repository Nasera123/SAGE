import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';
import '../controllers/book_controller.dart';
import '../controllers/category_controller.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../routes/app_pages.dart';
import '../../note_editor/views/music_dialog.dart';
import '../../note_editor/controllers/music_controller.dart';
import 'widgets/category_filter_widget.dart';

class BookView extends GetView<BookController> {
  const BookView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Initialize category controller
    final categoryController = Get.put(CategoryController());
    
    // Auto-refresh saat halaman ditampilkan
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.book.value != null) {
        // Cek apakah perlu refresh (misalnya setelah edit halaman)
        if (controller.needsRefresh.value) {
          print('BookView: needsRefresh flag detected, triggering loadBookPages');
          controller.loadBookPages();
          controller.needsRefresh.value = false;
        } else {
          // Refresh ringan saat tampilan pertama kali muncul
          controller.refreshBook();
        }
      }
    });
    
    return WillPopScope(
      onWillPop: () async {
        // Stop music when navigating away from the book
        await controller.handleLeavingBook();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Obx(() => Text(controller.book.value?.title ?? 'New Book')),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
              onPressed: () {
                controller.refreshBook();
                controller.loadBookPages();
                Get.snackbar(
                  'Refreshed',
                  'Book data refreshed',
                  snackPosition: SnackPosition.BOTTOM,
                  duration: const Duration(seconds: 2),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.music_note),
              tooltip: 'Background Music',
              onPressed: () => _showMusicDialog(context),
            ),
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: controller.saveBook,
              tooltip: 'Save Book',
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') {
                  _showDeleteBookDialog(context);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete Book'),
                    ],
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
                // Realtime activity indicator
                Obx(() {
                  if (controller.realtimeActivity.isNotEmpty) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.withOpacity(0.5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.sync, color: Colors.green, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              controller.realtimeActivity.value,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }),
                
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
                
                // Description field
                const SizedBox(height: 24),
                const Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: controller.descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Enter book description (optional)',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => controller.descriptionController.clear(),
                    ),
                  ),
                ),
                
                // Categories section
                const SizedBox(height: 24),
                Obx(() {
                  if (controller.book.value == null) {
                    return const SizedBox.shrink();
                  }
                  
                  return BookCategorySelectionWidget(
                    bookId: controller.book.value!.id,
                    categoryController: categoryController,
                  );
                }),
                
                // Pages section
                const SizedBox(height: 24),
                
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
      ),
    );
  }
  
  Widget _buildPagesList(BuildContext context) {
    if (controller.book.value == null) {
      return const Center(
        child: Text('No book loaded'),
      );
    }
    
    return Obx(() {
      // Cek ulang jumlah halaman
      final pageIds = controller.book.value?.pageIds ?? [];
      
      if (pageIds.isEmpty) {
        return Center(
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
        );
      }
      
      if (controller.isLoadingPages.value) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: pageIds.length,
            itemBuilder: (context, index) {
              final pageId = pageIds[index];
              
              // Find the corresponding note for this page
              final pageNote = controller.bookPages.firstWhereOrNull(
                (note) => note.id == pageId
              );
              
              // Jika halaman tidak ditemukan, menampilkan placeholder
              if (pageNote == null) {
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                    child: Text('${index + 1}', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
                  ),
                  title: const Text('Loading page...', style: TextStyle(fontStyle: FontStyle.italic)),
                  trailing: const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }
              
              return Dismissible(
                key: Key(pageId),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16.0),
                  color: Colors.red,
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                  ),
                ),
                confirmDismiss: (direction) async {
                  bool deleteNote = false;
                  
                  return await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return StatefulBuilder(
                        builder: (context, setState) {
                          return AlertDialog(
                            title: const Text("Delete Page"),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Are you sure you want to delete this page?"),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Checkbox(
                                      value: deleteNote,
                                      onChanged: (value) {
                                        setState(() {
                                          deleteNote = value ?? false;
                                        });
                                      },
                                    ),
                                    const Expanded(
                                      child: Text(
                                        "Also move the note to trash (can be restored later)",
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text("Cancel"),
                              ),
                              TextButton(
                                onPressed: () {
                                  // Store the deleteNote value for onDismissed
                                  controller.tempDeleteNote = deleteNote;
                                  Navigator.of(context).pop(true);
                                },
                                child: const Text(
                                  "Delete",
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          );
                        }
                      );
                    },
                  );
                },
                onDismissed: (direction) {
                  // Use the stored value for deleteNote
                  controller.deletePage(pageId, deleteNote: controller.tempDeleteNote);
                },
                child: Card(
                  margin: const EdgeInsets.only(bottom: 8.0),
                  elevation: 2,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Text('${index + 1}', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
                    ),
                    title: Text(pageNote?.title ?? 'Page ${index + 1}'),
                    subtitle: Text(
                      pageNote != null 
                          ? 'Updated: ${_formatDate(pageNote.updatedAt)}'
                          : 'Tap to open and edit'
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                          onPressed: () async {
                            bool deleteNote = false;
                            
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (BuildContext context) {
                                return StatefulBuilder(
                                  builder: (context, setState) {
                                    return AlertDialog(
                                      title: const Text("Delete Page"),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text("Are you sure you want to delete this page?"),
                                          const SizedBox(height: 16),
                                          Row(
                                            children: [
                                              Checkbox(
                                                value: deleteNote,
                                                onChanged: (value) {
                                                  setState(() {
                                                    deleteNote = value ?? false;
                                                  });
                                                },
                                              ),
                                              const Expanded(
                                                child: Text(
                                                  "Also move the note to trash (can be restored later)",
                                                  style: TextStyle(fontSize: 12),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(false),
                                          child: const Text("Cancel"),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(true),
                                          child: const Text(
                                            "Delete",
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    );
                                  }
                                );
                              },
                            );
                            
                            if (confirm == true) {
                              controller.deletePage(pageId, deleteNote: deleteNote);
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_ios, size: 16),
                      ],
                    ),
                    onTap: () async {
                      // Stop current book music before navigating to the page
                      await controller.handleLeavingBook();
                      
                      // Open the note editor and refresh when returning
                      final result = await Get.toNamed(
                        Routes.NOTE_EDITOR,
                        arguments: {
                          'noteId': pageId,
                          'isBookPage': true,
                          'bookId': controller.book.value!.id
                        },
                      );
                      
                      // Pastikan selalu refresh halaman setelah kembali dari editor
                      controller.loadBookPages();
                      
                      // Reload book music when returning from the page
                      if (Get.isRegistered<MusicController>()) {
                        final musicController = Get.find<MusicController>();
                        await musicController.loadMusicForBook(controller.book.value!.id);
                      }
                    },
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add New Page'),
            onPressed: controller.createNewPage,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      );
    });
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
  
  void _showDeleteBookDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Book'),
                content: Text(          'Are you sure you want to move "${controller.book.value!.title}" to trash? You can restore it later from the trash.',        ),
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
  
  void _showMusicDialog(BuildContext context) {
    if (controller.book.value == null) return;
    
    showDialog(
      context: context,
      builder: (context) => MusicDialog(
        bookId: controller.book.value!.id,
      ),
    );
  }
} 