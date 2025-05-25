import 'package:get/get.dart';
import '../../../data/models/book_model.dart';
import '../../../data/repositories/book_repository.dart';

class BookSearchController extends GetxController {
  final BookRepository _bookRepository = Get.find<BookRepository>();
  
  final books = <Book>[].obs;
  final isLoading = false.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;
  final searchQuery = ''.obs;
  
  // Pagination
  final currentPage = 0.obs;
  final booksPerPage = 20;
  final hasMoreBooks = true.obs;
  
  @override
  void onInit() {
    super.onInit();
    // Cek apakah ada query pencarian dari argumen
    if (Get.arguments != null && Get.arguments['query'] != null) {
      searchQuery.value = Get.arguments['query'] as String;
      searchBooks(searchQuery.value);
    }
  }
  
  Future<void> searchBooks(String query, {bool refresh = true}) async {
    if (query.isEmpty) return;
    
    if (refresh) {
      currentPage.value = 0;
      books.clear();
      hasMoreBooks.value = true;
    }
    
    // Simpan query untuk paginasi
    searchQuery.value = query;
    
    if (!hasMoreBooks.value) return;
    
    try {
      isLoading.value = true;
      hasError.value = false;
      
      final offset = currentPage.value * booksPerPage;
      final results = await _bookRepository.searchPublishedBooks(
        query,
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
      errorMessage.value = 'Failed to search books: $e';
    } finally {
      isLoading.value = false;
    }
  }
  
  void loadMore() {
    if (!isLoading.value && hasMoreBooks.value) {
      searchBooks(searchQuery.value, refresh: false);
    }
  }
  
  void clearSearch() {
    searchQuery.value = '';
    books.clear();
    currentPage.value = 0;
    hasMoreBooks.value = true;
  }
} 