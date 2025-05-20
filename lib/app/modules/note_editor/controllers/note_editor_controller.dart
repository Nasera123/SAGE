import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/models/note_model.dart';
import '../../../data/models/tag_model.dart' as tag_model;
import '../../../data/repositories/note_repository.dart';
import '../../../data/repositories/tag_repository.dart';
import '../../../data/services/supabase_service.dart';
import '../../../modules/home/controllers/home_controller.dart';
import '../../../modules/book/controllers/book_controller.dart';

class NoteEditorController extends GetxController {
  final NoteRepository _noteRepository = Get.find<NoteRepository>();
  final TagRepository _tagRepository = Get.find<TagRepository>();
  final SupabaseService _supabaseService = Get.find<SupabaseService>();
  final ImagePicker _imagePicker = ImagePicker();
  
  final isLoading = true.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;
  final isUploadingImage = false.obs;
  
  // Book-related properties
  final isBookPage = false.obs;
  final bookId = ''.obs;
  
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
  
  // Initialize titleController to avoid late init error
  final titleController = TextEditingController();
  
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
    print('NoteEditorController: onInit');
    
    // Initialize book-related properties
    if (Get.arguments != null) {
      if (Get.arguments is Map) {
        final args = Get.arguments as Map;
        print('Arguments received: $args');
        
        // Check if it's a book page
        if (args.containsKey('isBookPage') && args['isBookPage'] == true) {
          isBookPage.value = true;
          if (args.containsKey('bookId')) {
            bookId.value = args['bookId'] as String;
            print('This is a book page with bookId: ${bookId.value}');
          }
        }
        
        // Check if we have a noteId
        if (args.containsKey('noteId')) {
          final noteId = args['noteId'] as String;
          print('Loading note with ID from arguments: $noteId');
          loadNote(noteId);
          // Editor will be initialized in loadNote
          return;
        }
      } else if (Get.arguments is Note) {
        print('Note object received directly');
        note = Get.arguments as Note;
        titleController.text = note.title;
        loadTags();
        setupRealtimeSubscriptions();
        _trackCollaboration();
        // Inisialisasi editor setelah data dimuat
        initializeEditor();
        return;
      } else {
        hasError.value = true;
        errorMessage.value = 'Invalid note data';
      }
    } else {
      hasError.value = true;
      errorMessage.value = 'No note data provided';
    }
    
