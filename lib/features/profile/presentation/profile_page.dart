import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/auth_error_translator.dart';
import '../../../core/theme.dart';
import '../../subscription/presentation/paywall_screen.dart';
import '../../subscription/presentation/subscription_status_card.dart';
import 'edit_profile_page.dart';

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
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Text(
              name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: ElevaColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              email,
              style: const TextStyle(
                fontSize: 14,
                color: ElevaColors.textMuted,
              ),
            ),
            const SizedBox(height: 20),
            const SubscriptionStatusCard(),
            const SizedBox(height: 20),
            _ProfileTile(
              icon: Icons.workspace_premium_rounded,
              title: 'Gerenciar assinatura',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const PaywallScreen(),
                  ),
                );
              },
            ),
            _ProfileTile(
              icon: Icons.edit_rounded,
              title: 'Editar perfil',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const EditProfilePage(),
                  ),
                );
              },
            ),
            _ProfileTile(
              icon: Icons.notifications_rounded,
              title: 'Notificações',
              trailing: Switch(
                value: true,
                activeTrackColor: ElevaColors.goldLight,
                activeThumbColor: ElevaColors.gold,
                onChanged: (_) {},
              ),
            ),
            _ProfileTile(
              icon: Icons.info_outline_rounded,
              title: 'Sobre o app',
              onTap: () => _showAboutApp(context),
            ),
            const SizedBox(height: 20),
            _ProfileTile(
              icon: Icons.delete_outline_rounded,
              title: 'Excluir conta',
              iconColor: Colors.red.shade400,
              textColor: Colors.red.shade400,
              onTap: () => _showDeleteDialog(context),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await Supabase.instance.client.auth.signOut();
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Sair'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _showAboutApp(BuildContext context) async {
    String version = '1.0.0';
    try {
      final info = await PackageInfo.fromPlatform();
      if (info.version.isNotEmpty) version = info.version;
    } catch (_) {}

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/images/logo.png', height: 56),
              const SizedBox(height: 16),
              const Text(
                'Eleva',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: ElevaColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Versão $version',
                style: const TextStyle(
                  fontSize: 14,
                  color: ElevaColors.textMuted,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Eleve sua fé, todos os dias.',
                style: TextStyle(
                  fontSize: 14,
                  color: ElevaColors.textMuted,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text(
                    'Fechar',
                    style: TextStyle(color: ElevaColors.gold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    final passwordController = TextEditingController();
    bool obscure = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Excluir conta',
            style: TextStyle(color: ElevaColors.textDark),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Essa ação não pode ser desfeita. Todos os seus dados serão removidos permanentemente.',
                style: TextStyle(
                  fontSize: 14,
                  color: ElevaColors.textMuted,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: passwordController,
                obscureText: obscure,
                decoration: InputDecoration(
                  hintText: 'Confirme sua senha',
                  prefixIcon: const Icon(Icons.lock_outline,
                      color: ElevaColors.gold),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: ElevaColors.textMuted,
                    ),
                    onPressed: () =>
                        setDialogState(() => obscure = !obscure),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: ElevaColors.textMuted),
              ),
            ),
            TextButton(
              onPressed: () async {
                final password = passwordController.text;
                if (password.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Informe sua senha para confirmar'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  final supabase = Supabase.instance.client;
                  final email = supabase.auth.currentUser?.email ?? '';

                  await supabase.auth.signInWithPassword(
                    email: email,
                    password: password,
                  );

                  await supabase.rpc('delete_own_account');

                  await supabase.auth.signOut();

                  if (context.mounted) {
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Conta excluída com sucesso.'),
                        backgroundColor: ElevaColors.gold,
                      ),
                    );
                  }
                } on AuthException catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(translateAuthError(e.message)),
                        backgroundColor: Colors.red.shade400,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erro ao excluir conta: $e'),
                        backgroundColor: Colors.red.shade400,
                      ),
                    );
                  }
                }
              },
              child: Text(
                'Excluir',
                style: TextStyle(
                  color: Colors.red.shade400,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? iconColor;
  final Color? textColor;

  const _ProfileTile({
    required this.icon,
    required this.title,
    this.onTap,
    this.trailing,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: ElevaColors.offWhite,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? ElevaColors.gold),
        title: Text(
          title,
          style: TextStyle(
            color: textColor ?? ElevaColors.textDark,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: trailing ??
            (onTap != null
                ? const Icon(
                    Icons.chevron_right_rounded,
                    color: ElevaColors.textMuted,
                  )
                : null),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}

