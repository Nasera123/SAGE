import 'tag_model.dart' as tag_model;

class Note {
  final String id;
  final String userId;
  final String? folderId;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<tag_model.Tag> tags;

  Note({
    required this.id,
    required this.userId,
    this.folderId,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.tags = const [],
  });

  // Factory for an empty note
  factory Note.empty() {
    return Note(
      id: '',
      userId: '',
      folderId: null,
      title: '',
      content: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      tags: const [],
    );
  }

  factory Note.fromJson(Map<String, dynamic> json, {List<tag_model.Tag> tags = const []}) {
    return Note(
      id: json['id'],
      userId: json['user_id'],
      folderId: json['folder_id'],
      title: json['title'],
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      tags: tags,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'folder_id': folderId,
      'title': title,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // For creating a new note without id, createdAt and updatedAt
  Map<String, dynamic> toJsonForCreate() {
    return {
      'user_id': userId,
      'folder_id': folderId,
      'title': title,
      'content': content,
    };
  }

  Note copyWith({
    String? id,
    String? userId,
    String? folderId,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<tag_model.Tag>? tags,
  }) {
    return Note(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      folderId: folderId ?? this.folderId,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
    );
  }
}

class Tag {
  final String id;
  final String userId;
  final String name;
  final DateTime createdAt;

  Tag({
    required this.id,
    required this.userId,
    required this.name,
    required this.createdAt,
  });

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // For creating a new tag without id and createdAt
  Map<String, dynamic> toJsonForCreate() {
    return {
      'user_id': userId,
      'name': name,
    };
  }

  Tag copyWith({
    String? id,
    String? userId,
    String? name,
    DateTime? createdAt,
  }) {
    return Tag(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }
} 