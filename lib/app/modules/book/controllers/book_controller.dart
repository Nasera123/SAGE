import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'package:get/get.dart';
import '../../../data/repositories/book_repository.dart';
import '../../../data/repositories/note_repository.dart';
import '../../../data/models/book_model.dart';
import '../../../data/models/note_model.dart';
import '../../../routes/app_pages.dart';
import '../../../data/services/supabase_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import '../../note_editor/controllers/music_controller.dart';
import '../../../data/services/music_service.dart';

class BookController extends GetxController {
  final BookRepository _bookRepository = Get.find<BookRepository>();
  final NoteRepository _noteRepository = Get.find<NoteRepository>();
  final SupabaseService _supabaseService = Get.find<SupabaseService>();
  
  final isLoading = false.obs;
  final isSaving = false.obs;
  final isUploadingCover = false.obs;
  final isLoadingPages = false.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;
  
  // Flag untuk menandakan buku perlu direfresh
  final needsRefresh = false.obs;
  
  final book = Rxn<Book>();
  final Rxn<File> selectedCoverImage = Rxn<File>();
  final Rxn<Uint8List> selectedCoverImageWeb = Rxn<Uint8List>();
  final Rxn<XFile> selectedCoverImageFile = Rxn<XFile>();
  
  final titleController = TextEditingController();
  
  final ImagePicker _imagePicker = ImagePicker();
  
  // List of pages with details
  final RxList<Note> bookPages = <Note>[].obs;
  
  // Temporary property to hold deleteNote value for swipe dismiss
  bool tempDeleteNote = false;
  
  // For real-time updates
  RealtimeChannel? _bookChannel;
  RealtimeChannel? _pagesChannel;
  DateTime? _lastExternalUpdate;
  final realtimeActivity = ''.obs;
  
  // Timer untuk periodic refresh
  Timer? _periodicRefreshTimer;
  
  bool get isWeb => kIsWeb;
  
  @override
  void onInit() {
    super.onInit();
    print('BookController: onInit');
    
    // Check if we're editing an existing book
    if (Get.arguments != null && Get.arguments['bookId'] != null) {
      loadBook(Get.arguments['bookId']);
    }
    
    // Set up listener untuk needsRefresh flag
    ever(needsRefresh, (bool val) {
      if (val && book.value != null) {
        print('Auto-refreshing book pages due to needsRefresh flag');
        loadBookPages();
        // Reset flag setelah refresh
        needsRefresh.value = false;
      }
    });
  }
  
  @override
  void onClose() {
    titleController.dispose();
    _bookChannel?.unsubscribe();
    _pagesChannel?.unsubscribe();
    _periodicRefreshTimer?.cancel();
    super.onClose();
  }
  
