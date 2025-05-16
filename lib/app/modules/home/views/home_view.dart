import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/home_controller.dart';
import '../../../data/models/note_model.dart';
import '../../../data/models/folder_model.dart';
import '../../../data/models/tag_model.dart' as tag_model;
import '../../../routes/app_pages.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'dart:convert';
import 'package:line_icons/line_icons.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SAGE'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              _showSearchDialog(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Navigate to settings
              Get.toNamed(Routes.SETTINGS);
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: controller.signOut,
          ),
        ],
      ),
      drawer: _buildDrawer(context),
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
                  'Error loading data',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(controller.errorMessage.value),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: controller.loadData,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        
        if (controller.notes.isEmpty) {
          return _buildEmptyState(context);
        }
        
        // Add title area to show current folder/tag/search filter
        return Column(
          children: [
            // Title area showing current view
            Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _getCurrentTitle(),
                      style: Theme.of(context).textTheme.titleLarge,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (controller.selectedFolder.value != null || 
                      controller.selectedTag.value != null ||
                      controller.searchQuery.isNotEmpty)
                    TextButton.icon(
                      icon: const Icon(Icons.clear),
                      label: const Text('Clear'),
                      onPressed: controller.clearFilters,
                    ),
                ],
              ),
            ),
            
            // Notes list with Expanded to prevent overflow
            Expanded(
              child: _buildNotesList(context),
            ),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: controller.createNote,
        child: const Icon(Icons.add),
      ),
    );
  }
  
  String _getCurrentTitle() {
    if (controller.selectedFolder.value != null) {
      return 'Folder: ${controller.selectedFolder.value!.name}';
    } else if (controller.selectedTag.value != null) {
      return 'Tag: ${controller.selectedTag.value!.name}';
    } else if (controller.searchQuery.isNotEmpty) {
      return 'Search: ${controller.searchQuery.value}';
    } else {
      return 'All Notes';
    }
  }
  
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
                          // Top section with user info
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Get.toNamed(Routes.PROFILE),
                      child: FutureBuilder<String?>(
                        future: controller.getUserProfileImage(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return CircleAvatar(
                              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                              child: const SizedBox(
                                width: 15,
                                height: 15,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            );
                          }
                          
                          if (snapshot.hasData && snapshot.data != null && snapshot.data!.isNotEmpty) {
                            // Display the user's profile image
                            return CircleAvatar(
                              backgroundImage: NetworkImage(snapshot.data!),
                              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                            );
                          } else {
                            // Display initials if no profile image
                            return CircleAvatar(
                              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                              child: Text(
                                controller.getUserInitials(),
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                                      const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Get.toNamed(Routes.PROFILE),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              controller.getUserDisplayName(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Tap to edit profile',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    PopupMenuButton(
                      icon: const Icon(LineIcons.verticalEllipsis, size: 20),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          child: const Row(
                            children: [
                              Icon(LineIcons.user, size: 18),
                              SizedBox(width: 8),
                              Text('Profile'),
                            ],
                          ),
                          onTap: () => Future.delayed(
                            const Duration(milliseconds: 100),
                            () => Get.toNamed(Routes.PROFILE),
                          ),
                        ),
                        PopupMenuItem(
                          child: const Row(
                            children: [
                              Icon(LineIcons.cog, size: 18),
                              SizedBox(width: 8),
                              Text('Settings'),
                            ],
                          ),
                          onTap: () => Future.delayed(
                            const Duration(milliseconds: 100),
                            () => Get.toNamed(Routes.SETTINGS),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            
            // Search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: InkWell(
                onTap: () => _showSearchDialog(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(LineIcons.search, 
                        size: 18, 
                        color: Theme.of(context).colorScheme.onSurfaceVariant
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Search',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Main Navigation
            ListTile(
              leading: const Icon(LineIcons.home),
              title: const Text('Home'),
              selected: controller.selectedFolder.value == null && controller.selectedTag.value == null,
              onTap: () {
                controller.clearFilters();
                Get.back(); // Close drawer
              },
            ),
            ListTile(
              leading: const Icon(LineIcons.inbox),
              title: const Text('Inbox'),
              onTap: () {
                // Placeholder for inbox functionality
                Get.back();
                Get.snackbar('Coming Soon', 'Inbox functionality will be available soon',
                  snackPosition: SnackPosition.BOTTOM);
              },
            ),
            
            const Divider(),
            
            // Private section
            Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 4.0),
              child: Text(
                'PRIVATE',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            
            // Private items
            ListTile(
              leading: const Icon(LineIcons.book),
              title: const Text('Reading List'),
              onTap: () {
                Get.back();
                Get.snackbar('Feature Coming Soon', 'Reading List will be added in future updates',
                  snackPosition: SnackPosition.BOTTOM);
              },
            ),
            
            // Books option
            ListTile(
              leading: const Icon(Icons.library_books),
              title: const Text('My Books'),
              onTap: () {
                Get.back();
                Get.toNamed(Routes.BOOK_LIST);
              },
            ),
            
            // New book button
            ListTile(
              leading: const Icon(Icons.book_online),
              title: const Text('New Book'),
              onTap: () {
                Get.back();
                Get.toNamed(Routes.BOOK);
              },
            ),
            
            // New page / Create note button
            ListTile(
              leading: const Icon(LineIcons.plusCircle),
              title: const Text('New page'),
              onTap: () {
                Get.back();
                controller.createNote();
              },
            ),
            
            const Divider(),
            
            // FOLDERS SECTION
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'FOLDERS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      Get.back(); // Close drawer
                      _showCreateFolderDialog(context);
                    },
                  ),
                ],
              ),
            ),
            
            // Folder list
            Expanded(
              child: Obx(() {
                if (controller.folders.isEmpty) {
                  return const Center(
                    child: Text('No folders yet'),
                  );
                }
                
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: controller.folders.length,
                  itemBuilder: (context, index) {
                    final folder = controller.folders[index];
                    return ListTile(
                      leading: const Icon(Icons.folder),
                      title: Text(
                        folder.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      selected: controller.selectedFolder.value?.id == folder.id,
                      trailing: PopupMenuButton(
                        icon: const Icon(Icons.more_horiz),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            child: const Text('Rename'),
                            onTap: () => Future.delayed(
                              const Duration(milliseconds: 100),
                              () => _showEditFolderDialog(context, folder),
                            ),
                          ),
                          PopupMenuItem(
                            child: const Text('Manage Notes'),
                            onTap: () => Future.delayed(
                              const Duration(milliseconds: 100),
                              () => _showFolderNotesDialog(context, folder),
                            ),
                          ),
                          PopupMenuItem(
                            child: const Text('Delete'),
                            onTap: () => Future.delayed(
                              const Duration(milliseconds: 100),
                              () => _showDeleteFolderDialog(context, folder),
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        controller.selectFolder(folder);
                        Get.back(); // Close drawer
                      },
                    );
                  },
                );
              }),
            ),
            
            // Shared section
            const Divider(),
            Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 4.0),
              child: Text(
                'SHARED',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            
            Container(
              height: 80,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Shared pages will go here'),
                    TextButton.icon(
                      icon: const Icon(Icons.share_outlined, size: 16),
                      label: const Text('Start collaborating'),
                      onPressed: () {
                        Get.back();
                        Get.snackbar('Coming Soon', 'Sharing functionality will be added in future updates',
                          snackPosition: SnackPosition.BOTTOM);
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            const Divider(),
            
            // Tags expandable section
            ExpansionTile(
              title: const Text('Tags'),
              leading: const Icon(Icons.tag_outlined),
              childrenPadding: const EdgeInsets.only(left: 16.0),
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('New Tag'),
                        onPressed: () {
                          Get.back(); // Close drawer
                          _showCreateTagDialog(context);
                        },
                      ),
                    ],
                  ),
                ),
                Obx(() {
                  if (controller.tags.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No tags yet'),
                    );
                  }
                  
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: controller.tags.length,
                    itemBuilder: (context, index) {
                      final tag = controller.tags[index];
                      return ListTile(
                        leading: const Icon(Icons.tag, size: 18),
                        title: Text(
                          tag.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        selected: controller.selectedTag.value?.id == tag.id,
                        trailing: IconButton(
                          icon: const Icon(Icons.more_horiz),
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              builder: (context) => Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.edit),
                                    title: const Text('Rename'),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _showEditTagDialog(context, tag);
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.delete),
                                    title: const Text('Delete'),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _showDeleteTagDialog(context, tag);
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        onTap: () {
                          controller.selectTag(tag);
                          Get.back(); // Close drawer
                        },
                      );
                    },
                  );
                }),
              ],
            ),
            
            // Bottom options
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              onTap: () {
                Get.back(); // Close drawer
                Get.toNamed(Routes.SETTINGS);
              },
            ),
            ListTile(
              leading: const Icon(Icons.style_outlined),
              title: const Text('Templates'),
              onTap: () {
                Get.back();
                Get.snackbar('Coming Soon', 'Templates functionality will be added in future updates',
                  snackPosition: SnackPosition.BOTTOM);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Trash'),
              onTap: () {
                Get.back();
                Get.snackbar('Coming Soon', 'Trash functionality will be added in future updates',
                  snackPosition: SnackPosition.BOTTOM);
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEmptyState(BuildContext context) {
    String message = 'No notes yet. Create your first note!';
    
    if (controller.selectedFolder.value != null) {
      message = 'No notes in "${controller.selectedFolder.value!.name}" folder.';
    } else if (controller.selectedTag.value != null) {
      message = 'No notes with "${controller.selectedTag.value!.name}" tag.';
    } else if (controller.searchQuery.isNotEmpty) {
      message = 'No notes matching "${controller.searchQuery.value}".';
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.note_add,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Create Note'),
            onPressed: controller.createNote,
          ),
        ],
      ),
    );
  }
  
  Widget _buildNotesList(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: controller.notes.length,
      itemBuilder: (context, index) {
        final note = controller.notes[index];
        String content = '';
        
        // Clean up content for preview
        try {
          final jsonContent = jsonDecode(note.content);
          if (jsonContent is List && jsonContent.isNotEmpty) {
            // Extract text content from Delta format
            for (var op in jsonContent) {
              if (op is Map && op.containsKey('insert')) {
                content += op['insert'].toString();
              }
            }
          } else {
            content = "Content preview not available";
          }
        } catch (e) {
          // Handle malformed content
          content = note.content
            .replaceAll('[["insert":"', '')
            .replaceAll('"]]', '')
            .replaceAll('\\n', '\n');
        }
        
        // Limit preview length
        if (content.length > 100) {
          content = content.substring(0, 100) + '...';
        }
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Slidable(
            endActionPane: ActionPane(
              motion: const ScrollMotion(),
              children: [
                SlidableAction(
                  onPressed: (context) => _showMoveToFolderDialog(context, note),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  icon: Icons.folder,
                  label: 'Move',
                ),
                if (note.folderId != null)
                  SlidableAction(
                    onPressed: (context) => _removeFromFolder(context, note),
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    icon: Icons.folder_off,
                    label: 'Remove from Folder',
                  ),
                SlidableAction(
                  onPressed: (context) => _showDeleteNoteDialog(context, note),
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  icon: Icons.delete,
                  label: 'Delete',
                ),
              ],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => controller.openNote(note),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            note.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          DateFormat('MMM d, yyyy').format(note.updatedAt),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    if (note.tags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: note.tags.map((tag) => Chip(
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          label: Text(
                            tag.name,
                            style: const TextStyle(fontSize: 10),
                          ),
                          padding: EdgeInsets.zero,
                        )).toList(),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      content,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        fontSize: 14,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  void _showSearchDialog(BuildContext context) {
    final searchController = TextEditingController();
    searchController.text = controller.searchQuery.value;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Notes'),
        content: TextField(
          controller: searchController,
          decoration: const InputDecoration(
            hintText: 'Enter search term',
            prefixIcon: Icon(Icons.search),
          ),
          autofocus: true,
          onSubmitted: (value) {
            controller.search(value);
            Get.back();
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.search(searchController.text);
              Get.back();
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }
  
  void _showCreateFolderDialog(BuildContext context) {
    controller.newFolderController.clear();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Folder'),
        content: TextField(
          controller: controller.newFolderController,
          decoration: const InputDecoration(
            hintText: 'Folder name',
            prefixIcon: Icon(Icons.folder),
          ),
          autofocus: true,
          onSubmitted: (_) => controller.createFolder(),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: controller.createFolder,
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
  
  void _showCreateTagDialog(BuildContext context) {
    controller.newTagController.clear();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Tag'),
        content: TextField(
          controller: controller.newTagController,
          decoration: const InputDecoration(
            hintText: 'Tag name',
            prefixIcon: Icon(Icons.tag),
          ),
          autofocus: true,
          onSubmitted: (_) => controller.createTag(),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: controller.createTag,
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
  
  void _showDeleteFolderDialog(BuildContext context, Folder folder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Folder'),
        content: Text(
          'Are you sure you want to delete the folder "${folder.name}"? This will not delete the notes inside the folder.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.deleteFolder(folder.id);
              Get.back();
            },
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
  
  void _showDeleteTagDialog(BuildContext context, tag_model.Tag tag) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Tag'),
        content: Text(
          'Are you sure you want to delete the tag "${tag.name}"? This will not delete the notes with this tag.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.deleteTag(tag.id);
              Get.back();
            },
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
  
  void _showDeleteNoteDialog(BuildContext context, Note note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: Text(
          'Are you sure you want to delete the note "${note.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.deleteNote(note.id);
              Get.back();
            },
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
  
  void _showMoveToFolderDialog(BuildContext context, Note note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Move to Folder'),
        content: SizedBox(
          width: double.maxFinite,
          child: Obx(() {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('No Folder'),
                  leading: const Icon(Icons.folder_off),
                  onTap: () {
                    controller.moveNoteToFolder(note.id, null);
                    Get.back();
                  },
                ),
                const Divider(),
                if (controller.folders.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No folders available'),
                    ),
                  )
                else
                  ...controller.folders.map((folder) => ListTile(
                    title: Text(folder.name),
                    leading: const Icon(Icons.folder),
                    onTap: () {
                      controller.moveNoteToFolder(note.id, folder.id);
                      Get.back();
                    },
                  )),
              ],
            );
          }),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
  
  void _showEditFolderDialog(BuildContext context, Folder folder) {
    controller.editFolderController.text = folder.name;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Folder'),
        content: TextField(
          controller: controller.editFolderController,
          decoration: const InputDecoration(
            hintText: 'Folder name',
            prefixIcon: Icon(Icons.folder),
          ),
          autofocus: true,
          onSubmitted: (_) => controller.editFolder(folder),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => controller.editFolder(folder),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
  
  void _showEditTagDialog(BuildContext context, tag_model.Tag tag) {
    controller.editTagController.text = tag.name;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Tag'),
        content: TextField(
          controller: controller.editTagController,
          decoration: const InputDecoration(
            hintText: 'Tag name',
            prefixIcon: Icon(Icons.tag),
          ),
          autofocus: true,
          onSubmitted: (_) => controller.editTag(tag),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => controller.editTag(tag),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
  
  void _showFolderNotesDialog(BuildContext context, Folder folder) {
    // We need to fetch notes for this specific folder
    controller.loadNotes(specificFolderId: folder.id).then((_) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Notes in "${folder.name}"'),
          content: SizedBox(
            width: double.maxFinite,
            child: Obx(() {
              final folderNotes = controller.notes.where((note) => note.folderId == folder.id).toList();
              
              if (folderNotes.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No notes in this folder'),
                );
              }
              
              return ListView.builder(
                shrinkWrap: true,
                itemCount: folderNotes.length,
                itemBuilder: (context, index) {
                  final note = folderNotes[index];
                  return ListTile(
                    title: Text(
                      note.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      DateFormat('MMM d, yyyy').format(note.updatedAt),
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.folder_off),
                      tooltip: 'Remove from folder',
                      onPressed: () {
                        controller.moveNoteToFolder(note.id, null);
                        // We need to refresh the list
                        controller.loadNotes(specificFolderId: folder.id);
                      },
                    ),
                    onTap: () {
                      Get.back();
                      controller.openNote(note);
                    },
                  );
                },
              );
            }),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    });
  }
  
  void _removeFromFolder(BuildContext context, Note note) {
    // Confirm with the user before removing from folder
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove from Folder'),
        content: Text(
          'Are you sure you want to remove "${note.title}" from its folder?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.moveNoteToFolder(note.id, null);
              Get.back();
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}
