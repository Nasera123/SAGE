import 'package:uuid/uuid.dart';

class Book {
  final String id;
  String title;
  String? coverUrl;
  final DateTime createdAt;
  DateTime updatedAt;
  final String userId;
  String? userDisplayName; // Added for denormalization when showing published books
  List<String> pageIds; // IDs of pages in this book
  bool isDeleted;
  DateTime? deletedAt;
  bool isPublic; // Added for publication feature
  String? description; // Added for publication feature
  
  Book({
    String? id,
    required this.title,
    this.coverUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    required this.userId,
    this.userDisplayName,
    List<String>? pageIds,
    this.isDeleted = false,
    this.deletedAt,
    this.isPublic = false, // Default to private
    this.description,
  }) : 
    id = id ?? const Uuid().v4(),
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now(),
    pageIds = pageIds ?? [];
  
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'id': id,
      'title': title,
      'cover_url': coverUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'user_id': userId,
      'user_display_name': userDisplayName,
      'page_ids': pageIds,
      'is_deleted': isDeleted,
    };
    
    if (deletedAt != null) {
      data['deleted_at'] = deletedAt!.toIso8601String();
    }
    
    data['is_public'] = isPublic;
    
    // Hanya sertakan description jika nilai tidak null
    if (description != null) {
      data['description'] = description;
    }
    
    return data;
  }
  
  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'],
      title: json['title'],
      coverUrl: json['cover_url'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      userId: json['user_id'],
      userDisplayName: json['user_display_name'],
      pageIds: json['page_ids'] != null 
        ? List<String>.from(json['page_ids'])
        : [],
      isDeleted: json['is_deleted'] ?? false,
      deletedAt: json['deleted_at'] != null ? DateTime.parse(json['deleted_at']) : null,
      isPublic: json['is_public'] ?? false,
      description: json['description'],
    );
  }
  
  // Create a copy of the book with some properties modified
  Book copyWith({
    String? title,
    String? coverUrl,
    DateTime? updatedAt,
    String? userDisplayName,
    List<String>? pageIds,
    bool? isDeleted,
    DateTime? deletedAt,
    bool? isPublic,
    String? description,
  }) {
    return Book(
      id: this.id, // ID never changes
      title: title ?? this.title,
      coverUrl: coverUrl ?? this.coverUrl,
      createdAt: this.createdAt, // Creation time never changes
      updatedAt: updatedAt ?? DateTime.now(),
      userId: this.userId, // User ID never changes
      userDisplayName: userDisplayName ?? this.userDisplayName,
      pageIds: pageIds ?? List.from(this.pageIds),
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      isPublic: isPublic ?? this.isPublic,
      description: description ?? this.description,
    );
  }
  
  void update({
    String? title,
    String? coverUrl,
    String? description,
  }) {
    if (title != null) this.title = title;
    if (coverUrl != null) this.coverUrl = coverUrl;
    if (description != null) this.description = description;
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
  
  void moveToTrash() {
    isDeleted = true;
    deletedAt = DateTime.now();
    updatedAt = DateTime.now();
  }
  
  void restore() {
    isDeleted = false;
    deletedAt = null;
    updatedAt = DateTime.now();
  }
  
  void publish() {
    isPublic = true;
    updatedAt = DateTime.now();
  }
  
  void unpublish() {
    isPublic = false;
    updatedAt = DateTime.now();
  }
} 