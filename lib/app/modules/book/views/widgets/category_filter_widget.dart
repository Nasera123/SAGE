import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/category_controller.dart';
import '../../../../data/models/category_model.dart';
import '../../controllers/public_library_controller.dart';

class CategoryFilterWidget extends StatelessWidget {
  final bool isPublic;
  final CategoryController categoryController;
  
  const CategoryFilterWidget({
    Key? key,
    this.isPublic = false,
    required this.categoryController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text(
            'Categories',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Obx(() {
          if (categoryController.isLoading.value) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          if (categoryController.categories.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No categories available'),
            );
          }
          
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                // "All" filter chip
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: const Text('All'),
                    selected: categoryController.selectedCategoryId.value.isEmpty,
                    onSelected: (selected) {
                      if (selected) {
                        categoryController.clearFilter();
                        // Refresh main book list if public library controller exists
                        if (isPublic && Get.isRegistered<PublicLibraryController>()) {
                          final publicController = Get.find<PublicLibraryController>();
                          publicController.resetAndRefresh();
                        }
                      }
                    },
                  ),
                ),
                ...categoryController.categories.map((category) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      label: Text(category.name),
                      selected: categoryController.selectedCategoryId.value == category.id,
                      onSelected: (selected) {
                        if (selected) {
                          if (isPublic) {
                            categoryController.filterPublicBooksByCategory(category.id);
                          } else {
                            categoryController.filterBooksByCategory(category.id);
                          }
                        } else if (categoryController.selectedCategoryId.value == category.id) {
                          categoryController.clearFilter();
                          // Refresh main book list if public library controller exists
                          if (isPublic && Get.isRegistered<PublicLibraryController>()) {
                            final publicController = Get.find<PublicLibraryController>();
                            publicController.resetAndRefresh();
                          }
                        }
                      },
                    ),
                  );
                }).toList(),
              ],
            ),
          );
        }),
        const Divider(),
      ],
    );
  }
}

// Book category selection widget for adding/removing categories from a book
class BookCategorySelectionWidget extends StatelessWidget {
  final String bookId;
  final CategoryController categoryController;
  
  const BookCategorySelectionWidget({
    Key? key,
    required this.bookId,
    required this.categoryController,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    // Load book categories when widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      categoryController.loadBookCategories(bookId);
    });
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Categories',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Obx(() {
          if (categoryController.isLoading.value) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          if (categoryController.categories.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No categories available'),
            );
          }
          
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: categoryController.categories.map((category) {
                    final isSelected = categoryController.bookCategories.any((c) => c.id == category.id);
                    
                    return FilterChip(
                      label: Text(category.name),
                      selected: isSelected,
                      onSelected: (selected) async {
                        if (selected) {
                          await categoryController.addCategoryToBook(bookId, category.id);
                        } else {
                          await categoryController.removeCategoryFromBook(bookId, category.id);
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('New Category'),
                  onPressed: () => _showAddCategoryDialog(context),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
  
  // Show dialog to add a new category
  void _showAddCategoryDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Category Name',
                hintText: 'Enter category name',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Enter category description',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                Get.snackbar(
                  'Error',
                  'Category name cannot be empty',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
                return;
              }
              
              final description = descriptionController.text.trim().isNotEmpty 
                  ? descriptionController.text.trim() 
                  : null;
              
              final success = await categoryController.createCategory(name, description: description);
              
              Navigator.of(context).pop();
              
              if (success) {
                Get.snackbar(
                  'Success',
                  'Category created successfully',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
              } else {
                Get.snackbar(
                  'Error',
                  'Failed to create category',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
} 