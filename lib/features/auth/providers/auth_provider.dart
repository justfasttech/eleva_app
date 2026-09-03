import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authStateProvider = StreamNotifierProvider<AuthStateNotifier, User?>(
  AuthStateNotifier.new,
);

class AuthStateNotifier extends StreamNotifier<User?> {
  @override
  Stream<User?> build() {
    final supabase = Supabase.instance.client;

    final controller = StreamController<User?>();

    controller.add(supabase.auth.currentUser);

    final subscription = supabase.auth.onAuthStateChange.listen((data) {
      controller.add(data.session?.user);
    });

    ref.onDispose(() {
      subscription.cancel();
      controller.close();
    });

    return controller.stream;
  }
}
