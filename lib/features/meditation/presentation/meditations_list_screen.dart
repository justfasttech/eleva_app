import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../models/meditation.dart';
import '../providers/meditation_provider.dart';
import '../../unlocks/providers/unlocks_provider.dart';
import 'meditation_player_screen.dart';

class MeditationsListScreen extends ConsumerStatefulWidget {
  final String? themeId;
  final String? themeName;

  const MeditationsListScreen({super.key, this.themeId, this.themeName});

  @override
  ConsumerState<MeditationsListScreen> createState() => _MeditationsListScreenState();
}

class _MeditationsListScreenState extends ConsumerState<MeditationsListScreen> {
  String? _selectedType;

  static const _typeFilters = [
    (value: null, label: 'Todos'),
    (value: 'guiada', label: 'Guiada'),
    (value: 'ambiente', label: 'Ambiente'),
  ];

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Meditation>> meditationsAsync;
    if (widget.themeId != null) {
      meditationsAsync = ref.watch(meditationsByThemeProvider(widget.themeId));
    } else {
      meditationsAsync = ref.watch(meditationsProvider);
    }

    final unlockedIds = ref.watch(unlockedContentIdsProvider);
    final canUnlockAsync = ref.watch(canUnlockTodayProvider('meditation'));

    return Scaffold(
      backgroundColor: ElevaColors.white,
      appBar: AppBar(
        title: Text(
          widget.themeName != null
              ? 'Meditações - ${widget.themeName}'
              : 'Meditações',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
      ),
      body: Column(
        children: [
          if (widget.themeId == null)
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _typeFilters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final filter = _typeFilters[i];
                  final selected = _selectedType == filter.value;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedType = filter.value),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected ? ElevaColors.gold : ElevaColors.offWhite,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        filter.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : ElevaColors.textMuted,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          if (widget.themeId == null) const SizedBox(height: 16),
          Expanded(
            child: meditationsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: ElevaColors.gold),
              ),
              error: (e, _) => Center(
                child: Text('Erro ao carregar meditações: $e'),
              ),
              data: (meditations) {
                var published = meditations.where((m) => m.isPublished).toList();
                if (_selectedType != null) {
                  published = published.where((m) => m.type == _selectedType).toList();
                }
                if (published.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.self_improvement_rounded, size: 48, color: ElevaColors.textMuted.withValues(alpha: 0.4)),
                        const SizedBox(height: 12),
                        const Text(
                          'Nenhuma meditação disponível',
                          style: TextStyle(fontSize: 15, color: ElevaColors.textMuted),
                        ),
                      ],
                    ),
                  );
                }

                final unlocked = published.where((m) => unlockedIds.contains(m.id)).toList();
                final locked = published.where((m) => !unlockedIds.contains(m.id)).toList();
                final allItems = [...unlocked, ...locked];

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: allItems.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final meditation = allItems[i];
                    final isUnlocked = unlockedIds.contains(meditation.id);
                    if (!isUnlocked) {
                      return _LockedMeditationCard(
                        meditation: meditation,
                        onTap: () => _handleLockedTap(context, meditation, canUnlockAsync),
                      );
                    }
                    return _MeditationCard(meditation: meditation);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _handleLockedTap(
    BuildContext context,
    Meditation meditation,
    AsyncValue<bool> canUnlockAsync,
  ) {
    final canUnlock = canUnlockAsync.value ?? false;

    if (!canUnlock) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text('Você já desbloqueou uma meditação hoje. Volte amanhã após as 7h.'),
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
        title: const Text('Desbloquear meditação?',
            style: TextStyle(color: ElevaColors.textDark)),
        content: Text(
          '"${meditation.title}"\n\nVocê pode desbloquear 1 meditação por dia.',
          style: const TextStyle(color: ElevaColors.textMuted),
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await unlockContent(
                contentType: 'meditation',
                contentId: meditation.id,
                faithPoints: meditation.faithPoints,
              );
              if (success && context.mounted) {
                ref.invalidate(canUnlockTodayProvider('meditation'));
                ref.invalidate(userUnlocksProvider);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MeditationPlayerScreen(meditation: meditation),
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
          ),
          SizedBox(height:10),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }
}

class _MeditationCard extends StatelessWidget {
  final Meditation meditation;

  const _MeditationCard({required this.meditation});

  @override
  Widget build(BuildContext context) {
    final isGuided = meditation.type == 'guiada';
    return Material(
      color: ElevaColors.offWhite,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MeditationPlayerScreen(meditation: meditation)),
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
                child: Icon(
                  isGuided ? Icons.self_improvement_rounded : Icons.waves_rounded,
                  size: 22,
                  color: ElevaColors.gold,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meditation.title,
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
                      '${meditation.durationLabel} · ${meditation.typeLabel}',
                      style: const TextStyle(fontSize: 12, color: ElevaColors.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: ElevaColors.gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  meditation.typeLabel,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: ElevaColors.gold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, size: 20, color: ElevaColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _LockedMeditationCard extends StatelessWidget {
  final Meditation meditation;
  final VoidCallback onTap;

  const _LockedMeditationCard({required this.meditation, required this.onTap});

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
                    meditation.title,
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
                    style: TextStyle(fontSize: 12, color: ElevaColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
