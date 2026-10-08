import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme.dart';
import '../../../home/providers/tree_messages_provider.dart';

class TreeAchievementDialog extends ConsumerStatefulWidget {
  final int level;

  const TreeAchievementDialog({super.key, required this.level});

  @override
  ConsumerState<TreeAchievementDialog> createState() =>
      _TreeAchievementDialogState();
}

class _TreeAchievementDialogState
    extends ConsumerState<TreeAchievementDialog> {
  AudioPlayer? _audioPlayer;
  bool _isPlayerReady = false;

  @override
  void dispose() {
    _audioPlayer?.dispose();
    super.dispose();
  }

  Future<void> _initAudio(String url) async {
    try {
      _audioPlayer ??= AudioPlayer();
      await _audioPlayer!.setUrl(url);
      if (mounted) {
        setState(() => _isPlayerReady = true);
        _audioPlayer!.play();
      }
    } catch (_) {}
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(treeMessagesProvider);

    String levelName = '';
    String message = '';
    String? audioUrl;

    messagesAsync.whenData((messages) {
      final match =
          messages.where((m) => m.level == widget.level).toList();
      if (match.isNotEmpty) {
        levelName = match.first.name;
        message = match.first.message;
        audioUrl = match.first.audioUrl;
      }
    });

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Parabéns!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: ElevaColors.gold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Você alcançou: $levelName',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: ElevaColors.textDark),
            ),
            const SizedBox(height: 20),
            Container(
              height: 160,
              width: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/images/trees/${widget.level}.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.park_rounded,
                      size: 60,
                      color: ElevaColors.gold.withValues(alpha: 0.4),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: ElevaColors.textMuted,
                height: 1.5,
              ),
            ),
            if (audioUrl != null && audioUrl!.isNotEmpty) ...[
              const SizedBox(height: 16),
              if (!_isPlayerReady)
                OutlinedButton.icon(
                  onPressed: () => _initAudio(audioUrl!),
                  icon: const Icon(Icons.play_arrow_rounded, size: 20),
                  label: const Text('Ouvir mensagem'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ElevaColors.gold,
                    side: const BorderSide(color: ElevaColors.gold),
                  ),
                )
              else ...[
                StreamBuilder<Duration>(
                  stream: _audioPlayer!.positionStream,
                  builder: (context, snapshot) {
                    final position = snapshot.data ?? Duration.zero;
                    final total = _audioPlayer!.duration ?? Duration.zero;
                    final double maxMs = total.inMilliseconds.toDouble().clamp(1.0, double.infinity);
                    final double valueMs = position.inMilliseconds.toDouble().clamp(0.0, maxMs);
                    return Column(
                      children: [
                        SliderTheme(
                          data: SliderThemeData(
                            activeTrackColor: ElevaColors.gold,
                            inactiveTrackColor: ElevaColors.gold.withValues(alpha: 0.2),
                            thumbColor: ElevaColors.gold,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                            trackHeight: 3,
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                          ),
                          child: Slider(
                            value: valueMs,
                            max: maxMs,
                            onChanged: (v) => _audioPlayer!.seek(Duration(milliseconds: v.toInt())),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_formatDuration(position),
                                  style: const TextStyle(fontSize: 11, color: ElevaColors.textMuted)),
                              Text(_formatDuration(total),
                                  style: const TextStyle(fontSize: 11, color: ElevaColors.textMuted)),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
                StreamBuilder<PlayerState>(
                  stream: _audioPlayer!.playerStateStream,
                  builder: (context, snapshot) {
                    final state = snapshot.data;
                    final isPlaying = state?.playing ?? false;
                    final completed = state?.processingState == ProcessingState.completed;
                    return GestureDetector(
                      onTap: () {
                        if (completed) {
                          _audioPlayer!.seek(Duration.zero);
                          _audioPlayer!.play();
                        } else if (isPlaying) {
                          _audioPlayer!.pause();
                        } else {
                          _audioPlayer!.play();
                        }
                      },
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [ElevaColors.gold, ElevaColors.goldLight],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: ElevaColors.gold.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          completed
                              ? Icons.replay_rounded
                              : isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                          size: 26,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                SharePlus.instance.share(
                  ShareParams(
                    text: '🌳 Alcancei o nível "$levelName" no Eleva!\n\n$message\n\n#Eleva #Fé #JornadaEspiritual',
                  ),
                );
              },
              icon: const Icon(Icons.share_rounded, size: 18),
              label: const Text('Compartilhar conquista'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Fechar',
                style: TextStyle(color: ElevaColors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
