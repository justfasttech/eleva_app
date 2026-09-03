import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/providers/auth_provider.dart';
import 'faith_history_provider.dart';

final hourlyFaithMergerProvider = Provider<HourlyFaithMerger>((ref) {
  final merger = HourlyFaithMerger(ref);
  ref.onDispose(() => merger.dispose());
  return merger;
});

class HourlyFaithMerger with WidgetsBindingObserver {
  final Ref _ref;
  Timer? _timer;
  DateTime? _nextMergeTime;

  HourlyFaithMerger(this._ref) {
    WidgetsBinding.instance.addObserver(this);
    _scheduleNextMerge();
  }

  void _scheduleNextMerge() {
    _timer?.cancel();
    final now = DateTime.now();
    _nextMergeTime = DateTime(now.year, now.month, now.day, now.hour + 1);
    final duration = _nextMergeTime!.difference(now);

    _timer = Timer(duration, () {
      _mergePendingFaith();
      _scheduleNextMerge();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final now = DateTime.now();
      if (_nextMergeTime != null && now.isAfter(_nextMergeTime!)) {
        _mergePendingFaith();
        _scheduleNextMerge();
      }
    }
  }

  Future<void> _mergePendingFaith() async {
    final user = _ref.read(authStateProvider).value;
    if (user == null) return;

    try {
      await Supabase.instance.client.rpc(
        'merge_pending_faith',
        params: {'p_user_id': user.id},
      );
      _ref.invalidate(faithHistoryProvider);
    } catch (_) {}
  }

  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
  }
}
