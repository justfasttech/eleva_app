class ContentTheme {
  final String id;
  final String name;
  final String? description;
  final String? iconName;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ContentTheme({
    required this.id,
    required this.name,
    this.description,
    this.iconName,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ContentTheme.fromMap(Map<String, dynamic> map) {
    return ContentTheme(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      iconName: map['icon_name'] as String?,
      isActive: map['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'icon_name': iconName,
      'is_active': isActive,
    };
  }
}
