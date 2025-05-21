import 'package:flutter/material.dart';import 'package:get/get.dart';import 'package:flutter_quill/flutter_quill.dart';import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';import '../controllers/note_editor_controller.dart';import '../../../data/models/tag_model.dart' as tag_model;import 'package:intl/intl.dart';import '../../../modules/home/controllers/home_controller.dart';import 'dart:async';import '../views/music_dialog.dart';

class NoteEditorView extends GetView<NoteEditorController> {
  const NoteEditorView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        try {
          // Simpan perubahan dengan cepat dan langsung kembali
          print('Back button pressed - saving and returning');
          controller.saveAndClose();
        } catch (e) {
          print('Error on back navigation: $e');
          // Tetap kembali meskipun ada error
          Get.back();
        }
        
        // Return true untuk mengizinkan navigasi kembali default
        return true;
      },
      child: Scaffold(
      appBar: AppBar(
        title: Obx(() => controller.isLoading.value 
          ? const Text('Loading...') 
          : const Text('Edit Note')
        ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              // Simpan perubahan dengan cepat dan langsung kembali
              print('Back button in AppBar pressed - saving and returning');
              controller.saveAndClose();
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
          IconButton(
            icon: const Icon(Icons.music_note),
            tooltip: 'Background Music',
            onPressed: () => _showMusicDialog(context),
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
              
              // Editor
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  color: Theme.of(context).colorScheme.background.withOpacity(0.5),
                  child: Stack(
                    children: [
                      // Editor container
                      Container(
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
                        child: NotionLikeQuillEditor(
                          controller: controller.quillController,
                          focusNode: controller.editorFocusNode,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            // Tombol simpan yang jelas
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Simpan Perubahan'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                  ),
                  onPressed: () => controller.saveNote(),
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
  
  void _showMusicDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => MusicDialog(
        noteId: controller.note.id,
      ),
    );
  }
} 

class NotionLikeQuillEditor extends StatefulWidget {
  final QuillController controller;
  final FocusNode focusNode;

  const NotionLikeQuillEditor({
    Key? key,
    required this.controller,
    required this.focusNode,
  }) : super(key: key);

  @override
  State<NotionLikeQuillEditor> createState() => _NotionLikeQuillEditorState();
}

class _NotionLikeQuillEditorState extends State<NotionLikeQuillEditor> {
  OverlayEntry? _overlayEntry;
  final LayerLink _toolbarLayerLink = LayerLink();
  Timer? _inactivityTimer;
  
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_checkSelection);
    widget.controller.addListener(_handleTextChange);
    
    // Request focus when editor is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _hideToolbar();
    widget.controller.removeListener(_checkSelection);
    widget.controller.removeListener(_handleTextChange);
    _inactivityTimer?.cancel();
    super.dispose();
  }
  
  void _handleTextChange() {
    // Reset timer whenever text changes
    _inactivityTimer?.cancel();
    
    // Start a new timer
    _inactivityTimer = Timer(const Duration(seconds: 5), () {
      // Show toolbar after 5 seconds of inactivity
      if (!_hasActiveSelection()) {
        _showToolbarAtCurrentPosition();
      }
    });
  }
  
  bool _hasActiveSelection() {
    final selection = widget.controller.selection;
    return selection.baseOffset != selection.extentOffset;
  }
  
  void _showToolbarAtCurrentPosition() {
    if (widget.controller.document.isEmpty() || !widget.focusNode.hasFocus) {
      return; // Don't show if document is empty or editor doesn't have focus
    }
    
    // Get current cursor position
    final selection = widget.controller.selection;
    if (selection.baseOffset < 0) return;
    
    _showToolbar();
  }

  void _checkSelection() {
    final selection = widget.controller.selection;
    final hasSelection = selection.baseOffset != selection.extentOffset;
    
    if (hasSelection) {
      _showToolbar();
    } else {
      _hideToolbar();
    }
  }

  void _showToolbar() {
    if (_overlayEntry != null) return;
    
    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: 50,
          left: 0,
          right: 0,
          child: Center(
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Font size controls with +/- buttons
                        _buildFontSizeControls(context),
                        const VerticalDivider(width: 1, indent: 8, endIndent: 8),
                        
                        // Font family dropdown
                        _buildFontFamilyDropdown(context),
                        const VerticalDivider(width: 1, indent: 8, endIndent: 8),
                        
                        // Basic formatting
                        _buildButton(context, Icons.format_bold, Attribute.bold),
                        _buildButton(context, Icons.format_italic, Attribute.italic),
                        _buildButton(context, Icons.format_underlined, Attribute.underline),
                        _buildButton(context, Icons.format_strikethrough, Attribute.strikeThrough),
                        const VerticalDivider(width: 1, indent: 8, endIndent: 8),
                        _buildButton(context, Icons.format_quote, Attribute.blockQuote),
                        _buildButton(context, Icons.format_list_bulleted, Attribute.ul),
                        _buildButton(context, Icons.format_list_numbered, Attribute.ol),
                        const VerticalDivider(width: 1, indent: 8, endIndent: 8),
                        
                        // Image upload button
                        _buildImageUploadButton(context),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
    
    overlay.insert(_overlayEntry!);
  }

  // Font size dropdown with increment/decrement buttons
  Widget _buildFontSizeControls(BuildContext context) {
    const fontSizes = [
      '8', '10', '12', '14', '16', '18', '20', '24', '28', '32', '36'
    ];
    
    // Get current font size from selection
    final styleAttr = widget.controller.getSelectionStyle().attributes;
    String currentSize = '16'; // default size
    if (styleAttr.containsKey(Attribute.size.key)) {
      currentSize = styleAttr[Attribute.size.key]!.value;
    }
    
    // Find index of current size
    int currentIndex = fontSizes.indexOf(currentSize);
    if (currentIndex == -1) currentIndex = 4; // Default to '16' if not found
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Decrease font size button
          InkWell(
            borderRadius: BorderRadius.circular(4),
            onTap: () {
              if (currentIndex > 0) {
                final newSize = fontSizes[currentIndex - 1];
                widget.controller.formatSelection(Attribute.fromKeyValue('size', newSize));
              }
            },
            child: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Icon(Icons.remove, size: 18),
            ),
          ),
          
          const SizedBox(width: 4),
          
          // Current font size display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.5)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              currentSize,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          
          const SizedBox(width: 4),
          
          // Increase font size button
          InkWell(
            borderRadius: BorderRadius.circular(4),
            onTap: () {
              if (currentIndex < fontSizes.length - 1) {
                final newSize = fontSizes[currentIndex + 1];
                widget.controller.formatSelection(Attribute.fromKeyValue('size', newSize));
              }
            },
            child: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Icon(Icons.add, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  // Font family dropdown
  Widget _buildFontFamilyDropdown(BuildContext context) {
    const fontFamilies = [
      {'label': 'Sans Serif', 'value': 'sans-serif'},
      {'label': 'Serif', 'value': 'serif'},
      {'label': 'Monospace', 'value': 'monospace'},
      {'label': 'Roboto', 'value': 'Roboto'},
      {'label': 'Poppins', 'value': 'Poppins'},
    ];
    
    // Get current font family from selection
    final styleAttr = widget.controller.getSelectionStyle().attributes;
    String currentFont = 'sans-serif';
    if (styleAttr.containsKey(Attribute.font.key)) {
      currentFont = styleAttr[Attribute.font.key]!.value;
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.font_download, size: 20),
          const SizedBox(width: 4),
          DropdownButton<String>(
            value: currentFont,
            icon: const Icon(Icons.arrow_drop_down, size: 20),
            underline: Container(),
            items: fontFamilies.map((font) {
              return DropdownMenuItem<String>(
                value: font['value'],
                child: Text(
                  font['label']!,
                  style: TextStyle(fontFamily: font['value']),
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                widget.controller.formatSelection(Attribute.fromKeyValue('font', value));
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildButton(BuildContext context, IconData icon, Attribute attribute) {
    final isSelected = widget.controller.getSelectionStyle().attributes.containsKey(attribute.key);
    
    return IconButton(
      icon: Icon(icon),
      iconSize: 20,
      padding: const EdgeInsets.all(8),
      color: isSelected 
        ? Theme.of(context).colorScheme.primary 
        : Theme.of(context).colorScheme.onSurface,
      onPressed: () {
        widget.controller.formatSelection(attribute);
      },
    );
  }

  // Build Image Upload Button
  Widget _buildImageUploadButton(BuildContext context) {
    final controller = Get.find<NoteEditorController>();
    
    return Obx(() {
      return IconButton(
        icon: controller.isUploadingImage.value 
          ? const SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.image),
        iconSize: 20,
        padding: const EdgeInsets.all(8),
        tooltip: 'Insert image',
        onPressed: controller.isUploadingImage.value 
          ? null 
          : () => controller.pickAndUploadImage(),
      );
    });
  }

  void _hideToolbar() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => widget.focusNode.requestFocus(),
      child: QuillEditor(
        controller: widget.controller,
        focusNode: widget.focusNode,
        scrollController: ScrollController(),
        config: QuillEditorConfig(
          scrollable: true,
          placeholder: 'Start typing...',
          padding: EdgeInsets.zero,
          embedBuilders: FlutterQuillEmbeds.editorBuilders(
            imageEmbedConfig: const QuillEditorImageEmbedConfig(),
          ),
        ),
      ),
    );
  }
} 