import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get/get.dart';
import '../constants.dart';

class SupabaseService extends GetxService {
  late final SupabaseClient _client;
  SupabaseClient get client => _client;

  // Static instance for singleton access
  static SupabaseService? _instance;
  static SupabaseService get instance {
    if (_instance == null) {
      throw Exception('SupabaseService not initialized. Call initialize() first.');
    }
    return _instance!;
  }

  // Static initialize method called from main.dart
  static Future<SupabaseService> initialize() async {
    if (_instance == null) {
      final service = SupabaseService();
      await service._init();
      _instance = service;
      // Register in GetX for dependency injection
      Get.put<SupabaseService>(_instance!, permanent: true);
    }
    return _instance!;
  }

  // Private init method
  Future<void> _init() async {
    try {
      await Supabase.initialize(
        url: AppConstants.supabaseUrl,
        anonKey: AppConstants.supabaseAnonKey,
      );
      _client = Supabase.instance.client;
      print('SupabaseService initialized successfully');
    } catch (e) {
      print('Error initializing Supabase: $e');
      rethrow;
    }
  }

  // Cleanup method to properly dispose of resources
  @override
  void onClose() {
    try {
      // Remove all active realtime subscriptions
      _client.removeAllChannels();
      print('Successfully unsubscribed from all Supabase realtime channels');
    } catch (e) {
      print('Error during Supabase cleanup: $e');
    }
    super.onClose();
  }

  // Helper method to safely handle subscription
  RealtimeChannel safelySubscribe(RealtimeChannel channel) {
    try {
      channel.subscribe((status, error) {
        if (error != null) {
          print('Error connecting to channel: $error');
        } else {
          print('Connected to channel: $status');
        }
      });
      return channel;
    } catch (e) {
      print('Error subscribing to channel: $e');
      // Return the unsubscribed channel so further operations won't fail
      return channel;
    }
  }

  // Auth methods
  Future<AuthResponse> signUp({required String email, required String password}) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signIn({required String email, required String password}) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  User? get currentUser => _client.auth.currentUser;

  bool get isAuthenticated => currentUser != null;

  // Subscribe to auth state changes
  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  // Database operations
  PostgrestFilterBuilder get folders => _client.from('folders').select();
  PostgrestFilterBuilder get notes => _client.from('notes').select();
  PostgrestFilterBuilder get tags => _client.from('tags').select();
  PostgrestFilterBuilder get noteTags => _client.from('note_tags').select();

  // Realtime subscriptions
  RealtimeChannel subscribeFolderChanges({
    required String userId, 
    Function(PostgresChangePayload)? callback
  }) {
    try {
      final channel = _client
          .channel('public:folders:${userId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'folders',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: userId,
            ),
            callback: callback ?? (payload) {
              print('Folder change detected: ${payload.eventType} - ${payload.newRecord?['id']}');
          },
          );
      
      return safelySubscribe(channel);
    } catch (e) {
      print('Error creating folder subscription: $e');
      rethrow;
    }
  }

  RealtimeChannel subscribeNoteChanges({
    required String userId, 
    Function(PostgresChangePayload)? callback
  }) {
    try {
      final channel = _client
          .channel('public:notes:${userId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notes',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: userId,
            ),
            callback: callback ?? (payload) {
              print('Note change detected: ${payload.eventType} - ${payload.newRecord?['id']}');
          },
          );
      
      return safelySubscribe(channel);
    } catch (e) {
      print('Error creating note subscription: $e');
      rethrow;
    }
  }

  RealtimeChannel subscribeTagChanges({
    required String userId, 
    Function(PostgresChangePayload)? callback
  }) {
    try {
      final channel = _client
          .channel('public:tags:${userId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'tags',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: userId,
            ),
            callback: callback ?? (payload) {
              print('Tag change detected: ${payload.eventType} - ${payload.newRecord?['id']}');
          },
          );
      
      return safelySubscribe(channel);
    } catch (e) {
      print('Error creating tag subscription: $e');
      rethrow;
    }
  }

  RealtimeChannel subscribeNoteTagChanges({
    Function(PostgresChangePayload)? callback
  }) {
    try {
      final userId = currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      
      final channel = _client
          .channel('public:note_tags:${userId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'note_tags',
            callback: callback ?? (payload) {
              print('Note tag change detected: ${payload.eventType} - ${payload.newRecord?['note_id']}');
          },
          );
      
      return safelySubscribe(channel);
    } catch (e) {
      print('Error creating note tag subscription: $e');
      rethrow;
    }
  }
} 