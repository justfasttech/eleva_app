import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/theme.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/reset_password_screen.dart';
import 'features/admin/presentation/admin_screen.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/providers/user_profile_provider.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/onboarding/presentation/onboarding_screen.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  late final StreamSubscription<AuthState> _subscription;
  bool _isRecovery = false;

  @override
  void initState() {
    super.initState();
    _subscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery && mounted) {
        setState(() => _isRecovery = true);
      }
      if (data.event == AuthChangeEvent.signedOut && mounted) {
        setState(() => _isRecovery = false);
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'Eleva',
      debugShowCheckedModeBanner: false,
      theme: elevaTheme,
      home: authState.when(
        data: (user) {
          if (_isRecovery && user != null) {
            return const ResetPasswordScreen();
          }
          if (user == null) return const LoginScreen();
          return ref.watch(userProfileProvider).when(
            loading: () => const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: ElevaColors.gold),
              ),
            ),
            error: (_, __) => const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: ElevaColors.gold),
              ),
            ),
            data: (profile) {
              if (profile == null || profile.id != user.id) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(color: ElevaColors.gold),
                  ),
                );
              }
              if (profile.isAdmin) return const AdminScreen();
              if (!profile.onboardingCompleted) return const OnboardingScreen();
              return const HomeScreen();
            },
          );
        },
        loading: () => const Scaffold(
          body: Center(
            child: CircularProgressIndicator(color: ElevaColors.gold),
          ),
        ),
        error: (_, __) => const LoginScreen(),
      ),
    );
  }
}
