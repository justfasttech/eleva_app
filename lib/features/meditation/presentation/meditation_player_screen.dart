import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme.dart';
import '../models/meditation.dart';
import '../providers/meditation_provider.dart';

class MeditationPlayerScreen extends ConsumerStatefulWidget {
  final Meditation meditation;
  final bool isAdmin;

  const MeditationPlayerScreen({super.key, required this.meditation, this.isAdmin = false});

  @override
  ConsumerState<MeditationPlayerScreen> createState() => _MeditationPlayerScreenState();
}

class _MeditationPlayerScreenState extends ConsumerState<MeditationPlayerScreen> {
  AudioPlayer? _audioPlayer;
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  bool _completed = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMedia();
  }

  Future<void> _loadMedia() async {
    final m = widget.meditation;
    if (m.hasVideo) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(m.videoUrl!));
      try {
        await _videoController!.initialize();
        if (mounted) {
          setState(() {
            _chewieController = ChewieController(
              videoPlayerController: _videoController!,
              autoPlay: false,
              looping: false,
              materialProgressColors: ChewieProgressColors(
                playedColor: ElevaColors.gold,
                handleColor: ElevaColors.gold,
                backgroundColor: Colors.grey,
                bufferedColor: ElevaColors.goldLight,
              ),
            );
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _error = 'Erro ao carregar vídeo';
          });
        }
      }
    }
    if (m.hasAudio) {
      _audioPlayer = AudioPlayer();
      try {
        await _audioPlayer!.setUrl(m.audioUrl!);
        if (mounted) setState(() => _isLoading = false);
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _error = 'Erro ao carregar áudio';
          });
        }
      }
    }
    if (!m.hasVideo && !m.hasAudio) {
      setState(() {
        _isLoading = false;
        _error = 'Nenhuma mídia disponível';
      });
    }
  }

  void _markCompleted() {
    if (_completed) return;
    setState(() => _completed = true);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Meditação concluída!'),
        backgroundColor: ElevaColors.gold,
      ),
    );
  }

  @override
  void dispose() {
    _audioPlayer?.dispose();
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
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
                await Supabase.instance.client
                    .from('meditations')
                    .delete()
                    .eq('id', m.id);
                ref.invalidate(meditationsProvider);
                if (mounted) Navigator.pop(context);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao excluir: $e')),
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
    final m = widget.meditation;

    return Scaffold(
      backgroundColor: ElevaColors.offWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: ElevaColors.textDark,
        actions: [
          if (widget.isAdmin)
            IconButton(
              onPressed: () => _confirmDelete(m),
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              tooltip: 'Excluir meditação',
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!m.hasVideo) ...[
                  const SizedBox(height: 32),
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [ElevaColors.gold, ElevaColors.goldLight],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: ElevaColors.gold.withValues(alpha: 0.3),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      m.type == 'guiada'
                          ? Icons.self_improvement_rounded
                          : Icons.waves_rounded,
                      size: 52,
                      color: Colors.white,
                    ),
                  ),
                ],
                if (m.hasVideo) const SizedBox(height: 16),
                if (m.hasVideo && _chewieController != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: AspectRatio(
                      aspectRatio: _videoController!.value.aspectRatio,
                      child: Chewie(controller: _chewieController!),
                    ),
                  ),
                if (m.hasVideo && _isLoading)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(color: ElevaColors.gold),
                  ),
                const SizedBox(height: 24),
                Text(
                  m.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: ElevaColors.textDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: ElevaColors.gold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${m.typeLabel} · ${m.durationLabel}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: ElevaColors.gold,
                    ),
                  ),
                ),
                if (m.description != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    m.description!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: ElevaColors.textMuted,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (!m.hasVideo && !m.hasAudio) const SizedBox(height: 32),
                if (m.hasVideo) const SizedBox(height: 24),
                if (m.hasAudio) ...[
                  if (_audioPlayer == null && _isLoading)
                    const CircularProgressIndicator(color: ElevaColors.gold)
                  else if (_audioPlayer == null && _error != null)
                    Text(
                      _error!,
                      style: const TextStyle(color: ElevaColors.textMuted, fontSize: 14),
                    )
                  else if (_audioPlayer != null) ...[
                    StreamBuilder<Duration>(
                      stream: _audioPlayer!.positionStream,
                      builder: (context, posSnap) {
                        final position = posSnap.data ?? Duration.zero;
                        final total = _audioPlayer!.duration ?? Duration.zero;
                        return Column(
                          children: [
                            SliderTheme(
                              data: SliderThemeData(
                                trackHeight: 4,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                                overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                                activeTrackColor: ElevaColors.gold,
                                inactiveTrackColor: ElevaColors.gold.withValues(alpha: 0.15),
                                thumbColor: ElevaColors.gold,
                                overlayColor: ElevaColors.gold.withValues(alpha: 0.1),
                              ),
                              child: Slider(
                                min: 0,
                                max: total.inMilliseconds.toDouble().clamp(1, double.infinity),
                                value: position.inMilliseconds
                                    .toDouble()
                                    .clamp(0, total.inMilliseconds.toDouble().clamp(1, double.infinity)),
                                onChanged: (v) {
                                  _audioPlayer!.seek(Duration(milliseconds: v.toInt()));
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDuration(position),
                                    style: const TextStyle(fontSize: 12, color: ElevaColors.textMuted),
                                  ),
                                  Text(
                                    _formatDuration(total),
                                    style: const TextStyle(fontSize: 12, color: ElevaColors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    StreamBuilder<PlayerState>(
                      stream: _audioPlayer!.playerStateStream,
                      builder: (context, snapshot) {
                        final state = snapshot.data;
                        final playing = state?.playing ?? false;
                        final completed =
                            state?.processingState == ProcessingState.completed;

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: () {
                                final pos = _audioPlayer!.position - const Duration(seconds: 15);
                                _audioPlayer!.seek(pos < Duration.zero ? Duration.zero : pos);
                              },
                              icon: const Icon(Icons.replay_10_rounded),
                              iconSize: 32,
                              color: ElevaColors.textDark,
                            ),
                            const SizedBox(width: 16),
                            GestureDetector(
                              onTap: () {
                                if (completed) {
                                  _audioPlayer!.seek(Duration.zero);
                                  _audioPlayer!.play();
                                } else if (playing) {
                                  _audioPlayer!.pause();
                                } else {
                                  _audioPlayer!.play();
                                }
                              },
                              child: Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [ElevaColors.gold, ElevaColors.goldLight],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: ElevaColors.gold.withValues(alpha: 0.3),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  completed
                                      ? Icons.replay_rounded
                                      : playing
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded,
                                  size: 36,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            IconButton(
                              onPressed: () {
                                final pos = _audioPlayer!.position + const Duration(seconds: 15);
                                final max = _audioPlayer!.duration ?? Duration.zero;
                                _audioPlayer!.seek(pos > max ? max : pos);
                              },
                              icon: const Icon(Icons.forward_10_rounded),
                              iconSize: 32,
                              color: ElevaColors.textDark,
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 32),
                ],
                if (!widget.isAdmin)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _completed ? null : _markCompleted,
                      icon: Icon(_completed ? Icons.check_circle_rounded : Icons.check_rounded),
                      label: Text(_completed ? 'Concluída!' : 'Marcar como concluída'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _completed ? ElevaColors.gold.withValues(alpha: 0.3) : ElevaColors.gold,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
