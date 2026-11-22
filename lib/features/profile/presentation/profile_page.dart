import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/auth_error_translator.dart';
import '../../../core/eleva_design.dart';
import '../../auth/providers/user_profile_provider.dart';
import '../../community/providers/friends_provider.dart';
import '../../subscription/presentation/manage_subscription_screen.dart';
import '../../subscription/presentation/paywall_screen.dart';
import '../../subscription/providers/subscription_provider.dart';
import 'edit_profile_page.dart';
import 'privacy_policy_page.dart';
import 'widgets/profile_avatar.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email ?? '';
    final firstName = user?.userMetadata?['name'] as String? ?? '';
    final surname = user?.userMetadata?['surname'] as String? ?? '';
    final name = firstName.isNotEmpty
        ? '$firstName${surname.isNotEmpty ? ' $surname' : ''}'
        : email.split('@').first;

    final profile = ref.watch(userProfileProvider).value;
    final faithPoints = profile?.faithLevel ?? 0;
    final stage = FaithStage.fromPoints(faithPoints);
    final friendsCount = ref.watch(acceptedFriendsProvider).value?.length;
    final daysOnEleva = profile == null
        ? null
        : DateTime.now().difference(profile.createdAt).inDays + 1;

    return ColoredBox(
      color: EDColors.surface,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ProfileHeader(
                name: name,
                initial: name.isNotEmpty ? name[0].toUpperCase() : '?',
                avatarUrl: profile?.avatarUrl,
                subtitle: 'Estágio ${stage.number} · ${stage.name}',
                onEdit: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const EditProfilePage()),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      value: _formatPoints(faithPoints),
                      label: 'pontos de fé',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatTile(
                      value: daysOnEleva?.toString() ?? '–',
                      label: daysOnEleva == 1 ? 'dia no Eleva' : 'dias no Eleva',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatTile(
                      value: friendsCount?.toString() ?? '–',
                      label: friendsCount == 1 ? 'amigo' : 'amigos',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _FaithJourneyCard(points: faithPoints),
              const SizedBox(height: 16),
              const _SubscriptionCard(),
              const SizedBox(height: 16),
              _MenuGroup(
                children: [
                  _MenuTile(
                    icon: Icons.workspace_premium_outlined,
                    title: 'Gerenciar assinatura',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ManageSubscriptionScreen(),
                      ),
                    ),
                  ),
                  _MenuTile(
                    icon: Icons.notifications_none_rounded,
                    title: 'Notificações',
                    trailing: Switch(
                      value: true,
                      activeTrackColor: EDColors.blue,
                      activeThumbColor: Colors.white,
                      onChanged: (_) {},
                    ),
                  ),
                  _MenuTile(
                    icon: Icons.shield_outlined,
                    title: 'Política de Privacidade',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PrivacyPolicyPage(),
                      ),
                    ),
                  ),
                  _MenuTile(
                    icon: Icons.info_outline_rounded,
                    title: 'Sobre o app',
                    onTap: () => _showAboutApp(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _MenuGroup(
                children: [
                  _MenuTile(
                    icon: Icons.logout_rounded,
                    title: 'Sair',
                    color: EDColors.danger,
                    showChevron: false,
                    onTap: () async {
                      await Supabase.instance.client.auth.signOut();
                    },
                  ),
                  _MenuTile(
                    icon: Icons.delete_outline_rounded,
                    title: 'Excluir conta',
                    color: EDColors.danger,
                    showChevron: false,
                    onTap: () => _showDeleteDialog(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatPoints(double points) =>
      points == points.roundToDouble()
          ? points.toInt().toString()
          : points.toStringAsFixed(1).replaceAll('.', ',');

  Future<void> _showAboutApp(BuildContext context) async {
    String version = '1.1.1';
    try {
      final info = await PackageInfo.fromPlatform();
      if (info.version.isNotEmpty) version = info.version;
    } catch (_) {}

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => EDDialog(
        leading: Container(
          width: 88,
          height: 88,
          decoration: const BoxDecoration(
            color: EDColors.navy,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Image.asset('assets/images/logo_lotus.png', width: 52),
        ),
        title: 'Eleva',
        content: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: EDColors.goldSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Versão $version',
                style: EDText.body(size: 12, weight: FontWeight.w800, color: EDColors.goldInk),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Eleve sua fé, todos os dias.',
              textAlign: TextAlign.center,
              style: EDText.display(size: 17, weight: FontWeight.w400, color: EDColors.inkMuted)
                  .copyWith(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 12),
            Text(
              '© ${DateTime.now().year} Ino Technology',
              style: EDText.body(size: 12, color: EDColors.inkMuted),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: EDDecor.primaryButton(),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    final passwordController = TextEditingController();
    bool obscure = true;
    bool deleting = false;
    String? error;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => EDDialog(
          icon: Icons.delete_outline_rounded,
          iconColor: EDColors.danger,
          iconBackground: const Color(0xFFFDECEA),
          title: 'Excluir conta?',
          message:
              'Essa ação não pode ser desfeita. Seu perfil, diário, progresso de fé e '
              'publicações serão removidos permanentemente.',
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (error != null) ...[
                EDErrorBanner(error!),
                const SizedBox(height: 12),
              ],
              Text(
                'Digite sua senha para confirmar',
                style: EDText.body(size: 13, weight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: passwordController,
                obscureText: obscure,
                autofillHints: const [AutofillHints.password],
                style: EDText.body(size: 15),
                decoration: EDDecor.input(
                  hint: 'Sua senha',
                  suffixIcon: IconButton(
                    tooltip: obscure ? 'Mostrar senha' : 'Ocultar senha',
                    icon: Icon(
                      obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: EDColors.inkMuted,
                    ),
                    onPressed: () => setDialogState(() => obscure = !obscure),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: EDDecor.dangerButton(),
              onPressed: deleting
                  ? null
                  : () async {
                      final password = passwordController.text;
                      if (password.isEmpty) {
                        setDialogState(() => error = 'Informe sua senha para confirmar');
                        return;
                      }

                      setDialogState(() {
                        deleting = true;
                        error = null;
                      });

                      try {
                        final supabase = Supabase.instance.client;
                        final email = supabase.auth.currentUser?.email ?? '';

                        await supabase.auth.signInWithPassword(
                          email: email,
                          password: password,
                        );

                        await supabase.rpc('delete_own_account');

                        if (ctx.mounted) Navigator.of(ctx).pop();

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Conta excluída com sucesso.'),
                              backgroundColor: EDColors.blue,
                            ),
                          );
                        }

                        await supabase.auth.signOut();
                      } on AuthException catch (e) {
                        if (ctx.mounted) {
                          setDialogState(() {
                            error = translateAuthError(e.message);
                            deleting = false;
                          });
                        }
                      } catch (e) {
                        if (ctx.mounted) {
                          setDialogState(() {
                            error = 'Erro ao excluir conta. Tente novamente.';
                            deleting = false;
                          });
                        }
                        debugPrint('Erro ao excluir conta: $e');
                      }
                    },
              child: deleting
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    )
                  : const Text('Excluir minha conta'),
            ),
            TextButton(
              style: TextButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
              onPressed: deleting ? null : () => Navigator.of(ctx).pop(),
              child: Text(
                'Cancelar',
                style: EDText.body(weight: FontWeight.w700, color: EDColors.inkMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String name;
  final String initial;
  final String? avatarUrl;
  final String subtitle;
  final VoidCallback onEdit;

  const _ProfileHeader({
    required this.name,
    required this.initial,
    this.avatarUrl,
    required this.subtitle,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ProfileAvatar(initial: initial, avatarUrl: avatarUrl),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: EDText.display(size: 24),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: EDText.body(
                  size: 13,
                  weight: FontWeight.w600,
                  color: EDColors.inkMuted,
                ),
              ),
            ],
          ),
        ),
        Material(
          color: EDColors.card,
          shape: const CircleBorder(side: BorderSide(color: EDColors.border)),
          child: IconButton(
            tooltip: 'Editar perfil',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 20, color: EDColors.ink),
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;

  const _StatTile({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: EDDecor.card(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: EDText.display(size: 24)),
          const SizedBox(height: 2),
          Text(
            label,
            style: EDText.body(
              size: 12,
              weight: FontWeight.w600,
              color: EDColors.inkMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _FaithJourneyCard extends StatelessWidget {
  final double points;

  const _FaithJourneyCard({required this.points});

  @override
  Widget build(BuildContext context) {
    final current = FaithStage.fromPoints(points);
    final stages = FaithStage.all;
    final toNext = FaithStage.pointsToNext(points);
    final next = current.number < stages.length ? stages[current.number] : null;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: EDDecor.card(radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Jornada da fé',
                  style: EDText.body(size: 16, weight: FontWeight.w800),
                ),
              ),
              Text(
                'Nível ${(points / 5).floor().clamp(0, 14)} de 14',
                style: EDText.body(
                  size: 12,
                  weight: FontWeight.w700,
                  color: EDColors.inkMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Semantics(
            label: 'Estágio ${current.number} de ${stages.length}: ${current.name}',
            excludeSemantics: true,
            child: Row(
              children: [
                for (final stage in stages) ...[
                  _StageDot(
                    stage: stage,
                    reached: stage.number <= current.number,
                    isCurrent: stage.number == current.number,
                  ),
                  if (stage.number < stages.length)
                    Expanded(
                      child: Container(
                        height: 3,
                        color: stage.number < current.number
                            ? EDColors.gold
                            : EDColors.divider,
                      ),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (next != null && toNext != null)
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Próximo: ${next.name}',
                    style: EDText.body(size: 13, weight: FontWeight.w800),
                  ),
                  TextSpan(
                    text: ' · faltam ${_formatPoints(toNext)} pts. ',
                    style: EDText.body(
                      size: 13,
                      weight: FontWeight.w700,
                      color: EDColors.goldInk,
                    ),
                  ),
                  TextSpan(text: next.description),
                ],
              ),
              style: EDText.body(size: 13, color: EDColors.inkMuted, height: 1.45),
            )
          else
            Text(
              current.description,
              style: EDText.body(size: 13, color: EDColors.inkMuted, height: 1.45),
            ),
        ],
      ),
    );
  }

  static String _formatPoints(double v) => v == v.roundToDouble()
      ? v.toInt().toString()
      : v.toStringAsFixed(1).replaceAll('.', ',');
}

class _StageDot extends StatelessWidget {
  final FaithStage stage;
  final bool reached;
  final bool isCurrent;

  const _StageDot({
    required this.stage,
    required this.reached,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    final size = isCurrent ? 34.0 : 28.0;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: reached ? stage.color : EDColors.divider,
        boxShadow: isCurrent
            ? [
                const BoxShadow(color: Colors.white, spreadRadius: 3),
                BoxShadow(color: stage.color, spreadRadius: 5),
              ]
            : null,
      ),
      child: Text(
        '${stage.number}',
        style: EDText.body(
          size: 12,
          weight: FontWeight.w800,
          color: reached ? Colors.white : EDColors.inkMuted,
        ),
      ),
    );
  }
}

class _SubscriptionCard extends ConsumerWidget {
  const _SubscriptionCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(isPremiumProvider);
    final isTrialActive = ref.watch(isTrialActiveProvider);
    final trialDays = ref.watch(trialDaysRemainingProvider);
    final period = ref.watch(subscriptionPeriodProvider);

    final String title;
    final String subtitle;
    final IconData icon;
    if (isPremium) {
      title = period == 'annual' ? 'Premium Anual' : 'Premium Mensal';
      subtitle = period == 'annual' ? 'Renova anualmente' : 'Renova mensalmente';
      icon = Icons.star_rounded;
    } else if (isTrialActive) {
      title = 'Período de teste · $trialDays ${trialDays == 1 ? 'dia' : 'dias'}';
      subtitle = 'Assine e garanta acesso ilimitado';
      icon = Icons.schedule_rounded;
    } else {
      title = 'Seu teste expirou';
      subtitle = 'Assine para continuar';
      icon = Icons.lock_outline_rounded;
    }

    return Material(
      color: isPremium ? EDColors.navy : EDColors.goldSoft,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => isPremium
                ? const ManageSubscriptionScreen()
                : const PaywallScreen(),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: isPremium ? EDColors.gold : EDColors.goldInk),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: EDText.body(
                        weight: FontWeight.w800,
                        color: isPremium ? Colors.white : EDColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: EDText.body(
                        size: 12,
                        weight: FontWeight.w600,
                        color: isPremium ? EDColors.onNavyMuted : EDColors.goldInk,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isPremium)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: EDColors.ink,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Assinar',
                    style: EDText.body(
                      size: 13,
                      weight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                )
              else
                const Icon(Icons.chevron_right_rounded, color: EDColors.onNavyMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuGroup extends StatelessWidget {
  final List<Widget> children;

  const _MenuGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: EDDecor.card(radius: 20),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(height: 1, thickness: 1, color: EDColors.divider),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color color;
  final bool showChevron;

  const _MenuTile({
    required this.icon,
    required this.title,
    this.onTap,
    this.trailing,
    this.color = EDColors.ink,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 54),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(icon, size: 22, color: color == EDColors.ink ? EDColors.blue : color),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: EDText.body(weight: FontWeight.w700, color: color),
                ),
              ),
              if (trailing != null)
                trailing!
              else if (onTap != null && showChevron)
                const Icon(Icons.chevron_right_rounded, color: EDColors.hint),
            ],
          ),
        ),
      ),
    );
  }
}
