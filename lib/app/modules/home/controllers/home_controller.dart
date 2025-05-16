import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/note_model.dart';
import '../../../data/models/folder_model.dart';
import '../../../data/models/tag_model.dart' as tag_model;
import '../../../data/repositories/note_repository.dart';
import '../../../data/repositories/folder_repository.dart';
import '../../../data/repositories/tag_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../routes/app_pages.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeController extends GetxController {
  final NoteRepository _noteRepository = Get.find<NoteRepository>();
  final FolderRepository _folderRepository = Get.find<FolderRepository>();
  final TagRepository _tagRepository = Get.find<TagRepository>();
  final UserRepository _userRepository = Get.find<UserRepository>();
  
  final isLoading = true.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;
  
  // Data
  final notes = <Note>[].obs;
  final folders = <Folder>[].obs;
  final tags = <tag_model.Tag>[].obs;
  
  // Current selections
  final selectedFolder = Rxn<Folder>();
  final selectedTag = Rxn<tag_model.Tag>();
  final searchQuery = ''.obs;
  
  // For new folder/tag creation
  final TextEditingController newFolderController = TextEditingController();
  final TextEditingController newTagController = TextEditingController();
  
  // Realtime channels
  RealtimeChannel? _notesChannel;
  RealtimeChannel? _foldersChannel;
  RealtimeChannel? _tagsChannel;
  RealtimeChannel? _noteTagsChannel;
  
  @override
  void onInit() {
    super.onInit();
    loadData();
    setupRealtimeSubscriptions();
  }
  
  @override
  void onReady() {
    super.onReady();
    print('HomeController ready');
  }
  
  // Called when returning to this screen from another screen
  void onPageRevisited() {
    print('Home page revisited');
    // Always refresh notes when coming back to this screen
    loadNotes();
  }
  
  @override
  void onClose() {
    _notesChannel?.unsubscribe();
    _foldersChannel?.unsubscribe();
    _tagsChannel?.unsubscribe();
    _noteTagsChannel?.unsubscribe();
    newFolderController.dispose();
    newTagController.dispose();
    super.onClose();
  }
  
  void setupRealtimeSubscriptions() {
    try {
      final userId = _userRepository.currentUser?.id;
      if (userId == null) {
        print('Cannot setup realtime: No current user');
        return;
      }
      
      // Create reusable callback functions for channel events
      void handleNoteChange(PostgresChangePayload payload) {
        print('Note change detected: ${payload.eventType}');
        loadNotes();
      }
      
      void handleFolderChange(PostgresChangePayload payload) {
        print('Folder change detected: ${payload.eventType}');
        loadFolders();
      }
      
      void handleTagChange(PostgresChangePayload payload) {
        print('Tag change detected: ${payload.eventType}');
        loadTags();
      }
      
      void handleNoteTagChange(PostgresChangePayload payload) {
        print('Note tag change detected: ${payload.eventType}');
        loadNotes();
      }
      
      try {
        // Set up notes channel - subscribe directly with callback
        _notesChannel = _noteRepository.subscribeNoteChanges(
          onNoteChange: handleNoteChange
        );
      } catch (e) {
        print('Error setting up notes channel: $e');
      }
      
      try {
        // Set up folders channel - subscribe directly with callback
        _foldersChannel = _folderRepository.subscribeFolderChanges(
          onFolderChange: handleFolderChange
        );
      } catch (e) {
        print('Error setting up folders channel: $e');
      }
      
      try {
        // Set up tags channel - subscribe directly with callback
        _tagsChannel = _tagRepository.subscribeTagChanges(
          onTagChange: handleTagChange
        );
      } catch (e) {
        print('Error setting up tags channel: $e');
      }
      
      try {
        // Set up note_tags channel - subscribe directly with callback
        _noteTagsChannel = _noteRepository.subscribeNoteTagChanges(
          onNoteTagChange: handleNoteTagChange
        );
      } catch (e) {
        print('Error setting up note tags channel: $e');
      }
    } catch (e) {
      print('Error setting up realtime subscriptions: $e');
    }
  }
  
  Future<void> loadData() async {
    isLoading.value = true;
    hasError.value = false;
    
    try {
      await Future.wait([
        loadNotes(),
        loadFolders(),
        loadTags(),
      ]);
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'Error loading data: ${e.toString()}';
      print('Error loading data: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> loadNotes() async {
    try {
      if (selectedFolder.value != null) {
        notes.value = await _noteRepository.getNotes(folderId: selectedFolder.value!.id);
      } else if (selectedTag.value != null) {
        notes.value = await _noteRepository.getNotesByTag(selectedTag.value!.id);
      } else {
        notes.value = await _noteRepository.getNotes();
      }
      
      if (searchQuery.isNotEmpty) {
        filterNotesBySearch();
      }
    } catch (e) {
      print('Error loading notes: $e');
    }
  }
  
  Future<void> loadFolders() async {
    try {
      folders.value = await _folderRepository.getFolders();
    } catch (e) {
      print('Error loading folders: $e');
    }
  }
  
  Future<void> loadTags() async {
    try {
      tags.value = await _tagRepository.getTags();
    } catch (e) {
      print('Error loading tags: $e');
    }
  }
  
  void selectFolder(Folder? folder) {
    selectedFolder.value = folder;
    selectedTag.value = null;
    loadNotes();
  }
  
  void selectTag(tag_model.Tag? tag) {
    selectedTag.value = tag;
    selectedFolder.value = null;
    loadNotes();
  }
  
  void clearFilters() {
    selectedFolder.value = null;
    selectedTag.value = null;
    searchQuery.value = '';
    loadNotes();
  }
  
  void search(String query) {
    searchQuery.value = query;
    filterNotesBySearch();
  }
  
  void filterNotesBySearch() {
    if (searchQuery.isEmpty) {
      loadNotes();
      return;
    }
    
    final query = searchQuery.value.toLowerCase();
    notes.value = notes.where((note) {
      return note.title.toLowerCase().contains(query) || 
             note.content.toLowerCase().contains(query);
    }).toList();
  }
  
  Future<void> createFolder() async {
    if (newFolderController.text.isEmpty) return;
    
    try {
      final newFolder = await _folderRepository.createFolder(name: newFolderController.text.trim());
      // Add the new folder to the observable list immediately
      folders.add(newFolder);
      folders.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase())); // Sort folders
      newFolderController.clear();
      Get.back(); // Close dialog
    } catch (e) {
      print('Error creating folder: $e');
      Get.snackbar(
        'Error',
        'Failed to create folder: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
  
  Future<void> createTag() async {
    if (newTagController.text.isEmpty) return;
    
    try {
      final newTag = await _tagRepository.createTag(name: newTagController.text.trim());
      // Add the new tag to the observable list immediately
      tags.add(newTag);
      tags.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase())); // Sort tags
      newTagController.clear();
      Get.back(); // Close dialog
    } catch (e) {
      print('Error creating tag: $e');
      Get.snackbar(
        'Error',
        'Failed to create tag: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
  
  Future<void> deleteFolder(String id) async {
    try {
      await _folderRepository.deleteFolder(id: id);
      // Remove folder from the observable list immediately
      folders.removeWhere((folder) => folder.id == id);
      if (selectedFolder.value?.id == id) {
        selectedFolder.value = null;
        loadNotes();
      }
    } catch (e) {
      print('Error deleting folder: $e');
      Get.snackbar(
        'Error',
        'Failed to delete folder: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
  
  Future<void> deleteTag(String id) async {
    try {
      await _tagRepository.deleteTag(id: id);
      // Remove tag from the observable list immediately
      tags.removeWhere((tag) => tag.id == id);
      if (selectedTag.value?.id == id) {
        selectedTag.value = null;
        loadNotes();
      }
    } catch (e) {
      print('Error deleting tag: $e');
      Get.snackbar(
        'Error',
        'Failed to delete tag: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
  
  Future<void> createNote() async {
    try {
      final newNote = await _noteRepository.createNote(
        title: 'New Note',
        content: '{"ops":[]}', // Empty Delta format for Quill instead of placeholder text
        folderId: selectedFolder.value?.id,
      );
      
      // Add the note to the observable list if it belongs in the current view
      int? addedIndex;
      if ((selectedFolder.value == null && selectedTag.value == null) || 
          (selectedFolder.value != null && newNote.folderId == selectedFolder.value!.id)) {
        notes.insert(0, newNote); // Add at the beginning (most recent)
        addedIndex = 0;
      }
      
      // Navigate to note edit screen and handle the result when returning
      final future = Get.toNamed('/note_editor', arguments: newNote);
      if (future != null) {
        future.then((result) {
          if (result is Note) {
            // Update the note in the list with the edited version
            if (addedIndex != null) {
              // If we know where we added it
              notes[addedIndex] = result;
            } else {
              // If it might have been added elsewhere, find and update it
              final index = notes.indexWhere((n) => n.id == result.id);
              if (index != -1) {
                notes[index] = result;
              } else {
                // If it wasn't in the list but should be now, add it
                if ((selectedFolder.value == null && selectedTag.value == null) || 
                    (selectedFolder.value != null && result.folderId == selectedFolder.value!.id)) {
                  notes.insert(0, result);
                }
              }
            }
          } else {
            // Fallback to refreshing the whole list
            loadNotes();
          }
        });
      }
    } catch (e) {
      print('Error creating note: $e');
      Get.snackbar(
        'Error',
        'Failed to create note: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
  
  Future<void> deleteNote(String id) async {
    try {
      await _noteRepository.deleteNote(id: id);
      
      // Remove note from the local list immediately
      notes.removeWhere((note) => note.id == id);
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
  
  Future<void> moveNoteToFolder(String noteId, String? folderId) async {
    try {
      await _noteRepository.moveNoteToFolder(noteId: noteId, folderId: folderId);
      
      // Immediately update the note in the local list
      final noteIndex = notes.indexWhere((note) => note.id == noteId);
      if (noteIndex != -1) {
        final updatedNote = notes[noteIndex].copyWith(folderId: folderId);
        
        // If the note was moved out of the currently selected folder
        if (selectedFolder.value != null && folderId != selectedFolder.value!.id) {
          notes.removeAt(noteIndex); // Remove note from the current folder view
        } else if (selectedFolder.value == null || folderId == selectedFolder.value!.id) {
          // If we're in the "All Notes" view or the note was moved to the current folder, update it
          notes[noteIndex] = updatedNote;
        }
      }
    } catch (e) {
      print('Error moving note to folder: $e');
      Get.snackbar(
        'Error',
        'Failed to move note: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
  
  void signOut() async {
    try {
      await _userRepository.signOut();
      Get.offAllNamed(Routes.AUTH);
    } catch (e) {
      print('Error signing out: $e');
      Get.snackbar(
        'Error',
        'Failed to sign out: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
  
  void openNote(Note note) {
    // Navigate to note editor with the selected note
    final future = Get.toNamed(Routes.NOTE_EDITOR, arguments: note);
    if (future != null) {
      future.then((result) {
        if (result != null) {
          // If we got a modified note back, update it immediately
          if (result is Note) {
            print('Received updated note from editor');
            // Find and update the note in the list
            final index = notes.indexWhere((n) => n.id == result.id);
            if (index != -1) {
              notes[index] = result;
            }
          } 
          // Otherwise just refresh the whole list
          else if (result == true) {
            print('Refreshing notes after returning from editor');
            loadNotes();
          }
        }
      });
    }
  }
}