  Future<void> loadBook(String id) async {
    isLoading.value = true;
    hasError.value = false;
    
    try {
      book.value = await _bookRepository.getBook(id);
      
      if (book.value != null) {
        titleController.text = book.value!.title;
        
        // Load the pages
        await loadBookPages();
        
        // Setup real-time subscription
        setupRealtimeSubscription();
        
        // Load associated music for this book
        try {
          if (Get.isRegistered<MusicController>()) {
            final musicController = Get.find<MusicController>();
            await musicController.loadMusicForBook(book.value!.id);
            print('Music loaded for book: ${book.value!.id}');
            
            // Explicitly find and play the music for this book
            final musicService = Get.find<MusicService>();
            if (!musicService.isPlaying.value && musicService.currentMusic.value != null) {
              await musicService.play();
              print('Autoplay started for book: ${book.value!.id}');
            }
          }
        } catch (e) {
          print('Error loading music for book: $e');
        }
      } else {
        hasError.value = true;
        errorMessage.value = 'Book not found';
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'Error loading book: ${e.toString()}';
      print('Error loading book: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
  void setupRealtimeSubscription() {
    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId == null || book.value == null) {
        print('Cannot setup realtime: No current user or book');
        return;
      }
      
      // Batalkan subscription lama jika ada
      _bookChannel?.unsubscribe();
      _pagesChannel?.unsubscribe();
      
      // Subscribe to specific book changes
      _bookChannel = _bookRepository.subscribeSpecificBookChanges(
        bookId: book.value!.id,
        onBookChange: (payload) {
          // Don't react to our own changes
          if (isSaving.value) return;
          
          // Set timestamp for tracking external updates
          _lastExternalUpdate = DateTime.now();
          
          print('Book update detected from another client: ${payload.eventType}');
          realtimeActivity.value = 'Book updated from another device at ${DateTime.now().toLocal().toIso8601String().substring(11, 19)}';
          
          // Schedule refresh after a short delay to avoid conflicts
          Future.delayed(Duration(milliseconds: 100), () {
            refreshBook();
          });
        }
      );

      // Subscribe to note changes that might affect book pages
      _pagesChannel = _noteRepository.subscribeNoteChanges(
        onNoteChange: (payload) {
          // Only process events for notes that are pages in this book
          if (book.value != null && book.value!.pageIds.isNotEmpty) {
            final changedNoteId = payload.newRecord?['id'] ?? payload.oldRecord?['id'];
            
            if (changedNoteId != null && book.value!.pageIds.contains(changedNoteId)) {
              print('Detected change to a note that is a page in this book: $changedNoteId');
              realtimeActivity.value = 'Page updated at ${DateTime.now().toLocal().toIso8601String().substring(11, 19)}';
              
              // Only refresh if we're not currently saving
              if (!isSaving.value) {
                // If the note was deleted, we might need to update pageIds
                if (payload.eventType == 'UPDATE' && 
                    payload.newRecord != null && 
                    payload.newRecord!['is_deleted'] == true) {
                  print('A page was moved to trash, refreshing book data');
                }
                
                // Load pages after a short delay to avoid conflicts
                Future.delayed(Duration(milliseconds: 300), () {
                  loadBookPages();
                });
              }
            }
          }
        }
      );
      
      // Mulai periodic refresh timer (setiap 30 detik)
      _periodicRefreshTimer?.cancel();
      _periodicRefreshTimer = Timer.periodic(Duration(seconds: 30), (_) {
        if (!isSaving.value && !isLoading.value && !isLoadingPages.value) {
          // Silent refresh (tanpa notifikasi) untuk memastikan data selalu segar
          _silentRefresh();
        }
      });
    } catch (e) {
      print('Error setting up realtime subscription: $e');
    }
  }
  
  // Silent refresh tanpa notifikasi
  Future<void> _silentRefresh() async {
    try {
      final updatedBook = await _bookRepository.getBook(book.value!.id);
      
      if (updatedBook != null) {
        // Bandingkan jumlah pageIds untuk mengetahui apakah ada perubahan
        final oldPageCount = book.value?.pageIds.length ?? 0;
        final newPageCount = updatedBook.pageIds.length;
        
        book.value = updatedBook;
        
        // Only update title if changed and we're not editing
        if (updatedBook.title != titleController.text && !isSaving.value) {
          titleController.text = updatedBook.title;
        }
        
        // Refresh halaman jika jumlah berubah
        if (oldPageCount != newPageCount) {
          print('Page count changed: $oldPageCount -> $newPageCount, refreshing pages');
          await loadBookPages();
        }
      }
    } catch (e) {
      print('Error during silent refresh: $e');
    }
  }
  
  Future<void> refreshBook() async {
    try {
      final updatedBook = await _bookRepository.getBook(book.value!.id);
      
      if (updatedBook != null) {
        // Cek perubahan jumlah halaman
        final oldPageCount = book.value?.pageIds.length ?? 0;
        final newPageCount = updatedBook.pageIds.length;
        
        book.value = updatedBook;
        book.refresh(); // Memastikan UI diperbarui
        
        // Only update title if it changed and we're not editing
        if (updatedBook.title != titleController.text && !isSaving.value) {
          titleController.text = updatedBook.title;
        }
        
        // Refresh page list
        await loadBookPages();
        
        // Tampilkan notifikasi jika jumlah halaman berubah
        if (oldPageCount != newPageCount) {
          Get.snackbar(
            'Book Updated',
            'Book pages changed: $oldPageCount -> $newPageCount',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.green.withOpacity(0.7),
            colorText: Colors.white,
            duration: Duration(seconds: 2),
          );
        } else {
          Get.snackbar(
            'Book Updated',
            'Book data has been refreshed',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.green.withOpacity(0.7),
            colorText: Colors.white,
            duration: Duration(seconds: 2),
          );
        }
      }
    } catch (e) {
      print('Error refreshing book: $e');
    }
  }
  
  Future<void> loadBookPages() async {
    if (book.value == null) {
      print('loadBookPages: No book loaded');
      bookPages.clear();
      return;
    }
    
    // Jika tidak ada pageIds, hapus bookPages dan return
    if (book.value!.pageIds.isEmpty) {
      print('loadBookPages: Book has no pages');
      bookPages.clear();
      return;
    }
    
    isLoadingPages.value = true;
    print('Loading book pages for book: ${book.value!.id}');
    print('Page IDs: ${book.value!.pageIds}');
    
    try {
      // Selalu ambil data halaman terbaru untuk memastikan judul dan konten terbaru
      print('Fetching all pages to ensure latest titles and content');
      final pages = await _noteRepository.getNotesByIds(book.value!.pageIds);
      print('Fetched ${pages.length} pages from ${book.value!.pageIds.length} page IDs');
      
      // Periksa jika ada halaman yang hilang
      if (pages.length < book.value!.pageIds.length) {
        print('Some pages were not found: Expected ${book.value!.pageIds.length}, got ${pages.length}');
        
        // Identifikasi halaman yang hilang
        final fetchedIds = pages.map((page) => page.id).toList();
        final missingIds = book.value!.pageIds.where((id) => !fetchedIds.contains(id)).toList();
        print('Missing page IDs: $missingIds');
        
        // Coba bersihkan pageIds dari halaman yang tidak ada
        final Book updatedBook = book.value!;
        for (final missingId in missingIds) {
          updatedBook.removePage(missingId);
        }
        
        // Update buku jika ada perubahan pada pageIds
        if (missingIds.isNotEmpty) {
          print('Updating book to remove missing pages');
          await _bookRepository.updateBook(updatedBook);
        }
      }
      
      // Tambahkan logging untuk setiap halaman
      for (var i = 0; i < pages.length; i++) {
        final page = pages[i];
        print('Page ${i+1}: ID=${page.id}, Title=${page.title}, Content length=${page.content.length}');
      }
      
      // Update bookPages setelah semua pengecekan
      bookPages.value = pages;
      bookPages.refresh(); // Force UI refresh
      
      // Refresh book data untuk memastikan sinkronisasi
      book.refresh();
    } catch (e) {
      print('Error loading book pages: $e');
      Get.snackbar(
        'Error',
        'Failed to load book pages. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoadingPages.value = false;
    }
  }
  
  Future<void> saveBook() async {
    if (titleController.text.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Book title cannot be empty',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    
    isSaving.value = true;
    
    try {
      if (book.value == null) {
        // Create new book
        final newBook = await _bookRepository.createBook(
          title: titleController.text.trim(),
        );
        
        if (newBook != null) {
          book.value = newBook;
          
          // Setup real-time subscriptions immediately for the new book
          setupRealtimeSubscription();
          
          // Upload cover if selected
          if (selectedCoverImageFile.value != null) {
            await uploadCoverImage();
          }
          
          Get.snackbar(
            'Success',
            'Book created successfully',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        } else {
          throw Exception('Failed to create book');
        }
      } else {
        // Update existing book
        book.value!.update(
          title: titleController.text.trim(),
        );
        
        final success = await _bookRepository.updateBook(book.value!);
        
        if (success) {
          // Upload cover if selected
          if (selectedCoverImageFile.value != null) {
            await uploadCoverImage();
          } else {
            // Trigger refreshBook to ensure UI is updated
            await refreshBook();
          }
          
          Get.snackbar(
            'Success',
            'Book updated successfully',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        } else {
          throw Exception('Failed to update book');
        }
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to save book: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      print('Error saving book: $e');
    } finally {
      isSaving.value = false;
    }
  }
  
  Future<void> pickCoverImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 800,
        imageQuality: 80,
      );
      
      if (image != null) {
        selectedCoverImageFile.value = image;
        
        if (kIsWeb) {
          // For web platform
          try {
            final bytes = await image.readAsBytes();
            selectedCoverImageWeb.value = bytes;
            print('Cover image selected for web: ${image.path}, size: ${bytes.length} bytes');
          } catch (e) {
            print('Error reading image bytes: $e');
            Get.snackbar(
              'Error',
              'Could not process the selected image',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.red,
              colorText: Colors.white,
            );
          }
        } else {
          // For mobile platforms
          selectedCoverImage.value = File(image.path);
          print('Cover image selected: ${image.path}');
        }
      }
    } catch (e) {
      print('Error picking cover image: $e');
      Get.snackbar(
        'Error',
        'Could not select image. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }
  
  Future<void> uploadCoverImage() async {
    if (selectedCoverImageFile.value == null || book.value == null) return;
    
    isUploadingCover.value = true;
    
    try {
      String? coverUrl;
      
      if (kIsWeb) {
        // Web upload
        if (selectedCoverImageWeb.value != null) {
          coverUrl = await _bookRepository.uploadBookCoverWeb(
            selectedCoverImageWeb.value!,
            book.value!.id,
            selectedCoverImageFile.value!.name,
          );
        }
      } else {
        // Mobile upload
        if (selectedCoverImage.value != null) {
          coverUrl = await _bookRepository.uploadBookCover(
            selectedCoverImage.value!,
            book.value!.id,
          );
        }
      }
      
      if (coverUrl != null) {
        // Update book with new cover URL
        book.value!.update(coverUrl: coverUrl);
        await _bookRepository.updateBook(book.value!);
        
        Get.snackbar(
          'Success',
          'Book cover updated successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        throw Exception('Failed to upload cover image');
      }
    } catch (e) {
      print('Error uploading cover image: $e');
      Get.snackbar(
        'Error',
        'Failed to upload cover image. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isUploadingCover.value = false;
      selectedCoverImage.value = null;
      selectedCoverImageWeb.value = null;
      selectedCoverImageFile.value = null;
    }
  }
  
  void showImagePickerOptions() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        color: Get.theme.cardColor,
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Change Book Cover',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take a photo'),
                onTap: () {
                  Get.back();
                  pickCoverImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from gallery'),
                onTap: () {
                  Get.back();
                  pickCoverImage(ImageSource.gallery);
                },
              ),
              if (book.value?.coverUrl != null && book.value!.coverUrl!.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Remove current cover', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Get.back();
                    _removeCoverImage();
                  },
                ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Get.back(),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Future<void> _removeCoverImage() async {
    if (book.value == null) return;
    
    try {
      book.value!.update(coverUrl: '');
      await _bookRepository.updateBook(book.value!);
      
      Get.snackbar(
        'Success',
        'Book cover removed',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      print('Error removing book cover: $e');
      Get.snackbar(
        'Error',
        'Failed to remove book cover: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
  
  Future<void> deleteBook() async {
    if (book.value == null) return;
    
    try {
      await _bookRepository.deleteBook(book.value!.id);
      
      // Stop music before navigating back
      await handleLeavingBook();
      
      Get.back(result: {'deleted': true, 'bookId': book.value!.id});
      
      Get.snackbar(
        'Success',
        'Book moved to trash',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      print('Error deleting book: $e');
      Get.snackbar(
        'Error',
        'Failed to delete book: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
  
  // Handle leaving the book view and stop music
  Future<void> handleLeavingBook() async {
    try {
      if (Get.isRegistered<MusicController>()) {
        final musicController = Get.find<MusicController>();
        await musicController.handleLeavingBook();
        print('Music stopped when leaving book');
      }
    } catch (e) {
      print('Error stopping music when leaving book: $e');
    }
  }
  
  Future<void> createNewPage() async {
    if (book.value == null) {
      Get.snackbar(
        'Error',
        'Please save the book first',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    
    try {
      // Create a new note to use as a page
      final NoteRepository noteRepository = Get.find<NoteRepository>();
      final newNote = await noteRepository.createNote(
        title: 'New Page in ${book.value!.title}',
        content: '{"ops":[{"insert":"\\n"}]}', // Empty quill delta
      );
      
      // Update the local book model first to include the new page ID
      if (book.value != null) {
        book.value!.addPage(newNote.id);
        book.value!.updatedAt = DateTime.now(); // Force update timestamp untuk memastikan perubahan terdeteksi
        book.refresh(); // Trigger UI update
      }
      
      // Add the note ID to the book's pages in database
      final success = await _bookRepository.updateBook(book.value!);
      
      if (success) {
        // Add the page to local pages list immediately for better UX
        bookPages.add(newNote);
        
        Get.snackbar(
          'Success',
          'New page added to book',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        
        // Open the note editor for the new page
        Get.toNamed(
          Routes.NOTE_EDITOR,
          arguments: {
            'noteId': newNote.id,
            'isBookPage': true,
            'bookId': book.value!.id
          },
        )?.then((_) {
          // Refresh pages when coming back from editor
          loadBookPages();
        });
      } else {
        throw Exception('Failed to add page to book');
      }
    } catch (e) {
      print('Error creating new page: $e');
      Get.snackbar(
        'Error',
        'Failed to create new page: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
  
  Future<void> deletePage(String pageId, {bool deleteNote = false}) async {
    if (book.value == null) return;
    
    try {
      // First remove the page ID from the book
      final success = await _bookRepository.removePageFromBook(book.value!.id, pageId);
      
      if (success) {
        // Update local state immediately for better UX
        book.value!.removePage(pageId);
        bookPages.removeWhere((page) => page.id == pageId);
        
        // If requested, also delete the underlying note (move to trash)
        if (deleteNote) {
          try {
            // Use deleteNote which now moves to trash instead of permanently deleting
            // Pass the book ID so we can restore the note to this book later
            await Get.find<NoteRepository>().deleteNote(
              id: pageId, 
              originalBookId: book.value!.id
            );
            Get.snackbar(
              'Success',
              'Page removed and moved to trash',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.green,
              colorText: Colors.white,
            );
          } catch (e) {
            print('Error moving note to trash: $e');
            Get.snackbar(
              'Warning',
              'Page removed from book but note could not be moved to trash',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.orange,
              colorText: Colors.white,
            );
          }
        } else {
          Get.snackbar(
            'Success',
            'Page removed from book',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        }
        
        // Refresh book data to ensure everything is in sync
        await loadBook(book.value!.id);
      } else {
        throw Exception('Failed to remove page from book');
      }
    } catch (e) {
      print('Error deleting page: $e');
      Get.snackbar(
        'Error',
        'Failed to delete page: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
} 