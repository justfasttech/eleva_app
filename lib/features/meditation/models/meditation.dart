class Meditation {
  final String id;
  final String title;
  final String? description;
  final int durationMinutes;
  final String type;
  final String? audioUrl;
  final String? audioFileName;
  final String? videoUrl;
  final String? videoFileName;
  final double faithPoints;
  final String themeId;
  final bool isPublished;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Meditation({
    required this.id,
    required this.title,
    this.description,
    required this.durationMinutes,
    required this.type,
    this.audioUrl,
    this.audioFileName,
    this.videoUrl,
    this.videoFileName,
    required this.faithPoints,
    required this.themeId,
    required this.isPublished,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Meditation.fromMap(Map<String, dynamic> map) {
    return Meditation(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      durationMinutes: map['duration_minutes'] as int? ?? 0,
      type: map['type'] as String,
      audioUrl: map['audio_url'] as String?,
      audioFileName: map['audio_file_name'] as String?,
      videoUrl: map['video_url'] as String?,
      videoFileName: map['video_file_name'] as String?,
      faithPoints: (map['faith_points'] as num?)?.toDouble() ?? 1.0,
      themeId: map['theme_id'] as String? ?? '',
      isPublished: map['is_published'] as bool? ?? true,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'duration_minutes': durationMinutes,
      'type': type,
      'audio_url': audioUrl,
      'audio_file_name': audioFileName,
      'video_url': videoUrl,
      'video_file_name': videoFileName,
      'faith_points': faithPoints,
      'theme_id': themeId,
      'is_published': isPublished,
    };
  }

  String get typeLabel => type == 'guiada' ? 'Sessão guiada' : 'Sons ambiente';
  String get durationLabel => '$durationMinutes min';
  bool get hasAudio => audioUrl != null && audioUrl!.isNotEmpty;
  bool get hasVideo => videoUrl != null && videoUrl!.isNotEmpty;
  bool get hasMedia => hasAudio || hasVideo;
}
