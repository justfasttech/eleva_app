class SpiritualReading {
  final String id;
  final String title;
  final String content;
  final String category;
  final String? author;
  final String? reference;
  final int faithPoints;
  final int level;
  final bool isPublished;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SpiritualReading({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    this.author,
    this.reference,
    required this.faithPoints,
    this.level = 1,
    required this.isPublished,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SpiritualReading.fromMap(Map<String, dynamic> map) {
    return SpiritualReading(
      id: map['id'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      category: map['category'] as String,
      author: map['author'] as String?,
      reference: map['reference'] as String?,
      faithPoints: map['faith_points'] as int? ?? 1,
      level: map['level'] as int? ?? 1,
      isPublished: map['is_published'] as bool? ?? true,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'category': category,
      'author': author,
      'reference': reference,
      'faith_points': faithPoints,
      'level': level,
      'is_published': isPublished,
    };
  }

  static const categories = <String, ({String label, String icon})>{
    'textos': (label: 'Textos', icon: 'auto_stories'),
    'parabolas': (label: 'Parábolas', icon: 'menu_book'),
    'salmos': (label: 'Salmos', icon: 'music_note'),
    'versiculos': (label: 'Versículos', icon: 'format_quote'),
    'sabedorias': (label: 'Sabedorias', icon: 'lightbulb'),
  };

  String get categoryLabel => categories[category]?.label ?? category;
}
