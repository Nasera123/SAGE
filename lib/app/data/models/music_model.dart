import 'package:uuid/uuid.dart';

class Music {
  final String id;
  final String userId;
  final String title;
  final String artist;
  final String url;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;
  final DateTime? deletedAt;

  Music({
    String? id,
    required this.userId,
    required this.title,
    required this.artist,
    required this.url,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isDeleted = false,
    this.deletedAt,
  }) : 
    id = id ?? const Uuid().v4(),
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now();

  factory Music.fromJson(Map<String, dynamic> json) {
    return Music(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      artist: json['artist'],
      url: json['url'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      isDeleted: json['is_deleted'] ?? false,
      deletedAt: json['deleted_at'] != null ? DateTime.parse(json['deleted_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'artist': artist,
      'url': url,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_deleted': isDeleted,
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  // For creating a new music without id, createdAt and updatedAt
  Map<String, dynamic> toJsonForCreate() {
    return {
      'user_id': userId,
      'title': title,
      'artist': artist,
      'url': url,
      'is_deleted': isDeleted,
    };
  }

  Music copyWith({
    String? id,
    String? userId,
    String? title,
    String? artist,
    String? url,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
    DateTime? deletedAt,
  }) {
    return Music(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      url: url ?? this.url,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
} 