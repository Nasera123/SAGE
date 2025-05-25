import 'package:get/get.dart';
import '../../../data/models/book_model.dart';
import '../../../data/repositories/book_repository.dart';
import '../../../data/services/supabase_service.dart';

class PublicLibraryController extends GetxController {
  final BookRepository _bookRepository = Get.find<BookRepository>();
  final SupabaseService _supabaseService = Get.find<SupabaseService>();

  final books = <Book>[].obs;
  final isLoading = true.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;
  final searchQuery = ''.obs;
  final isSearching = false.obs;
  
  // Pagination
  final currentPage = 0.obs;
  final booksPerPage = 20;
  final hasMoreBooks = true.obs;
  
  @override
  void onInit() {
    super.onInit();
    loadPublishedBooks();
  }
  
  Future<void> loadPublishedBooks({bool refresh = false}) async {
    if (refresh) {
      currentPage.value = 0;
      books.clear();
      hasMoreBooks.value = true;
    }
    
    if (!hasMoreBooks.value) return;
    
    try {
      isLoading.value = true;
      hasError.value = false;
      
      final offset = currentPage.value * booksPerPage;
      final results = await _bookRepository.getPublishedBooks(
        limit: booksPerPage, 
        offset: offset
      );
      
      if (results.isEmpty) {
        hasMoreBooks.value = false;
      } else {
        books.addAll(results);
        currentPage.value++;
      }
      
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'Failed to load books: $e';
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> searchBooks(String query) async {
    searchQuery.value = query;
    
    if (query.isEmpty) {
      books.clear();
      currentPage.value = 0;
      hasMoreBooks.value = true;
      await loadPublishedBooks(refresh: true);
      return;
    }
    
    try {
      isLoading.value = true;
      isSearching.value = true;
      hasError.value = false;
      
      final results = await _bookRepository.searchPublishedBooks(
        query,
        limit: 50 // Get more results for search
      );
      
      books.clear();
      books.addAll(results);
      
      // Disable pagination for search results
      hasMoreBooks.value = false;
      
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'Failed to search books: $e';
    } finally {
      isLoading.value = false;
    }
  }
  
  void clearSearch() {
    if (searchQuery.isNotEmpty) {
      searchQuery.value = '';
      isSearching.value = false;
      loadPublishedBooks(refresh: true);
    }
  }
  
  String getUserInitials(Book book) {
    if (book.userDisplayName == null || book.userDisplayName!.isEmpty) {
      return 'U';
    }
    
    final nameParts = book.userDisplayName!.split(' ');
    if (nameParts.length > 1) {
      return '${nameParts[0][0]}${nameParts[1][0]}';
    } else {
      return nameParts[0][0];
    }
  }
} 