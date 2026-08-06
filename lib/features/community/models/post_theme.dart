class PostTheme {
  final String id;
  final String name;
  final DateTime createdAt;

  const PostTheme({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  factory PostTheme.fromMap(Map<String, dynamic> map) {
    return PostTheme(
      id: map['id'] as String,
      name: map['name'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name};
  }
}
