import 'package:flutter/material.dart';

import '../../../../core/theme.dart';
import 'inline_video_native.dart'
    if (dart.library.js_interop) 'inline_video_web.dart';

class PostMediaDisplay extends StatelessWidget {
  final String? imageUrl;
  final String? videoUrl;
  final bool autoplay;

  const PostMediaDisplay({
    super.key,
    this.imageUrl,
    this.videoUrl,
    this.autoplay = true,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    final hasVideo = videoUrl != null && videoUrl!.isNotEmpty;

    if (!hasImage && !hasVideo) return const SizedBox.shrink();

    return Column(
      children: [
        if (hasImage)
          GestureDetector(
            onTap: () => _showFullImage(context, imageUrl!),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 350),
              child: SizedBox(
                width: double.infinity,
                child: Image.network(
                  imageUrl!,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      height: 200,
                      color: ElevaColors.offWhite,
                      alignment: Alignment.center,
                      child: CircularProgressIndicator(
                        color: ElevaColors.gold,
                        value: progress.expectedTotalBytes != null
                            ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                  errorBuilder: (_, __, ___) => Container(
                    height: 200,
                    color: ElevaColors.offWhite,
                    alignment: Alignment.center,
                    child: const Icon(Icons.broken_image_rounded, size: 40, color: ElevaColors.textMuted),
                  ),
                ),
              ),
            ),
          ),
        if (hasImage && hasVideo) const SizedBox(height: 2),
        if (hasVideo) InlineVideoPlayer(key: ValueKey(videoUrl), videoUrl: videoUrl!, autoplay: autoplay),
      ],
    );
  }

  void _showFullImage(BuildContext context, String url) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _FullImageView(imageUrl: url)),
    );
  }
}

class _FullImageView extends StatelessWidget {
  final String imageUrl;
  const _FullImageView({required this.imageUrl});

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
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const Center(
                child: CircularProgressIndicator(color: ElevaColors.gold),
              );
            },
          ),
        ),
      ),
    );
  }
}
