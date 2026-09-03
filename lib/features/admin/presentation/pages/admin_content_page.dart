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
import '../../../content_themes/providers/content_themes_provider.dart';

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
              'Conteudo',
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
                labelStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
                unselectedLabelStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadingsTab extends ConsumerStatefulWidget {
  const _ReadingsTab();

  @override
  ConsumerState<_ReadingsTab> createState() => _ReadingsTabState();
}

class _ReadingsTabState extends ConsumerState<_ReadingsTab> {
  String? _selectedThemeId;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final readingsAsync = ref.watch(spiritualReadingsProvider);
    final themesAsync = ref.watch(contentThemesProvider);
    final themes = themesAsync.value ?? [];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  key: ValueKey(_selectedThemeId),
                  initialValue: _selectedThemeId,
                  decoration: InputDecoration(
                    labelText: 'Filtrar por tema',
                    labelStyle: TextStyle(color: cs.onSurfaceVariant),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    isDense: true,
                  ),
                  items: themes
                      .map((t) => DropdownMenuItem(
                            value: t.id,
                            child: Text(t.name,
                                style: const TextStyle(fontSize: 13)),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedThemeId = v),
                ),
              ),
              if (_selectedThemeId != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () => setState(() => _selectedThemeId = null),
                  tooltip: 'Limpar filtro',
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        _AddButton(
          label: 'Nova leitura',
          onTap: () => _showReadingForm(context, ref),
        ),
        Expanded(
          child: readingsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Erro: $e')),
            data: (readings) {
              final filtered = _selectedThemeId != null
                  ? readings
                      .where((r) => r.themeId == _selectedThemeId)
                      .toList()
                  : readings;

              if (filtered.isEmpty) {
                return const Center(
                  child: Text('Nenhuma leitura cadastrada',
                      style: TextStyle(fontSize: 14, color: Colors.grey)),
                );
              }

              final grouped = <int, List<SpiritualReading>>{};
              for (final r in filtered) {
                grouped.putIfAbsent(r.level, () => []).add(r);
              }
              final sortedKeys = grouped.keys.toList()..sort();

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: sortedKeys.length,
                itemBuilder: (context, sectionIndex) {
                  final level = sortedKeys[sectionIndex];
                  final sectionReadings = grouped[level]!;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (sectionIndex > 0) const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Nível $level',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: cs.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...sectionReadings.map((r) {
                        final tName = themes.where((t) => t.id == r.themeId);
                        final themeLabel = tName.isNotEmpty ? tName.first.name : '---';
                        return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _ContentCard(
                              icon: Icons.menu_book_rounded,
                              title: r.title,
                              subtitle: '$themeLabel · ${r.reference ?? r.categoryLabel}',
                              trailing: _CategoryBadge(label: r.categoryLabel),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ReadingDetailScreen(
                                      reading: r, isAdmin: true),
                                ),
                              ),
                              onEdit: () =>
                                  _showReadingForm(context, ref, existing: r),
                              onDelete: () => _confirmDelete(r),
                            ),
                          );
                        }),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _confirmDelete(SpiritualReading reading) {
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
              try {
                await Supabase.instance.client
                    .from('spiritual_readings')
                    .delete()
                    .eq('id', reading.id);
                ref.invalidate(spiritualReadingsProvider);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao excluir leitura: $e')),
                  );
                }
              }
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
  String? _selectedThemeId;

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
              try {
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
                ref.invalidate(meditationsProvider);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao excluir meditação: $e')),
                  );
                }
              }
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final meditationsAsync = ref.watch(meditationsProvider);
    final themesAsync = ref.watch(contentThemesProvider);
    final themes = themesAsync.value ?? [];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  key: ValueKey(_selectedThemeId),
                  initialValue: _selectedThemeId,
                  decoration: InputDecoration(
                    labelText: 'Filtrar por tema',
                    labelStyle: TextStyle(color: cs.onSurfaceVariant),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    isDense: true,
                  ),
                  items: themes
                      .map((t) => DropdownMenuItem(
                            value: t.id,
                            child: Text(t.name,
                                style: const TextStyle(fontSize: 13)),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedThemeId = v),
                ),
              ),
              if (_selectedThemeId != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () => setState(() => _selectedThemeId = null),
                  tooltip: 'Limpar filtro',
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        _AddButton(
          label: 'Nova meditação',
          onTap: () => _showMeditationForm(context, ref),
        ),
        Expanded(
          child: meditationsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Erro: $e')),
            data: (meditations) {
              final filtered = _selectedThemeId != null
                  ? meditations
                      .where((m) => m.themeId == _selectedThemeId)
                      .toList()
                  : meditations;

              if (filtered.isEmpty) {
                return const Center(
                  child: Text('Nenhuma meditação cadastrada',
                      style: TextStyle(fontSize: 14, color: Colors.grey)),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final m = filtered[i];
                  final tName = themes.where((t) => t.id == m.themeId);
                  final themeLabel = tName.isNotEmpty ? tName.first.name : '---';
                  return _ContentCard(
                    icon: m.type == 'guiada'
                        ? Icons.self_improvement_rounded
                        : Icons.waves_rounded,
                    title: m.title,
                    subtitle: '$themeLabel · ${m.durationLabel} · ${m.typeLabel}',
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
                        builder: (_) => MeditationPlayerScreen(meditation: m, isAdmin: true),
                      ),
                    ),
                    onEdit: () => _showMeditationForm(context, ref, existing: m),
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

void _showReadingForm(BuildContext context, WidgetRef ref, {SpiritualReading? existing}) {
  final cs = Theme.of(context).colorScheme;
  final titleCtrl = TextEditingController(text: existing?.title ?? '');
  final referenceCtrl = TextEditingController(text: existing?.reference ?? '');
  final authorCtrl = TextEditingController(text: existing?.author ?? '');
  final contentCtrl = TextEditingController(text: existing?.content ?? '');
  String selectedCategory = existing?.category ?? 'textos';
  int selectedLevel = existing?.level ?? 1;
  String? selectedThemeId = existing?.themeId.isEmpty == true ? null : existing?.themeId;
  bool isPublished = existing?.isPublished ?? true;
  bool isSaving = false;
  final themes = ref.read(contentThemesProvider).value ?? [];

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

        Future<void> pickAndUploadAudio() async {
          final result = await FilePicker.platform.pickFiles(
            type: FileType.audio,
            withData: true,
          );
          if (result == null || result.files.first.bytes == null) return;

          final file = result.files.first;
          setSheetState(() => isUploading = true);

          try {
            final storagePath =
                '${DateTime.now().millisecondsSinceEpoch}_${file.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_')}';
            await Supabase.instance.client.storage
                .from('reading-audio')
                .uploadBinary(storagePath, file.bytes!);

            final url = Supabase.instance.client.storage
                .from('reading-audio')
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
            formPlayer!.play();
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
                  DropdownButtonFormField<String>(
                    initialValue: selectedThemeId,
                    dropdownColor: cs.surface,
                    style: TextStyle(color: cs.onSurface, fontSize: 16),
                    decoration: const InputDecoration(hintText: 'Tema do conteúdo'),
                    items: themes
                        .map((t) => DropdownMenuItem(
                              value: t.id,
                              child: Text(t.name),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setSheetState(() => selectedThemeId = v);
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
                  DropdownButtonFormField<int>(
                    initialValue: selectedLevel,
                    dropdownColor: cs.surface,
                    style: TextStyle(color: cs.onSurface, fontSize: 16),
                    decoration: const InputDecoration(
                        hintText: 'Nível da leitura (1-7)'),
                    items: List.generate(
                      7,
                      (i) => DropdownMenuItem(
                        value: i + 1,
                        child: Text('Nível ${i + 1}'),
                      ),
                    ),
                    onChanged: (v) {
                      if (v != null) setSheetState(() => selectedLevel = v);
                    },
                  ),
                  const SizedBox(height: 16),
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
                          'Áudio (opcional)',
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
                            onPressed: isUploading ? null : pickAndUploadAudio,
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
                        if (uploadedFileName != null) ...[
                          const SizedBox(height: 6),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                setSheetState(() {
                                  uploadedAudioUrl = null;
                                  uploadedFileName = null;
                                });
                              },
                              icon: const Icon(Icons.delete_outline_rounded,
                                  color: Colors.red, size: 18),
                              label: const Text('Remover áudio',
                                  style: TextStyle(color: Colors.red)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.red, width: 0.5),
                              ),
                            ),
                          ),
                        ],
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
                            final content = contentCtrl.text.trim();
                            if (title.isEmpty || content.isEmpty || selectedThemeId == null) return;

                            setSheetState(() => isSaving = true);
                            disposePlayer();

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
                              'level': selectedLevel,
                              'theme_id': selectedThemeId,
                              'audio_url': uploadedAudioUrl,
                              'audio_file_name': uploadedFileName,
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
        );
      },
    ),
  );
}

