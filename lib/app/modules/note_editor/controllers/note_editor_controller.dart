import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/models/note_model.dart';
import '../../../data/models/tag_model.dart' as tag_model;
import '../../../data/repositories/note_repository.dart';
import '../../../data/repositories/tag_repository.dart';
import '../../../data/services/supabase_service.dart';
import '../../../modules/home/controllers/home_controller.dart';

class NoteEditorController extends GetxController {
  final NoteRepository _noteRepository = Get.find<NoteRepository>();
  final TagRepository _tagRepository = Get.find<TagRepository>();
  final SupabaseService _supabaseService = Get.find<SupabaseService>();
  
  final isLoading = true.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;
  
  // Note data with better reactivity
  final Rx<Note> _note = Rx<Note>(Note.empty());
  Note get note => _note.value;
  set note(Note value) => _note.value = value;
  
  // Separately manage QuillController to avoid GetX reactivity issues
  QuillController? _quillController;
  QuillController get quillController {
    if (_quillController == null) {
      initializeEditor();
    }
    return _quillController!;
  }
  
  late TextEditingController titleController;
  
  // Add a dedicated FocusNode for the editor
  final titleFocusNode = FocusNode();
  final editorFocusNode = FocusNode();
  
  final tags = <tag_model.Tag>[].obs;
  final selectedTags = <tag_model.Tag>[].obs;
  final availableTags = <tag_model.Tag>[].obs;
  
  final TextEditingController newTagController = TextEditingController();
  final isSaving = false.obs;
  final isAutosaving = false.obs;
  final isDirty = false.obs;
  
  // Collaborative editing indicators
  final isCollaborating = false.obs;
  final activeCollaborators = <String>[].obs;
  final realtimeActivity = ''.obs;
  
  Timer? _autosaveTimer;
  final autosaveInterval = const Duration(seconds: 3); // More frequent autosave
  Timer? _debounceTimer;
  final debounceInterval = const Duration(milliseconds: 500);
  
  // Realtime channels
  RealtimeChannel? _noteChannel;
  RealtimeChannel? _tagChannel;
  RealtimeChannel? _noteTagChannel;
  DateTime? _lastExternalUpdate;
  
  // Timer for periodically checking for collaborators
  Timer? _collaboratorTimer;
  
  @override
  void onInit() {
    super.onInit();
    
    // Get note from arguments
    if (Get.arguments is Note) {
      note = Get.arguments as Note;
      titleController = TextEditingController(text: note.title);
      loadTags();
      setupRealtimeSubscriptions();
      
      // Start tracking collaboration
      _trackCollaboration();
    } else {
      hasError.value = true;
      errorMessage.value = 'Invalid note data';
    }
    
    // Initialize the editor
    initializeEditor();
  }
  
  @override
  void onClose() {
    _autosaveTimer?.cancel();
    _debounceTimer?.cancel();
    _collaboratorTimer?.cancel();
    _noteChannel?.unsubscribe();
    _tagChannel?.unsubscribe();
    _noteTagChannel?.unsubscribe();
    _quillController?.dispose();
    titleController.dispose();
    newTagController.dispose();
    
    // Dispose focus nodes
    titleFocusNode.dispose();
    editorFocusNode.dispose();
    
    super.onClose();
  }
  
  void setupRealtimeSubscriptions() {
    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) {
        print('Cannot setup realtime: No current user');
        return;
      }
      
      // Subscribe to specific note changes
      _noteChannel = _noteRepository.subscribeSpecificNoteChanges(
        noteId: note.id,
        onNoteChange: (payload) {
          // Don't react to our own changes
          if (isSaving.value) return;
          
          // Set timestamp for tracking external updates
          _lastExternalUpdate = DateTime.now();
          
          print('Note update detected from another client');
          realtimeActivity.value = 'Note updated from another device at ${DateTime.now().toLocal().toIso8601String().substring(11, 19)}';
          
          // Schedule refresh after a short delay to avoid conflicts
          Future.delayed(Duration(milliseconds: 100), () {
            refreshNote();
          });
        }
      );
      
