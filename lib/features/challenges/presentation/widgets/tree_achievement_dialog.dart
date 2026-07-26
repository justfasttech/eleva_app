import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme.dart';

class TreeAchievementDialog extends StatelessWidget {
  final int level;

  const TreeAchievementDialog({super.key, required this.level});

  static const _treeLevels = [
    '', // 0 - nunca mostrado
    'Semente',
    'Broto',
    'Raiz',
    'Crescimento',
    'Fortalecimento',
    'Enraizamento',
    'Florescimento',
    'Frutificação',
    'Abundância',
    'Maturidade',
    'Sabedoria',
    'Resiliência',
    'Plenitude',
    'Árvore da Vida',
  ];

  static const _treeMessages = [
    '', // 0 - nunca mostrado
    'A fé está nascendo no seu coração. Tudo começa aqui.',
    'Um broto surge! Sua jornada espiritual começa a tomar forma.',
    'Suas raízes estão se firmando na Palavra de Deus.',
    'Sua fé está crescendo e se fortalecendo através da oração.',
    'Você está se fortalecendo espiritualmente a cada dia.',
    'Sua fé já tem base sólida. Você se mantém firme nas dificuldades.',
    'Flores desabrocham! Sua vida espiritual está florescendo.',
    'Você começa a dar frutos e impactar outras vidas com o amor de Deus.',
    'A abundância de Deus se manifesta na sua caminhada de fé.',
    'Sua fé é sólida e madura. Você anda com Deus diariamente.',
    'A sabedoria divina guia seus passos e decisões.',
    'Sua fé é resiliente. Nenhuma tempestade abala suas raízes.',
    'Você vive o propósito de Deus em plenitude e inspira muitos ao redor.',
    'Sua fé é uma Árvore da Vida — inspiração para gerações.',
  ];

  @override
  Widget build(BuildContext context) {
    final message = level < _treeMessages.length ? _treeMessages[level] : '';
    final levelName = level < _treeLevels.length ? _treeLevels[level] : '';

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
                  'assets/images/trees/$level.png',
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
