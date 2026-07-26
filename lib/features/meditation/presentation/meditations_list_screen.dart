import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../models/meditation.dart';
import '../providers/meditation_provider.dart';
import 'meditation_player_screen.dart';

class MeditationsListScreen extends ConsumerStatefulWidget {
  const MeditationsListScreen({super.key});

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
    final meditationsAsync = ref.watch(meditationsProvider);

    return Scaffold(
      backgroundColor: ElevaColors.white,
      appBar: AppBar(
        title: const Text(
          'Meditações',
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
          const SizedBox(height: 16),
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
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: published.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => _MeditationCard(meditation: published[i]),
                );
              },
            ),
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
