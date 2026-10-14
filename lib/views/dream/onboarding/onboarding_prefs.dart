import 'dart:async';

import 'package:fl_clash/common/common.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _dreamOnboardingSeenKey = 'dreamOnboardingSeen';

class DreamOnboardingSeenNotifier extends Notifier<bool> {
  // Builds unseen=false would flash the onboarding on every cold start while
  // the persisted value is still loading; a brief home flash for true
  // first-launch users is the harmless direction.
  @override
  bool build() => true;

  void markSeen() {
    if (state) {
      return;
    }
    state = true;
    unawaited(saveDreamOnboardingSeen(true));
  }

  Future<void> load() async {
    final prefs = await preferences.sharedPreferencesCompleter.future;
    state = prefs?.getBool(_dreamOnboardingSeenKey) ?? false;
  }
}

final dreamOnboardingSeenProvider =
    NotifierProvider<DreamOnboardingSeenNotifier, bool>(
      DreamOnboardingSeenNotifier.new,
    );

Future<void> saveDreamOnboardingSeen(bool value) async {
  final prefs = await preferences.sharedPreferencesCompleter.future;
  await prefs?.setBool(_dreamOnboardingSeenKey, value);
}
