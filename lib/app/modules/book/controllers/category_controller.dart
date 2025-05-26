import 'package:get/get.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/book_model.dart';
import '../../../data/repositories/category_repository.dart';
import '../../../data/repositories/book_repository.dart';

class CategoryController extends GetxController {
  final CategoryRepository categoryRepository = Get.find<CategoryRepository>();
  final BookRepository bookRepository = Get.find<BookRepository>();
  
  RxList<Category> categories = <Category>[].obs;
  RxList<Book> filteredBooks = <Book>[].obs;
  RxList<Category> bookCategories = <Category>[].obs;
  RxString selectedCategoryId = ''.obs;
  RxBool isLoading = false.obs;
  RxString currentBookId = ''.obs;
  
  @override
  void onInit() {
    super.onInit();
    loadCategories();
  }
  
  Future<void> loadCategories() async {
    isLoading.value = true;
    
    try {
      final fetchedCategories = await categoryRepository.getAllCategories();
      categories.assignAll(fetchedCategories);
    } catch (e) {
      print('Error loading categories: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> filterBooksByCategory(String categoryId) async {
    if (categoryId.isEmpty) {
      filteredBooks.clear();
      selectedCategoryId.value = '';
      return;
    }
    
    isLoading.value = true;
    selectedCategoryId.value = categoryId;
    
    try {
      final books = await bookRepository.getBooksByCategory(categoryId);
      filteredBooks.assignAll(books);
    } catch (e) {
      print('Error filtering books by category: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> filterPublicBooksByCategory(String categoryId) async {
    if (categoryId.isEmpty) {
      filteredBooks.clear();
      selectedCategoryId.value = '';
      print('Category filter cleared');
      return;
    }
    
    isLoading.value = true;
    selectedCategoryId.value = categoryId;
    print('Filtering public books by category: $categoryId');
    
    try {
      final books = await bookRepository.getPublicBooksByCategory(categoryId);
      print('Found ${books.length} books in category $categoryId');
      filteredBooks.assignAll(books);
    } catch (e) {
      print('Error filtering public books by category: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
  void clearFilter() {
    // Reset filter state
    print('Clearing category filter, previous selectedCategoryId: ${selectedCategoryId.value}');
    selectedCategoryId.value = '';
    
    // Memastikan daftar buku yang difilter dihapus secara lengkap
    if (filteredBooks.isNotEmpty) {
      print('Clearing ${filteredBooks.length} filtered books');
      filteredBooks.clear();
    }
    
    // Reset loading state juga untuk mencegah infinite loading
    isLoading.value = false;
    print('Category filter cleared completely');
  }
  
  // Load categories for a specific book
  Future<void> loadBookCategories(String bookId) async {
    try {
      currentBookId.value = bookId;
      final categories = await categoryRepository.getBookCategories(bookId);
      bookCategories.assignAll(categories);
    } catch (e) {
      print('Error loading book categories: $e');
      bookCategories.clear();
    }
  }
  
  // Add category to a book
  Future<bool> addCategoryToBook(String bookId, String categoryId) async {
    try {
      final result = await categoryRepository.addCategoryToBook(bookId, categoryId);
      if (result && bookId == currentBookId.value) {
        // Refresh book categories after successful addition
        await loadBookCategories(bookId);
      }
      return result;
    } catch (e) {
      print('Error adding category to book: $e');
      return false;
    }
  }
  
  // Remove category from a book
  Future<bool> removeCategoryFromBook(String bookId, String categoryId) async {
    try {
      final result = await categoryRepository.removeCategoryFromBook(bookId, categoryId);
      if (result && bookId == currentBookId.value) {
        // Refresh book categories after successful removal
        await loadBookCategories(bookId);
      }
      return result;
    } catch (e) {
      print('Error removing category from book: $e');
      return false;
    }
  }
  
  // Get categories for a specific book (for backward compatibility)
  Future<List<Category>> getBookCategories(String bookId) async {
    try {
      if (bookId == currentBookId.value && bookCategories.isNotEmpty) {
        return bookCategories;
      }
      
      await loadBookCategories(bookId);
      return bookCategories;
    } catch (e) {
      print('Error getting book categories: $e');
      return [];
    }
  }
  
  // Create a new category
  Future<bool> createCategory(String name, {String? description}) async {
    try {
      // Create a new category with the given name
      final category = Category(
        name: name,
        description: description,
      );
      
      // Insert the category into the database
      final insertedCategory = await categoryRepository.createCategory(category);
      if (insertedCategory != null) {
        // Add to the categories list
        categories.add(insertedCategory);
        // Sort categories by name
        categories.sort((a, b) => a.name.compareTo(b.name));
        return true;
      }
      return false;
    } catch (e) {
      print('Error creating category: $e');
      return false;
    }
  }
} 