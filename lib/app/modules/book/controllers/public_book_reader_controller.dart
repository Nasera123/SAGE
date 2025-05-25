import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/book_model.dart';
import '../../../data/models/note_model.dart';
import '../../../data/repositories/book_repository.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'dart:convert';
import '../../../data/repositories/readlist_repository.dart';
import '../controllers/readlist_controller.dart';

class PublicBookReaderController extends GetxController {
  final BookRepository _bookRepository = Get.find<BookRepository>();
  final ReadlistRepository _readlistRepository = Get.find<ReadlistRepository>();
  
  final book = Rx<Book?>(null);
  final notes = <Note>[].obs;
  final isLoading = false.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;
  
  // Page navigation
  final pageController = PageController();
  final currentPageIndex = 0.obs;
  
  // Quill controllers for each note
  final Map<String, quill.QuillController> _quillControllers = {};
  
  @override
  void onInit() {
    super.onInit();
    
    // Get the book ID from arguments
    if (Get.arguments != null && Get.arguments['bookId'] != null) {
      final bookId = Get.arguments['bookId'] as String;
      loadBook(bookId);
    } else {
      hasError.value = true;
      errorMessage.value = 'No book ID provided';
    }
  }
  
  @override
  void onClose() {
    // Dispose quill controllers
    _quillControllers.values.forEach((controller) {
      controller.dispose();
    });
    
    pageController.dispose();
    super.onClose();
  }
  
  Future<void> loadBook(String bookId) async {
    try {
      isLoading.value = true;
      hasError.value = false;
      
      print('PublicBookReaderController: Memulai loading buku publik dengan ID $bookId');
      
      // Get the book data
      final bookData = await _bookRepository.getPublicBook(bookId);
      if (bookData == null) {
        print('PublicBookReaderController: Buku dengan ID $bookId tidak ditemukan atau bukan publik');
        hasError.value = true;
        errorMessage.value = 'Book not found or not public';
        return;
      }
      
      print('PublicBookReaderController: Buku ditemukan dengan judul "${bookData.title}"');
      print('PublicBookReaderController: Buku memiliki ${bookData.pageIds.length} halaman IDs: ${bookData.pageIds}');
      
      book.value = bookData;
      
      // Get all notes (pages) for the book
      final bookNotes = await _bookRepository.getPublicBookNotes(bookId);
      print('PublicBookReaderController: Mengambil ${bookNotes.length} halaman untuk buku');
      
      if (bookNotes.isEmpty) {
        print('PublicBookReaderController: Tidak ada halaman ditemukan untuk buku');
        hasError.value = true;
        errorMessage.value = 'No pages found for this book';
        return;
      }
      
      // Filter and sort notes according to book.pageIds order
      final orderedNotes = <Note>[];
      for (final noteId in bookData.pageIds) {
        final note = bookNotes.firstWhereOrNull((n) => n.id == noteId);
        if (note != null) {
          orderedNotes.add(note);
        }
      }
      
      notes.assignAll(orderedNotes);
      
      // Initialize quill controllers for each note
      for (final note in notes) {
        _initQuillController(note);
      }
      
      print('PublicBookReaderController: Buku berhasil dimuat dengan ${notes.length} halaman');
    } catch (e) {
      print('PublicBookReaderController: Error loading book: $e');
      hasError.value = true;
      errorMessage.value = 'Error loading book: $e';
    } finally {
      isLoading.value = false;
    }
  }
  
  // Initialize a QuillController for a note
  void _initQuillController(Note note) {
    try {
      if (_quillControllers.containsKey(note.id)) return;
      
      // Parse the note content
      var contentJson = [];
      try {
        contentJson = jsonDecode(note.content);
      } catch (e) {
        print('Error parsing note content: $e');
        contentJson = [{"insert": "Error loading content"}];
      }
      
      // Create a quill controller for the note
      final controller = quill.QuillController(
        document: quill.Document.fromJson(contentJson),
        selection: const TextSelection.collapsed(offset: 0),
        readOnly: true  // Make it read-only
      );
      
      // Store the controller
      _quillControllers[note.id] = controller;
    } catch (e) {
      print('Error initializing quill controller: $e');
    }
  }
  
  // Get the quill controller for a specific note
  quill.QuillController getQuillControllerForNote(String noteId) {
    if (!_quillControllers.containsKey(noteId)) {
      // Create a default controller if not found
      final controller = quill.QuillController.basic();
      _quillControllers[noteId] = controller;
    }
    return _quillControllers[noteId]!;
  }
  
  // Navigate to the next page
  void nextPage() {
    if (currentPageIndex.value < notes.length - 1) {
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
  
  // Navigate to the previous page
  void previousPage() {
    if (currentPageIndex.value > 0) {
      pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
  
  // Get author initials for display
  String getUserInitials() {
    final displayName = book.value?.userDisplayName;
    if (displayName == null || displayName.isEmpty) return '?';
    
    final parts = displayName.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return displayName[0].toUpperCase();
  }
  
  // Check if a book is in the user's reading list
  Future<bool> isInReadlist(String bookId) async {
    try {
      final readlistController = Get.find<ReadlistController>(tag: 'global_readlist');
      return await readlistController.isInReadlist(bookId);
    } catch (e) {
      print('Error checking readlist status: $e');
      return false;
    }
  }
  
  // Navigate to a specific page directly
  void goToPage(int index) {
    if (index >= 0 && index < notes.length) {
      pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      currentPageIndex.value = index;
    }
  }
} 