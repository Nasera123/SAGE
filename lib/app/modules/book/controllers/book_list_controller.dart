import 'package:get/get.dart';
import '../../../data/repositories/book_repository.dart';
import '../../../data/models/book_model.dart';

class BookListController extends GetxController {
  final BookRepository _bookRepository = Get.find<BookRepository>();
  
  final isLoading = false.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;
  
  final books = <Book>[].obs;
  
  @override
  void onInit() {
    super.onInit();
    loadBooks();
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