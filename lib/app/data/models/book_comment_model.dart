import 'package:uuid/uuid.dart';

class BookComment {
  final String id;
  final String bookId;
  final String userId;
  final String userDisplayName;
  final String? userAvatarUrl;
  final String content;
  final DateTime createdAt;
  final bool isRead;
  
  BookComment({
    String? id,
    required this.bookId,
    required this.userId,
    required this.userDisplayName,
    this.userAvatarUrl,
    required this.content,
    DateTime? createdAt,
    this.isRead = false,
  }) : 
    id = id ?? const Uuid().v4(),
    createdAt = createdAt ?? DateTime.now();
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'book_id': bookId,
      'user_id': userId,
      'user_display_name': userDisplayName,
      'user_avatar_url': userAvatarUrl,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
    };
  }
  
  factory BookComment.fromJson(Map<String, dynamic> json) {
    return BookComment(
      id: json['id'],
      bookId: json['book_id'],
      userId: json['user_id'],
      userDisplayName: json['user_display_name'] ?? 'Anonymous',
      userAvatarUrl: json['user_avatar_url'],
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
      isRead: json['is_read'] ?? false,
    );
  }
} 