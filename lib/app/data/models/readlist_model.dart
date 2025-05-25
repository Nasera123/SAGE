import 'package:uuid/uuid.dart';
import 'book_model.dart';

class ReadlistItem {
  final String id;
  final String bookId;
  final String userId;
  final DateTime addedAt;
  Book? book;
  
  ReadlistItem({
    String? id,
    required this.bookId,
    required this.userId,
    DateTime? addedAt,
    this.book,
  }) : 
    id = id ?? const Uuid().v4(),
    addedAt = addedAt ?? DateTime.now();
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'book_id': bookId,
      'user_id': userId,
      'added_at': addedAt.toIso8601String(),
    };
  }
  
  factory ReadlistItem.fromJson(Map<String, dynamic> json, {Book? bookData}) {
    return ReadlistItem(
      id: json['id'],
      bookId: json['book_id'],
      userId: json['user_id'],
      addedAt: DateTime.parse(json['added_at']),
      book: bookData,
    );
  }
} 