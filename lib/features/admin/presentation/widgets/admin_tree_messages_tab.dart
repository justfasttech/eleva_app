import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:just_audio/just_audio.dart';
import 'package:file_picker/file_picker.dart';

import '../../../home/models/tree_message.dart';
import '../../../home/providers/tree_messages_provider.dart';

class AdminTreeMessagesTab extends ConsumerWidget {
  const AdminTreeMessagesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final messagesAsync = ref.watch(treeMessagesProvider);

    return messagesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erro: $e')),
      data: (messages) {
        if (messages.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Nenhuma mensagem cadastrada',
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                Text(
                  'Execute o SQL seed para popular as mensagens',
                  style: TextStyle(
                      color: cs.onSurfaceVariant, fontSize: 12),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          itemCount: messages.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final msg = messages[i];
            return Container(
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      '${msg.level}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: cs.primary,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  msg.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      msg.message,
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (msg.audioFileName != null &&
                        msg.audioFileName!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Icon(Icons.audiotrack_rounded,
                                size: 12, color: cs.primary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                msg.audioFileName!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: cs.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                trailing: IconButton(
                  icon:
                      Icon(Icons.edit_rounded, size: 20, color: cs.primary),
                  onPressed: () =>
                      _showTreeMessageForm(context, existing: msg),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

void _showTreeMessageForm(BuildContext context,
    {required TreeMessage existing}) {
  final cs = Theme.of(context).colorScheme;
  final nameCtrl = TextEditingController(text: existing.name);
  final messageCtrl = TextEditingController(text: existing.message);
  bool isSaving = false;

  String? uploadedAudioUrl = existing.audioUrl;
  String? uploadedFileName = existing.audioFileName;
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
                .from('tree-audio')
                .uploadBinary(storagePath, file.bytes!);

            final url = Supabase.instance.client.storage
                .from('tree-audio')
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
                    'Editar nível ${existing.level}',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameCtrl,
                    style: TextStyle(color: cs.onSurface),
                    decoration:
                        const InputDecoration(hintText: 'Nome do nível'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: messageCtrl,
                    style: TextStyle(color: cs.onSurface),
                    decoration: const InputDecoration(
                        hintText: 'Mensagem motivacional'),
                    maxLines: 3,
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
                            onPressed:
                                isUploading ? null : pickAndUploadAudio,
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
                                disposePlayer();
                                setSheetState(() {
                                  uploadedAudioUrl = null;
                                  uploadedFileName = null;
                                  isPlaying = false;
                                });
                              },
                              icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: Colors.red,
                                  size: 18),
                              label: const Text('Remover áudio',
                                  style: TextStyle(color: Colors.red)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                    color: Colors.red, width: 0.5),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                              final name = nameCtrl.text.trim();
                              final message = messageCtrl.text.trim();
                              if (name.isEmpty || message.isEmpty) return;

                              setSheetState(() => isSaving = true);
                              disposePlayer();

                              await Supabase.instance.client
                                  .from('tree_messages')
                                  .update({
                                    'name': name,
                                    'message': message,
                                    'audio_url': uploadedAudioUrl,
                                    'audio_file_name': uploadedFileName,
                                  })
                                  .eq('id', existing.id);

                              if (ctx.mounted) Navigator.pop(ctx);
                            },
                      child: isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Salvar alterações'),
                    ),
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
