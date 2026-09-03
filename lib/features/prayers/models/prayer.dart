class Prayer {
  final String id;
  final String title;
  final String content;
  final String themeId;
  final String? audioUrl;
  final String? audioFileName;
  final String? videoUrl;
  final String? videoFileName;
  final double faithPoints;
  final bool isPublished;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Prayer({
    required this.id,
    required this.title,
    required this.content,
    required this.themeId,
    this.audioUrl,
    this.audioFileName,
    this.videoUrl,
    this.videoFileName,
    required this.faithPoints,
    required this.isPublished,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Prayer.fromMap(Map<String, dynamic> map) {
    return Prayer(
      id: map['id'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      themeId: map['theme_id'] as String,
      audioUrl: map['audio_url'] as String?,
      audioFileName: map['audio_file_name'] as String?,
      videoUrl: map['video_url'] as String?,
      videoFileName: map['video_file_name'] as String?,
      faithPoints: (map['faith_points'] as num?)?.toDouble() ?? 1.0,
      isPublished: map['is_published'] as bool? ?? true,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'theme_id': themeId,
      'audio_url': audioUrl,
      'audio_file_name': audioFileName,
      'video_url': videoUrl,
      'video_file_name': videoFileName,
      'faith_points': faithPoints,
      'is_published': isPublished,
    };
  }

  bool get hasAudio => audioUrl != null && audioUrl!.isNotEmpty;
  bool get hasVideo => videoUrl != null && videoUrl!.isNotEmpty;
}
