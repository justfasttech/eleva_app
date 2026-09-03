import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../models/quiz.dart';
import '../providers/quiz_provider.dart';

class QuizResultsScreen extends ConsumerWidget {
  final String quizId;
  final QuizAttempt attempt;

  const QuizResultsScreen({
    super.key,
    required this.quizId,
    required this.attempt,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quizAsync = ref.watch(quizWithQuestionsProvider(quizId));

    return Scaffold(
      backgroundColor: ElevaColors.offWhite,
      appBar: AppBar(
        backgroundColor: ElevaColors.gold,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Resultado do Quiz',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: quizAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (quiz) => _buildResults(context, quiz),
      ),
    );
  }

  Widget _buildResults(BuildContext context, Quiz quiz) {
    final total = quiz.questions.length;
    final percentage = total > 0 ? (attempt.correctCount / total * 100).round() : 0;
    final isGood = percentage >= 60;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: ElevaColors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: (isGood ? ElevaColors.gold : ElevaColors.textMuted)
                        .withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isGood ? Icons.emoji_events_rounded : Icons.school_rounded,
                    size: 32,
                    color: isGood ? ElevaColors.gold : ElevaColors.textMuted,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  quiz.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ElevaColors.textDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Acertou ${attempt.correctCount} de $total ($percentage%)',
                  style: const TextStyle(fontSize: 15, color: ElevaColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ...List.generate(quiz.questions.length, (i) {
            final q = quiz.questions[i];
            final userAnswer = attempt.answers[i.toString()] ?? '';
            final isCorrect = userAnswer == q.correctOption;

            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ElevaColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isCorrect
                      ? Colors.green.withValues(alpha: 0.3)
                      : Colors.red.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isCorrect
                              ? Colors.green.withValues(alpha: 0.12)
                              : Colors.red.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isCorrect ? Icons.check_rounded : Icons.close_rounded,
                          size: 16,
                          color: isCorrect ? Colors.green : Colors.red,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Pergunta ${i + 1}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: ElevaColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    q.questionText,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: ElevaColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...QuizQuestion.optionKeys.map((key) {
                    final text = q.optionText(key);
                    final isUserChoice = key == userAnswer;
                    final isCorrectOption = key == q.correctOption;

                    Color bg = ElevaColors.offWhite;
                    Color border = Colors.transparent;
                    Color textColor = ElevaColors.textDark;
                    IconData? icon;

                    if (isCorrectOption) {
                      bg = Colors.green.withValues(alpha: 0.08);
                      border = Colors.green.withValues(alpha: 0.4);
                      icon = Icons.check_circle_rounded;
                    }
                    if (isUserChoice && !isCorrect) {
                      bg = Colors.red.withValues(alpha: 0.08);
                      border = Colors.red.withValues(alpha: 0.4);
                      textColor = Colors.red;
                      icon = Icons.cancel_rounded;
                    }

                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: border, width: 1),
                      ),
                      child: Row(
                        children: [
                          Text(
                            '${key.toUpperCase()}) ',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              text,
                              style: TextStyle(fontSize: 13, color: textColor),
                            ),
                          ),
                          if (icon != null)
                            Icon(
                              icon,
                              size: 18,
                              color: isCorrectOption ? Colors.green : Colors.red,
                            ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
