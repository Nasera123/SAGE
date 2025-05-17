import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/repositories/book_repository.dart';
import '../../../data/models/book_model.dart';

class BookListController extends GetxController {
  final BookRepository _bookRepository = Get.find<BookRepository>();
  
  final isLoading = false.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;
  
  final books = <Book>[].obs;
  
  // For real-time updates
  RealtimeChannel? _booksChannel;
  
  @override
  void onInit() {
    super.onInit();
    loadBooks();
    setupRealtimeSubscription();
  }
  
  @override
  void onClose() {
    _booksChannel?.unsubscribe();
    super.onClose();
  }
  
  void setupRealtimeSubscription() {
    try {
      // Subscribe to book changes
      _booksChannel = _bookRepository.subscribeBookChanges(
        onBookChange: (payload) {
          print('Book list change detected: ${payload.eventType}');
          
          // Handle different types of changes
          if (payload.eventType == 'INSERT') {
            // New book created, reload books
            loadBooks();
          } else if (payload.eventType == 'UPDATE' && payload.newRecord != null) {
            // Book updated, update in the list
            final updatedBook = Book.fromJson(payload.newRecord!);
            final index = books.indexWhere((book) => book.id == updatedBook.id);
            if (index != -1) {
              books[index] = updatedBook;
            }
          } else if (payload.eventType == 'DELETE' && payload.oldRecord != null) {
            // Book deleted, remove from list
            final deletedBookId = payload.oldRecord!['id'] as String;
            books.removeWhere((book) => book.id == deletedBookId);
          }
        }
      );
    } catch (e) {
      print('Error setting up realtime subscription for books: $e');
    }
  }
  
  Future<void> loadBooks() async {
    isLoading.value = true;
    hasError.value = false;
    
    try {
      books.value = await _bookRepository.getBooks();
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'Error loading books: ${e.toString()}';
      print('Error loading books: $e');
    } finally {
      isLoading.value = false;
    }
  }
} 