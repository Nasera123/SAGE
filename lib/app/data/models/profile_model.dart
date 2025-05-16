import 'package:get/get.dart';

class Profile {
  final String id;
  final String? fullName;
  final String? avatarUrl;
  final DateTime? updatedAt;
  final DateTime? createdAt;
  
  Profile({
    required this.id,
    this.fullName,
    this.avatarUrl,
    this.updatedAt,
    this.createdAt,
  });
  
  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'],
      fullName: json['full_name'],
      avatarUrl: json['avatar_url'],
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'updated_at': updatedAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
    };
  }
  
  Profile copyWith({
    String? id,
    String? fullName,
    String? avatarUrl,
    DateTime? updatedAt,
    DateTime? createdAt,
  }) {
    return Profile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
} 