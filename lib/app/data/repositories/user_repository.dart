import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import 'package:get/get.dart';

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
    required String fullName,
    String? avatarUrl,
  }) async {
    final User? currentUser = _supabaseService.client.auth.currentUser;
    if (currentUser == null) return null;

    await _supabaseService.client.from('profiles').upsert({
      'id': currentUser.id,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'updated_at': DateTime.now().toIso8601String(),
    });

    return _supabaseService.client.auth.currentUser;
  }
  
  Future<Map<String, dynamic>?> getUserProfile() async {
    final User? currentUser = _supabaseService.client.auth.currentUser;
    if (currentUser == null) return null;

    final response = await _supabaseService.client
        .from('profiles')
        .select('*')
        .eq('id', currentUser.id)
        .single();

    return response;
  }
} 