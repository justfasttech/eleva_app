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

  @override
  void dispose() {
    _audioPlayer?.dispose();
    super.dispose();
  }

  Future<void> _playAudio(String url) async {
    try {
      _audioPlayer ??= AudioPlayer();
      await _audioPlayer!.setUrl(url);
      _audioPlayer!.play();
    } catch (_) {}
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
                color: ElevaColors.offWhite,
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
              OutlinedButton.icon(
                onPressed: () => _playAudio(audioUrl!),
                icon: const Icon(Icons.play_arrow_rounded, size: 20),
                label: const Text('Ouvir mensagem'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ElevaColors.gold,
                  side: const BorderSide(color: ElevaColors.gold),
                ),
              ),
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
