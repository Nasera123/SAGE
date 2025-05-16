import 'package:uuid/uuid.dart';

class Book {
  final String id;
  String title;
  String? coverUrl;
  final DateTime createdAt;
  DateTime updatedAt;
  final String userId;
  List<String> pageIds; // IDs of pages in this book
  
  Book({
    String? id,
    required this.title,
    this.coverUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    required this.userId,
    List<String>? pageIds,
  }) : 
    id = id ?? const Uuid().v4(),
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now(),
    pageIds = pageIds ?? [];
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'cover_url': coverUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'user_id': userId,
      'page_ids': pageIds,
    };
  }
  
  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'],
      title: json['title'],
      coverUrl: json['cover_url'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      userId: json['user_id'],
      pageIds: json['page_ids'] != null 
        ? List<String>.from(json['page_ids'])
        : [],
    );
  }
  
  void update({
    String? title,
    String? coverUrl,
  }) {
    if (title != null) this.title = title;
    if (coverUrl != null) this.coverUrl = coverUrl;
    updatedAt = DateTime.now();
  }
  
  void addPage(String pageId) {
    pageIds.add(pageId);
    updatedAt = DateTime.now();
  }
  
  void removePage(String pageId) {
    pageIds.remove(pageId);
    updatedAt = DateTime.now();
  }
} 