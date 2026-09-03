import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/theme.dart';
import '../../../tasks/providers/tasks_provider.dart';

class DailyTasks extends ConsumerStatefulWidget {
  const DailyTasks({super.key});

  @override
  ConsumerState<DailyTasks> createState() => _DailyTasksState();
}

class _DailyTasksState extends ConsumerState<DailyTasks> {
  final Set<String> _completedDailyIds = {};
  final Set<String> _completedWeeklyIds = {};
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadCompletedTasks();
  }

  static String _currentWeekKey() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return monday.toIso8601String().substring(0, 10);
  }

  Future<void> _loadCompletedTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final weekKey = _currentWeekKey();

    final savedDate = prefs.getString('tasks_date');
    if (savedDate != today) {
      await prefs.setString('tasks_date', today);
      await prefs.setStringList('completed_tasks', []);
    } else {
      final saved = prefs.getStringList('completed_tasks') ?? [];
      _completedDailyIds.addAll(saved);
    }

    final savedWeek = prefs.getString('tasks_week');
    if (savedWeek != weekKey) {
      await prefs.setString('tasks_week', weekKey);
      await prefs.setStringList('completed_weekly_tasks', []);
    } else {
      final saved = prefs.getStringList('completed_weekly_tasks') ?? [];
      _completedWeeklyIds.addAll(saved);
    }

    if (mounted) setState(() => _loaded = true);
  }

  Future<void> _completeTask(String taskId, {bool weekly = false}) async {
    final ids = weekly ? _completedWeeklyIds : _completedDailyIds;
    if (ids.contains(taskId)) return;

    setState(() => ids.add(taskId));

    final prefs = await SharedPreferences.getInstance();
    final key = weekly ? 'completed_weekly_tasks' : 'completed_tasks';
    await prefs.setStringList(key, ids.toList());
  }

  @override
  Widget build(BuildContext context) {
    final dailyAsync = ref.watch(dailyTasksProvider);
    final weeklyAsync = ref.watch(weeklyTasksProvider);

    if (!_loaded) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSection(
          title: 'Tarefas aconselháveis',
          icon: Icons.star_rounded,
          tasksAsync: dailyAsync,
          completedIds: _completedDailyIds,
          weekly: false,
        ),
        const SizedBox(height: 20),
        _buildSection(
          title: 'Tarefas da semana',
          icon: Icons.date_range_rounded,
          tasksAsync: weeklyAsync,
          completedIds: _completedWeeklyIds,
          weekly: true,
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required AsyncValue tasksAsync,
    required Set<String> completedIds,
    required bool weekly,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: ElevaColors.gold),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: ElevaColors.textDark,
              ),
            ),
            const Spacer(),
            tasksAsync.when(
              data: (tasks) {
                final List active = (tasks as List).where((t) => t.isActive).toList();
                final completed = active.where((t) => completedIds.contains(t.id)).length;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: ElevaColors.offWhite,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$completed/${active.length}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ElevaColors.gold),
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
        const SizedBox(height: 12),
        tasksAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: CircularProgressIndicator(color: ElevaColors.gold),
            ),
          ),
          error: (_, __) => const Text(
            'Erro ao carregar tarefas',
            style: TextStyle(fontSize: 13, color: ElevaColors.textMuted),
          ),
          data: (tasks) {
            final List active = (tasks as List).where((t) => t.isActive).toList();
            if (active.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Nenhuma tarefa disponível',
                  style: TextStyle(fontSize: 13, color: ElevaColors.textMuted),
                ),
              );
            }
            return Column(
              children: active.map((task) {
                final done = completedIds.contains(task.id);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: done ? ElevaColors.gold.withValues(alpha: 0.08) : ElevaColors.offWhite,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: done ? null : () => _completeTask(task.id, weekly: weekly),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: done
                                    ? ElevaColors.gold.withValues(alpha: 0.2)
                                    : ElevaColors.gold.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.task_alt_rounded, size: 18, color: ElevaColors.gold),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                task.title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: done ? ElevaColors.gold : ElevaColors.textDark,
                                  decoration: done ? TextDecoration.lineThrough : null,
                                ),
                              ),
                            ),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: done ? ElevaColors.gold : Colors.transparent,
                                border: Border.all(
                                  color: done ? ElevaColors.gold : ElevaColors.textMuted.withValues(alpha: 0.4),
                                  width: 1.5,
                                ),
                              ),
                              child: done
                                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
