// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:web/web.dart' as web;

class InlineVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final bool autoplay;
  const InlineVideoPlayer({super.key, required this.videoUrl, this.autoplay = true});

  @override
  State<InlineVideoPlayer> createState() => _InlineVideoPlayerState();
}

class _InlineVideoPlayerState extends State<InlineVideoPlayer> {
  static int _counter = 0;
  late final String _viewType;
  web.HTMLVideoElement? _video;

  @override
  void initState() {
    super.initState();
    _viewType = 'eleva-video-${_counter++}';
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final el = web.HTMLVideoElement()
        ..src = widget.videoUrl
        ..autoplay = false
        ..muted = true
        ..controls = true
        ..loop = true
        ..preload = 'metadata';
      el.style.width = '100%';
      el.style.height = '100%';
      el.style.objectFit = 'contain';
      el.style.backgroundColor = '#000';
      _video = el;
      return el;
    });
  }

  @override
  void dispose() {
    _video?.pause();
    _video = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key('video_${widget.videoUrl}'),
      onVisibilityChanged: widget.autoplay
          ? (info) {
              final v = _video;
              if (v == null) return;
              try {
                if (info.visibleFraction > 0.5) {
                  v.play();
                } else {
                  v.pause();
                }
              } catch (_) {}
            }
          : (_) {},
      child: Container(
        color: const Color(0xFF000000),
        width: double.infinity,
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: HtmlElementView(viewType: _viewType),
        ),
      ),
    );
  }
}
