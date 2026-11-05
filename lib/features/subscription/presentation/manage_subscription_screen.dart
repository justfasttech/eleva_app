import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme.dart';
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

  @override
  void initState() {
    super.initState();
    _loadEntitlementInfo();
  }

  Future<void> _loadEntitlementInfo() async {
    try {
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
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(subscriptionStatusProvider);
    final period = ref.watch(subscriptionPeriodProvider);
    final isPaid = status == 'premium';

    if (!isPaid) {
      return const PaywallScreen();
    }

    final planName = period == 'annual' ? 'Premium Anual' : 'Premium Mensal';

    final String renewText;
    if (_loaded && !_willRenew) {
      renewText = 'Cancelado — $_daysRemaining dias restantes';
    } else {
      renewText =
          period == 'annual' ? 'Renova anualmente' : 'Renova mensalmente';
    }

    final String statusLabel;
    final IconData statusIcon;
    if (_loaded && !_willRenew) {
      statusLabel = 'Cancelado';
      statusIcon = Icons.cancel_rounded;
    } else {
      statusLabel = 'Assinatura ativa';
      statusIcon = Icons.check_circle_rounded;
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_rounded, color: ElevaColors.textDark),
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
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon,
                              color: ElevaColors.white, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            statusLabel,
                            style: const TextStyle(
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
                subtitle:
                    'Acesso a todas as leituras, meditações e desafios',
              ),
              _InfoTile(
                icon: Icons.groups_rounded,
                title: 'Comunidade',
                subtitle:
                    'Acesso à comunidade, fórum e grupos exclusivos',
              ),
              _InfoTile(
                icon: Icons.favorite_rounded,
                title: 'Apoio ao Eleva',
                subtitle: 'Você ajuda a manter o app funcionando',
              ),
              const Spacer(),
              if (_loaded && !_willRenew)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Sua assinatura foi cancelada e expira em $_daysRemaining dias.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              else ...[
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
              ],
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
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                    color: Colors.red.shade400,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    Uri storeUrl;
    if (kIsWeb) {
      final managementURL = await RevenueCatService.getManagementURL();
      if (managementURL != null) {
        await launchUrl(Uri.parse(managementURL),
            mode: LaunchMode.externalApplication);
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Não foi possível abrir o gerenciamento. Tente novamente.'),
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
