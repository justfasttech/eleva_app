import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../home/providers/faith_history_recorder.dart';
import '../utils/faith_analyzer.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    setState(() => _saving = true);

    final text = _controller.text.trim();
    final score = analyzeFaithLevel(text);

    await Supabase.instance.client.from('profiles').update({
      'faith_level': score,
      'faith_description': text,
      'onboarding_completed': true,
    }).eq('id', user.id);

    await recordFaithSnapshot(user.id, score);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
              28, 40, 28, MediaQuery.of(context).viewInsets.bottom + 28),
          child: Column(
            children: [
              Image.asset('assets/images/logo.png', height: 64),
              const SizedBox(height: 32),
              const Text(
                'Bem-vindo ao Eleva!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: ElevaColors.textDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Conte-nos um pouco sobre você e sua\njornada de fé.',
                style: TextStyle(
                  fontSize: 15,
                  color: ElevaColors.textMuted,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              Container(
                decoration: BoxDecoration(
                  color: ElevaColors.offWhite,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
                  controller: _controller,
                  maxLines: 7,
                  maxLength: 500,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText:
                        'Escreva sobre sua experiência espiritual, suas práticas, o que busca nessa jornada...',
                    hintMaxLines: 3,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                    counterStyle: TextStyle(
                      fontSize: 11,
                      color: ElevaColors.textMuted,
                    ),
                  ),
                  style: const TextStyle(
                    fontSize: 14,
                    color: ElevaColors.textDark,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: ElevaColors.gold.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 18, color: ElevaColors.gold),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Com base no que você escrever, vamos definir seu nível inicial de fé para personalizar sua experiência.',
                        style: TextStyle(
                          fontSize: 12,
                          color: ElevaColors.gold,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _continue,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Continuar'),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
