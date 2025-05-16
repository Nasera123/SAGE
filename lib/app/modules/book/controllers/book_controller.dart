import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'package:get/get.dart';
import '../../../data/repositories/book_repository.dart';
import '../../../data/models/book_model.dart';
import 'package:image_picker/image_picker.dart';

class BookController extends GetxController {
  final BookRepository _bookRepository = Get.find<BookRepository>();
  
  final isLoading = false.obs;
  final isSaving = false.obs;
  final isUploadingCover = false.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;
  
  final book = Rxn<Book>();
  final Rxn<File> selectedCoverImage = Rxn<File>();
  final Rxn<Uint8List> selectedCoverImageWeb = Rxn<Uint8List>();
  final Rxn<XFile> selectedCoverImageFile = Rxn<XFile>();
  
  final titleController = TextEditingController();
  
  final ImagePicker _imagePicker = ImagePicker();
  
  bool get isWeb => kIsWeb;
  
  @override
  void onInit() {
    super.onInit();
    
    // Check if we're editing an existing book
    if (Get.arguments != null && Get.arguments['bookId'] != null) {
      loadBook(Get.arguments['bookId']);
    }
  }
  
  @override
  void onClose() {
    titleController.dispose();
    super.onClose();
  }
  
  Future<void> loadBook(String id) async {
    isLoading.value = true;
    hasError.value = false;
    
    try {
      book.value = await _bookRepository.getBook(id);
      
      if (book.value != null) {
        titleController.text = book.value!.title;
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
      final success = await _bookRepository.deleteBook(book.value!.id);
      
      if (success) {
        Get.back(result: {'deleted': true});
        
        Get.snackbar(
          'Success',
          'Book deleted successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        throw Exception('Failed to delete book');
      }
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
    
    // Implement page creation here
    // This will be connected to the existing note functionality
    print('Creating new page in book: ${book.value!.id}');
    
    // Placeholder for now - we'll integrate with the note system later
    Get.snackbar(
      'Coming Soon',
      'Page creation functionality will be added soon',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
} 