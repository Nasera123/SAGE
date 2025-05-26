import 'package:uuid/uuid.dart';

class Category {
  final String id;
  final String name;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  Category({
    String? id,
    required this.name,
    this.description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : 
    this.id = id ?? const Uuid().v4(),
    this.createdAt = createdAt ?? DateTime.now(),
    this.updatedAt = updatedAt ?? DateTime.now();

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
} 