import 'package:get/get.dart';
import '../../../data/models/note_model.dart';
import '../../../data/models/book_model.dart';
import '../../../data/repositories/trash_repository.dart';
import '../../../modules/home/controllers/home_controller.dart';

class TrashController extends GetxController {
  final TrashRepository _trashRepository = Get.find<TrashRepository>();
  
  final RxList<Note> trashedNotes = <Note>[].obs;
  final RxList<Book> trashedBooks = <Book>[].obs;
  final RxBool isLoading = true.obs;
  
  @override
  void onInit() {
    super.onInit();
    loadTrashItems();
  }
  
  Future<void> loadTrashItems() async {
    isLoading.value = true;
    
    try {
      final trash = await _trashRepository.getTrashItems();
      trashedNotes.value = trash['notes'] as List<Note>;
      trashedBooks.value = trash['books'] as List<Book>;
    } catch (e) {
      print('Error loading trash items: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> emptyTrash() async {
    try {
      final success = await _trashRepository.emptyTrash();
      if (success) {
        trashedNotes.clear();
        trashedBooks.clear();
        Get.snackbar('Success', 'Trash emptied successfully',
          snackPosition: SnackPosition.BOTTOM);
      } else {
        Get.snackbar('Error', 'Failed to empty trash',
          snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      print('Error emptying trash: $e');
      Get.snackbar('Error', 'Failed to empty trash: $e',
        snackPosition: SnackPosition.BOTTOM);
    }
  }
  
  Future<void> restoreNote(String noteId) async {
    try {
      final success = await _trashRepository.restoreNote(noteId);
      if (success) {
        trashedNotes.removeWhere((note) => note.id == noteId);
        Get.snackbar('Success', 'Note restored successfully',
          snackPosition: SnackPosition.BOTTOM);
          
        // Reload data in the HomeController if it exists
        try {
          final homeController = Get.find<HomeController>();
          homeController.loadData();
        } catch (e) {
          // HomeController not found or not initialized yet, which is fine
          print('Note restored, but HomeController not available: $e');
        }
      } else {
        Get.snackbar('Error', 'Failed to restore note',
          snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      print('Error restoring note: $e');
      Get.snackbar('Error', 'Failed to restore note: $e',
        snackPosition: SnackPosition.BOTTOM);
    }
  }
  
  Future<void> restoreBook(String bookId) async {
    try {
      final success = await _trashRepository.restoreBook(bookId);
      if (success) {
        trashedBooks.removeWhere((book) => book.id == bookId);
        Get.snackbar('Success', 'Book restored successfully',
          snackPosition: SnackPosition.BOTTOM);
          
        // Reload data in the HomeController if it exists
        try {
          final homeController = Get.find<HomeController>();
          homeController.loadData();
        } catch (e) {
          // HomeController not found or not initialized yet, which is fine
          print('Book restored, but HomeController not available: $e');
        }
      } else {
        Get.snackbar('Error', 'Failed to restore book',
          snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      print('Error restoring book: $e');
      Get.snackbar('Error', 'Failed to restore book: $e',
        snackPosition: SnackPosition.BOTTOM);
    }
  }
  
  Future<void> permanentlyDeleteNote(String noteId) async {
    try {
      final success = await _trashRepository.permanentlyDeleteNote(noteId);
      if (success) {
        trashedNotes.removeWhere((note) => note.id == noteId);
        Get.snackbar('Success', 'Note permanently deleted',
          snackPosition: SnackPosition.BOTTOM);
      } else {
        Get.snackbar('Error', 'Failed to delete note',
          snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      print('Error deleting note: $e');
      Get.snackbar('Error', 'Failed to delete note: $e',
        snackPosition: SnackPosition.BOTTOM);
    }
  }
  
  Future<void> permanentlyDeleteBook(String bookId) async {
    try {
      final success = await _trashRepository.permanentlyDeleteBook(bookId);
      if (success) {
        trashedBooks.removeWhere((book) => book.id == bookId);
        Get.snackbar('Success', 'Book permanently deleted',
          snackPosition: SnackPosition.BOTTOM);
      } else {
        Get.snackbar('Error', 'Failed to delete book',
          snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      print('Error deleting book: $e');
      Get.snackbar('Error', 'Failed to delete book: $e',
        snackPosition: SnackPosition.BOTTOM);
    }
  }
} 