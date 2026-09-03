import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../../core/theme.dart';

class InlineVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final bool autoplay;
  const InlineVideoPlayer({super.key, required this.videoUrl, this.autoplay = true});

  @override
  State<InlineVideoPlayer> createState() => _InlineVideoPlayerState();
}

class _InlineVideoPlayerState extends State<InlineVideoPlayer> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        if (mounted) setState(() => _initialized = true);
      }).catchError((_) {
        if (mounted) setState(() => _hasError = true);
      });
    _controller.addListener(_onUpdate);
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onUpdate);
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    _controller.value.isPlaying ? _controller.pause() : _controller.play();
  }

  void _toggleMute() {
    _controller.setVolume(_controller.value.volume > 0 ? 0 : 1);
  }

  void _openFullscreen() {
    _controller.pause();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullScreenVideo(
          videoUrl: widget.videoUrl,
          startPosition: _controller.value.position,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        height: 200,
        width: double.infinity,
        color: Colors.black87,
        alignment: Alignment.center,
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 40, color: Colors.white54),
            SizedBox(height: 8),
            Text('Erro ao carregar vídeo',
                style: TextStyle(color: Colors.white54, fontSize: 13)),
          ],
        ),
      );
    }

    if (!_initialized) {
      return Container(
        height: 200,
        width: double.infinity,
        color: Colors.black87,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(color: ElevaColors.gold),
      );
    }

    final isPlaying = _controller.value.isPlaying;
    final isMuted = _controller.value.volume == 0;

    return VisibilityDetector(
      key: Key('video_${widget.videoUrl}'),
      onVisibilityChanged: widget.autoplay
          ? (info) {
              if (!mounted) return;
              if (info.visibleFraction > 0.5) {
                if (!_controller.value.isPlaying) _controller.play();
              } else {
                if (_controller.value.isPlaying) _controller.pause();
              }
            }
          : (_) {},
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _openFullscreen,
            child: Container(
              color: Colors.black,
              width: double.infinity,
              child: AspectRatio(
                aspectRatio: _controller.value.aspectRatio.clamp(0.5, 3.0),
                child: VideoPlayer(_controller),
              ),
            ),
          ),
          Container(
            color: Colors.black87,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _togglePlayPause,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      size: 24,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _toggleMute,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                      size: 24,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _openFullscreen,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.fullscreen_rounded,
                      size: 24,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FullScreenVideo extends StatefulWidget {
  final String videoUrl;
  final Duration startPosition;
  const _FullScreenVideo({required this.videoUrl, required this.startPosition});

  @override
  State<_FullScreenVideo> createState() => _FullScreenVideoState();
}

class _FullScreenVideoState extends State<_FullScreenVideo> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        if (!mounted) return;
        _controller.seekTo(widget.startPosition);
        _controller.play();
        setState(() => _initialized = true);
      });
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return d.inHours > 0 ? '${d.inHours}:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
      body: Center(
        child: !_initialized
            ? const CircularProgressIndicator(color: ElevaColors.gold)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AspectRatio(
                    aspectRatio: _controller.value.aspectRatio.clamp(0.5, 3.0),
                    child: VideoPlayer(_controller),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 3,
                            thumbShape:
                                const RoundSliderThumbShape(enabledThumbRadius: 7),
                            activeTrackColor: ElevaColors.gold,
                            inactiveTrackColor: Colors.white24,
                            thumbColor: ElevaColors.gold,
                            overlayColor: ElevaColors.gold.withValues(alpha: 0.2),
                          ),
                          child: Slider(
                            value: _controller.value.duration.inMilliseconds > 0
                                ? _controller.value.position.inMilliseconds /
                                    _controller.value.duration.inMilliseconds
                                : 0,
                            onChanged: (v) {
                              _controller.seekTo(Duration(
                                  milliseconds:
                                      (v * _controller.value.duration.inMilliseconds)
                                          .toInt()));
                            },
                          ),
                        ),
                        Text(
                          '${_fmt(_controller.value.position)} / ${_fmt(_controller.value.duration)}',
                          style:
                              const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: () => _controller.setVolume(
                                  _controller.value.volume > 0 ? 0 : 1),
                              icon: Icon(
                                _controller.value.volume > 0
                                    ? Icons.volume_up_rounded
                                    : Icons.volume_off_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            IconButton(
                              onPressed: () {
                                _controller.value.isPlaying
                                    ? _controller.pause()
                                    : _controller.play();
                              },
                              icon: Icon(
                                _controller.value.isPlaying
                                    ? Icons.pause_circle_filled_rounded
                                    : Icons.play_circle_filled_rounded,
                                color: Colors.white,
                                size: 52,
                              ),
                            ),
                            const SizedBox(width: 16),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(
                                Icons.fullscreen_exit_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
