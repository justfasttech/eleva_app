class DiaryEntry {
  final String id;
  final String userId;
  final String title;
  final String content;
  final String mood;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DiaryEntry({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.mood,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DiaryEntry.fromMap(Map<String, dynamic> map) {
    return DiaryEntry(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      title: map['title'] as String? ?? '',
      content: map['content'] as String,
      mood: map['mood'] as String? ?? 'neutral',
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'title': title,
      'content': content,
      'mood': mood,
    };
  }

  static const moods = <String, ({String emoji, String label})>{
    'happy': (emoji: '😊', label: 'Feliz'),
    'grateful': (emoji: '🙏', label: 'Grato(a)'),
    'peaceful': (emoji: '😌', label: 'Em paz'),
    'reflective': (emoji: '🤔', label: 'Reflexivo(a)'),
    'sad': (emoji: '😢', label: 'Triste'),
    'anxious': (emoji: '😰', label: 'Ansioso(a)'),
    'hopeful': (emoji: '🌟', label: 'Esperançoso(a)'),
    'loved': (emoji: '💛', label: 'Amado(a)'),
    'neutral': (emoji: '😐', label: 'Neutro'),
  };

  String get moodEmoji => moods[mood]?.emoji ?? '😐';
  String get moodLabel => moods[mood]?.label ?? 'Neutro';
}
