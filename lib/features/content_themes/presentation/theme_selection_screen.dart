import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../providers/content_themes_provider.dart';
import '../../unlocks/providers/unlocks_provider.dart';
import '../../readings/presentation/readings_list_screen.dart';
import '../../meditation/presentation/meditations_list_screen.dart';
import '../../prayers/presentation/prayers_list_screen.dart';
import '../../quiz/presentation/quizzes_list_screen.dart';

class ThemeSelectionScreen extends ConsumerWidget {
  final String contentType;

  const ThemeSelectionScreen({super.key, required this.contentType});

  String get _title {
    switch (contentType) {
      case 'reading':
        return 'Escolha um tema - Leituras';
      case 'meditation':
        return 'Escolha um tema - Meditações';
      case 'prayer':
        return 'Escolha um tema - Orações';
      default:
        return 'Escolha um tema';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themesAsync = ref.watch(contentThemesProvider);
    final canUnlockAsync = ref.watch(canUnlockTodayProvider(contentType));

    return Scaffold(
      backgroundColor: ElevaColors.offWhite,
      appBar: AppBar(
        backgroundColor: ElevaColors.gold,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: ElevaColors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: canUnlockAsync.when(
              loading: () => const SizedBox(
                height: 20,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              error: (_, __) => const SizedBox.shrink(),
              data: (canUnlock) => Row(
                children: [
                  Icon(
                    canUnlock
                        ? Icons.lock_open_rounded
                        : Icons.lock_clock_rounded,
                    size: 20,
                    color: canUnlock ? ElevaColors.gold : ElevaColors.textMuted,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      canUnlock
                          ? '1 desbloqueio disponível hoje'
                          : 'Já desbloqueou hoje. Volte amanhã após as 7h',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: canUnlock
                            ? ElevaColors.textDark
                            : ElevaColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: themesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text('Erro ao carregar temas: $e',
                    style: const TextStyle(color: ElevaColors.textMuted)),
              ),
              data: (themes) {
                if (themes.isEmpty) {
                  return const Center(
                    child: Text(
                      'Nenhum tema disponível',
                      style: TextStyle(
                          fontSize: 16, color: ElevaColors.textMuted),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: themes.length,
                  itemBuilder: (context, i) {
                    final theme = themes[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: () => _navigateToContent(context, theme.id, theme.name),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: ElevaColors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                theme.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: ElevaColors.textDark,
                                ),
                              ),
                              if (theme.description != null &&
                                  theme.description!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    theme.description!,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: ElevaColors.textMuted,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToContent(BuildContext context, String themeId, String themeName) {
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
      case 'quiz':
        screen = QuizzesListScreen(themeId: themeId, themeName: themeName);
        break;
      default:
        return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }
}
