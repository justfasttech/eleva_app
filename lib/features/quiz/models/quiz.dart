class QuizQuestion {
  final String id;
  final String quizId;
  final String questionText;
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;
  final String correctOption;
  final int orderIndex;
  final double faithPointsCorrect;
  final double faithPointsWrong;

  const QuizQuestion({
    required this.id,
    required this.quizId,
    required this.questionText,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
    required this.correctOption,
    required this.orderIndex,
    this.faithPointsCorrect = 1.0,
    this.faithPointsWrong = 0.0,
  });

  factory QuizQuestion.fromMap(Map<String, dynamic> map) {
    return QuizQuestion(
      id: map['id'] as String,
      quizId: map['quiz_id'] as String? ?? '',
      questionText: map['question_text'] as String? ?? '',
      optionA: map['option_a'] as String? ?? '',
      optionB: map['option_b'] as String? ?? '',
      optionC: map['option_c'] as String? ?? '',
      optionD: map['option_d'] as String? ?? '',
      correctOption: map['correct_option'] as String? ?? 'a',
      orderIndex: map['order_index'] as int? ?? 0,
      faithPointsCorrect: (map['faith_points_correct'] as num?)?.toDouble() ?? 1.0,
      faithPointsWrong: (map['faith_points_wrong'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'quiz_id': quizId,
      'question_text': questionText,
      'option_a': optionA,
      'option_b': optionB,
      'option_c': optionC,
      'option_d': optionD,
      'correct_option': correctOption,
      'order_index': orderIndex,
      'faith_points_correct': faithPointsCorrect,
      'faith_points_wrong': faithPointsWrong,
    };
  }

  String optionText(String key) {
    switch (key) {
      case 'a': return optionA;
      case 'b': return optionB;
      case 'c': return optionC;
      case 'd': return optionD;
      default: return '';
    }
  }

  static const List<String> optionKeys = ['a', 'b', 'c', 'd'];
}

class Quiz {
  final String id;
  final String title;
  final String themeId;
  final double faithPointsCorrect;
  final double faithPointsWrong;
  final bool isPublished;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<QuizQuestion> questions;

  const Quiz({
    required this.id,
    required this.title,
    required this.themeId,
    required this.faithPointsCorrect,
    required this.faithPointsWrong,
    required this.isPublished,
    required this.createdAt,
    required this.updatedAt,
    this.questions = const [],
  });

  factory Quiz.fromMap(Map<String, dynamic> map) {
    List<QuizQuestion> questions = [];
    if (map['quiz_questions'] is List) {
      final list = map['quiz_questions'] as List;
      questions = list
          .map((q) => QuizQuestion.fromMap(q as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    }

    return Quiz(
      id: map['id'] as String,
      title: map['title'] as String? ?? '',
      themeId: map['theme_id'] as String? ?? '',
      faithPointsCorrect: (map['faith_points_correct'] as num?)?.toDouble() ?? 3.0,
      faithPointsWrong: (map['faith_points_wrong'] as num?)?.toDouble() ?? -1.0,
      isPublished: map['is_published'] as bool? ?? true,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? '') ?? DateTime.now(),
      questions: questions,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'theme_id': themeId,
      'faith_points_correct': faithPointsCorrect,
      'faith_points_wrong': faithPointsWrong,
      'is_published': isPublished,
    };
  }

  Quiz copyWith({List<QuizQuestion>? questions}) {
    return Quiz(
      id: id,
      title: title,
      themeId: themeId,
      faithPointsCorrect: faithPointsCorrect,
      faithPointsWrong: faithPointsWrong,
      isPublished: isPublished,
      createdAt: createdAt,
      updatedAt: updatedAt,
      questions: questions ?? this.questions,
    );
  }
}

class QuizAttempt {
  final String id;
  final String userId;
  final String quizId;
  final int correctCount;
  final double totalPoints;
  final Map<String, String> answers;
  final DateTime completedAt;

  const QuizAttempt({
    required this.id,
    required this.userId,
    required this.quizId,
    required this.correctCount,
    required this.totalPoints,
    required this.answers,
    required this.completedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'quiz_id': quizId,
      'correct_count': correctCount,
      'total_points': totalPoints,
      'answers': answers,
    };
  }

  factory QuizAttempt.fromMap(Map<String, dynamic> map) {
    final rawAnswers = map['answers'];
    final Map<String, String> answers = {};
    if (rawAnswers is Map) {
      for (final entry in rawAnswers.entries) {
        answers[entry.key.toString()] = entry.value.toString();
      }
    }

    return QuizAttempt(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      quizId: map['quiz_id'] as String,
      correctCount: map['correct_count'] as int? ?? 0,
      totalPoints: (map['total_points'] as num?)?.toDouble() ?? 0.0,
      answers: answers,
      completedAt: DateTime.parse(map['completed_at'] as String),
    );
  }
}
