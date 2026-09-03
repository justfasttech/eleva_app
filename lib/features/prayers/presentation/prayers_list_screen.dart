import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../models/prayer.dart';
import '../providers/prayers_provider.dart';
import '../../unlocks/providers/unlocks_provider.dart';
import 'prayer_detail_screen.dart';

class PrayersListScreen extends ConsumerWidget {
  final String? themeId;
  final String? themeName;

  const PrayersListScreen({super.key, this.themeId, this.themeName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prayersAsync = ref.watch(prayersByThemeProvider(themeId));
    final unlockedIds = ref.watch(unlockedContentIdsProvider);
    final canUnlockAsync = ref.watch(canUnlockTodayProvider('prayer'));

    return Scaffold(
      backgroundColor: ElevaColors.offWhite,
      appBar: AppBar(
        backgroundColor: ElevaColors.gold,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          themeName != null ? 'Orações - $themeName' : 'Orações',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: prayersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (prayers) {
          final published = prayers.where((p) => p.isPublished).toList();
          if (published.isEmpty) {
            return const Center(
              child: Text(
                'Nenhuma oração disponível neste tema',
                style: TextStyle(fontSize: 14, color: ElevaColors.textMuted),
              ),
            );
          }

          final unlocked = published.where((p) => unlockedIds.contains(p.id)).toList();
          final locked = published.where((p) => !unlockedIds.contains(p.id)).toList();
          final sorted = [...unlocked, ...locked];

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: sorted.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final prayer = sorted[i];
              final isUnlocked = unlockedIds.contains(prayer.id);

              return GestureDetector(
                onTap: () {
                  if (isUnlocked) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PrayerDetailScreen(prayer: prayer),
                      ),
                    );
                  } else {
                    _handleLockedTap(context, ref, prayer, canUnlockAsync);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: ElevaColors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isUnlocked
                              ? ElevaColors.gold.withValues(alpha: 0.12)
                              : Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isUnlocked
                              ? Icons.volunteer_activism_rounded
                              : Icons.lock_rounded,
                          color: isUnlocked
                              ? ElevaColors.gold
                              : ElevaColors.textMuted,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              prayer.title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: isUnlocked
                                    ? ElevaColors.textDark
                                    : ElevaColors.textMuted,
                              ),
                            ),
                            if (!isUnlocked)
                              const Text(
                                'Toque para desbloquear',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: ElevaColors.textMuted,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _handleLockedTap(
    BuildContext context,
    WidgetRef ref,
    Prayer prayer,
    AsyncValue<bool> canUnlockAsync,
  ) {
    final canUnlock = canUnlockAsync.value ?? false;

    if (!canUnlock) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text('Você já desbloqueou uma oração hoje. Volte amanhã após as 7h.'),
            backgroundColor: ElevaColors.textMuted,
          ),
        );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ElevaColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Desbloquear oração?',
            style: TextStyle(color: ElevaColors.textDark)),
        content: Text(
          '"${prayer.title}"\n\nVocê pode desbloquear 1 oração por dia.',
          style: const TextStyle(color: ElevaColors.textMuted),
        ),
        actions: [
        
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await unlockContent(
                contentType: 'prayer',
                contentId: prayer.id,
                faithPoints: prayer.faithPoints,
              );
              if (success && context.mounted) {
                ref.invalidate(canUnlockTodayProvider('prayer'));
                ref.invalidate(userUnlocksProvider);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PrayerDetailScreen(prayer: prayer),
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
