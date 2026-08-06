import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../auth/providers/user_profile_provider.dart';
import '../../readings/providers/readings_provider.dart';
import '../../readings/presentation/reading_detail_screen.dart';
import '../../readings/presentation/readings_list_screen.dart';
import '../../meditation/providers/meditation_provider.dart';
import '../../meditation/presentation/meditation_player_screen.dart';
import '../../meditation/presentation/meditations_list_screen.dart';

class ChallengesPage extends ConsumerWidget {
  const ChallengesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                'Fortaleça sua fé com leituras e meditações',
                style: TextStyle(fontSize: 14, color: ElevaColors.textMuted),
              ),
            ),
            const SizedBox(height: 20),

            _buildSectionHeader(context, 'Leituras Espirituais', Icons.menu_book_rounded,
              onSeeAll: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReadingsListScreen()),
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
                  final profile = ref.watch(userProfileProvider).value;
                  final faithLevel = profile?.faithLevel ?? 0;
                  final userReadingLevel = ((faithLevel ~/ 10) + 1).clamp(1, 7);
                  final published = readings.where((r) => r.isPublished).toList();
                  final unlocked = published.where((r) => r.level <= userReadingLevel).take(6).toList();
                  final locked = published.where((r) => r.level > userReadingLevel).take(3).toList();
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
                      if (r.level > userReadingLevel) {
                        return _LockedContentCard(
                          title: r.title,
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

            _buildSectionHeader(context, 'Meditação', Icons.self_improvement_rounded,
              onSeeAll: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MeditationsListScreen()),
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
                  final published = meditations.where((m) => m.isPublished).take(6).toList();
                  if (published.isEmpty) {
                    return const Center(
                      child: Text('Em breve!', style: TextStyle(color: ElevaColors.textMuted)),
                    );
                  }
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(left: 24, right: 60),
                    clipBehavior: Clip.none,
                    itemCount: published.length,
                    itemBuilder: (context, i) {
                      final m = published[i];
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
          ],
        ),
      ),
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

  const _LockedContentCard({required this.title});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.5,
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
                color: Colors.grey.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.lock_rounded,
                  size: 17, color: ElevaColors.textMuted),
            ),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Será desbloqueada',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: ElevaColors.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2),
                Text(
                  'no futuro',
                  style: TextStyle(fontSize: 11, color: ElevaColors.textMuted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

