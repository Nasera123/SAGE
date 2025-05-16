import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import 'package:get/get.dart';
import '../models/profile_model.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

class UserRepository {
  final SupabaseService _supabaseService = Get.find<SupabaseService>();

  SupabaseClient get client => _supabaseService.client;
  
  Stream<AuthState> get onAuthStateChange => _supabaseService.onAuthStateChange;

  User? get currentUser => _supabaseService.currentUser;

  bool get isAuthenticated => _supabaseService.isAuthenticated;

  Future<AuthResponse> signUp({required String email, required String password}) async {
    try {
      return await _supabaseService.signUp(email: email, password: password);
    } catch (e) {
      print('Error signing up: $e');
      rethrow;
    }
  }

  Future<AuthResponse> signIn({required String email, required String password}) async {
    try {
      return await _supabaseService.signIn(email: email, password: password);
    } catch (e) {
      print('Error signing in: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _supabaseService.signOut();
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }

  Future<User?> getCurrentUser() async {
    return _supabaseService.client.auth.currentUser;
  }

  Future<User?> updateUserProfile({
    String? fullName,
    String? avatarUrl,
  }) async {
    final User? currentUser = _supabaseService.client.auth.currentUser;
    if (currentUser == null) return null;

    try {
      Map<String, dynamic> profileData = {
        'id': currentUser.id,
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      if (fullName != null) {
        profileData['full_name'] = fullName;
      }
      
      if (avatarUrl != null) {
        profileData['avatar_url'] = avatarUrl;
      }

      // Check if profile exists first
      try {
        await _supabaseService.client
            .from('profiles')
            .select('id')
            .eq('id', currentUser.id)
            .single();
      } catch (e) {
        // Profile doesn't exist, create it with default values
        await _supabaseService.client.from('profiles').insert({
          'id': currentUser.id,
          'full_name': fullName ?? '',
          'avatar_url': avatarUrl ?? '',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
        return currentUser;
      }

      // Profile exists, update it
      await _supabaseService.client.from('profiles').upsert(profileData);
      return currentUser;
    } catch (e) {
      print('Error updating profile: $e');
      rethrow;
    }
  }
  
  Future<String?> uploadProfileImage(File imageFile) async {
    try {
      final User? currentUser = _supabaseService.client.auth.currentUser;
      if (currentUser == null) {
        print('Cannot upload image: User not logged in');
        return null;
      }
      
      print('Starting image upload for user: ${currentUser.id}');
      print('Original image path: ${imageFile.path}');
      
      // Create a unique file name
      final fileExt = path.extension(imageFile.path);
      final fileName = '${currentUser.id}_profile$fileExt';
      print('Generated filename: $fileName');
      
      // Verify file exists and check size
      if (!await imageFile.exists()) {
        print('Error: Image file does not exist at path: ${imageFile.path}');
        return null;
      }
      
      final fileSize = await imageFile.length();
      print('File size: $fileSize bytes');
      
      if (fileSize > 5 * 1024 * 1024) {
        print('Error: File too large (${fileSize} bytes)');
        return null;
      }
      
      // Simplified upload - always use the same filename for a user
      // Makes it easier to update and retrieve
      print('Uploading to Supabase storage...');
      
      // Use simpler upload method
      await _supabaseService.client
          .storage
          .from('avatars')
          .upload(
            fileName,
            imageFile, 
            fileOptions: const FileOptions(
              cacheControl: '0',
              upsert: true
            )
          );
      
      print('Upload completed successfully');
      
      // Get the public URL with a cache-busting parameter
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final String publicUrl = _supabaseService.client
          .storage
          .from('avatars')
          .getPublicUrl(fileName) + '?t=$timestamp';
      
      print('Generated public URL: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('Error uploading profile image: $e');
      print('Stack trace: ${StackTrace.current}');
      return null;
    }
  }
  
  Future<Profile?> getUserProfile() async {
    final User? currentUser = _supabaseService.client.auth.currentUser;
    if (currentUser == null) return null;

    try {
      final response = await _supabaseService.client
          .from('profiles')
          .select('*')
          .eq('id', currentUser.id)
          .single();

      return Profile.fromJson(response);
    } catch (e) {
      print('Error getting user profile: $e');
      
      // If profile doesn't exist, create a default one
      if (e.toString().contains('404')) {
        try {
          // Create default profile
          final defaultProfile = {
            'id': currentUser.id,
            'full_name': '',
            'avatar_url': '',
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          };
          
          await _supabaseService.client.from('profiles').insert(defaultProfile);
          
          return Profile.fromJson(defaultProfile);
        } catch (insertError) {
          print('Error creating default profile: $insertError');
          return null;
        }
      }
      
      return null;
    }
  }
} 