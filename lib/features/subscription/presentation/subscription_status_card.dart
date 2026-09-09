import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../providers/subscription_provider.dart';

class SubscriptionStatusCard extends ConsumerWidget {
  const SubscriptionStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(subscriptionStatusProvider);
    final trialDays = ref.watch(trialDaysRemainingProvider);
    final isTrialActive = ref.watch(isTrialActiveProvider);

    final bool isPaid = status == 'premium';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: isPaid
            ? const LinearGradient(
                colors: [ElevaColors.gold, ElevaColors.goldDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isPaid ? null : ElevaColors.offWhite,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            isPaid ? Icons.star_rounded : Icons.access_time_rounded,
            color: isPaid ? ElevaColors.white : ElevaColors.gold,
            size: 28,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPaid
                      ? 'Premium'
                      : isTrialActive
                          ? 'Período de teste'
                          : 'Plano gratuito',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isPaid ? ElevaColors.white : ElevaColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isPaid
                      ? 'Acesso ilimitado a todo conteúdo'
                      : isTrialActive
                          ? '$trialDays dias restantes'
                          : 'Assine para continuar',
                  style: TextStyle(
                    fontSize: 13,
                    color: isPaid
                        ? ElevaColors.white.withValues(alpha: 0.85)
                        : ElevaColors.textMuted,
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
