import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme.dart';
import '../providers/subscription_provider.dart';
import '../services/revenuecat_service.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  bool _loading = false;
  Offerings? _offerings;

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    if (kIsWeb) return;
    final offerings = await RevenueCatService.getOfferings();
    if (mounted) setState(() => _offerings = offerings);
  }

  Future<void> _purchase(Package package) async {
    setState(() => _loading = true);
    await RevenueCatService.purchasePackage(package);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _purchaseWeb() async {
    // TODO: Substituir pela URL real do RevenueCat Web / Stripe Checkout
    const checkoutUrl = 'https://your-stripe-checkout-url.com';
    final uri = Uri.parse(checkoutUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _restore() async {
    setState(() => _loading = true);
    await RevenueCatService.restorePurchases();
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final trialDays = ref.watch(trialDaysRemainingProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(
            children: [
              const SizedBox(height: 24),
              Image.asset('assets/images/logo.png', height: 72),
              const SizedBox(height: 24),
              const Text(
                'Eleve sua fé sem limites',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: ElevaColors.textDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                trialDays > 0
                    ? 'Seu período de teste expira em $trialDays dias.'
                    : 'Seu período de teste expirou.',
                style: const TextStyle(
                  fontSize: 15,
                  color: ElevaColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),
              _BenefitRow(
                icon: Icons.auto_awesome_rounded,
                text: 'Conteúdo ilimitado todos os dias',
              ),
              _BenefitRow(
                icon: Icons.menu_book_rounded,
                text: 'Leituras, meditações e orações sem restrições',
              ),
              _BenefitRow(
                icon: Icons.psychology_rounded,
                text: 'Acesso a todos os desafios de fé',
              ),
              _BenefitRow(
                icon: Icons.favorite_rounded,
                text: 'Apoie o desenvolvimento do Eleva',
              ),
              const SizedBox(height: 40),
              if (_loading)
                const CircularProgressIndicator(color: ElevaColors.gold)
              else ...[
                if (kIsWeb)
                  ElevatedButton(
                    onPressed: _purchaseWeb,
                    child: const Text('Assinar agora'),
                  )
                else if (_offerings?.current != null) ...[
                  for (final package
                      in _offerings!.current!.availablePackages)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ElevatedButton(
                        onPressed: () => _purchase(package),
                        child: Text(
                          package.storeProduct.title.isNotEmpty
                              ? '${package.storeProduct.title} — ${package.storeProduct.priceString}'
                              : 'Assinar — ${package.storeProduct.priceString}',
                        ),
                      ),
                    ),
                ] else
                  ElevatedButton(
                    onPressed: _purchaseWeb,
                    child: const Text('Assinar agora'),
                  ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _restore,
                  child: const Text(
                    'Restaurar compras',
                    style: TextStyle(color: ElevaColors.gold),
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _BenefitRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: ElevaColors.goldLight.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: ElevaColors.gold, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                color: ElevaColors.textDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
