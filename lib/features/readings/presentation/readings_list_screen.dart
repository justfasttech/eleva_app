import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../models/spiritual_reading.dart';
import '../providers/readings_provider.dart';
import '../../unlocks/providers/unlocks_provider.dart';
import 'reading_detail_screen.dart';

class ReadingsListScreen extends ConsumerStatefulWidget {
  final String? initialCategory;
  final String? themeId;
  final String? themeName;

  const ReadingsListScreen({
    super.key,
    this.initialCategory,
    this.themeId,
    this.themeName,
  });

  @override
  ConsumerState<ReadingsListScreen> createState() => _ReadingsListScreenState();
}

class _ReadingsListScreenState extends ConsumerState<ReadingsListScreen> {
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
  }

  static const _categoryFilters = [
    (value: null, label: 'Todos'),
    (value: 'textos', label: 'Textos'),
    (value: 'parabolas', label: 'Parábolas'),
    (value: 'salmos', label: 'Salmos'),
    (value: 'versiculos', label: 'Versículos'),
    (value: 'sabedorias', label: 'Sabedorias'),
  ];

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<SpiritualReading>> readingsAsync;
    if (widget.themeId != null) {
      readingsAsync = ref.watch(readingsByThemeProvider(widget.themeId));
    } else {
      readingsAsync = ref.watch(readingsByCategoryProvider(_selectedCategory));
    }

    final unlockedIds = ref.watch(unlockedContentIdsProvider);
    final canUnlockAsync = ref.watch(canUnlockTodayProvider('reading'));

    return Scaffold(
      backgroundColor: ElevaColors.white,
      appBar: AppBar(
        title: Text(
          widget.themeName != null
              ? 'Leituras - ${widget.themeName}'
              : 'Leituras Espirituais',
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
                itemCount: _categoryFilters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final filter = _categoryFilters[i];
                  final selected = _selectedCategory == filter.value;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = filter.value),
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
            child: readingsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: ElevaColors.gold),
              ),
              error: (e, _) => Center(
                child: Text('Erro ao carregar leituras: $e'),
              ),
              data: (readings) {
                final published = readings.where((r) => r.isPublished).toList();
                if (published.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.menu_book_rounded, size: 48, color: ElevaColors.textMuted.withValues(alpha: 0.4)),
                        const SizedBox(height: 12),
                        const Text(
                          'Nenhuma leitura disponível',
                          style: TextStyle(fontSize: 15, color: ElevaColors.textMuted),
                        ),
                      ],
                    ),
                  );
                }
                final unlocked = published.where((r) => unlockedIds.contains(r.id)).toList();
                final locked = published.where((r) => !unlockedIds.contains(r.id)).toList();
                final allItems = [...unlocked, ...locked];

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: allItems.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final reading = allItems[i];
                    final isUnlocked = unlockedIds.contains(reading.id);
                    if (!isUnlocked) {
                      return _LockedReadingCard(
                        reading: reading,
                        onTap: () => _handleLockedTap(context, reading, canUnlockAsync),
                      );
                    }
                    return _ReadingCard(reading: reading);
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
    SpiritualReading reading,
    AsyncValue<bool> canUnlockAsync,
  ) {
    final canUnlock = canUnlockAsync.value ?? false;

    if (!canUnlock) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text('Você já desbloqueou uma leitura hoje. Volte amanhã após as 7h.'),
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
        title: const Text('Desbloquear leitura?',
            style: TextStyle(color: ElevaColors.textDark)),
        content: Text(
          '"${reading.title}"\n\nVocê pode desbloquear 1 leitura por dia.',
          style: const TextStyle(color: ElevaColors.textMuted),
        ),
        actions: [

          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await unlockContent(
                contentType: 'reading',
                contentId: reading.id,
                faithPoints: reading.faithPoints,
              );
              if (success && context.mounted) {
                ref.invalidate(canUnlockTodayProvider('reading'));
                ref.invalidate(userUnlocksProvider);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReadingDetailScreen(reading: reading),
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

class _ReadingCard extends StatelessWidget {
  final SpiritualReading reading;

  const _ReadingCard({required this.reading});

  IconData get _categoryIcon => switch (reading.category) {
    'textos' => Icons.auto_stories_rounded,
    'parabolas' => Icons.menu_book_rounded,
    'salmos' => Icons.music_note_rounded,
    'versiculos' => Icons.format_quote_rounded,
    'sabedorias' => Icons.lightbulb_rounded,
    _ => Icons.article_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ElevaColors.offWhite,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ReadingDetailScreen(reading: reading)),
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
                child: Icon(_categoryIcon, size: 22, color: ElevaColors.gold),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reading.title,
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
                      reading.reference ?? reading.categoryLabel,
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
                  reading.categoryLabel,
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

class _LockedReadingCard extends StatelessWidget {
  final SpiritualReading reading;
  final VoidCallback onTap;

  const _LockedReadingCard({required this.reading, required this.onTap});

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
                    reading.title,
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
