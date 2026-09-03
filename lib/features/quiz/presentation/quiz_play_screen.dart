import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme.dart';
import '../models/quiz.dart';
import '../providers/quiz_provider.dart';
import 'quiz_results_screen.dart';

class QuizPlayScreen extends ConsumerStatefulWidget {
  final Quiz quiz;

  const QuizPlayScreen({super.key, required this.quiz});

  @override
  ConsumerState<QuizPlayScreen> createState() => _QuizPlayScreenState();
}

class _QuizPlayScreenState extends ConsumerState<QuizPlayScreen> {
  int _currentIndex = 0;
  String? _selectedOption;
  bool _answered = false;
  int _correctCount = 0;
  bool _finished = false;
  final Map<int, bool> _results = {};
  final Map<int, String> _userAnswers = {};
  bool _saved = false;

  static const _optionKeys = ['a', 'b', 'c', 'd'];

  void _selectOption(String key) {
    if (_answered) return;
    setState(() {
      _selectedOption = key;
    });
  }

  void _confirmAnswer(QuizQuestion question) {
    if (_selectedOption == null || _answered) return;
    final correct = _selectedOption == question.correctOption;
    setState(() {
      _answered = true;
      if (correct) _correctCount++;
      _results[_currentIndex] = correct;
      _userAnswers[_currentIndex] = _selectedOption!;
    });
  }

  void _nextQuestion(int totalQuestions) {
    if (_currentIndex + 1 >= totalQuestions) {
      setState(() => _finished = true);
      _saveAttempt();
    } else {
      setState(() {
        _currentIndex++;
        _selectedOption = null;
        _answered = false;
      });
    }
  }

