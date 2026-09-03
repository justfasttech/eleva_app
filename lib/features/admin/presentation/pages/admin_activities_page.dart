import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../tasks/models/daily_task.dart';
import '../../../tasks/providers/tasks_provider.dart';
import '../widgets/admin_prayers_tab.dart';

class AdminActivitiesPage extends StatefulWidget {
  const AdminActivitiesPage({super.key});

  @override
  State<AdminActivitiesPage> createState() => _AdminActivitiesPageState();
}

class _AdminActivitiesPageState extends State<AdminActivitiesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Text(
              'Atividades',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: cs.onSurfaceVariant,
                labelStyle:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                unselectedLabelStyle:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                indicator: BoxDecoration(
                  color: cs.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                padding: const EdgeInsets.all(4),
                tabs: const [
                  Tab(text: 'Tarefas'),
                  Tab(text: 'Orações'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _TasksTab(),
                AdminPrayersTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TasksTab extends ConsumerWidget {
  const _TasksTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tasksAsync = ref.watch(allTasksProvider);

    return Column(
      children: [
        _AddButton(
          label: 'Nova tarefa',
          onTap: () => _showTaskForm(context),
        ),
        Expanded(
          child: tasksAsync.when(
            loading: () =>
                Center(child: CircularProgressIndicator(color: cs.primary)),
            error: (e, _) => Center(child: Text('Erro: $e')),
            data: (tasks) {
              if (tasks.isEmpty) {
                return const Center(
                  child: Text('Nenhuma tarefa cadastrada',
                      style: TextStyle(fontSize: 14, color: Colors.grey)),
                );
              }
              final daily = tasks.where((t) => t.isDaily).toList();
              final weekly = tasks.where((t) => t.isWeekly).toList();
              return ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  if (daily.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 12),
                      child: Row(
                        children: [
                          Icon(Icons.today_rounded, size: 18, color: cs.primary),
                          const SizedBox(width: 8),
                          Text('Tarefas Diarias',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurface)),
                        ],
                      ),
                    ),
                    ...daily.map((t) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _buildTaskCard(context, cs, t),
                        )),
                  ],
                  if (weekly.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 12),
                      child: Row(
                        children: [
                          Icon(Icons.date_range_rounded,
                              size: 18, color: cs.primary),
                          const SizedBox(width: 8),
                          Text('Tarefas Semanais',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurface)),
                        ],
                      ),
                    ),
                    ...weekly.map((t) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _buildTaskCard(context, cs, t),
                        )),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTaskCard(BuildContext context, ColorScheme cs, DailyTask t) {
    return _ContentCard(
      icon: Icons.task_alt_rounded,
      title: t.title,
      subtitle: '${t.frequencyLabel} · ${t.isActive ? "Ativa" : "Inativa"}',
      onEdit: () => _showTaskForm(context, existing: t),
      onDelete: () => _confirmDeleteTask(context, t),
    );
  }

  void _confirmDeleteTask(BuildContext context, DailyTask task) {
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cs.surface,
        title: Text('Excluir tarefa?', style: TextStyle(color: cs.onSurface)),
        content: Text('"${task.title}" sera removida.',
            style: TextStyle(color: cs.onSurfaceVariant)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar',
                style: TextStyle(color: cs.onSurfaceVariant)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await Supabase.instance.client
                  .from('daily_tasks')
                  .delete()
                  .eq('id', task.id);
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

void _showTaskForm(BuildContext context, {DailyTask? existing}) {
  final cs = Theme.of(context).colorScheme;
  final titleCtrl = TextEditingController(text: existing?.title ?? '');
  bool isActive = existing?.isActive ?? true;
  String frequency = existing?.frequency ?? 'daily';
  bool isSaving = false;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: cs.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheetState) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 16, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              existing != null ? 'Editar tarefa' : 'Nova tarefa',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: titleCtrl,
              style: TextStyle(color: cs.onSurface),
              decoration: const InputDecoration(hintText: 'Nome da tarefa'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text('Frequencia:',
                    style: TextStyle(color: cs.onSurface, fontSize: 14)),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: const Text('Diaria'),
                  selected: frequency == 'daily',
                  onSelected: (_) =>
                      setSheetState(() => frequency = 'daily'),
                  selectedColor: cs.primary,
                  labelStyle: TextStyle(
                    color:
                        frequency == 'daily' ? Colors.white : cs.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Semanal'),
                  selected: frequency == 'weekly',
                  onSelected: (_) =>
                      setSheetState(() => frequency = 'weekly'),
                  selectedColor: cs.primary,
                  labelStyle: TextStyle(
                    color:
                        frequency == 'weekly' ? Colors.white : cs.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              value: isActive,
              onChanged: (v) => setSheetState(() => isActive = v),
              title: Text('Ativa',
                  style: TextStyle(color: cs.onSurface, fontSize: 14)),
              activeTrackColor: cs.primary,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      final title = titleCtrl.text.trim();
                      if (title.isEmpty) return;

                      setSheetState(() => isSaving = true);

                      final data = {
                        'title': title,
                        'is_active': isActive,
                        'frequency': frequency,
                      };

                      final client = Supabase.instance.client;
                      if (existing != null) {
                        await client
                            .from('daily_tasks')
                            .update(data)
                            .eq('id', existing.id);
                      } else {
                        await client.from('daily_tasks').insert(data);
                      }

                      if (ctx.mounted) Navigator.pop(ctx);
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(existing != null
                      ? 'Salvar alteracoes'
                      : 'Salvar tarefa'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _AddButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _AddButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      child: Material(
        color: primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_rounded, size: 20, color: primary),
                const SizedBox(width: 8),
                Text(label,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: primary)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ContentCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _ContentCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: cs.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 12, color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
              if (onEdit != null) ...[
                const SizedBox(width: 4),
                IconButton(
                  onPressed: onEdit,
                  icon: Icon(Icons.edit_rounded,
                      size: 16, color: cs.onSurfaceVariant),
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
              if (onDelete != null)
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded,
                      size: 16, color: Colors.red),
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
