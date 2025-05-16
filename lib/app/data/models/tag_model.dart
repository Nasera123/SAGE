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