  Future<void> _saveAttempt() async {
    if (_saved) return;
    _saved = true;
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      final questionsData = ref.read(quizWithQuestionsProvider(widget.quiz.id)).value;
      final questions = questionsData?.questions ?? [];
      final answersMap = _userAnswers.map((k, v) => MapEntry(k.toString(), v));
      double totalPoints = 0;
      for (final entry in _userAnswers.entries) {
        final idx = entry.key;
        final answer = entry.value;
        if (idx < questions.length) {
          final q = questions[idx];
          totalPoints += answer == q.correctOption
              ? q.faithPointsCorrect
              : q.faithPointsWrong;
        }
      }
      await Supabase.instance.client.from('quiz_attempts').insert({
        'user_id': userId,
        'quiz_id': widget.quiz.id,
        'correct_count': _correctCount,
        'total_points': totalPoints,
        'answers': answersMap,
      });
      if (totalPoints != 0) {
        await Supabase.instance.client.rpc('apply_faith_penalty', params: {
          'p_user_id': userId,
          'p_amount': totalPoints,
        });
      }
      ref.invalidate(userQuizAttemptsProvider);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final completedIds = ref.watch(completedQuizIdsProvider);
    final attempt = ref.watch(quizAttemptForProvider(widget.quiz.id));
    if (completedIds.contains(widget.quiz.id) && attempt != null && !_finished) {
      return QuizResultsScreen(quizId: widget.quiz.id, attempt: attempt);
    }
    final questionsAsync = ref.watch(quizWithQuestionsProvider(widget.quiz.id));

    return Scaffold(
      backgroundColor: ElevaColors.white,
      appBar: AppBar(
        title: Text(
          widget.quiz.title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
      ),
      body: questionsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: ElevaColors.gold),
        ),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (quizData) {
          final questions = quizData.questions;
          if (questions.isEmpty) {
            return const Center(
              child: Text('Este quiz ainda não tem perguntas.',
                  style: TextStyle(color: ElevaColors.textMuted)),
            );
          }

          if (_finished) return _buildResultScreen(questions);
          return _buildQuestionScreen(questions[_currentIndex], questions.length);
        },
      ),
    );
  }

  Widget _buildQuestionScreen(QuizQuestion question, int total) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: ElevaColors.gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Pergunta ${_currentIndex + 1} de $total',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: ElevaColors.gold,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '$_correctCount acerto${_correctCount != 1 ? 's' : ''}',
                style: const TextStyle(fontSize: 13, color: ElevaColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_currentIndex + 1) / total,
              backgroundColor: ElevaColors.offWhite,
              valueColor: const AlwaysStoppedAnimation<Color>(ElevaColors.gold),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            question.questionText,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: ElevaColors.textDark,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          ...List.generate(4, (i) {
            final key = _optionKeys[i];
            final text = question.optionText(key);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _OptionButton(
                label: key.toUpperCase(),
                text: text,
                isSelected: _selectedOption == key,
                isCorrect: key == question.correctOption,
                showResult: _answered,
                onTap: () => _selectOption(key),
              ),
            );
          }),
          const Spacer(),
          if (_selectedOption != null && !_answered)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _confirmAnswer(question),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ElevaColors.gold,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Confirmar'),
              ),
            ),
          if (_answered)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _nextQuestion(total),
                child: Text(
                  _currentIndex + 1 >= total ? 'Ver resultado' : 'Próxima pergunta',
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResultScreen(List<QuizQuestion> questions) {
    final total = questions.length;
    final percentage = (_correctCount / total * 100).round();
    final isGood = percentage >= 60;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: (isGood ? ElevaColors.gold : ElevaColors.textMuted)
                    .withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isGood ? Icons.emoji_events_rounded : Icons.refresh_rounded,
                size: 40,
                color: isGood ? ElevaColors.gold : ElevaColors.textMuted,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isGood ? 'Parabéns!' : 'Continue estudando!',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: ElevaColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Você acertou $_correctCount de $total perguntas ($percentage%)',
              style: const TextStyle(fontSize: 16, color: ElevaColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final attempt = ref.read(quizAttemptForProvider(widget.quiz.id));
                  if (attempt != null) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => QuizResultsScreen(
                          quizId: widget.quiz.id,
                          attempt: attempt,
                        ),
                      ),
                    );
                  }
                },
                child: const Text('Ver resultados'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Voltar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionButton extends StatelessWidget {
  final String label;
  final String text;
  final bool isSelected;
  final bool isCorrect;
  final bool showResult;
  final VoidCallback onTap;

  const _OptionButton({
    required this.label,
    required this.text,
    required this.isSelected,
    required this.isCorrect,
    required this.showResult,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color borderColor;
    Color textColor;

    if (showResult) {
      if (isCorrect) {
        bgColor = Colors.green.withValues(alpha: 0.1);
        borderColor = Colors.green;
        textColor = Colors.green.shade700;
      } else if (isSelected && !isCorrect) {
        bgColor = Colors.red.withValues(alpha: 0.1);
        borderColor = Colors.red;
        textColor = Colors.red.shade700;
      } else {
        bgColor = ElevaColors.offWhite;
        borderColor = Colors.transparent;
        textColor = ElevaColors.textMuted;
      }
    } else if (isSelected) {
      bgColor = ElevaColors.gold.withValues(alpha: 0.1);
      borderColor = ElevaColors.gold;
      textColor = ElevaColors.textDark;
    } else {
      bgColor = ElevaColors.offWhite;
      borderColor = Colors.transparent;
      textColor = ElevaColors.textDark;
    }

    return GestureDetector(
      onTap: showResult ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: showResult && isCorrect
                    ? Colors.green.withValues(alpha: 0.2)
                    : showResult && isSelected && !isCorrect
                        ? Colors.red.withValues(alpha: 0.2)
                        : ElevaColors.gold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: showResult && isCorrect
                    ? const Icon(Icons.check_rounded, size: 18, color: Colors.green)
                    : showResult && isSelected && !isCorrect
                        ? const Icon(Icons.close_rounded, size: 18, color: Colors.red)
                        : Text(
                            label,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: ElevaColors.gold,
                            ),
                          ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
