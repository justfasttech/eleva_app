class DailyTask {
  final String id;
  final String title;
  final double faithPoints;
  final bool isActive;
  final String frequency;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DailyTask({
    required this.id,
    required this.title,
    required this.faithPoints,
    required this.isActive,
    this.frequency = 'daily',
    required this.createdAt,
    required this.updatedAt,
  });

  factory DailyTask.fromMap(Map<String, dynamic> map) {
    return DailyTask(
      id: map['id'] as String,
      title: map['title'] as String,
      faithPoints: (map['faith_points'] as num?)?.toDouble() ?? 1.0,
      isActive: map['is_active'] as bool? ?? true,
      frequency: map['frequency'] as String? ?? 'daily',
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'faith_points': faithPoints,
      'is_active': isActive,
      'frequency': frequency,
    };
  }

  bool get isDaily => frequency == 'daily';
  bool get isWeekly => frequency == 'weekly';
  String get frequencyLabel => isDaily ? 'Diária' : 'Semanal';
}