void _showMeditationForm(BuildContext context, WidgetRef ref, {Meditation? existing}) {
  final cs = Theme.of(context).colorScheme;
  final titleCtrl = TextEditingController(text: existing?.title ?? '');
  final descCtrl = TextEditingController(text: existing?.description ?? '');
  final durationCtrl =
      TextEditingController(text: existing?.durationMinutes.toString() ?? '');
  String selectedType = existing?.type ?? 'guiada';
  String? selectedThemeId = existing?.themeId.isEmpty == true ? null : existing?.themeId;
  bool isPublished = existing?.isPublished ?? true;
  bool isSaving = false;
  final themes = ref.read(contentThemesProvider).value ?? [];

  String? uploadedAudioUrl = existing?.audioUrl;
  String? uploadedFileName = existing?.audioFileName;
  String? uploadedVideoUrl = existing?.videoUrl;
  String? uploadedVideoName = existing?.videoFileName;
  bool isUploading = false;
  bool isUploadingVideo = false;

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
                '${DateTime.now().millisecondsSinceEpoch}_${file.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_')}';
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

        Future<void> pickAndUploadVideo() async {
          final result = await FilePicker.platform.pickFiles(
            type: FileType.video,
            withData: true,
          );
          if (result == null || result.files.first.bytes == null) return;

          final file = result.files.first;
          setSheetState(() => isUploadingVideo = true);

          try {
            final storagePath =
                '${DateTime.now().millisecondsSinceEpoch}_${file.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_')}';
            await Supabase.instance.client.storage
                .from('meditation-video')
                .uploadBinary(storagePath, file.bytes!);

            final url = Supabase.instance.client.storage
                .from('meditation-video')
                .getPublicUrl(storagePath);

            setSheetState(() {
              uploadedVideoUrl = url;
              uploadedVideoName = file.name;
              isUploadingVideo = false;
            });
          } catch (e) {
            setSheetState(() => isUploadingVideo = false);
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
            formPlayer!.play();
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
                  DropdownButtonFormField<String>(
                    initialValue: selectedThemeId,
                    dropdownColor: cs.surface,
                    style: TextStyle(color: cs.onSurface, fontSize: 16),
                    decoration: const InputDecoration(hintText: 'Tema do conteúdo'),
                    items: themes
                        .map((t) => DropdownMenuItem(
                              value: t.id,
                              child: Text(t.name),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setSheetState(() => selectedThemeId = v);
                    },
                  ),
                  const SizedBox(height: 16),
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
                        if (uploadedFileName != null) ...[
                          const SizedBox(height: 6),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                setSheetState(() {
                                  uploadedAudioUrl = null;
                                  uploadedFileName = null;
                                });
                              },
                              icon: const Icon(Icons.delete_outline_rounded,
                                  color: Colors.red, size: 18),
                              label: const Text('Remover áudio',
                                  style: TextStyle(color: Colors.red)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.red, width: 0.5),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
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
                          'Vídeo (opcional)',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface),
                        ),
                        const SizedBox(height: 10),
                        if (uploadedVideoName != null)
                          Row(
                            children: [
                              Icon(Icons.video_file_rounded,
                                  size: 18, color: cs.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  uploadedVideoName!,
                                  style: TextStyle(
                                      fontSize: 13, color: cs.onSurface),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: isUploadingVideo ? null : pickAndUploadVideo,
                            icon: isUploadingVideo
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: cs.primary),
                                  )
                                : Icon(Icons.video_call_rounded,
                                    color: cs.primary),
                            label: Text(isUploadingVideo
                                ? 'Enviando...'
                                : uploadedVideoName != null
                                    ? 'Trocar vídeo'
                                    : 'Enviar vídeo'),
                          ),
                        ),
                        if (uploadedVideoName != null) ...[
                          const SizedBox(height: 6),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                setSheetState(() {
                                  uploadedVideoUrl = null;
                                  uploadedVideoName = null;
                                });
                              },
                              icon: const Icon(Icons.delete_outline_rounded,
                                  color: Colors.red, size: 18),
                              label: const Text('Remover vídeo',
                                  style: TextStyle(color: Colors.red)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.red, width: 0.5),
                              ),
                            ),
                          ),
                        ],
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
                            if (title.isEmpty || duration == null || selectedThemeId == null) return;

                            setSheetState(() => isSaving = true);
                            disposePlayer();

                            final data = {
                              'title': title,
                              'description': descCtrl.text.trim().isEmpty
                                  ? null
                                  : descCtrl.text.trim(),
                              'duration_minutes': duration,
                              'type': selectedType,
                              'theme_id': selectedThemeId,
                              'audio_url': uploadedAudioUrl,
                              'audio_file_name': uploadedFileName,
                              'video_url': uploadedVideoUrl,
                              'video_file_name': uploadedVideoName,
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