      // Subscribe to tag changes
      _tagChannel = _supabaseService.client.channel('tags:${userId}');
      _tagChannel!.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'tags',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: userId,
        ),
        callback: (payload) {
          print('Tag change detected: ${payload.eventType}');
          
          // Handle tag deletion - remove from selected tags if it was deleted
          if (payload.eventType == 'DELETE' && payload.oldRecord != null) {
            final deletedTagId = payload.oldRecord!['id'] as String;
            selectedTags.removeWhere((tag) => tag.id == deletedTagId);
            
            // Update note.tags collection to keep it in sync
            final updatedTags = note.tags.where((tag) => tag.id != deletedTagId).toList();
            note = note.copyWith(tags: updatedTags);
          }
          
          loadTags();
          
          // Also update the HomeController if it exists and the event is INSERT
          if (payload.eventType == 'INSERT' && Get.isRegistered<HomeController>()) {
            final homeController = Get.find<HomeController>();
            
            // Only trigger a reload if we're not already in the middle of a user-initiated tag creation
            if (!isSaving.value) {
              homeController.loadTags();
            }
          }
        },
      );
      _tagChannel!.subscribe();
      
      // Subscribe to note-tag relationship changes
      _noteTagChannel = _supabaseService.client.channel('note_tags:${note.id}');
      _noteTagChannel!.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'note_tags',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'note_id',
          value: note.id,
        ),
        callback: (payload) {
          print('Note tag mapping changed: ${payload.eventType}');
          
          // We'll manually handle the tag changes to prevent duplicates
          // For INSERT operations, we can add the tag directly if we have it
          if (payload.eventType == 'INSERT' && payload.newRecord != null) {
            final tagId = payload.newRecord!['tag_id'] as String;
            // Only add if not already in the selected tags
            if (!selectedTags.any((tag) => tag.id == tagId)) {
              // Find the tag in our all tags list
              tag_model.Tag? matchingTag;
              for (var tag in tags) {
                if (tag.id == tagId) {
                  matchingTag = tag;
                  break;
                }
              }
              
              if (matchingTag != null) {
                // Add to selected tags
                selectedTags.add(matchingTag);
                // Add to note tags
                final updatedTags = [...note.tags, matchingTag];
                note = note.copyWith(tags: updatedTags);
                _updateAvailableTags();
                return; // We've handled this event, no need to reload all tags
              }
            }
          }
          
          // For DELETE operations, we can remove the tag directly
          if (payload.eventType == 'DELETE' && payload.oldRecord != null) {
            final tagId = payload.oldRecord!['tag_id'] as String;
            // Remove from selected tags
            selectedTags.removeWhere((tag) => tag.id == tagId);
            // Remove from note tags
            final updatedTags = note.tags.where((tag) => tag.id != tagId).toList();
            note = note.copyWith(tags: updatedTags);
            _updateAvailableTags();
            return; // We've handled this event, no need to reload all tags
          }
          
          // For any other cases or if we couldn't handle directly, reload all tags
          loadTags();
        },
      );
      _noteTagChannel!.subscribe();
    } catch (e) {
      print('Error setting up realtime subscription: $e');
    }
  }
  
  // Simple collaboration tracking
  void _trackCollaboration() {
    try {
      // Record that this user is viewing the document
      _updateCollaborationStatus(true);
      
      // Set up a timer to periodically check for active collaborators
      _collaboratorTimer = Timer.periodic(Duration(seconds: 10), (_) {
        _checkCollaborators();
      });
      
      // Also check immediately
      _checkCollaborators();
    } catch (e) {
      print('Error tracking collaboration: $e');
    }
  }
  
  // Update the collaboration status in the database
  Future<void> _updateCollaborationStatus(bool isActive) async {
    try {
      final userId = _supabaseService.currentUser?.id;
      final email = _supabaseService.currentUser?.email;
      
      if (userId == null || email == null) return;
      
      await _supabaseService.client.from('note_collaborators').upsert({
        'note_id': note.id,
        'user_id': userId,
        'email': email,
        'last_active': DateTime.now().toIso8601String(),
        'is_active': isActive
      }, onConflict: 'note_id,user_id');
      
      // If leaving, set as inactive
      if (!isActive) {
        isCollaborating.value = false;
      }
    } catch (e) {
      print('Error updating collaboration status: $e');
    }
  }
  
  // Check for active collaborators
  Future<void> _checkCollaborators() async {
    try {
      // First, update that this user is still active
      await _updateCollaborationStatus(true);
      
      // Then, query for other active collaborators
      final response = await _supabaseService.client
          .from('note_collaborators')
          .select()
          .eq('note_id', note.id)
          .eq('is_active', true)
          .neq('user_id', _supabaseService.currentUser!.id)
          // Only consider users active in the last 30 seconds
          .gt('last_active', DateTime.now().subtract(Duration(seconds: 30)).toIso8601String());
      
      if (response != null && response is List) {
        final List<String> users = [];
        for (final user in response) {
          if (user['email'] != null && user['email'] is String) {
            users.add(user['email'] as String);
          }
        }
        
        // Check if the list of collaborators changed
        if (!_areListsEqual(activeCollaborators, users)) {
          if (activeCollaborators.isEmpty && users.isNotEmpty) {
            realtimeActivity.value = 'Someone joined the document';
          } else if (activeCollaborators.isNotEmpty && users.isEmpty) {
            realtimeActivity.value = 'Everyone left the document';
          } else if (activeCollaborators.length < users.length) {
            realtimeActivity.value = 'Someone joined the document';
          } else if (activeCollaborators.length > users.length) {
            realtimeActivity.value = 'Someone left the document';
          }
          
          // Update the list of active collaborators
          activeCollaborators.value = users;
        }
        
        // Update collaborative state
        isCollaborating.value = users.isNotEmpty;
      }
    } catch (e) {
      print('Error checking collaborators: $e');
    }
  }
  
  // Helper to compare two lists
  bool _areListsEqual(List<String> list1, List<String> list2) {
    if (list1.length != list2.length) return false;
    
    for (final item in list1) {
      if (!list2.contains(item)) return false;
    }
    
    return true;
  }
  
  Future<void> refreshNote() async {
    try {
      final updatedNote = await _noteRepository.getNote(note.id);
      
      // Only update if the content has actually changed
      if (updatedNote.content != note.content) {
        note = updatedNote;
        
        // Reload the editor if we're not currently editing
        if (!isDirty.value) {
          initializeEditor();
        } else {
          // Show a notification that there are remote changes
          Get.snackbar(
            'Note Updated',
            'This note was updated from another device',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.amber,
            colorText: Colors.black,
            duration: Duration(seconds: 3),
            mainButton: TextButton(
              onPressed: () {
                // Apply the remote changes if user taps the button
                note = updatedNote;
                initializeEditor();
              },
              child: Text('Refresh', style: TextStyle(color: Colors.black)),
            ),
          );
        }
      }
      
      // Always refresh title if it changed
      if (updatedNote.title != titleController.text) {
        titleController.text = updatedNote.title;
      }
      
      // Always refresh tags
      selectedTags.value = updatedNote.tags;
      _updateAvailableTags();
    } catch (e) {
      print('Error refreshing note: $e');
    }
  }
  
  void initializeEditor() {
    isLoading.value = true;
    
    try {
      if (_quillController != null) {
        _quillController!.dispose();
      }
      
      // Parse the content JSON
      Document document;
      
      // Check for empty or invalid content
      if (note.content.isEmpty || note.content == '{"ops":[]}') {
        // For new or empty notes, create a clean document
        document = Document();
      } else {
        try {
          // First try to parse as a proper JSON object
          final dynamic contentJson = jsonDecode(note.content.replaceAll('\u0000', '')
                                                         .replaceAll('\u001A', ''));
          
          // Check if it's a Delta object or needs conversion
          if (contentJson is List && contentJson.isNotEmpty && contentJson[0] is Map) {
            // Properly formatted Delta JSON
        document = Document.fromJson(contentJson);
          } else if (contentJson is Map && contentJson.containsKey('ops')) {
            // Formatted as {ops: [...]} structure
            document = Document.fromJson(contentJson['ops']);
          } else {
            // Not a valid Delta - create a new document with the parsed content as string
            final String safeContent = contentJson.toString();
            document = Document()..insert(0, safeContent);
          }
        } catch (parseError) {
          print('JSON parse error: $parseError');
          
          // Try to sanitize the content to create valid JSON
          String sanitizedContent = note.content
            .replaceAll('\u0000', '') // Remove null characters
            .replaceAll('\u001A', '') // Remove SUB characters
            .replaceAll(RegExp(r'[^\x20-\x7E\s]'), '') // Remove non-printable ASCII
            .replaceAll('[["insert":"', '')
            .replaceAll('"]]', '')
            .replaceAll('\\n', '\n')
            .replaceAll('\\r', '\r')
            .replaceAll('\\t', '\t')
            .replaceAll('\\\"', '\"')
            .replaceAll('\\\\', '\\');
          
          // If all else fails, create a document with the sanitized content or an empty document
          try {
            document = Document.fromJson([{"insert": sanitizedContent}]);
      } catch (e) {
            // Last resort - empty document instead of placeholder text
            document = Document();
          }
        }
      }
      
      _quillController = QuillController(
        document: document,
        selection: const TextSelection.collapsed(offset: 0)
      );
      
      // Listen for changes to mark as dirty and trigger debounced save
      _quillController!.addListener(_onDocumentChange);
      
      // Listen for focus changes to ensure proper focus behavior
      editorFocusNode.addListener(_onEditorFocusChange);
      titleFocusNode.addListener(_onTitleFocusChange);
      
      // Setup autosave
      _setupAutosave();
      
      isLoading.value = false;
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'Error initializing editor: ${e.toString()}';
      print('Error initializing editor: $e');
    }
  }
  
  void _onDocumentChange() {
    // Mark document as dirty
    if (!isDirty.value) {
      isDirty.value = true;
    }
    
    // Only trigger debounced save if we didn't just receive an external update
    final now = DateTime.now();
    final shouldDebounce = _lastExternalUpdate == null || 
        now.difference(_lastExternalUpdate!) > Duration(seconds: 2);
    
    if (shouldDebounce) {
      // Set up debounced save to avoid too many saves
      _debounceTimer?.cancel();
      _debounceTimer = Timer(debounceInterval, () {
        if (isDirty.value && !isSaving.value) {
          saveNote(isAutosave: true);
        }
      });
    }
  }
  
  void _onEditorFocusChange() {
    // When editor gains focus, ensure title field doesn't have focus
    if (editorFocusNode.hasFocus && titleFocusNode.hasFocus) {
      titleFocusNode.unfocus();
    }
  }
  
  void _onTitleFocusChange() {
    // When title gains focus, ensure editor doesn't have focus
    if (titleFocusNode.hasFocus && editorFocusNode.hasFocus) {
      editorFocusNode.unfocus();
    }
  }
  
  void _setupAutosave() {
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer.periodic(autosaveInterval, (_) {
      if (isDirty.value && !isSaving.value) {
        saveNote(isAutosave: true);
      }
    });
  }
  
  Future<void> loadTags() async {
    try {
      // Get all tags
      final allTags = await _tagRepository.getTags();
      tags.value = allTags;
      
      // Refresh note to get latest tags
      final updatedNote = await _noteRepository.getNote(note.id);
      
      // Clear and repopulate to prevent duplicates
      selectedTags.clear();
      selectedTags.addAll(updatedNote.tags);
      
      // Update local note with latest tags
      note = note.copyWith(tags: updatedNote.tags);
      
      // Filter available tags
      _updateAvailableTags();
    } catch (e) {
      print('Error loading tags: $e');
    }
  }
  
  void _updateAvailableTags() {
    // Filter out already selected tags
    availableTags.value = tags.where((tag) {
      return !selectedTags.any((selectedTag) => selectedTag.id == tag.id);
    }).toList();
  }
  
  Future<void> saveNote({bool isAutosave = false}) async {
    if (isSaving.value) return;
    
    isSaving.value = true;
    if (isAutosave) {
      isAutosaving.value = true;
    }
    
    try {
      // Ensure proper Delta format and prevent corrupted content
      final quillDelta = quillController.document.toDelta();
      final content = jsonEncode(quillDelta.toJson());
      
      final title = titleController.text.trim();
      
      if (title.isEmpty) {
        Get.snackbar(
          'Error',
          'Title cannot be empty',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        isSaving.value = false;
        isAutosaving.value = false;
        return;
      }
      
      // Update the note
      final updatedNote = note.copyWith(
        title: title,
        content: content,
      );
      
      // Save to repository
      final savedNote = await _noteRepository.updateNote(note: updatedNote);
      
      // Update local note
      note = savedNote;
      
      // Mark as not dirty
      isDirty.value = false;
      
      if (!isAutosave) {
        Get.snackbar(
          'Success',
          'Note saved successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print('Error saving note: $e');
      Get.snackbar(
        'Error',
        'Failed to save note: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isSaving.value = false;
      isAutosaving.value = false;
    }
  }
  
  Future<void> addTagToNote(tag_model.Tag tag) async {
    try {
      // Check if tag is already added to avoid duplicates
      if (selectedTags.any((t) => t.id == tag.id)) {
        print('Tag already added to note');
        return;
      }
      
      await _noteRepository.addTagToNote(noteId: note.id, tagId: tag.id);
      
      // Update the selected tags
      selectedTags.add(tag);
      
      // Also update the note.tags collection to keep it in sync
      final updatedTags = [...note.tags, tag];
      note = note.copyWith(tags: updatedTags);
      
      _updateAvailableTags();
    } catch (e) {
      print('Error adding tag to note: $e');
      Get.snackbar(
        'Error',
        'Failed to add tag: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
  
  Future<void> removeTagFromNote(tag_model.Tag tag) async {
    try {
      await _noteRepository.removeTagFromNote(noteId: note.id, tagId: tag.id);
      
      // Update the selected tags
      selectedTags.removeWhere((t) => t.id == tag.id);
      _updateAvailableTags();
    } catch (e) {
      print('Error removing tag from note: $e');
      Get.snackbar(
        'Error',
        'Failed to remove tag: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
  
  Future<void> createAndAddTag() async {
    if (newTagController.text.isEmpty) return;
    
    try {
      // Create new tag
      final newTag = await _tagRepository.createTag(name: newTagController.text.trim());
      newTagController.clear();
      
      // Add to note
      await _noteRepository.addTagToNote(noteId: note.id, tagId: newTag.id);
      
      // Update the HomeController's tags list if it exists
      if (Get.isRegistered<HomeController>()) {
        final homeController = Get.find<HomeController>();
        homeController.tags.add(newTag);
        homeController.tags.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase())); // Sort tags
      }
      
      // Update local selected tags to make tag visible in the note
      selectedTags.add(newTag);
      
      // Update note.tags collection to keep it in sync
      final updatedTags = [...note.tags, newTag];
      note = note.copyWith(tags: updatedTags);
      
      // Update available tags list
      _updateAvailableTags();
      
      // Close dialog
      Get.back();
    } catch (e) {
      print('Error creating and adding tag: $e');
      Get.snackbar(
        'Error',
        'Failed to create and add tag: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
  
  Future<void> saveAndClose() async {
    if (isDirty.value) {
      await saveNote();
    }
    
    // Return the updated note directly to the calling screen
    Get.back(result: note);
  }
  
  // Method to delete the current note
  Future<void> deleteNote() async {
    try {
      await _noteRepository.deleteNote(id: note.id);
      
      // Show success message
      Get.snackbar(
        'Success',
        'Note deleted successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      
      // Return to home screen with a special result to indicate deletion
      Get.back(result: 'deleted:${note.id}');
    } catch (e) {
      print('Error deleting note: $e');
      Get.snackbar(
        'Error',
        'Failed to delete note: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
  
  // Show confirmation dialog before deleting
  void confirmDelete() {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note?\nThis action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(), // Close dialog
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back(); // Close dialog
              deleteNote(); // Delete the note
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
} 