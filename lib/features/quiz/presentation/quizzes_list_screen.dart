import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../models/quiz.dart';
import '../providers/quiz_provider.dart';
import '../../unlocks/providers/unlocks_provider.dart';
import 'quiz_play_screen.dart';

class QuizzesListScreen extends ConsumerStatefulWidget {
  final String? themeId;
  final String? themeName;

  const QuizzesListScreen({super.key, this.themeId, this.themeName});

  @override
  ConsumerState<QuizzesListScreen> createState() => _QuizzesListScreenState();
}

class _QuizzesListScreenState extends ConsumerState<QuizzesListScreen> {
  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Quiz>> quizzesAsync;
    if (widget.themeId != null) {
      quizzesAsync = ref.watch(quizzesByThemeProvider(widget.themeId));
    } else {
      quizzesAsync = ref.watch(quizzesProvider);
    }

    final unlockedIds = ref.watch(unlockedContentIdsProvider);
    final canUnlockAsync = ref.watch(canUnlockTodayProvider('quiz'));

    return Scaffold(
      backgroundColor: ElevaColors.white,
      appBar: AppBar(
        title: Text(
          widget.themeName != null
              ? 'Quizzes - ${widget.themeName}'
              : 'Quizzes',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
      ),
      body: quizzesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: ElevaColors.gold),
        ),
        error: (e, _) => Center(
          child: Text('Erro ao carregar quizzes: $e'),
        ),
        data: (quizzes) {
          final published = quizzes.where((q) => q.isPublished).toList();
          if (published.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.quiz_rounded, size: 48,
                      color: ElevaColors.textMuted.withValues(alpha: 0.4)),
                  const SizedBox(height: 12),
                  const Text(
                    'Nenhum quiz disponível',
                    style: TextStyle(fontSize: 15, color: ElevaColors.textMuted),
                  ),
                ],
              ),
            );
          }
          final unlocked = published
              .where((q) => unlockedIds.contains(q.id))
              .toList();
          final locked = published
              .where((q) => !unlockedIds.contains(q.id))
              .toList();
          final allItems = [...unlocked, ...locked];

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            itemCount: allItems.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final quiz = allItems[i];
              final isUnlocked = unlockedIds.contains(quiz.id);
              if (!isUnlocked) {
                return _LockedQuizCard(
                  quiz: quiz,
                  onTap: () =>
                      _handleLockedTap(context, quiz, canUnlockAsync),
                );
              }
              return _QuizCard(quiz: quiz);
            },
          );
        },
      ),
    );
  }

  void _handleLockedTap(
    BuildContext context,
    Quiz quiz,
    AsyncValue<bool> canUnlockAsync,
  ) {
    final canUnlock = canUnlockAsync.value ?? false;

    if (!canUnlock) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text(
                'Você já desbloqueou um quiz hoje. Volte amanhã após as 7h.'),
            backgroundColor: ElevaColors.textMuted,
          ),
        );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ElevaColors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Desbloquear quiz?',
            style: TextStyle(color: ElevaColors.textDark)),
        content: Text(
          '"${quiz.title}"\n\nVocê pode desbloquear 1 quiz por dia.',
          style: const TextStyle(color: ElevaColors.textMuted),
        ),
        actions: [
       
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await unlockContent(
                contentType: 'quiz',
                contentId: quiz.id,
                faithPoints: 0,
              );
              if (success && context.mounted) {
                ref.invalidate(canUnlockTodayProvider('quiz'));
                ref.invalidate(userUnlocksProvider);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => QuizPlayScreen(quiz: quiz),
                  ),
                );
              } else if (context.mounted) {
                ScaffoldMessenger.of(context)
                  ..clearSnackBars()
                  ..showSnackBar(
                    const SnackBar(
                      content: Text('Não foi possível desbloquear. Tente novamente.'),
                      backgroundColor: Colors.red,
                    ),
                  );
              }
            },
            child: const Text('Desbloquear'),
          ),          SizedBox(height:10),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }
}

class _QuizCard extends StatelessWidget {
  final Quiz quiz;

  const _QuizCard({required this.quiz});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ElevaColors.offWhite,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => QuizPlayScreen(quiz: quiz)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: ElevaColors.gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.quiz_rounded,
                    size: 22, color: ElevaColors.gold),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quiz.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: ElevaColors.textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${quiz.questions.length} pergunta${quiz.questions.length != 1 ? "s" : ""}',
                      style: const
                          TextStyle(fontSize: 12, color: ElevaColors.textMuted),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: ElevaColors.gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Quiz',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: ElevaColors.gold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded,
                  size: 20, color: ElevaColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _LockedQuizCard extends StatelessWidget {
  final Quiz quiz;
  final VoidCallback onTap;

  const _LockedQuizCard({required this.quiz, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ElevaColors.offWhite,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.lock_rounded,
                  size: 22, color: ElevaColors.textMuted),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quiz.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: ElevaColors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Toque para desbloquear',
                    style:
                        TextStyle(fontSize: 12, color: ElevaColors.textMuted),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.lock_rounded,
              size: 20,
              color: ElevaColors.textMuted.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}
