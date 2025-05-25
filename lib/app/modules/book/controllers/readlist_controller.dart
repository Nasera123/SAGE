import 'package:get/get.dart';
import '../../../data/models/readlist_model.dart';
import '../../../data/repositories/readlist_repository.dart';

class ReadlistController extends GetxController {
  final ReadlistRepository _readlistRepository = Get.find<ReadlistRepository>();
  
  final readlistItems = <ReadlistItem>[].obs;
  final isLoading = false.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;
  
  @override
  void onInit() {
    super.onInit();
    loadReadlist();
  }
  
  Future<void> loadReadlist() async {
    try {
      isLoading.value = true;
      hasError.value = false;
      errorMessage.value = '';
      
      final items = await _readlistRepository.getReadlist();
      readlistItems.assignAll(items);
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'Failed to load readlist: $e';
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<bool> addToReadlist(String bookId) async {
    try {
      isLoading.value = true;
      
      final success = await _readlistRepository.addToReadlist(bookId);
      if (success) {
        loadReadlist();
      }
      
      return success;
    } catch (e) {
      errorMessage.value = 'Failed to add book to readlist: $e';
      return false;
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<bool> removeFromReadlist(String bookId) async {
    try {
      isLoading.value = true;
      
      final success = await _readlistRepository.removeFromReadlist(bookId);
      if (success) {
        readlistItems.removeWhere((item) => item.bookId == bookId);
      }
      
      return success;
    } catch (e) {
      errorMessage.value = 'Failed to remove book from readlist: $e';
      return false;
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<bool> isInReadlist(String bookId) async {
    try {
      return await _readlistRepository.isInReadlist(bookId);
    } catch (e) {
      print('Error checking readlist status: $e');
      return false;
    }
  }
} 