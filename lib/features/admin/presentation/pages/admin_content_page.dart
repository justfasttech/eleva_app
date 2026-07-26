import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:just_audio/just_audio.dart';
import 'package:file_picker/file_picker.dart';

import '../../../readings/models/spiritual_reading.dart';
import '../../../readings/providers/readings_provider.dart';
import '../../../readings/presentation/reading_detail_screen.dart';
import '../../../meditation/models/meditation.dart';
import '../../../meditation/providers/meditation_provider.dart';
import '../../../meditation/presentation/meditation_player_screen.dart';
import '../../../tasks/models/daily_task.dart';
import '../../../tasks/providers/tasks_provider.dart';
import '../../../verses/models/daily_verse.dart';
import '../../../verses/providers/verses_provider.dart';

class AdminContentPage extends StatefulWidget {
  const AdminContentPage({super.key});

  @override
  State<AdminContentPage> createState() => _AdminContentPageState();
}

class _AdminContentPageState extends State<AdminContentPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
              'Gerenciar Conteudos',
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
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: Colors.white,
                unselectedLabelColor: cs.onSurfaceVariant,
                labelStyle: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600),
                unselectedLabelStyle: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w500),
                indicator: BoxDecoration(
                  color: cs.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                padding: const EdgeInsets.all(4),
                tabs: const [
                  Tab(text: 'Leituras'),
                  Tab(text: 'Meditacoes'),
                  Tab(text: 'Tarefas'),
                  Tab(text: 'Versiculos'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _ReadingsTab(),
                _MeditationsTab(),
                _TasksTab(),
                _VersesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadingsTab extends ConsumerWidget {
  const _ReadingsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readingsAsync = ref.watch(spiritualReadingsProvider);

    return Column(
      children: [
        _AddButton(
          label: 'Nova leitura',
          onTap: () => _showReadingForm(context),
        ),
        Expanded(
          child: readingsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Erro: $e')),
            data: (readings) {
              if (readings.isEmpty) {
                return const Center(
                  child: Text('Nenhuma leitura cadastrada',
                      style: TextStyle(fontSize: 14, color: Colors.grey)),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: readings.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final r = readings[i];
                  return _ContentCard(
                    icon: Icons.menu_book_rounded,
                    title: r.title,
                    subtitle: r.reference ?? r.categoryLabel,
                    trailing: _CategoryBadge(label: r.categoryLabel),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReadingDetailScreen(reading: r, isAdmin: true),
                      ),
                    ),
                    onEdit: () => _showReadingForm(context, existing: r),
                    onDelete: () => _confirmDelete(context, r),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, SpiritualReading reading) {
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cs.surface,
        title: Text('Excluir leitura?', style: TextStyle(color: cs.onSurface)),
        content: Text('"${reading.title}" será removida permanentemente.',
            style: TextStyle(color: cs.onSurfaceVariant)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar', style: TextStyle(color: cs.onSurfaceVariant)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await Supabase.instance.client
                  .from('spiritual_readings')
                  .delete()
                  .eq('id', reading.id);
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _MeditationsTab extends ConsumerStatefulWidget {
  const _MeditationsTab();

  @override
  ConsumerState<_MeditationsTab> createState() => _MeditationsTabState();
}

class _MeditationsTabState extends ConsumerState<_MeditationsTab> {
  AudioPlayer? _previewPlayer;
  String? _playingId;

  @override
  void dispose() {
    _previewPlayer?.dispose();
    super.dispose();
  }

  Future<void> _togglePreview(Meditation m) async {
    if (_playingId == m.id) {
      await _previewPlayer?.stop();
      setState(() => _playingId = null);
      return;
    }

    _previewPlayer?.dispose();
    _previewPlayer = AudioPlayer();
    setState(() => _playingId = m.id);

    try {
      await _previewPlayer!.setUrl(m.audioUrl!);
      _previewPlayer!.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed && mounted) {
          setState(() => _playingId = null);
        }
      });
      await _previewPlayer!.play();
    } catch (_) {
      if (mounted) setState(() => _playingId = null);
    }
  }

  void _confirmDelete(Meditation m) {
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cs.surface,
        title: Text('Excluir meditação?', style: TextStyle(color: cs.onSurface)),
        content: Text('"${m.title}" será removida permanentemente.',
            style: TextStyle(color: cs.onSurfaceVariant)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar', style: TextStyle(color: cs.onSurfaceVariant)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              if (m.audioUrl != null) {
                try {
                  final uri = Uri.parse(m.audioUrl!);
                  final path = uri.pathSegments.last;
                  await Supabase.instance.client.storage
                      .from('meditation-audio')
                      .remove([path]);
                } catch (_) {}
              }
              await Supabase.instance.client
                  .from('meditations')
                  .delete()
                  .eq('id', m.id);
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final meditationsAsync = ref.watch(meditationsProvider);

    return Column(
      children: [
        _AddButton(
          label: 'Nova meditação',
          onTap: () => _showMeditationForm(context),
        ),
        Expanded(
          child: meditationsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Erro: $e')),
            data: (meditations) {
              if (meditations.isEmpty) {
                return const Center(
                  child: Text('Nenhuma meditação cadastrada',
                      style: TextStyle(fontSize: 14, color: Colors.grey)),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: meditations.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final m = meditations[i];
                  return _ContentCard(
                    icon: m.type == 'guiada'
                        ? Icons.self_improvement_rounded
                        : Icons.waves_rounded,
                    title: m.title,
                    subtitle: '${m.durationLabel} · ${m.typeLabel}',
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _CategoryBadge(label: m.typeLabel),
                        if (m.hasAudio) ...[
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => _togglePreview(m),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _playingId == m.id
                                    ? Icons.stop_rounded
                                    : Icons.play_arrow_rounded,
                                size: 18,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MeditationPlayerScreen(meditation: m),
                      ),
                    ),
                    onEdit: () => _showMeditationForm(context, existing: m),
                    onDelete: () => _confirmDelete(m),
                  );
                },
              );
            },
          ),
        ),
      ],
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
                          Text('Tarefas Diárias', style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurface)),
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
                          Icon(Icons.date_range_rounded, size: 18, color: cs.primary),
                          const SizedBox(width: 8),
                          Text('Tarefas Semanais', style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurface)),
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
      subtitle: '${t.faithPoints} pontos · ${t.frequencyLabel} · ${t.isActive ? "Ativa" : "Inativa"}',
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: cs.primary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '+${t.faithPoints}',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
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
        content: Text('"${task.title}" será removida.',
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

class _VersesTab extends ConsumerWidget {
  const _VersesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final versesAsync = ref.watch(dailyVersesProvider);

    return Column(
      children: [
        _AddButton(
          label: 'Novo versículo',
          onTap: () => _showVerseForm(context),
        ),
        Expanded(
          child: versesAsync.when(
            loading: () =>
                Center(child: CircularProgressIndicator(color: cs.primary)),
            error: (e, _) => Center(child: Text('Erro: $e')),
            data: (verses) {
              if (verses.isEmpty) {
                return const Center(
                  child: Text('Nenhum versículo cadastrado',
                      style: TextStyle(fontSize: 14, color: Colors.grey)),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: verses.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final v = verses[i];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: cs.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                v.text,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: cs.onSurface,
                                  height: 1.4,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              if (v.source.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  v.source,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: cs.primary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => _showVerseForm(context, existing: v),
                          icon: Icon(Icons.edit_rounded,
                              size: 18, color: cs.onSurfaceVariant),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        IconButton(
                          onPressed: () =>
                              _confirmDeleteVerse(context, v),
                          icon: const Icon(Icons.delete_outline_rounded,
                              size: 18, color: Colors.red),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _confirmDeleteVerse(BuildContext context, DailyVerse verse) {
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cs.surface,
        title:
            Text('Excluir versículo?', style: TextStyle(color: cs.onSurface)),
        content: Text(
            '"${verse.text.length > 60 ? '${verse.text.substring(0, 60)}...' : verse.text}" será removido.',
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
                  .from('daily_verses')
                  .delete()
                  .eq('id', verse.id);
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// === Widgets reutilizaveis ===

void _showReadingForm(BuildContext context, {SpiritualReading? existing}) {
  final cs = Theme.of(context).colorScheme;
  final titleCtrl = TextEditingController(text: existing?.title ?? '');
  final referenceCtrl = TextEditingController(text: existing?.reference ?? '');
  final authorCtrl = TextEditingController(text: existing?.author ?? '');
  final contentCtrl = TextEditingController(text: existing?.content ?? '');
  final pointsCtrl =
      TextEditingController(text: (existing?.faithPoints ?? 1).toString());
  String selectedCategory = existing?.category ?? 'textos';
  bool isPublished = existing?.isPublished ?? true;
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
        child: SingleChildScrollView(
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
                existing != null ? 'Editar leitura' : 'Nova leitura',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleCtrl,
                style: TextStyle(color: cs.onSurface),
                decoration: const InputDecoration(hintText: 'Título'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: referenceCtrl,
                style: TextStyle(color: cs.onSurface),
                decoration:
                    const InputDecoration(hintText: 'Referência (ex: Salmos 23:1-6)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: authorCtrl,
                style: TextStyle(color: cs.onSurface),
                decoration:
                    const InputDecoration(hintText: 'Autor (opcional)'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedCategory,
                dropdownColor: cs.surface,
                style: TextStyle(color: cs.onSurface, fontSize: 16),
                decoration: const InputDecoration(hintText: 'Categoria'),
                items: SpiritualReading.categories.entries
                    .map((e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value.label),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setSheetState(() => selectedCategory = v);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentCtrl,
                style: TextStyle(color: cs.onSurface),
                decoration:
                    const InputDecoration(hintText: 'Conteúdo da leitura...'),
                maxLines: null,
                minLines: 6,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: pointsCtrl,
                style: TextStyle(color: cs.onSurface),
                decoration:
                    const InputDecoration(hintText: 'Pontos de fé'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                value: isPublished,
                onChanged: (v) => setSheetState(() => isPublished = v),
                title: Text('Publicado',
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
                        final content = contentCtrl.text.trim();
                        if (title.isEmpty || content.isEmpty) return;

                        setSheetState(() => isSaving = true);

                        final data = {
                          'title': title,
                          'reference': referenceCtrl.text.trim().isEmpty
                              ? null
                              : referenceCtrl.text.trim(),
                          'author': authorCtrl.text.trim().isEmpty
                              ? null
                              : authorCtrl.text.trim(),
                          'category': selectedCategory,
                          'content': content,
                          'faith_points':
                              int.tryParse(pointsCtrl.text.trim()) ?? 1,
                          'is_published': isPublished,
                        };

                        final client = Supabase.instance.client;
                        if (existing != null) {
                          await client
                              .from('spiritual_readings')
                              .update(data)
                              .eq('id', existing.id);
                        } else {
                          await client
                              .from('spiritual_readings')
                              .insert(data);
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
                        ? 'Salvar alterações'
                        : 'Salvar leitura'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

void _showMeditationForm(BuildContext context, {Meditation? existing}) {
  final cs = Theme.of(context).colorScheme;
  final titleCtrl = TextEditingController(text: existing?.title ?? '');
  final descCtrl = TextEditingController(text: existing?.description ?? '');
  final durationCtrl =
      TextEditingController(text: existing?.durationMinutes.toString() ?? '');
  final pointsCtrl =
      TextEditingController(text: (existing?.faithPoints ?? 1).toString());
  String selectedType = existing?.type ?? 'guiada';
  bool isPublished = existing?.isPublished ?? true;
  bool isSaving = false;

  String? uploadedAudioUrl = existing?.audioUrl;
  String? uploadedFileName = existing?.audioFileName;
  bool isUploading = false;

  AudioPlayer? formPlayer;
  bool isPlaying = false;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: cs.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheetState) {
        void disposePlayer() {
          formPlayer?.dispose();
          formPlayer = null;
        }

        Future<void> pickAndUpload() async {
          final result = await FilePicker.platform.pickFiles(
            type: FileType.audio,
            withData: true,
          );
          if (result == null || result.files.first.bytes == null) return;

          final file = result.files.first;
          setSheetState(() => isUploading = true);

          try {
            final storagePath =
                '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
            await Supabase.instance.client.storage
                .from('meditation-audio')
                .uploadBinary(storagePath, file.bytes!);

            final url = Supabase.instance.client.storage
                .from('meditation-audio')
                .getPublicUrl(storagePath);

            setSheetState(() {
              uploadedAudioUrl = url;
              uploadedFileName = file.name;
              isUploading = false;
            });
          } catch (e) {
            setSheetState(() => isUploading = false);
            if (ctx.mounted) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(
                  content: Text('Erro no upload: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }

        Future<void> togglePlay() async {
          if (isPlaying) {
            await formPlayer?.stop();
            setSheetState(() => isPlaying = false);
            return;
          }
          if (uploadedAudioUrl == null) return;

          disposePlayer();
          formPlayer = AudioPlayer();
          try {
            await formPlayer!.setUrl(uploadedAudioUrl!);
            formPlayer!.playerStateStream.listen((state) {
              if (state.processingState == ProcessingState.completed &&
                  ctx.mounted) {
                setSheetState(() => isPlaying = false);
              }
            });
            await formPlayer!.play();
            setSheetState(() => isPlaying = true);
          } catch (_) {
            setSheetState(() => isPlaying = false);
          }
        }

        return PopScope(
          onPopInvokedWithResult: (_, __) => disposePlayer(),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
                24, 16, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
            child: SingleChildScrollView(
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
                    existing != null ? 'Editar meditação' : 'Nova meditação',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleCtrl,
                    style: TextStyle(color: cs.onSurface),
                    decoration: const InputDecoration(hintText: 'Título'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    style: TextStyle(color: cs.onSurface),
                    decoration:
                        const InputDecoration(hintText: 'Descrição (opcional)'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: durationCtrl,
                    style: TextStyle(color: cs.onSurface),
                    decoration: const InputDecoration(
                        hintText: 'Duração em minutos (ex: 10)'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedType,
                    dropdownColor: cs.surface,
                    style: TextStyle(color: cs.onSurface, fontSize: 16),
                    decoration: const InputDecoration(hintText: 'Tipo'),
                    items: const [
                      DropdownMenuItem(
                          value: 'guiada', child: Text('Sessão guiada')),
                      DropdownMenuItem(
                          value: 'ambiente', child: Text('Sons ambiente')),
                    ],
                    onChanged: (v) {
                      if (v != null) setSheetState(() => selectedType = v);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: pointsCtrl,
                    style: TextStyle(color: cs.onSurface),
                    decoration:
                        const InputDecoration(hintText: 'Pontos de fé'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  // Audio upload section
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Áudio',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface),
                        ),
                        const SizedBox(height: 10),
                        if (uploadedFileName != null)
                          Row(
                            children: [
                              Icon(Icons.audio_file_rounded,
                                  size: 18, color: cs.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  uploadedFileName!,
                                  style: TextStyle(
                                      fontSize: 13, color: cs.onSurface),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                onPressed: togglePlay,
                                icon: Icon(
                                  isPlaying
                                      ? Icons.stop_rounded
                                      : Icons.play_arrow_rounded,
                                  color: cs.primary,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                    minWidth: 36, minHeight: 36),
                              ),
                            ],
                          ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: isUploading ? null : pickAndUpload,
                            icon: isUploading
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: cs.primary),
                                  )
                                : Icon(Icons.upload_file_rounded,
                                    color: cs.primary),
                            label: Text(isUploading
                                ? 'Enviando...'
                                : uploadedFileName != null
                                    ? 'Trocar áudio'
                                    : 'Enviar áudio'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    value: isPublished,
                    onChanged: (v) => setSheetState(() => isPublished = v),
                    title: Text('Publicado',
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
                            final duration =
                                int.tryParse(durationCtrl.text.trim());
                            if (title.isEmpty || duration == null) return;

                            setSheetState(() => isSaving = true);
                            disposePlayer();

                            final data = {
                              'title': title,
                              'description': descCtrl.text.trim().isEmpty
                                  ? null
                                  : descCtrl.text.trim(),
                              'duration_minutes': duration,
                              'type': selectedType,
                              'audio_url': uploadedAudioUrl,
                              'audio_file_name': uploadedFileName,
                              'faith_points':
                                  int.tryParse(pointsCtrl.text.trim()) ?? 1,
                              'is_published': isPublished,
                            };

                            final client = Supabase.instance.client;
                            if (existing != null) {
                              await client
                                  .from('meditations')
                                  .update(data)
                                  .eq('id', existing.id);
                            } else {
                              await client.from('meditations').insert(data);
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
                            ? 'Salvar alterações'
                            : 'Salvar meditação'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

void _showTaskForm(BuildContext context, {DailyTask? existing}) {
  final cs = Theme.of(context).colorScheme;
  final titleCtrl = TextEditingController(text: existing?.title ?? '');
  final pointsCtrl = TextEditingController(
      text: existing != null ? existing.faithPoints.toString() : '');
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
            TextField(
              controller: pointsCtrl,
              style: TextStyle(color: cs.onSurface),
              decoration: const InputDecoration(hintText: 'Pontos (ex: 10)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text('Frequência:', style: TextStyle(color: cs.onSurface, fontSize: 14)),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: const Text('Diária'),
                  selected: frequency == 'daily',
                  onSelected: (_) => setSheetState(() => frequency = 'daily'),
                  selectedColor: cs.primary,
                  labelStyle: TextStyle(
                    color: frequency == 'daily' ? Colors.white : cs.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Semanal'),
                  selected: frequency == 'weekly',
                  onSelected: (_) => setSheetState(() => frequency = 'weekly'),
                  selectedColor: cs.primary,
                  labelStyle: TextStyle(
                    color: frequency == 'weekly' ? Colors.white : cs.onSurface,
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
                        'faith_points':
                            int.tryParse(pointsCtrl.text.trim()) ?? 1,
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
                  : Text(
                      existing != null ? 'Salvar alterações' : 'Salvar tarefa'),
            ),
          ],
        ),
      ),
    ),
  );
}

void _showVerseForm(BuildContext context, {DailyVerse? existing}) {
  final cs = Theme.of(context).colorScheme;
  final textCtrl = TextEditingController(text: existing?.text ?? '');
  final sourceCtrl = TextEditingController(text: existing?.source ?? '');
  bool isActive = existing?.isActive ?? true;
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
              existing != null ? 'Editar versículo' : 'Novo versículo',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: textCtrl,
              style: TextStyle(color: cs.onSurface),
              decoration: const InputDecoration(
                hintText: 'Frase do versículo...',
              ),
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: sourceCtrl,
              style: TextStyle(color: cs.onSurface),
              decoration: const InputDecoration(
                hintText: 'Referência (ex: Hebreus 11:1)',
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              value: isActive,
              onChanged: (v) => setSheetState(() => isActive = v),
              title: Text('Ativo',
                  style: TextStyle(color: cs.onSurface, fontSize: 14)),
              activeTrackColor: cs.primary,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      final text = textCtrl.text.trim();
                      if (text.isEmpty) return;

                      setSheetState(() => isSaving = true);

                      final source = sourceCtrl.text.trim();
                      final message = source.isNotEmpty
                          ? '$text — $source'
                          : text;

                      final data = {
                        'message': message,
                        'is_active': isActive,
                      };

                      final client = Supabase.instance.client;
                      if (existing != null) {
                        await client
                            .from('daily_verses')
                            .update(data)
                            .eq('id', existing.id);
                      } else {
                        await client.from('daily_verses').insert(data);
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
                      ? 'Salvar alterações'
                      : 'Salvar versículo'),
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
                Text(label, style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600, color: primary)),
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
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
              if (onDelete != null)
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded,
                      size: 16, color: Colors.red),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              if (onEdit == null && onDelete == null) ...[
                const SizedBox(width: 8),
                Icon(Icons.edit_rounded, size: 16, color: cs.onSurfaceVariant),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  final String label;
  const _CategoryBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(
          fontSize: 10, fontWeight: FontWeight.w600, color: primary)),
    );
  }
}
