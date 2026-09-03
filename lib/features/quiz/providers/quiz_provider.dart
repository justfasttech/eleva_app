import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/quiz.dart';

final quizzesProvider = StreamProvider<List<Quiz>>((ref) {
  return Supabase.instance.client
      .from('quizzes')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false)
      .asyncMap((_) async {
    final rows = await Supabase.instance.client
        .from('quizzes')
        .select('*, quiz_questions(id)')
        .order('created_at', ascending: false);
    return rows.map((r) => Quiz.fromMap(r)).toList();
  });
});

final quizzesByThemeProvider =
    Provider.family<AsyncValue<List<Quiz>>, String?>((ref, themeId) {
  final all = ref.watch(quizzesProvider);
  if (themeId == null) return all;
  return all.whenData(
    (quizzes) => quizzes.where((q) => q.themeId == themeId).toList(),
  );
});

final quizWithQuestionsProvider =
    FutureProvider.family<Quiz, String>((ref, quizId) async {
  final data = await Supabase.instance.client
      .from('quizzes')
      .select('*, quiz_questions(*)')
      .eq('id', quizId)
      .single();
  return Quiz.fromMap(data);
});

final userQuizAttemptsProvider = StreamProvider<List<QuizAttempt>>((ref) {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return Stream.value([]);
  return Supabase.instance.client
      .from('quiz_attempts')
      .stream(primaryKey: ['id'])
      .eq('user_id', userId)
      .order('completed_at', ascending: false)
      .map((rows) => rows.map((r) => QuizAttempt.fromMap(r)).toList());
});

final completedQuizIdsProvider = Provider<Set<String>>((ref) {
  final attempts = ref.watch(userQuizAttemptsProvider).value ?? [];
  return attempts.map((a) => a.quizId).toSet();
});

final quizAttemptForProvider =
    Provider.family<QuizAttempt?, String>((ref, quizId) {
  final attempts = ref.watch(userQuizAttemptsProvider).value ?? [];
  final matches = attempts.where((a) => a.quizId == quizId);
  return matches.isNotEmpty ? matches.first : null;
});
