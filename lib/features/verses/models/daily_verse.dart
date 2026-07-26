class DailyVerse {
  final String id;
  final String message;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DailyVerse({
    required this.id,
    required this.message,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DailyVerse.fromMap(Map<String, dynamic> map) {
    return DailyVerse(
      id: map['id'] as String,
      message: map['message'] as String,
      isActive: map['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'message': message,
      'is_active': isActive,
    };
  }

  String get text {
    final idx = message.lastIndexOf(' — ');
    return idx > 0 ? message.substring(0, idx).trim() : message;
  }

  String get source {
    final idx = message.lastIndexOf(' — ');
    return idx > 0 ? message.substring(idx + 3).trim() : '';
  }
}
