class ScoringWord {
  final String id;
  final String word;
  final int points;
  final DateTime createdAt;

  const ScoringWord({
    required this.id,
    required this.word,
    required this.points,
    required this.createdAt,
  });

  factory ScoringWord.fromMap(Map<String, dynamic> map) {
    return ScoringWord(
      id: map['id'] as String,
      word: map['word'] as String,
      points: map['points'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'word': word,
      'points': points,
    };
  }
}
