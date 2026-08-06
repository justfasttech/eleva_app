import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../auth/providers/user_profile_provider.dart';
import '../models/spiritual_reading.dart';
import '../providers/readings_provider.dart';
import 'reading_detail_screen.dart';

class ReadingsListScreen extends ConsumerStatefulWidget {
  final String? initialCategory;

  const ReadingsListScreen({super.key, this.initialCategory});

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
    final readingsAsync = ref.watch(readingsByCategoryProvider(_selectedCategory));
    final profile = ref.watch(userProfileProvider).value;
    final faithLevel = profile?.faithLevel ?? 0;
    final userReadingLevel = ((faithLevel ~/ 10) + 1).clamp(1, 7);

    return Scaffold(
      backgroundColor: ElevaColors.white,
      appBar: AppBar(
        title: const Text(
          'Leituras Espirituais',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
      ),
      body: Column(
        children: [
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
          const SizedBox(height: 16),
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
                final unlocked = published.where((r) => r.level <= userReadingLevel).toList();
                final locked = published.where((r) => r.level > userReadingLevel).toList();
                final allItems = [...unlocked, ...locked];

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: allItems.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final reading = allItems[i];
                    if (reading.level > userReadingLevel) {
                      return _LockedReadingCard(reading: reading);
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

  const _LockedReadingCard({required this.reading});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.5,
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
                    'Será desbloqueada no futuro',
                    style: TextStyle(fontSize: 12, color: ElevaColors.textMuted),
                  ),
                ],
              ),
            ),
            const Icon(Icons.lock_outline_rounded,
                size: 18, color: ElevaColors.textMuted),
          ],
        ),
      ),
    );
  }
}
