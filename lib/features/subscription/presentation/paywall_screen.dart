import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  bool _loadingOfferings = false;
  bool _offeringsError = false;
  Package? _monthlyPkg;
  Package? _annualPkg;
  int _selectedPlan = 1; // 0 = mensal, 1 = anual (pré-selecionado)

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    if (kIsWeb) return;
    setState(() {
      _loadingOfferings = true;
      _offeringsError = false;
    });
    try {
      final offerings = await RevenueCatService.getOfferings();
      if (offerings?.current != null && mounted) {
        final packages = offerings!.current!.availablePackages;
        setState(() {
          _monthlyPkg = packages
              .where((p) => p.packageType == PackageType.monthly)
              .firstOrNull;
          _annualPkg = packages
              .where((p) => p.packageType == PackageType.annual)
              .firstOrNull;
          _monthlyPkg ??= packages.isNotEmpty ? packages.first : null;
        });
      } else if (mounted) {
        setState(() => _offeringsError = true);
      }
    } catch (_) {
      if (mounted) setState(() => _offeringsError = true);
    } finally {
      if (mounted) setState(() => _loadingOfferings = false);
    }
  }

  Package? get _selectedPackage =>
      _selectedPlan == 0 ? _monthlyPkg : _annualPkg;

  String get _selectedPeriod => _selectedPlan == 0 ? 'monthly' : 'annual';

  double? get _savingsPercent {
    if (_monthlyPkg == null || _annualPkg == null) return null;
    final monthlyYearly = _monthlyPkg!.storeProduct.price * 12;
    final annualPrice = _annualPkg!.storeProduct.price;
    if (monthlyYearly <= 0) return null;
    return ((monthlyYearly - annualPrice) / monthlyYearly * 100);
  }

  Future<void> _purchase() async {
    if (kIsWeb) {
      _purchaseWeb();
      return;
    }
    final pkg = _selectedPackage;
    if (pkg == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Carregando planos... Tente novamente em instantes.'),
          backgroundColor: ElevaColors.gold,
        ),
      );
      _loadOfferings();
      return;
    }
    setState(() => _loading = true);
    try {
      final success = await RevenueCatService.purchasePackage(pkg);
      if (success) {
        await _syncSubscriptionToSupabase();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Assinatura ativada com sucesso!'),
              backgroundColor: ElevaColors.gold,
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao processar compra: $e'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Substitua pelos Payment Links reais do Stripe Dashboard
  static const _stripeMonthlyLink = 'https://buy.stripe.com/6oUbJ26BS0f1gKD3dadwc01';
  static const _stripeAnnualLink = 'https://buy.stripe.com/9B69AUe4k6Dpbqj5lidwc02';

  Future<void> _purchaseWeb() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    final email = Supabase.instance.client.auth.currentUser?.email;

    final baseUrl =
        _selectedPlan == 0 ? _stripeMonthlyLink : _stripeAnnualLink;

    final params = <String, String>{};
    if (userId != null) params['client_reference_id'] = userId;
    if (email != null) params['prefilled_email'] = email;

    final uri = Uri.parse(baseUrl).replace(queryParameters: params);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _restore() async {
    setState(() => _loading = true);
    try {
      if (kIsWeb) {
        await _checkWebSubscription();
      } else {
        final customerInfo = await RevenueCatService.restorePurchases();
        if (customerInfo != null &&
            customerInfo.entitlements.all['premium']?.isActive == true) {
          await _syncSubscriptionToSupabase();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Compra restaurada com sucesso!'),
                backgroundColor: ElevaColors.gold,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Nenhuma assinatura encontrada.'),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao verificar assinatura: $e'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _checkWebSubscription() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final data = await Supabase.instance.client
        .from('profiles')
        .select('subscription_status')
        .eq('id', userId)
        .single();

    if (data['subscription_status'] == 'premium') {
      ref.invalidate(isPremiumProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Assinatura confirmada!'),
            backgroundColor: ElevaColors.gold,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Assinatura ainda não encontrada. Aguarde alguns instantes e tente novamente.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _syncSubscriptionToSupabase() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    await Supabase.instance.client.from('profiles').update({
      'subscription_status': 'premium',
      'subscription_period': _selectedPeriod,
    }).eq('id', userId);
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
              const SizedBox(height: 32),
              if (_loadingOfferings)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: CircularProgressIndicator(color: ElevaColors.gold),
                )
              else if (_offeringsError && !kIsWeb)
                Column(
                  children: [
                    const Text(
                      'Não foi possível carregar os planos.',
                      style: TextStyle(fontSize: 14, color: ElevaColors.textMuted),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _loadOfferings,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Tentar novamente'),
                    ),
                  ],
                )
              else ...[
                _buildPlanCards(),
                const SizedBox(height: 28),
                if (_loading)
                  const CircularProgressIndicator(color: ElevaColors.gold)
                else ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _purchase,
                      child: Text(_buildCtaText()),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _restore,
                    child: Text(
                      kIsWeb ? 'Já assinei' : 'Restaurar compras',
                      style: const TextStyle(color: ElevaColors.gold),
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  String _buildCtaText() {
    if (kIsWeb) {
      return _selectedPlan == 0
          ? 'Assinar mensal — R\$19,90/mês'
          : 'Assinar anual — R\$158,90/ano';
    }
    final pkg = _selectedPackage;
    if (pkg == null) return 'Assinar agora';
    return 'Assinar — ${pkg.storeProduct.priceString}';
  }

  Widget _buildPlanCards() {
    final monthlyPrice = kIsWeb
        ? 'R\$19,90'
        : _monthlyPkg?.storeProduct.priceString ?? 'R\$19,90';
    final annualPrice = kIsWeb
        ? 'R\$158,90'
        : _annualPkg?.storeProduct.priceString ?? 'R\$158,90';

    String annualMonthly;
    double? savings = _savingsPercent;
    if (!kIsWeb && _annualPkg != null) {
      final perMonth = _annualPkg!.storeProduct.price / 12;
      annualMonthly =
          '${_annualPkg!.storeProduct.currencyCode} ${perMonth.toStringAsFixed(2)}';
    } else {
      annualMonthly = 'R\$13,24';
      savings = 33;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _PlanCard(
              label: 'Mensal',
              price: monthlyPrice,
              period: '/mês',
              selected: _selectedPlan == 0,
              onTap: () => setState(() => _selectedPlan = 0),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _PlanCard(
              label: 'Anual',
              price: annualMonthly,
              period: '/mês',
              subtitle: '$annualPrice/ano',
              savingsPercent: savings?.round(),
              selected: _selectedPlan == 1,
              onTap: () => setState(() => _selectedPlan = 1),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String label;
  final String price;
  final String period;
  final String? subtitle;
  final int? savingsPercent;
  final bool selected;
  final VoidCallback onTap;

  const _PlanCard({
    required this.label,
    required this.price,
    required this.period,
    this.subtitle,
    this.savingsPercent,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? ElevaColors.goldLight.withValues(alpha: 0.2)
              : ElevaColors.offWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? ElevaColors.gold : const Color(0xFFDDDDDD),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  selected ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: selected ? ElevaColors.gold : ElevaColors.textMuted,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: selected ? ElevaColors.gold : ElevaColors.textDark,
                  ),
                ),
              ],
            ),
            if (savingsPercent != null && savingsPercent! > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: ElevaColors.gold,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Economize $savingsPercent%',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: ElevaColors.white,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: price,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: selected ? ElevaColors.gold : ElevaColors.textDark,
                    ),
                  ),
                  TextSpan(
                    text: period,
                    style: const TextStyle(
                      fontSize: 13,
                      color: ElevaColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: const TextStyle(
                  fontSize: 12,
                  color: ElevaColors.textMuted,
                ),
              ),
            ],
          ],
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
