import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import '../../../data/repositories/book_repository.dart';
import '../../../data/models/book_model.dart';
import '../../../routes/app_pages.dart';

class BookListController extends GetxController {
  final BookRepository _bookRepository = Get.find<BookRepository>();
  
  final isLoading = false.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;
  
  final books = <Book>[].obs;
  
  // For real-time updates
  RealtimeChannel? _booksChannel;
  
  // Timer untuk periodic refresh
  Timer? _autoRefreshTimer;
  
  // To track if we should refresh on next route change
  bool shouldRefreshOnNextRoute = false;
  
  @override
  void onInit() {
    super.onInit();
    print('BookListController: onInit');
    loadBooks();
    setupRealtimeSubscription();
    _startAutoRefreshTimer();
  }
  
  @override
  void onReady() {
    super.onReady();
    // We're on the books list page now
    print('BookListController: onReady');
    // Already loaded in onInit, no need to load again
  }
  
  @override
  void onClose() {
    print('BookListController: onClose');
    _booksChannel?.unsubscribe();
    _autoRefreshTimer?.cancel();
    super.onClose();
  }
  
  // Memulai timer untuk periodic refresh setiap 15 detik
  void _startAutoRefreshTimer() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(Duration(seconds: 15), (_) {
      if (!isLoading.value) {
        print('BookListController: auto-refresh timer triggered');
        _silentRefresh();
      }
    });
  }
  
  // Refresh tanpa loading indicator
  Future<void> _silentRefresh() async {
    try {
      print('BookListController: performing silent refresh');
      final updatedBooks = await _bookRepository.getBooks();
      
      // Bandingkan dengan daftar yang ada untuk cek perubahan
      if (_bookListsAreDifferent(books, updatedBooks)) {
        print('BookListController: changes detected, updating books');
        books.value = updatedBooks;
      } else {
        print('BookListController: no changes detected');
      }
    } catch (e) {
      print('Error during silent refresh: $e');
    }
  }
  
  // Cek perbedaan daftar buku
  bool _bookListsAreDifferent(List<Book> oldList, List<Book> newList) {
    if (oldList.length != newList.length) return true;
    
    // Bandingkan ID dan timestamps untuk deteksi perbedaan
    for (int i = 0; i < oldList.length; i++) {
      if (oldList[i].id != newList[i].id ||
          oldList[i].updatedAt != newList[i].updatedAt ||
          oldList[i].pageIds.length != newList[i].pageIds.length) {
        return true;
      }
    }
    
    return false;
  }
  
  void setupRealtimeSubscription() {
    try {
      // Batalkan subscription yang ada sebelumnya
      _booksChannel?.unsubscribe();
      
      // Subscribe to book changes
      _booksChannel = _bookRepository.subscribeBookChanges(
        onBookChange: (payload) {
          print('Book list change detected: ${payload.eventType}');
          
          // Handle different types of changes
          if (payload.eventType == 'INSERT') {
            // New book created - jangan reload seluruh list, cukup tambahkan buku baru jika ada
            if (payload.newRecord != null) {
              final newBook = Book.fromJson(payload.newRecord!);
              // Jangan tambahkan jika sudah ada atau is_deleted=true
              if (!newBook.isDeleted && !books.any((book) => book.id == newBook.id)) {
                print('BookListController: adding new book to list: ${newBook.title}');
                books.add(newBook);
                books.sort((a, b) => b.updatedAt.compareTo(a.updatedAt)); // Sort by most recent
                books.refresh(); // Force UI update
              }
            } else {
              // Fallback ke reload jika payload tidak lengkap
              print('BookListController: incomplete INSERT payload, reloading all books');
              loadBooks();
            }
          } else if (payload.eventType == 'UPDATE' && payload.newRecord != null) {
            // Book updated, update in the list
            final updatedBook = Book.fromJson(payload.newRecord!);
            
            // Debug: Print whether a book was marked as deleted
            if (updatedBook.isDeleted) {
              print('BookListController: Got UPDATE event for deleted book: ${updatedBook.title} (${updatedBook.id})');
            }
            
            // Jika buku sudah dihapus (is_deleted=true), maka hapus dari list
            if (updatedBook.isDeleted) {
              print('BookListController: removing deleted book: ${updatedBook.title} (${updatedBook.id})');
              // Check if the book is actually in the list
              final bookExists = books.any((b) => b.id == updatedBook.id);
              if (bookExists) {
                print('BookListController: book found in list, removing it');
                books.removeWhere((book) => book.id == updatedBook.id);
                books.refresh(); // Force UI update
                
                // Show notification that a book was removed
                Get.snackbar(
                  'Book Removed',
                  'Book "${updatedBook.title}" was moved to trash',
                  snackPosition: SnackPosition.BOTTOM,
                  duration: const Duration(seconds: 2),
                );
              } else {
                print('BookListController: book not found in list, nothing to remove');
              }
            } else {
              // Update existing book
              final index = books.indexWhere((book) => book.id == updatedBook.id);
              if (index != -1) {
                // Cek jika jumlah halaman berubah untuk log
                final oldPageCount = books[index].pageIds.length;
                final newPageCount = updatedBook.pageIds.length;
                if (oldPageCount != newPageCount) {
                  print('BookListController: book page count changed: ${updatedBook.title} - $oldPageCount -> $newPageCount');
                }
                
                // Update buku di list
                books[index] = updatedBook;
                books.refresh(); // Pastikan UI diperbarui
              } else {
                // Jika tidak ditemukan, mungkin buku baru, tambahkan
                print('BookListController: adding updated book not in list: ${updatedBook.title}');
                books.add(updatedBook);
                books.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
                books.refresh(); // Force UI update
              }
            }
          } else if (payload.eventType == 'DELETE' && payload.oldRecord != null) {
            // Book deleted, remove from list
            try {
              final deletedBookId = payload.oldRecord!['id'] as String;
              print('BookListController: removing permanently deleted book ID: $deletedBookId');
              
              // Check if the book is actually in the list
              final bookExists = books.any((b) => b.id == deletedBookId);
              if (bookExists) {
                print('BookListController: permanently deleted book found in list, removing it');
                books.removeWhere((book) => book.id == deletedBookId);
                books.refresh(); // Force UI update
              } else {
                print('BookListController: permanently deleted book not found in list');
              }
            } catch (e) {
              print('Error processing DELETE event: $e');
              // Fallback to reload
              loadBooks();
            }
          }
        }
      );
      print('BookListController: realtime subscription setup complete');
    } catch (e) {
      print('Error setting up realtime subscription for books: $e');
    }
  }
  
  Future<void> loadBooks() async {
    isLoading.value = true;
    hasError.value = false;
    
    try {
      print('BookListController: loading all books');
      books.value = await _bookRepository.getBooks();
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'Error loading books: ${e.toString()}';
      print('Error loading books: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
  // Refresh data when returning to this screen
  void refreshData() {
    print('BookListController: refreshData called');
    loadBooks();
  }
  
  // Directly handle book deletion from UI
  void handleBookDeletion(String bookId) {
    // Remove book from the list immediately
    final bookToDelete = books.firstWhereOrNull((b) => b.id == bookId);
    if (bookToDelete != null) {
      print('BookListController: directly removing deleted book: ${bookToDelete.title} (${bookToDelete.id})');
      books.removeWhere((book) => book.id == bookId);
      books.refresh();
      
      // Show notification
      Get.snackbar(
        'Book Removed',
        'Book "${bookToDelete.title}" was moved to trash',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    }
  }
  
  // Method to navigate to book detail with instant UI feedback
  void openBook(Book book) {
    Get.toNamed(
      Routes.BOOK,
      arguments: {'bookId': book.id}
    )?.then((result) {
      // Improved handling of result from book detail page
      print('BookListController: returned from book detail page with result: $result');
      
      if (result != null && result is Map<String, dynamic>) {
        // Check if the book was deleted
        if (result['deleted'] == true && result['bookId'] != null) {
          // Find and remove the deleted book from the list
          String bookId = result['bookId'];
          print('Book was deleted, removing from list: $bookId');
          handleBookDeletion(bookId);
        } else {
          // Just refresh the data
          refreshData();
        }
      } else {
        // Default refresh
        refreshData();
      }
    });
  }
  
  // Method to create new book with instant UI feedback
  void createNewBook() {
    Get.toNamed(Routes.BOOK)?.then((result) {
      // Refresh when returning from book creation page
      print('BookListController: returned from book creation page with result: $result');
      refreshData();
    });
  }
} 