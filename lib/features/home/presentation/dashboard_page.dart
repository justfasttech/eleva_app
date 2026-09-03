import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme.dart';
import '../../auth/providers/user_profile_provider.dart';
import '../../notifications/providers/notifications_provider.dart';
import '../../verses/providers/verses_provider.dart';
import 'notifications_page.dart';
import 'widgets/daily_tasks.dart';
import 'widgets/faith_tree.dart';
import 'widgets/friends_trees.dart';
import 'widgets/weekly_chart.dart';
import 'all_friends_page.dart';
import '../../diary/presentation/new_entry_sheet.dart';
import 'home_screen.dart';
import '../../challenges/presentation/widgets/tree_achievement_dialog.dart';
import '../providers/faith_penalty_checker.dart';

const _weekDays = ['Domingo', 'Segunda-feira', 'Terça-feira', 'Quarta-feira', 'Quinta-feira', 'Sexta-feira', 'Sábado'];
const _months = ['Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho', 'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'];

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  int? _previousTreeLevel;
  bool _penaltyChecked = false;
  bool _diaryPopupChecked = false;

  void _checkPenalties() {
    if (_penaltyChecked) return;
    _penaltyChecked = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await FaithPenaltyChecker.check(ref);
    });
  }

  void _checkDiaryPopup() {
    if (_diaryPopupChecked) return;
    _diaryPopupChecked = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _showDiaryReminderIfNeeded();
    });
  }

  Future<void> _showDiaryReminderIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final shownKey = 'diary_popup_shown_$today';

    if (prefs.getBool(shownKey) == true) return;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final entries = await Supabase.instance.client
          .from('diary_entries')
          .select('id')
          .eq('user_id', userId)
          .gte('created_at', '${today}T00:00:00')
          .limit(1);

      if ((entries as List).isNotEmpty) return;
    } catch (_) {
      return;
    }

    await prefs.setBool(shownKey, true);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ElevaColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: ElevaColors.gold.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_stories_rounded,
                size: 32,
                color: ElevaColors.gold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Diário da Alma',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: ElevaColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Que tal reservar um momento para registrar seus pensamentos e sentimentos hoje? Escrever ajuda a fortalecer sua jornada espiritual.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: ElevaColors.textMuted,
                height: 1.5,
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _navigateToDiary();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ElevaColors.gold,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Escrever agora'),
          ),
          SizedBox(height:10),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Mais tarde',
              style: TextStyle(color: ElevaColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToDiary() {
    ref.read(homeTabIndexProvider.notifier).setIndex(1);
    showNewEntrySheet(context);
  }

  @override
  Widget build(BuildContext context) {
    _checkPenalties();
    _checkDiaryPopup();
    final profileAsync = ref.watch(userProfileProvider);
    final profile = profileAsync.value;
    final name = profile?.name ?? '';
    final faithPoints = profile?.faithLevel ?? 0;
    final currentTreeLevel = (faithPoints ~/ 5).clamp(0, 14);

    if (_previousTreeLevel != null &&
        currentTreeLevel > _previousTreeLevel! &&
        currentTreeLevel > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (_) => TreeAchievementDialog(level: currentTreeLevel),
          );
        }
      });
    }
    _previousTreeLevel = currentTreeLevel;

    final verse = ref.watch(todayVerseProvider);

    final now = DateTime.now();
    final weekDay = _weekDays[now.weekday % 7];
    final month = _months[now.month - 1];
    final dateLabel = '$weekDay, ${now.day} de $month';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  height: 36,
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: ElevaColors.offWhite,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    dateLabel,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: ElevaColors.gold,
                    ),
                  ),
                ),
                const Spacer(),
                Stack(
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const NotificationsPage(),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.notifications_outlined,
                        color: ElevaColors.textDark,
                        size: 26,
                      ),
                    ),
                    if (ref.watch(unreadCountProvider) > 0)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            '${ref.watch(unreadCountProvider)}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Olá, $name',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: ElevaColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: ElevaColors.offWhite,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.format_quote_rounded, color: ElevaColors.gold, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          verse?.text ?? 'Carregando...',
                          style: const TextStyle(
                            fontSize: 13,
                            color: ElevaColors.textDark,
                            fontStyle: FontStyle.italic,
                            height: 1.4,
                          ),
                        ),
                        if (verse != null && verse.source.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            verse.source,
                            style: const TextStyle(
                              fontSize: 12,
                              color: ElevaColors.gold,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            FaithTree(faithPoints: faithPoints),
            const SizedBox(height: 20),
            Row(
              children: [
                const Text(
                  'Árvores de amigos',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: ElevaColors.textDark,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AllFriendsPage(),
                      ),
                    );
                  },
                  child: Text(
                    'Ver todos',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: ElevaColors.gold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const FriendsTrees(),
            const SizedBox(height: 24),
            const DailyTasks(),
            const SizedBox(height: 24),
            const FaithLineChart(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

