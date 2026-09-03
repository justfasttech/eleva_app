import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/providers/auth_provider.dart';
import 'faith_history_provider.dart';

final dailyFaithMergerProvider = Provider<DailyFaithMerger>((ref) {
  final merger = DailyFaithMerger(ref);
  ref.onDispose(() => merger.dispose());
  return merger;
});

class DailyFaithMerger with WidgetsBindingObserver {
  final Ref _ref;
  Timer? _timer;

  DailyFaithMerger(this._ref) {
    WidgetsBinding.instance.addObserver(this);
    _tryMerge();
    _scheduleNextCheck();
  }

  void _scheduleNextCheck() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(hours: 1), (_) => _tryMerge());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _tryMerge();
    }
  }

  Future<void> _tryMerge() async {
    final user = _ref.read(authStateProvider).value;
    if (user == null) return;

    try {
      final timezoneOffset = DateTime.now().timeZoneOffset.inMinutes;

      final result = await Supabase.instance.client.rpc(
        'daily_faith_merge',
        params: {
          'p_user_id': user.id,
          'p_tz_offset_minutes': timezoneOffset,
        },
      );

      if (result == true) {
        _ref.invalidate(faithHistoryProvider);
      }
    } catch (_) {}
  }

  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
  }
}
