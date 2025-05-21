import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/note_model.dart';
import '../../../data/models/folder_model.dart';
import '../../../data/models/tag_model.dart' as tag_model;
import '../../../data/repositories/note_repository.dart';
import '../../../data/repositories/folder_repository.dart';
import '../../../data/repositories/tag_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/services/supabase_service.dart';
import '../../../routes/app_pages.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeController extends GetxController {
  final NoteRepository _noteRepository = Get.find<NoteRepository>();
  final FolderRepository _folderRepository = Get.find<FolderRepository>();
  final TagRepository _tagRepository = Get.find<TagRepository>();
  final UserRepository _userRepository = Get.find<UserRepository>();
  final SupabaseService _supabaseService = Get.find<SupabaseService>();
  
  final isLoading = true.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;
  
  // Add a profile refresh trigger
  final profileRefreshTrigger = 0.obs;
  
  // Get user initials for avatar display
  String getUserInitials() {
    final user = _userRepository.currentUser;
    if (user == null) return 'U';
    
    // Try to extract from email (username portion)
    final email = user.email ?? '';
    if (email.isNotEmpty) {
      final username = email.split('@').first;
      if (username.isNotEmpty) {
        return username[0].toUpperCase();
      }
    }
    
    // Fallback
    return 'U';
  }
  
  // Get user display name (synchronous version - use email username)
  String getUserDisplayName() {
    final user = _userRepository.currentUser;
    if (user == null) return 'User';
    
    // Just return email username for synchronous calls
    return user.email?.split('@').first ?? 'User';
  }
  
  // Get user display name (asynchronous version)
  Future<String> getUserDisplayNameAsync() async {
    // Add the refresh trigger as a dependency to force refresh when it changes
    profileRefreshTrigger.value;
    try {
      final profile = await _userRepository.getUserProfile();
      if (profile != null && profile.fullName != null && profile.fullName!.isNotEmpty) {
        return profile.fullName!;
      }
    } catch (e) {
      print('Error getting user profile for display name: $e');
    }
    
    // Fall back to email username
    final user = _userRepository.currentUser;
    return user?.email?.split('@').first ?? 'User';
  }
  
  // Add a method to refresh profile data
  void refreshProfile() {
    // Increment the trigger to force UI rebuild
    profileRefreshTrigger.value++;
    print('Profile refresh triggered: ${profileRefreshTrigger.value}');
  }
  
  // Get profile avatar URL if available
  Future<String?> getUserProfileImage() async {
    // Add the refresh trigger as a dependency to force refresh when it changes
    profileRefreshTrigger.value;
    try {
      final profile = await _userRepository.getUserProfile();
      return profile?.avatarUrl;
    } catch (e) {
      print('Error getting user profile image: $e');
      return null;
    }
  }
  
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
  
  // For editing folder/tag
  final TextEditingController editFolderController = TextEditingController();
  final TextEditingController editTagController = TextEditingController();
  
  // Realtime channels
  RealtimeChannel? _notesChannel;
  RealtimeChannel? _foldersChannel;
  RealtimeChannel? _tagsChannel;
  RealtimeChannel? _noteTagsChannel;
  RealtimeChannel? _profileChannel;
  
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
    // Refresh profile data when the controller is ready
    refreshProfile();
  }
  
  // Called when returning to this screen from another screen
  void onPageRevisited() {
    print('Home page revisited');
    // Refresh profile and notes when coming back to this screen
    refreshProfile();
    loadNotes();
  }
  
  @override
  void onClose() {
    _notesChannel?.unsubscribe();
    _foldersChannel?.unsubscribe();
    _tagsChannel?.unsubscribe();
    _noteTagsChannel?.unsubscribe();
    _profileChannel?.unsubscribe();
    newFolderController.dispose();
    newTagController.dispose();
    editFolderController.dispose();
    editTagController.dispose();
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
      
      void handleProfileChange(PostgresChangePayload payload) {
          print('Profile change detected: ${payload.eventType}');
          refreshProfile();
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
      
      try {
        // Setup profile changes subscription
        _profileChannel = _supabaseService.client.channel('profiles:${userId}');
        _profileChannel!.onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'profiles',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: userId,
          ),
          callback: handleProfileChange,
        );
        _profileChannel!.subscribe();
        print('Profile channel subscription setup successfully');
      } catch (e) {
        print('Error setting up profile channel: $e');
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
      
      // Show a brief success message when manually refreshed
      if (!Get.isSnackbarOpen) {
        Get.snackbar(
          'Refreshed',
          'Content updated successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 1),
        );
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'Error loading data: ${e.toString()}';
      print('Error loading data: $e');
      
      // Show error message
      Get.snackbar(
        'Error',
        'Failed to refresh: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> loadNotes({String? specificFolderId}) async {
    try {
      if (specificFolderId != null) {
        // When a specific folder ID is provided, load notes for that folder
        notes.value = await _noteRepository.getNotes(folderId: specificFolderId);
      } else if (selectedFolder.value != null) {
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
      
      // Update any notes in the current view that have this tag
      for (int i = 0; i < notes.length; i++) {
        if (notes[i].tags.any((tag) => tag.id == id)) {
          // Create a new list without the deleted tag
          final updatedTags = notes[i].tags.where((tag) => tag.id != id).toList();
          // Update the note with the new tag list
          notes[i] = notes[i].copyWith(tags: updatedTags);
        }
      }
      
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
          
          // Show success message for removing from folder
          if (folderId == null) {
            Get.snackbar(
              'Note Removed',
              'Note was removed from folder',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.green,
              colorText: Colors.white,
              duration: const Duration(seconds: 2),
            );
          }
        } else if (selectedFolder.value == null || folderId == selectedFolder.value!.id) {
          // If we're in the "All Notes" view or the note was moved to the current folder, update it
          notes[noteIndex] = updatedNote;
          
          // Show success message for adding to folder
          if (folderId != null) {
            final folderName = folders.firstWhere((folder) => folder.id == folderId).name;
            Get.snackbar(
              'Note Moved',
              'Note was moved to folder "$folderName"',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.green,
              colorText: Colors.white,
              duration: const Duration(seconds: 2),
            );
          }
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
      // Ensure UserRepository is available before attempting to sign out
      if (!Get.isRegistered<UserRepository>()) {
        print('UserRepository not registered! Registering now...');
        Get.put(UserRepository(), permanent: true);
      }
      
      final userRepository = Get.find<UserRepository>();
      await userRepository.signOut();
      Get.offAllNamed(Routes.AUTH);
    } catch (e) {
      print('Error signing out: $e');
      Get.snackbar(
        'Error',
        'Failed to sign out: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
      
      // If still having issues, try direct Supabase signout as fallback
      try {
        final supabaseService = Get.find<SupabaseService>();
        await supabaseService.signOut();
        Get.offAllNamed(Routes.AUTH);
      } catch (fallbackError) {
        print('Fallback signout also failed: $fallbackError');
      }
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
          // Check for deletion result
          else if (result is String && result.startsWith('deleted:')) {
            final deletedId = result.substring(8); // Extract the note ID
            print('Note was deleted: $deletedId');
            // Remove the note from the list
            notes.removeWhere((note) => note.id == deletedId);
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
  
  Future<void> editFolder(Folder folder) async {
    if (editFolderController.text.isEmpty) return;
    
    try {
      final updatedFolder = folder.copyWith(name: editFolderController.text.trim());
      final result = await _folderRepository.updateFolder(folder: updatedFolder);
      
      // Update the folder in the observable list immediately
      final index = folders.indexWhere((f) => f.id == folder.id);
      if (index != -1) {
        folders[index] = result;
        folders.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase())); // Sort folders
      }
      
      // Update selected folder if it was the one edited
      if (selectedFolder.value?.id == folder.id) {
        selectedFolder.value = result;
      }
      
      editFolderController.clear();
      Get.back(); // Close dialog
    } catch (e) {
      print('Error editing folder: $e');
      Get.snackbar(
        'Error',
        'Failed to edit folder: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
  
  Future<void> editTag(tag_model.Tag tag) async {
    if (editTagController.text.isEmpty) return;
    
    try {
      final updatedTag = tag.copyWith(name: editTagController.text.trim());
      final result = await _tagRepository.updateTag(tag: updatedTag);
      
      // Update the tag in the observable list immediately
      final index = tags.indexWhere((t) => t.id == tag.id);
      if (index != -1) {
        tags[index] = result;
        tags.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase())); // Sort tags
      }
      
      // Update selected tag if it was the one edited
      if (selectedTag.value?.id == tag.id) {
        selectedTag.value = result;
      }
      
      editTagController.clear();
      Get.back(); // Close dialog
    } catch (e) {
      print('Error editing tag: $e');
      Get.snackbar(
        'Error',
        'Failed to edit tag: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
