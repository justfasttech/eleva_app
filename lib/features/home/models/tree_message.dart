class TreeMessage {
  final String id;
  final int level;
  final String name;
  final String message;
  final String? audioUrl;
  final String? audioFileName;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TreeMessage({
    required this.id,
    required this.level,
    required this.name,
    required this.message,
    this.audioUrl,
    this.audioFileName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TreeMessage.fromMap(Map<String, dynamic> map) {
    return TreeMessage(
      id: map['id'] as String,
      level: map['level'] as int,
      name: map['name'] as String,
      message: map['message'] as String,
      audioUrl: map['audio_url'] as String?,
      audioFileName: map['audio_file_name'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'level': level,
      'name': name,
      'message': message,
      'audio_url': audioUrl,
      'audio_file_name': audioFileName,
    };
  }
}
