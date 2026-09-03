import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/theme.dart';
import '../models/spiritual_reading.dart';

class ReadingDetailScreen extends ConsumerStatefulWidget {
  final SpiritualReading reading;
  final bool isAdmin;

  const ReadingDetailScreen({super.key, required this.reading, this.isAdmin = false});

  @override
  ConsumerState<ReadingDetailScreen> createState() => _ReadingDetailScreenState();
}

class _ReadingDetailScreenState extends ConsumerState<ReadingDetailScreen> {
  bool _completed = false;
  AudioPlayer? _player;
  bool _isLoadingAudio = false;
  String? _audioError;

  @override
  void initState() {
    super.initState();
    if (widget.reading.hasAudio) {
      _initAudio();
    }
  }

  Future<void> _initAudio() async {
    _player = AudioPlayer();
    setState(() => _isLoadingAudio = true);
    try {
      await _player!.setUrl(widget.reading.audioUrl!);
      if (mounted) setState(() => _isLoadingAudio = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingAudio = false;
          _audioError = 'Erro ao carregar áudio';
        });
      }
    }
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  void _markCompleted() {
    if (_completed) return;
    setState(() => _completed = true);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Leitura concluída!'),
        backgroundColor: ElevaColors.gold,
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final reading = widget.reading;

    return Scaffold(
      backgroundColor: ElevaColors.offWhite,
      appBar: AppBar(
        backgroundColor: ElevaColors.gold,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          reading.title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  if (reading.hasAudio) _buildAudioPlayer(),
                  if (reading.hasAudio) const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: ElevaColors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (reading.reference != null) ...[
                          Text(
                            reading.reference!,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: ElevaColors.gold,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (reading.author != null) ...[
                          Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: ElevaColors.gold.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.person_rounded,
                                  size: 16,
                                  color: ElevaColors.gold,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                reading.author!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: ElevaColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Divider(color: ElevaColors.offWhite, height: 1),
                          const SizedBox(height: 20),
                        ],
                        SelectableText(
                          reading.content,
                          style: const TextStyle(
                            fontSize: 17,
                            height: 1.8,
                            color: ElevaColors.textDark,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!widget.isAdmin)
            Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(context).padding.bottom + 16),
              child: SizedBox(
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
            ),
        ],
      ),
    );
  }

  Widget _buildAudioPlayer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ElevaColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: ElevaColors.gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.headphones_rounded,
                    size: 18, color: ElevaColors.gold),
              ),
              const SizedBox(width: 12),
              const Text(
                'Ouvir leitura',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: ElevaColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoadingAudio)
            const Padding(
              padding: EdgeInsets.all(8),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: ElevaColors.gold),
              ),
            )
          else if (_audioError != null)
            Text(_audioError!,
                style: const TextStyle(
                    fontSize: 13, color: ElevaColors.textMuted))
          else ...[
            StreamBuilder<Duration>(
              stream: _player!.positionStream,
              builder: (context, posSnap) {
                final position = posSnap.data ?? Duration.zero;
                final total = _player!.duration ?? Duration.zero;
                return Column(
                  children: [
                    SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6),
                        overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 14),
                        activeTrackColor: ElevaColors.gold,
                        inactiveTrackColor:
                            ElevaColors.gold.withValues(alpha: 0.15),
                        thumbColor: ElevaColors.gold,
                        overlayColor:
                            ElevaColors.gold.withValues(alpha: 0.1),
                      ),
                      child: Slider(
                        min: 0,
                        max: total.inMilliseconds
                            .toDouble()
                            .clamp(1, double.infinity),
                        value: position.inMilliseconds.toDouble().clamp(
                            0,
                            total.inMilliseconds
                                .toDouble()
                                .clamp(1, double.infinity)),
                        onChanged: (v) {
                          _player!
                              .seek(Duration(milliseconds: v.toInt()));
                        },
                      ),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatDuration(position),
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: ElevaColors.textMuted)),
                          Text(_formatDuration(total),
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: ElevaColors.textMuted)),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            StreamBuilder<PlayerState>(
              stream: _player!.playerStateStream,
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
                        final pos =
                            _player!.position - const Duration(seconds: 10);
                        _player!.seek(
                            pos < Duration.zero ? Duration.zero : pos);
                      },
                      icon: const Icon(Icons.replay_10_rounded),
                      iconSize: 28,
                      color: ElevaColors.textDark,
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        if (completed) {
                          _player!.seek(Duration.zero);
                          _player!.play();
                        } else if (playing) {
                          _player!.pause();
                        } else {
                          _player!.play();
                        }
                      },
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [ElevaColors.gold, ElevaColors.goldLight],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: ElevaColors.gold.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          completed
                              ? Icons.replay_rounded
                              : playing
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                          size: 28,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                        final pos =
                            _player!.position + const Duration(seconds: 10);
                        final max = _player!.duration ?? Duration.zero;
                        _player!.seek(pos > max ? max : pos);
                      },
                      icon: const Icon(Icons.forward_10_rounded),
                      iconSize: 28,
                      color: ElevaColors.textDark,
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
