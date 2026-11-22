import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/eleva_design.dart';
import '../../auth/providers/user_profile_provider.dart';
import '../providers/subscription_provider.dart';
import '../services/revenuecat_service.dart';
import 'paywall_screen.dart';

class ManageSubscriptionScreen extends ConsumerStatefulWidget {
  const ManageSubscriptionScreen({super.key});

  @override
  ConsumerState<ManageSubscriptionScreen> createState() =>
      _ManageSubscriptionScreenState();
}

class _ManageSubscriptionScreenState
    extends ConsumerState<ManageSubscriptionScreen> {
  bool _willRenew = true;
  int _daysRemaining = 0;
  bool _loaded = false;
  bool _cancelling = false;

  @override
  void initState() {
    super.initState();
    _loadEntitlementInfo();
  }

  Future<void> _loadEntitlementInfo() async {
    try {
      if (kIsWeb) {
        // No web, usar dados do Supabase profile (já sincronizado pelo verify-subscription)
        final profile = ref.read(userProfileProvider).value;
        if (profile != null && profile.isPremium && mounted) {
          final willRenew = profile.subscriptionWillRenew;
          int days = 0;
          if (profile.subscriptionEndDate != null) {
            days = profile.subscriptionEndDate!.difference(DateTime.now()).inDays;
            if (days < 0) days = 0;
          }
          setState(() {
            _willRenew = willRenew;
            _daysRemaining = days;
            _loaded = true;
          });
        }
        return;
      }

      // Mobile: usar RevenueCat
      final customerInfo = await Purchases.getCustomerInfo();
      final entitlement = customerInfo.entitlements.all['premium'];
      if (entitlement != null && entitlement.isActive && mounted) {
        final willRenew = entitlement.willRenew;
        int days = 0;
        if (entitlement.expirationDate != null) {
          final expDate = DateTime.parse(entitlement.expirationDate!);
          days = expDate.difference(DateTime.now()).inDays;
          if (days < 0) days = 0;
        }
        setState(() {
          _willRenew = willRenew;
          _daysRemaining = days;
          _loaded = true;
        });
      }
    } catch (e) {
      debugPrint('Error loading entitlement info: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(subscriptionStatusProvider);
    final period = ref.watch(subscriptionPeriodProvider);
    final isTrialActive = ref.watch(isTrialActiveProvider);
    final trialDays = ref.watch(trialDaysRemainingProvider);
    final isPaid = status == 'premium';

    return Scaffold(
      backgroundColor: EDColors.surface,
      appBar: EDDecor.appBar(context, 'Gerenciar assinatura'),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: isPaid
                ? _buildPremium(period)
                : _buildFree(isTrialActive, trialDays),
          ),
        ),
      ),
    );
  }

  Widget _buildFree(bool isTrialActive, int trialDays) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: EDColors.navy,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isTrialActive ? 'PERÍODO DE TESTE' : 'SEM ASSINATURA',
                style: EDText.eyebrow(color: EDColors.gold),
              ),
              const SizedBox(height: 8),
              Text(
                isTrialActive
                    ? '$trialDays ${trialDays == 1 ? 'dia restante' : 'dias restantes'}'
                    : 'Seu teste terminou',
                style: EDText.display(size: 30, weight: FontWeight.w500, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                'Assine o Premium para ter acesso ilimitado a todos os conteúdos.',
                style: EDText.body(color: EDColors.onNavyMuted, height: 1.45),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: EDDecor.primaryButton().copyWith(
                  backgroundColor: const WidgetStatePropertyAll(EDColors.gold),
                  foregroundColor: const WidgetStatePropertyAll(EDColors.ink),
                ),
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const PaywallScreen()),
                  );
                },
                child: const Text('Ver planos'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('O que o Premium inclui', style: EDText.body(size: 16, weight: FontWeight.w800)),
        const SizedBox(height: 12),
        ..._benefits(),
      ],
    );
  }

  Widget _buildPremium(String? period) {
    final planName = period == 'annual' ? 'Premium Anual' : 'Premium Mensal';
    final cancelled = _loaded && !_willRenew;

    final String renewText = cancelled
        ? 'Acesso até o fim do período · $_daysRemaining ${_daysRemaining == 1 ? 'dia' : 'dias'}'
        : (period == 'annual' ? 'Renova anualmente' : 'Renova mensalmente');

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: EDColors.navy,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: EDColors.navySoft,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.workspace_premium_rounded, color: EDColors.gold),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: cancelled ? const Color(0xFFFDECEA) : EDColors.gold,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          cancelled ? Icons.cancel_rounded : Icons.check_circle_rounded,
                          size: 16,
                          color: cancelled ? EDColors.danger : EDColors.ink,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          cancelled ? 'Cancelada' : 'Ativa',
                          style: EDText.body(
                            size: 12,
                            weight: FontWeight.w800,
                            color: cancelled ? EDColors.danger : EDColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                planName,
                style: EDText.display(size: 30, weight: FontWeight.w500, color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(renewText, style: EDText.body(color: EDColors.onNavyMuted)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('Seu plano inclui', style: EDText.body(size: 16, weight: FontWeight.w800)),
        const SizedBox(height: 12),
        ..._benefits(),
        const SizedBox(height: 24),
        if (cancelled)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: EDColors.goldSoft,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: EDColors.goldInk),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Sua assinatura foi cancelada e expira em $_daysRemaining ${_daysRemaining == 1 ? 'dia' : 'dias'}.',
                    style: EDText.body(size: 13, weight: FontWeight.w600, color: EDColors.goldInk),
                  ),
                ),
              ],
            ),
          )
        else ...[
          OutlinedButton.icon(
            style: EDDecor.secondaryButton(color: EDColors.danger),
            onPressed: _cancelling ? null : () => _cancelSubscription(context),
            icon: _cancelling
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: EDColors.danger),
                  )
                : const Icon(Icons.cancel_outlined, size: 20),
            label: Text(_cancelling ? 'Cancelando...' : 'Cancelar assinatura'),
          ),
          const SizedBox(height: 10),
          Text(
            kIsWeb
                ? 'Você mantém o acesso até o fim do período pago.'
                : 'O cancelamento é feito pela loja onde você assinou.',
            textAlign: TextAlign.center,
            style: EDText.body(size: 12, color: EDColors.inkMuted),
          ),
        ],
      ],
    );
  }

  List<Widget> _benefits() => const [
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
      ];

  Future<void> _cancelSubscription(BuildContext context) async {
    final String dialogContent = kIsWeb
        ? 'Sua assinatura será cancelada. Você manterá acesso até o fim do período pago. Deseja continuar?'
        : 'Você será redirecionado para a loja de aplicativos para gerenciar sua assinatura. Deseja continuar?';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => EDDialog(
        icon: Icons.cancel_outlined,
        iconColor: EDColors.danger,
        iconBackground: const Color(0xFFFDECEA),
        title: 'Cancelar assinatura?',
        message: dialogContent,
        actions: [
          ElevatedButton(
            style: EDDecor.dangerButton(),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Cancelar assinatura'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: EDColors.inkMuted,
              minimumSize: const Size(double.infinity, 48),
            ),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Manter assinatura', style: EDText.body(weight: FontWeight.w700, color: EDColors.inkMuted)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (kIsWeb) {
      await _cancelWebSubscription();
      return;
    }

    Uri storeUrl;
    if (Platform.isIOS) {
      storeUrl = Uri.parse('https://apps.apple.com/account/subscriptions');
    } else {
      storeUrl =
          Uri.parse('https://play.google.com/store/account/subscriptions');
    }

    await launchUrl(storeUrl, mode: LaunchMode.externalApplication);

    await Future.delayed(const Duration(seconds: 3));
    await RevenueCatService.syncSubscriptionStatus();
    if (mounted) {
      ref.invalidate(userProfileProvider);
      await _loadEntitlementInfo();
    }
  }

  Future<void> _cancelWebSubscription() async {
    setState(() => _cancelling = true);

    try {
      final response = await Supabase.instance.client.functions.invoke(
        'cancel-subscription',
        method: HttpMethod.post,
      );

      if (!mounted) return;

      if (response.status == 200) {
        ref.invalidate(userProfileProvider);

        // Usar dados da resposta diretamente em vez de esperar o Realtime
        int days = 0;
        if (response.data is Map && response.data['current_period_end'] != null) {
          final endDate = DateTime.tryParse(response.data['current_period_end']);
          if (endDate != null) {
            days = endDate.difference(DateTime.now()).inDays;
            if (days < 0) days = 0;
          }
        }

        if (mounted) {
          setState(() {
            _willRenew = false;
            _daysRemaining = days;
            _loaded = true;
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Assinatura cancelada. Acesso mantido até o fim do período.'),
              backgroundColor: EDColors.blue,
            ),
          );
        }
      } else {
        final errorMsg = response.data is Map
            ? (response.data['error'] ?? 'Erro desconhecido')
            : 'Erro ao cancelar assinatura';

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$errorMsg'),
              backgroundColor: Colors.red.shade400,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao cancelar: $e'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
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
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: EDDecor.card(radius: 18),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: EDColors.blueSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: EDColors.blue, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: EDText.body(size: 15, weight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(subtitle, style: EDText.body(size: 13, color: EDColors.inkMuted, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
