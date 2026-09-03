import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';

import '../../../core/theme.dart';
import '../models/prayer.dart';

class PrayerDetailScreen extends StatefulWidget {
  final Prayer prayer;

  const PrayerDetailScreen({super.key, required this.prayer});

  @override
  State<PrayerDetailScreen> createState() => _PrayerDetailScreenState();
}

class _PrayerDetailScreenState extends State<PrayerDetailScreen> {
  AudioPlayer? _audioPlayer;
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isLoadingMedia = false;
  String? _mediaError;

  @override
  void initState() {
    super.initState();
    if (widget.prayer.hasVideo) {
      _initVideo();
    }
    if (widget.prayer.hasAudio) {
      _initAudio();
    }
  }

  Future<void> _initVideo() async {
    setState(() => _isLoadingMedia = true);
    _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.prayer.videoUrl!));
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
          _isLoadingMedia = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMedia = false;
          _mediaError = 'Erro ao carregar vídeo';
        });
      }
    }
  }

  Future<void> _initAudio() async {
    _audioPlayer = AudioPlayer();
    setState(() => _isLoadingMedia = true);
    try {
      await _audioPlayer!.setUrl(widget.prayer.audioUrl!);
      if (mounted) setState(() => _isLoadingMedia = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMedia = false;
          _mediaError = 'Erro ao carregar áudio';
        });
      }
    }
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

  @override
  Widget build(BuildContext context) {
    final prayer = widget.prayer;

    return Scaffold(
      backgroundColor: ElevaColors.offWhite,
      appBar: AppBar(
        backgroundColor: ElevaColors.gold,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          prayer.title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (prayer.hasVideo) _buildVideoPlayer(),
            if (prayer.hasVideo) const SizedBox(height: 16),
            if (prayer.hasAudio) _buildAudioPlayer(),
            if (prayer.hasAudio) const SizedBox(height: 16),
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
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: ElevaColors.gold.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.volunteer_activism_rounded,
                          size: 20,
                          color: ElevaColors.gold,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Oração',
                        style: TextStyle(
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
                  SelectableText(
                    prayer.content,
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
    );
  }

  Widget _buildVideoPlayer() {
    return Container(
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
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          if (_isLoadingMedia)
            const Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: ElevaColors.gold),
            )
          else if (_mediaError != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_mediaError!,
                  style: const TextStyle(fontSize: 13, color: ElevaColors.textMuted)),
            )
          else if (_chewieController != null)
            AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: Chewie(controller: _chewieController!),
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
                'Ouvir oração',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: ElevaColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoadingMedia)
            const Padding(
              padding: EdgeInsets.all(8),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: ElevaColors.gold),
              ),
            )
          else if (_mediaError != null)
            Text(_mediaError!,
                style: const TextStyle(
                    fontSize: 13, color: ElevaColors.textMuted))
          else ...[
            StreamBuilder<Duration>(
              stream: _audioPlayer!.positionStream,
              builder: (context, posSnap) {
                final position = posSnap.data ?? Duration.zero;
                final total = _audioPlayer!.duration ?? Duration.zero;
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
                          _audioPlayer!
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
                        final pos =
                            _audioPlayer!.position - const Duration(seconds: 10);
                        _audioPlayer!.seek(
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
                          _audioPlayer!.seek(Duration.zero);
                          _audioPlayer!.play();
                        } else if (playing) {
                          _audioPlayer!.pause();
                        } else {
                          _audioPlayer!.play();
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
                            _audioPlayer!.position + const Duration(seconds: 10);
                        final max = _audioPlayer!.duration ?? Duration.zero;
                        _audioPlayer!.seek(pos > max ? max : pos);
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
