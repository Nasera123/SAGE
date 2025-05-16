import 'package:flutter/material.dart';import 'package:get/get.dart';import 'package:flutter_quill/flutter_quill.dart';import '../controllers/note_editor_controller.dart';import '../../../data/models/tag_model.dart' as tag_model;import 'package:intl/intl.dart';import '../../../modules/home/controllers/home_controller.dart';

class NoteEditorView extends GetView<NoteEditorController> {
  const NoteEditorView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Save changes if needed
        if (controller.isDirty.value) {
          await controller.saveNote();
        }
        
        // Return the updated note directly to the calling screen
        Get.back(result: controller.note); // Pass the actual updated note
        return false; // We handle the back navigation manually
      },
      child: Scaffold(
      appBar: AppBar(
        title: Obx(() => controller.isLoading.value 
          ? const Text('Loading...') 
          : const Text('Edit Note')
        ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              // Save changes if needed
              if (controller.isDirty.value) {
                await controller.saveNote();
              }
              
              // Tell GetX to refresh the notes list when returning to home
              Get.back(result: controller.note);
            },
          ),
        actions: [
            // Delete button
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete Note',
              onPressed: () => controller.confirmDelete(),
            ),
          IconButton(
            icon: const Icon(Icons.tag),
            tooltip: 'Manage Tags',
            onPressed: () => _showTagsDialog(context),
          ),
          Obx(() {
            if (controller.isSaving.value) {
              return const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }
            
            return IconButton(
              icon: const Icon(Icons.save),
              tooltip: 'Save Note',
              onPressed: () => controller.saveNote(),
            );
          }),
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
                  'Error loading note',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(controller.errorMessage.value),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Get.back(),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          );
        }
        
        // Status indicator
        final statusWidget = Obx(() {
          if (controller.isAutosaving.value) {
            return const Padding(
              padding: EdgeInsets.all(8.0),
              child: Row(
                  mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('Autosaving...', style: TextStyle(fontSize: 12)),
                ],
              ),
            );
          } else if (controller.isDirty.value) {
            return const Padding(
              padding: EdgeInsets.all(8.0),
              child: Row(
                  mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit, size: 12),
                  SizedBox(width: 8),
                  Text('Unsaved changes', style: TextStyle(fontSize: 12)),
                ],
              ),
            );
          } else {
            return const Padding(
              padding: EdgeInsets.all(8.0),
              child: Row(
                  mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check, size: 12, color: Colors.green),
                  SizedBox(width: 8),
                  Text('All changes saved', style: TextStyle(fontSize: 12)),
                ],
              ),
            );
          }
        });
        
        return Column(
          children: [
            // Title field
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: controller.titleController,
                  focusNode: controller.titleFocusNode,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) {
                    // Move focus to editor when user presses enter/next
                    controller.titleFocusNode.unfocus();
                    controller.editorFocusNode.requestFocus();
                  },
                  decoration: InputDecoration(
                  hintText: 'Note Title',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                  ),
                  style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            
            // Tags section
            Obx(() {
              if (controller.selectedTags.isEmpty) {
                return const SizedBox.shrink();
              }
              
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Wrap(
                  spacing: 8.0,
                    runSpacing: 4.0,
                  children: controller.selectedTags.map((tag) => Chip(
                    label: Text(tag.name),
                      deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => controller.removeTagFromNote(tag),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.7),
                      labelStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontSize: 12,
                      ),
                  )).toList(),
                ),
              );
            }),
            
              // Divider
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Divider(),
              ),
              
              // Simple toolbar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                constraints: const BoxConstraints(maxHeight: 56),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Center(
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.format_bold),
                          onPressed: () => controller.quillController.formatSelection(Attribute.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.format_italic),
                          onPressed: () => controller.quillController.formatSelection(Attribute.italic),
                        ),
                        IconButton(
                          icon: const Icon(Icons.format_underline),
                          onPressed: () => controller.quillController.formatSelection(Attribute.underline),
                        ),
                        const VerticalDivider(),
                        IconButton(
                          icon: const Icon(Icons.format_list_bulleted),
                          onPressed: () => controller.quillController.formatSelection(Attribute.ul),
                        ),
                        IconButton(
                          icon: const Icon(Icons.format_list_numbered),
                          onPressed: () => controller.quillController.formatSelection(Attribute.ol),
                        ),
                      ],
                    ),
                  ),
                ),
            ),
            
            // Editor
            Expanded(
              child: Container(
                  padding: const EdgeInsets.all(16.0),
                  color: Theme.of(context).colorScheme.background.withOpacity(0.5),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).shadowColor.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                padding: const EdgeInsets.all(16.0),
                child: QuillEditor.basic(
                  controller: controller.quillController,
                      focusNode: controller.editorFocusNode,
                  ),
                ),
              ),
            ),
            
              // Status and autosave indicator
              Container(
                color: Theme.of(context).colorScheme.surface,
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
            // Status indicator
                      statusWidget,
                      
                      const SizedBox(width: 16),
                      
                      // Last updated timestamp
                      Obx(() => Text(
                        'Last updated: ${DateFormat('MMM d, h:mm a').format(controller.note.updatedAt)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        ),
                      )),
                    ],
                  ),
                ),
            ),
          ],
        );
      }),
      ),
    );
  }
  
  void _showTagsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manage Tags'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Selected Tags:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Obx(() {
                if (controller.selectedTags.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: 16.0),
                    child: Text('No tags selected'),
                  );
                }
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Wrap(
                    spacing: 8.0,
                    children: controller.selectedTags.map((tag) => Chip(
                      label: Text(tag.name),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () {
                        controller.removeTagFromNote(tag);
                      },
                    )).toList(),
                  ),
                );
              }),
              
              const Divider(),
              const Text('Available Tags:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              
              Obx(() {
                if (controller.availableTags.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: 16.0),
                    child: Text('No more tags available'),
                  );
                }
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Wrap(
                    spacing: 8.0,
                    children: controller.availableTags.map((tag) => ActionChip(
                      label: Text(tag.name),
                      onPressed: () {
                        controller.addTagToNote(tag);
                      },
                    )).toList(),
                  ),
                );
              }),
              
              const Divider(),
              const Text('Create New Tag:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller.newTagController,
                      decoration: const InputDecoration(
                        hintText: 'Tag name',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: controller.createAndAddTag,
                    child: const Text('Add'),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
} 