    // Hanya inisialisasi editor jika belum diinisialisasi di flow di atas
    if (_quillController == null) {
      print('Fallback initialization of editor');
      initializeEditor();
    }
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
        // Pastikan untuk menghapus listener sebelum dispose untuk mencegah memory leak
        _quillController!.removeListener(_onDocumentChange);
        _quillController!.dispose();
      }
      
      // Parse the content JSON
      Document document;
      
      // Check for empty or invalid content
      if (note.content.isEmpty || note.content == '{"ops":[]}' || note.content == '{}') {
        // For new or empty notes, create a clean document
        document = Document();
        print('Creating empty document');
      } else {
        try {
          print('Parsing note content: ${note.content.length} chars');
          
          // First try to parse as a proper JSON object
          dynamic contentJson;
          try {
            // Bersihkan konten dari karakter tidak valid
            String cleanContent = note.content.replaceAll('\u0000', '')
                                             .replaceAll('\u001A', '');
            contentJson = jsonDecode(cleanContent);
            print('JSON successfully parsed');
          } catch (jsonError) {
            print('Error parsing JSON: $jsonError');
            // Jika parsing gagal, buat dokumen kosong
            document = Document();
            throw jsonError; // Throw untuk masuk ke blok catch
          }
          
          // Check if it's a Delta object or needs conversion
          if (contentJson is List && contentJson.isNotEmpty && contentJson[0] is Map) {
            // Properly formatted Delta JSON
            print('Content is List format Delta');
            try {
              document = Document.fromJson(contentJson);
              print('Document created from List JSON successfully');
            } catch (docError) {
              print('Error creating document from List JSON: $docError');
              document = Document();
            }
          } else if (contentJson is Map && contentJson.containsKey('ops')) {
            // Formatted as {ops: [...]} structure
            print('Content is Map format with ops key');
            try {
              document = Document.fromJson(contentJson['ops']);
              print('Document created from Map[ops] JSON successfully');
            } catch (docError) {
              print('Error creating document from Map[ops]: $docError');
              document = Document();
            }
          } else {
            // Not a valid Delta - create a new document with the parsed content as string
            print('Content is not a valid Delta format, converting to string');
            final String safeContent = contentJson.toString();
            document = Document()..insert(0, safeContent);
          }
        } catch (parseError) {
          print('Error processing content: $parseError');
          // Fallback to empty document
          print('Creating a fallback empty document');
          document = Document();
        }
      }
      
      _quillController = QuillController(
        document: document,
        selection: const TextSelection.collapsed(offset: 0)
      );
      
      // Set editor to read-only mode (false by default)
      _quillController!.readOnly = false;
      
      // Listen for changes to mark as dirty and trigger debounced save
      _quillController!.addListener(_onDocumentChange);
      print('Added document change listener to QuillController');
      
      // Listen for focus changes to ensure proper focus behavior
      editorFocusNode.addListener(_onEditorFocusChange);
      titleFocusNode.addListener(_onTitleFocusChange);
      
      // Setup autosave
      _setupAutosave();
      
      isLoading.value = false;
    } catch (e) {
      print('Fatal error initializing editor: $e');
      hasError.value = true;
      errorMessage.value = 'Error initializing editor: ${e.toString()}';
    }
  }
  
  void _onDocumentChange() {
    // Mark document as dirty
    if (!isDirty.value) {
      isDirty.value = true;
      print('Document marked as dirty - changes detected');
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
          print('Debounce timer triggered autosave');
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
        print('Periodic autosave triggered');
        saveNote(isAutosave: true);
      }
    });
    
    // Juga pastikan konten tersimpan saat editor kehilangan fokus
    editorFocusNode.addListener(() {
      if (!editorFocusNode.hasFocus && isDirty.value && !isSaving.value) {
        print('Editor lost focus - triggering save');
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
    if (isSaving.value) {
      print('Save skipped - another save in progress');
      return;
    }
    
    isSaving.value = true;
    isAutosaving.value = isAutosave;
    isDirty.value = false;
    
    try {
      // Update note with current content from the editor
      String noteContent;
      try {
        // Pastikan QuillController sudah diinisialisasi
        if (_quillController == null) {
          print('QuillController is null, initializing');
          initializeEditor();
        }
        
        // Encode content to JSON
        noteContent = jsonEncode(_quillController!.document.toDelta().toJson());
        print('Content encoded to JSON successfully');
      } catch (e) {
        print('Error encoding editor content: $e');
        // Fallback to empty content
        noteContent = '{"ops":[{"insert":"\\n"}]}';
        print('Using fallback empty content');
      }
      
      final noteTitle = titleController.text.trim().isEmpty ? 
          'Untitled Note' : titleController.text.trim();
      
      // Tambahkan log debugging untuk memastikan konten tersimpan
      print('Saving note: ${note.id}');
      print('Title: $noteTitle');
      print('Content length: ${noteContent.length}');
      
      // Create an updated note
      final updatedNote = note.copyWith(
        title: noteTitle,
        content: noteContent,
        updatedAt: DateTime.now(),
      );
      
      // Save the note
      print('Sending update request to repository');
      note = await _noteRepository.updateNote(note: updatedNote);
      print('Note saved successfully with ID: ${note.id}');
      
      // Only show the saved message if it's not an autosave
      if (!isAutosave) {
        Get.snackbar(
          'Saved',
          'Note saved successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      print('Error saving note: $e');
      isDirty.value = true;
      
      // Only show the error message if it's not an autosave
      if (!isAutosave) {
        Get.snackbar(
          'Error',
          'Failed to save note: ${e.toString()}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      }
      
      // Retry saving if it's not an autosave
      if (!isAutosave && !isSaving.value) {
        print('Scheduling retry save in 3 seconds');
        Future.delayed(Duration(seconds: 3), () {
          if (isDirty.value && !isSaving.value) {
            print('Retrying save operation');
            saveNote(isAutosave: true);
          }
        });
      }
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
    print('saveAndClose called');
    
    // Simpan perubahan (jika ada) secara cepat tanpa delay yang panjang
    try {
      if (!isSaving.value) {
        print('Saving content before closing');
        
        // Simpan note
        await saveNote(isAutosave: true); // Gunakan isAutosave agar tidak muncul snackbar
        print('Note saved before closing');
      } else {
        print('Skipping save because another save operation is in progress');
      }
    } catch (e) {
      print('Error saving note before closing: $e');
    }
    
    // Jika ini adalah halaman buku, siapkan untuk refresh nanti
    if (isBookPage.value && bookId.value.isNotEmpty) {
      try {
        // Set flag di BookController (jika ada) untuk refresh halaman nanti
        if (Get.isRegistered<BookController>()) {
          print('Notifying BookController to refresh pages');
          final bookController = Get.find<BookController>();
          bookController.needsRefresh.value = true;
        }
      } catch (e) {
        print('Error notifying book controller: $e');
      }
    }
    
    // Segera kembali ke halaman sebelumnya
    print('Returning to previous screen immediately');
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
  
  Future<void> loadNote(String id) async {
    isLoading.value = true;
    print('Loading note with ID: $id');
    
    try {
      // Pastikan kita menunggu penyimpanan sebelumnya selesai
      if (isSaving.value) {
        print('Waiting for ongoing save to complete before loading');
        await Future.delayed(Duration(seconds: 1));
        isSaving.value = false;
      }
      
      // Bersihkan controller yang ada jika ada
      if (_quillController != null) {
        _quillController!.removeListener(_onDocumentChange);
        _quillController!.dispose();
        _quillController = null;
      }
      
      print('Fetching note data from repository');
      final loadedNote = await _noteRepository.getNote(id);
      
      // Log detail note yang diambil
      print('Note loaded: ${loadedNote.id}');
      print('Title: ${loadedNote.title}');
      print('Content length: ${loadedNote.content.length}');
      
      // Set note dan data terkait
      note = loadedNote;
      titleController.text = note.title;
      
      // Load tags, setup subscriptions, and track collaboration
      loadTags();
      setupRealtimeSubscriptions();
      _trackCollaboration();
      
      // Inisialisasi editor setelah data dimuat
      initializeEditor();
      
    } catch (e) {
      print('Error loading note: $e');
      hasError.value = true;
      errorMessage.value = 'Error loading note: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  // Image handling functions
  Future<void> pickAndUploadImage() async {
    try {
      final pickedImage = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      
      if (pickedImage == null) return;
      
      isUploadingImage.value = true;
      Get.snackbar(
        'Upload',
        'Mempersiapkan upload gambar...',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
      
      // Read image bytes
      final bytes = await pickedImage.readAsBytes();
      
      // Dapatkan user ID untuk path penyimpanan
      final userId = _supabaseService.currentUser!.id;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${pickedImage.name ?? 'image.jpg'}';
      
      // Use the dedicated note_images bucket
      const bucketName = 'note_images';
      
      // Simplified storage path
      final storagePath = '$userId/$fileName';
      
      print('Uploading file to $bucketName/$storagePath');
      
      // Upload file ke bucket
      await _supabaseService.client.storage
        .from(bucketName)
        .uploadBinary(storagePath, bytes);
      
      // Dapatkan URL publik
      final imageUrl = _supabaseService.client.storage
        .from(bucketName)
        .getPublicUrl(storagePath);
      
      print('Image uploaded successfully: $imageUrl');
      
      // Sisipkan gambar ke editor
      insertImage(imageUrl);
      
      isUploadingImage.value = false;
      
      Get.snackbar(
        'Berhasil',
        'Gambar berhasil diunggah',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      
    } catch (e) {
      isUploadingImage.value = false;
      print('Error uploading image: $e');
      
      // Menampilkan pesan error yang lebih informatif
      String errorMessage = 'Gagal mengunggah gambar';
      
      if (e.toString().contains('401') || e.toString().contains('auth')) {
        errorMessage = 'Anda perlu login ulang untuk mengunggah gambar';
      } else if (e.toString().contains('403') || e.toString().contains('permission')) {
        errorMessage = 'Tidak memiliki izin untuk mengunggah gambar';
      } else if (e.toString().contains('404') || e.toString().contains('bucket not found')) {
        errorMessage = 'Bucket penyimpanan tidak ditemukan. Silakan hubungi administrator.';
      }
      
      Get.snackbar(
        'Error',
        '$errorMessage: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    }
  }
  
  void insertImage(String imageUrl) {
    if (_quillController == null) return;
    
    try {
      // Get current selection or end of document
      final index = _quillController!.selection.baseOffset >= 0 
          ? _quillController!.selection.baseOffset 
          : _quillController!.document.length - 1;
      
      // Always insert a new line before the image if not at the start of document
      if (index > 0) {
        _quillController!.document.insert(index, '\n');
      }
      
      // Insert the image embed
      final imageEmbed = BlockEmbed.image(imageUrl);
      _quillController!.document.insert(index + 1, imageEmbed);
      
      // Insert a new line after the image
      _quillController!.document.insert(index + 2, '\n');
      
      // Update selection to after the image
      _quillController!.updateSelection(
        TextSelection.collapsed(offset: index + 3),
        ChangeSource.local,
      );
      
      // Mark as dirty to trigger autosave
      isDirty.value = true;
      
      // Force a document change notification
      _onDocumentChange();
    } catch (e) {
      print('Error inserting image into editor: $e');
      Get.snackbar(
        'Error',
        'Gagal menyisipkan gambar ke editor: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
} 