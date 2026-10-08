import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme.dart';
import '../providers/subscription_provider.dart';
import 'paywall_screen.dart';

class ManageSubscriptionScreen extends ConsumerWidget {
  const ManageSubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(subscriptionStatusProvider);
    final period = ref.watch(subscriptionPeriodProvider);
    final isPaid = status == 'premium';

    if (!isPaid) {
      return const PaywallScreen();
    }

    final planName = period == 'annual' ? 'Premium Anual' : 'Premium Mensal';
    final renewText =
        period == 'annual' ? 'Renova anualmente' : 'Renova mensalmente';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: ElevaColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Gerenciar assinatura',
          style: TextStyle(color: ElevaColors.textDark),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [ElevaColors.gold, ElevaColors.goldDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.workspace_premium_rounded,
                      color: ElevaColors.white,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      planName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: ElevaColors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      renewText,
                      style: TextStyle(
                        fontSize: 14,
                        color: ElevaColors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: ElevaColors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded,
                              color: ElevaColors.white, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Assinatura ativa',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: ElevaColors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _InfoTile(
                icon: Icons.auto_awesome_rounded,
                title: 'Conteúdo ilimitado',
                subtitle: 'Acesso a todas as leituras, meditações e desafios',
              ),
              _InfoTile(
                icon: Icons.groups_rounded,
                title: 'Comunidade',
                subtitle: 'Acesso à comunidade, fórum e grupos exclusivos',
              ),
              _InfoTile(
                icon: Icons.favorite_rounded,
                title: 'Apoio ao Eleva',
                subtitle: 'Você ajuda a manter o app funcionando',
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _cancelSubscription(context),
                  icon: const Icon(Icons.cancel_outlined, size: 20),
                  label: const Text('Cancelar assinatura'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade400,
                    side: BorderSide(color: Colors.red.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'O cancelamento é feito pela loja onde você assinou.',
                style: TextStyle(
                  fontSize: 12,
                  color: ElevaColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _cancelSubscription(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Cancelar assinatura',
          style: TextStyle(color: ElevaColors.textDark),
        ),
        content: const Text(
          'Você será redirecionado para a loja de aplicativos para gerenciar sua assinatura. Deseja continuar?',
          style: TextStyle(fontSize: 14, color: ElevaColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Voltar',
                style: TextStyle(color: ElevaColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Continuar',
                style: TextStyle(
                    color: Colors.red.shade400, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    Uri storeUrl;
    if (kIsWeb) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Para cancelar, acesse a loja onde você fez a assinatura.'),
            backgroundColor: ElevaColors.gold,
          ),
        );
      }
      return;
    } else if (Platform.isIOS) {
      storeUrl = Uri.parse('https://apps.apple.com/account/subscriptions');
    } else {
      storeUrl =
          Uri.parse('https://play.google.com/store/account/subscriptions');
    }

    await launchUrl(storeUrl, mode: LaunchMode.externalApplication);
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: ElevaColors.goldLight.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: ElevaColors.gold, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: ElevaColors.textDark,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: ElevaColors.textMuted,
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
