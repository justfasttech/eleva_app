import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:just_audio/just_audio.dart';
import 'package:file_picker/file_picker.dart';

import '../../../prayers/models/prayer.dart';
import '../../../prayers/providers/prayers_provider.dart';
import '../../../content_themes/providers/content_themes_provider.dart';

class AdminPrayersTab extends ConsumerWidget {
  const AdminPrayersTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final prayersAsync = ref.watch(prayersProvider);
    final themesAsync = ref.watch(contentThemesProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showPrayerForm(context, ref),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Nova oração'),
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: prayersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Erro: $e')),
            data: (prayers) {
              if (prayers.isEmpty) {
                return Center(
                  child: Text(
                    'Nenhuma oração cadastrada',
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                );
              }

              final themes = themesAsync.value ?? [];
              String themeName(String themeId) {
                final t = themes.where((t) => t.id == themeId);
                return t.isNotEmpty ? t.first.name : '—';
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: prayers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final prayer = prayers[i];
                  return Container(
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: cs.outlineVariant.withValues(alpha: 0.3),
                      ),
                    ),
                    child: ListTile(
                      leading: Icon(
                        Icons.self_improvement_rounded,
                        color: cs.primary,
                      ),
                      title: Text(
                        prayer.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                      subtitle: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: cs.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              themeName(prayer.themeId),
                              style: TextStyle(
                                  fontSize: 11, color: cs.primary),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (!prayer.isPublished)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Rascunho',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.orange),
                              ),
                            ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit_rounded,
                                size: 20, color: cs.primary),
                            onPressed: () =>
                                _showPrayerForm(context, ref, existing: prayer),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_rounded,
                                size: 20, color: Colors.red),
                            onPressed: () => _confirmDelete(context, ref, prayer),
                          ),
                        ],
                      ),
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

  void _confirmDelete(BuildContext context, WidgetRef ref, Prayer prayer) {
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cs.surface,
        title:
            Text('Excluir oração?', style: TextStyle(color: cs.onSurface)),
        content: Text(
          '"${prayer.title}" será removida permanentemente.',
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await Supabase.instance.client
                    .from('prayers')
                    .delete()
                    .eq('id', prayer.id);
                ref.invalidate(prayersProvider);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao excluir oração: $e')),
                  );
                }
              }
            },
            child:
                const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

void _showPrayerForm(BuildContext context, WidgetRef ref,
    {Prayer? existing}) {
  final cs = Theme.of(context).colorScheme;
  final titleCtrl = TextEditingController(text: existing?.title ?? '');
  final contentCtrl = TextEditingController(text: existing?.content ?? '');
  String? selectedThemeId = existing?.themeId;
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
                .from('prayer-audio')
                .uploadBinary(storagePath, file.bytes!);

            final url = Supabase.instance.client.storage
                .from('prayer-audio')
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
                .from('prayer-video')
                .uploadBinary(storagePath, file.bytes!);

            final url = Supabase.instance.client.storage
                .from('prayer-video')
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
                    existing != null ? 'Editar oração' : 'Nova oração',
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
                    controller: contentCtrl,
                    style: TextStyle(color: cs.onSurface),
                    decoration: const InputDecoration(
                        hintText: 'Conteúdo da oração...'),
                    maxLines: null,
                    minLines: 6,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedThemeId,
                    dropdownColor: cs.surface,
                    style: TextStyle(color: cs.onSurface, fontSize: 16),
                    decoration:
                        const InputDecoration(hintText: 'Tema'),
                    items: themes
                        .map((t) => DropdownMenuItem(
                              value: t.id,
                              child: Text(t.name),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setSheetState(() => selectedThemeId = v);
                      }
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
                            final content = contentCtrl.text.trim();
                            if (title.isEmpty ||
                                content.isEmpty ||
                                selectedThemeId == null) return;

                            setSheetState(() => isSaving = true);
                            disposePlayer();

                            final data = {
                              'title': title,
                              'content': content,
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
                                  .from('prayers')
                                  .update(data)
                                  .eq('id', existing.id);
                            } else {
                              await client.from('prayers').insert(data);
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
                            : 'Salvar oração'),
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
