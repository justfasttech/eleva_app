import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../models/diary_entry.dart';
import '../providers/diary_provider.dart';
import 'entry_detail_page.dart';
import 'new_entry_sheet.dart';

const _months = [
  'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
  'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
];

String _monthYearLabel(DateTime dt) => '${_months[dt.month - 1]} ${dt.year}';

String _formatDate(DateTime dt) {
  final now = DateTime.now();
  final diff = now.difference(dt);
  if (diff.inMinutes < 1) return 'Agora';
  if (diff.inMinutes < 60) return 'Há ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'Há ${diff.inHours}h';
  if (diff.inDays == 1) return 'Ontem';
  return '${dt.day}/${dt.month.toString().padLeft(2, '0')}';
}

class DiaryPage extends ConsumerWidget {
  const DiaryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diaryAsync = ref.watch(diaryEntriesProvider);

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Diário da Alma',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: ElevaColors.textDark,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Registre seus sentimentos e reflexões',
                            style: TextStyle(
                              fontSize: 14,
                              color: ElevaColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => showNewEntrySheet(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: ElevaColors.gold,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          color: ElevaColors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          Expanded(
            child: diaryAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: ElevaColors.gold),
              ),
              error: (e, _) => Center(
                child: Text(
                  'Erro ao carregar: $e',
                  style: const TextStyle(color: ElevaColors.textMuted),
                ),
              ),
              data: (entries) {
                if (entries.isEmpty) return _EmptyState();
                return _EntryList(entries: entries);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: ElevaColors.gold.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.edit_note_rounded,
              size: 40,
              color: ElevaColors.gold,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Nenhum registro ainda',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: ElevaColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Comece escrevendo como você\nestá se sentindo hoje',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: ElevaColors.textMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 60),
            child: ElevatedButton.icon(
              onPressed: () => showNewEntrySheet(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Nova reflexão'),
            ),
          ),
        ],
      ),
    );
  }
}

class _EntryList extends StatelessWidget {
  final List<DiaryEntry> entries;

  const _EntryList({required this.entries});

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<DiaryEntry>>{};
    for (final entry in entries) {
      final key = _monthYearLabel(entry.createdAt);
      grouped.putIfAbsent(key, () => []).add(entry);
    }

    final sections = grouped.entries.toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: sections.length,
      itemBuilder: (context, sectionIndex) {
        final section = sections[sectionIndex];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(
                top: sectionIndex > 0 ? 20 : 0,
                bottom: 12,
              ),
              child: Text(
                section.key,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: ElevaColors.gold,
                ),
              ),
            ),
            ...section.value.map(
              (entry) => _DiaryEntryCard(entry: entry),
            ),
          ],
        );
      },
    );
  }
}

class _DiaryEntryCard extends StatelessWidget {
  final DiaryEntry entry;

  const _DiaryEntryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EntryDetailPage(entry: entry),
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: ElevaColors.offWhite,
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: ElevaColors.gold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    entry.moodEmoji,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title.isNotEmpty ? entry.title : 'Sem título',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: entry.title.isNotEmpty
                            ? ElevaColors.textDark
                            : ElevaColors.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          entry.moodLabel,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: ElevaColors.gold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '·',
                          style: TextStyle(
                            fontSize: 11,
                            color: ElevaColors.textMuted,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(entry.createdAt),
                          style: const TextStyle(
                            fontSize: 11,
                            color: ElevaColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: ElevaColors.textMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
