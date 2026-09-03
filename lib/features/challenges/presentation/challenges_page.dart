import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../readings/models/spiritual_reading.dart';
import '../../readings/providers/readings_provider.dart';
import '../../readings/presentation/reading_detail_screen.dart';
import '../../meditation/models/meditation.dart';
import '../../meditation/providers/meditation_provider.dart';
import '../../meditation/presentation/meditation_player_screen.dart';
import '../../prayers/models/prayer.dart';
import '../../prayers/providers/prayers_provider.dart';
import '../../prayers/presentation/prayer_detail_screen.dart';
import '../../unlocks/providers/unlocks_provider.dart';
import '../../content_themes/providers/content_themes_provider.dart';
import '../../content_themes/presentation/theme_selection_screen.dart';
import '../../readings/presentation/readings_list_screen.dart';
import '../../meditation/presentation/meditations_list_screen.dart';
import '../../prayers/presentation/prayers_list_screen.dart';
import '../../quiz/providers/quiz_provider.dart';
import '../../quiz/presentation/quiz_results_screen.dart';

class ChallengesPage extends ConsumerWidget {
  const ChallengesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unlockedIds = ref.watch(unlockedContentIdsProvider);
    final canUnlockReading = ref.watch(canUnlockTodayProvider('reading'));
    final canUnlockMeditation = ref.watch(canUnlockTodayProvider('meditation'));
    final canUnlockPrayer = ref.watch(canUnlockTodayProvider('prayer'));

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Desafios de Fé',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: ElevaColors.textDark,
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Fortaleça sua fé com leituras, meditações e orações',
                style: TextStyle(fontSize: 14, color: ElevaColors.textMuted),
              ),
            ),
            const SizedBox(height: 20),

            // --- Leituras ---
            _buildSectionHeader(context, 'Leituras Espirituais', Icons.menu_book_rounded,
              onSeeAll: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ThemeSelectionScreen(contentType: 'reading')),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 150,
              child: ref.watch(spiritualReadingsProvider).when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: ElevaColors.gold),
                ),
                error: (_, __) => const Center(
                  child: Text('Erro ao carregar', style: TextStyle(color: ElevaColors.textMuted)),
                ),
                data: (readings) {
                  final published = readings.where((r) => r.isPublished).toList();
                  final unlocked = published.where((r) => unlockedIds.contains(r.id)).take(6).toList();
                  final locked = published.where((r) => !unlockedIds.contains(r.id)).take(3).toList();
                  final allItems = [...unlocked, ...locked];
                  if (allItems.isEmpty) {
                    return const Center(
                      child: Text('Em breve!', style: TextStyle(color: ElevaColors.textMuted)),
                    );
                  }
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(left: 24, right: 60),
                    clipBehavior: Clip.none,
                    itemCount: allItems.length,
                    itemBuilder: (context, i) {
                      final r = allItems[i];
                      if (!unlockedIds.contains(r.id)) {
                        return _LockedContentCard(
                          title: r.title,
                          onTap: () => _handleLockedReadingTap(context, ref, r, canUnlockReading),
                        );
                      }
                      return _ContentCard(
                        title: r.title,
                        subtitle: r.reference ?? r.categoryLabel,
                        icon: Icons.auto_stories_rounded,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ReadingDetailScreen(reading: r),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // --- Meditações ---
            _buildSectionHeader(context, 'Meditação', Icons.self_improvement_rounded,
              onSeeAll: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ThemeSelectionScreen(contentType: 'meditation')),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 150,
              child: ref.watch(meditationsProvider).when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: ElevaColors.gold),
                ),
                error: (_, __) => const Center(
                  child: Text('Erro ao carregar', style: TextStyle(color: ElevaColors.textMuted)),
                ),
                data: (meditations) {
                  final published = meditations.where((m) => m.isPublished).toList();
                  final unlocked = published.where((m) => unlockedIds.contains(m.id)).take(6).toList();
                  final locked = published.where((m) => !unlockedIds.contains(m.id)).take(3).toList();
                  final allItems = [...unlocked, ...locked];
                  if (allItems.isEmpty) {
                    return const Center(
                      child: Text('Em breve!', style: TextStyle(color: ElevaColors.textMuted)),
                    );
                  }
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(left: 24, right: 60),
                    clipBehavior: Clip.none,
                    itemCount: allItems.length,
                    itemBuilder: (context, i) {
                      final m = allItems[i];
                      if (!unlockedIds.contains(m.id)) {
                        return _LockedContentCard(
                          title: m.title,
                          onTap: () => _handleLockedMeditationTap(context, ref, m, canUnlockMeditation),
                        );
                      }
                      return _ContentCard(
                        title: m.title,
                        subtitle: '${m.durationLabel} · ${m.typeLabel}',
                        icon: m.type == 'guiada'
                            ? Icons.self_improvement_rounded
                            : Icons.waves_rounded,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MeditationPlayerScreen(meditation: m),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // --- Orações ---
            _buildSectionHeader(context, 'Orações', Icons.volunteer_activism_rounded,
              onSeeAll: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ThemeSelectionScreen(contentType: 'prayer')),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 150,
              child: ref.watch(prayersProvider).when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: ElevaColors.gold),
                ),
                error: (_, __) => const Center(
                  child: Text('Erro ao carregar', style: TextStyle(color: ElevaColors.textMuted)),
                ),
                data: (prayers) {
                  final published = prayers.where((p) => p.isPublished).toList();
                  final unlocked = published.where((p) => unlockedIds.contains(p.id)).take(6).toList();
                  final locked = published.where((p) => !unlockedIds.contains(p.id)).take(3).toList();
                  final allItems = [...unlocked, ...locked];
                  if (allItems.isEmpty) {
                    return const Center(
                      child: Text('Em breve!', style: TextStyle(color: ElevaColors.textMuted)),
                    );
                  }
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(left: 24, right: 60),
                    clipBehavior: Clip.none,
                    itemCount: allItems.length,
                    itemBuilder: (context, i) {
                      final p = allItems[i];
                      if (!unlockedIds.contains(p.id)) {
                        return _LockedContentCard(
                          title: p.title,
                          onTap: () => _handleLockedPrayerTap(context, ref, p, canUnlockPrayer),
                        );
                      }
                      return _ContentCard(
                        title: p.title,
                        subtitle: 'Oração',
                        icon: Icons.volunteer_activism_rounded,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PrayerDetailScreen(prayer: p),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // --- Quizzes Realizados ---
            Builder(builder: (context) {
              final attemptsAsync = ref.watch(userQuizAttemptsProvider);
              final quizzesAsync = ref.watch(quizzesProvider);
              final attempts = attemptsAsync.value ?? [];
              final quizzes = quizzesAsync.value ?? [];

              if (attempts.isEmpty) return const SizedBox.shrink();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(context, 'Quizzes Realizados', Icons.quiz_rounded),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 150,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(left: 24, right: 60),
                      clipBehavior: Clip.none,
                      itemCount: attempts.length,
                      itemBuilder: (context, i) {
                        final attempt = attempts[i];
                        final quiz = quizzes.where((q) => q.id == attempt.quizId);
                        final title = quiz.isNotEmpty ? quiz.first.title : 'Quiz';
                        final total = quiz.isNotEmpty ? quiz.first.questions.length : attempt.correctCount;

                        return _ContentCard(
                          title: title,
                          subtitle: '${attempt.correctCount}/${total > 0 ? total : '?'} acertos',
                          icon: Icons.emoji_events_rounded,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => QuizResultsScreen(
                                quizId: attempt.quizId,
                                attempt: attempt,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  void _handleLockedReadingTap(
    BuildContext context, WidgetRef ref,
    SpiritualReading reading, AsyncValue<bool> canUnlockAsync,
  ) {
    _showThemeSelectionDialog(context, ref, 'reading');
  }

  void _handleLockedMeditationTap(
    BuildContext context, WidgetRef ref,
    Meditation meditation, AsyncValue<bool> canUnlockAsync,
  ) {
    _showThemeSelectionDialog(context, ref, 'meditation');
  }

  void _handleLockedPrayerTap(
    BuildContext context, WidgetRef ref,
    Prayer prayer, AsyncValue<bool> canUnlockAsync,
  ) {
    _showThemeSelectionDialog(context, ref, 'prayer');
  }

  void _showThemeSelectionDialog(
    BuildContext context, WidgetRef ref, String contentType,
  ) {
    String title;
    IconData icon;
    switch (contentType) {
      case 'reading':
        title = 'Escolha um tema - Leituras';
        icon = Icons.auto_stories_rounded;
        break;
      case 'meditation':
        title = 'Escolha um tema - Meditações';
        icon = Icons.self_improvement_rounded;
        break;
      case 'prayer':
        title = 'Escolha um tema - Orações';
        icon = Icons.volunteer_activism_rounded;
        break;
      default:
        return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ElevaColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(color: ElevaColors.textDark, fontSize: 16, fontWeight: FontWeight.w600)),
        content: Consumer(
          builder: (context, ref, _) {
            final themes = ref.watch(contentThemesProvider);
            return themes.when(
              loading: () => const SizedBox(
                height: 80,
                child: Center(child: CircularProgressIndicator(color: ElevaColors.gold)),
              ),
              error: (e, _) => Text('Erro ao carregar temas: $e'),
              data: (themesList) {
                if (themesList.isEmpty) {
                  return const Text('Nenhum tema disponível', style: TextStyle(color: ElevaColors.textMuted));
                }
                return SizedBox(
                  width: double.maxFinite,
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: themesList.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final theme = themesList[i];
                      return ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: ElevaColors.gold.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(icon, color: ElevaColors.gold, size: 20),
                        ),
                        title: Text(
                          theme.name,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ElevaColors.textDark),
                        ),
                        subtitle: theme.description != null && theme.description!.isNotEmpty
                            ? Text(theme.description!, style: const TextStyle(fontSize: 12, color: ElevaColors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis)
                            : null,
                        trailing: const Icon(Icons.chevron_right_rounded, color: ElevaColors.textMuted, size: 20),
                        onTap: () {
                          Navigator.pop(ctx);
                          _navigateToFilteredList(context, contentType, theme.id, theme.name);
                        },
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  void _navigateToFilteredList(BuildContext context, String contentType, String themeId, String themeName) {
    Widget screen;
    switch (contentType) {
      case 'reading':
        screen = ReadingsListScreen(themeId: themeId, themeName: themeName);
        break;
      case 'meditation':
        screen = MeditationsListScreen(themeId: themeId, themeName: themeName);
        break;
      case 'prayer':
        screen = PrayersListScreen(themeId: themeId, themeName: themeName);
        break;
      default:
        return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon, {VoidCallback? onSeeAll}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Icon(icon, size: 20, color: ElevaColors.gold),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ElevaColors.textDark),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onSeeAll,
            child: const Text(
              'Ver todos',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: ElevaColors.gold),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContentCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;

  const _ContentCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ElevaColors.offWhite,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: ElevaColors.gold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 17, color: ElevaColors.gold),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ElevaColors.textDark),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: ElevaColors.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LockedContentCard extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;

  const _LockedContentCard({
    required this.title,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: 0.6,
        child: Container(
          width: 150,
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: ElevaColors.offWhite,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: ElevaColors.gold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.lock_rounded,
                    size: 17, color: ElevaColors.gold),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: ElevaColors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Toque para desbloquear',
                    style: TextStyle(fontSize: 10, color: ElevaColors.gold),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
