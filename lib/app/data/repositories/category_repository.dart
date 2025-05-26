import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../models/category_model.dart';

class CategoryRepository extends GetxService {
  final SupabaseService _supabaseService = Get.find<SupabaseService>();
  
  SupabaseClient get client => _supabaseService.client;
  
  // Get all categories
  Future<List<Category>> getAllCategories() async {
    try {
      final response = await _supabaseService.client
          .from('categories')
          .select('*')
          .order('name');
      
      return response.map<Category>((json) => Category.fromJson(json)).toList();
    } catch (e) {
      print('Error getting categories: $e');
      return [];
    }
  }
  
  // Get categories for a specific book
  Future<List<Category>> getBookCategories(String bookId) async {
    try {
      final response = await _supabaseService.client
          .from('book_categories')
          .select('category_id, categories(*)')
          .eq('book_id', bookId);
      
      return response.map<Category>((json) => Category.fromJson(json['categories'])).toList();
    } catch (e) {
      print('Error getting book categories: $e');
      return [];
    }
  }
  
  // Add a category to a book
  Future<bool> addCategoryToBook(String bookId, String categoryId) async {
    final User? currentUser = _supabaseService.client.auth.currentUser;
    if (currentUser == null) return false;
    
    try {
      await _supabaseService.client
          .from('book_categories')
          .insert({
            'book_id': bookId,
            'category_id': categoryId
          });
      
      return true;
    } catch (e) {
      print('Error adding category to book: $e');
      return false;
    }
  }
  
  // Remove a category from a book
  Future<bool> removeCategoryFromBook(String bookId, String categoryId) async {
    final User? currentUser = _supabaseService.client.auth.currentUser;
    if (currentUser == null) return false;
    
    try {
      await _supabaseService.client
          .from('book_categories')
          .delete()
          .eq('book_id', bookId)
          .eq('category_id', categoryId);
      
      return true;
    } catch (e) {
      print('Error removing category from book: $e');
      return false;
    }
  }
  
  // Create a new category
  Future<Category?> createCategory(Category category) async {
    final User? currentUser = _supabaseService.client.auth.currentUser;
    if (currentUser == null) return null;
    
    try {
      final Map<String, dynamic> categoryData = {
        'id': category.id,
        'name': category.name,
        'created_at': category.createdAt.toIso8601String(),
        'updated_at': category.updatedAt.toIso8601String(),
      };
      
      // Add description if provided
      if (category.description != null) {
        categoryData['description'] = category.description;
      }
      
      final response = await _supabaseService.client
          .from('categories')
          .insert(categoryData)
          .select()
          .single();
      
      return Category.fromJson(response);
    } catch (e) {
      print('Error creating category: $e');
      return null;
    }
  }
} 