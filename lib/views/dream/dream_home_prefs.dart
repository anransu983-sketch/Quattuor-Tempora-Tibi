import 'dart:async';

import 'package:fl_clash/common/common.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _dreamGreetingKey = 'dreamHomeGreeting';
const _dreamSidebarExpandedKey = 'dreamHomeSidebarExpanded';

class DreamGreetingNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String value) {
    if (state == value) {
      return;
    }
    state = value;
    unawaited(saveDreamGreeting(value));
  }

  Future<void> load() async {
    final prefs = await preferences.sharedPreferencesCompleter.future;
    state = prefs?.getString(_dreamGreetingKey) ?? '';
  }
}

class DreamSidebarExpandedNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void set(bool value) {
    if (state == value) {
      return;
    }
    state = value;
    unawaited(saveDreamSidebarExpanded(value));
  }

  Future<void> load() async {
    final prefs = await preferences.sharedPreferencesCompleter.future;
    state = prefs?.getBool(_dreamSidebarExpandedKey) ?? true;
  }
}

final dreamGreetingProvider =
    NotifierProvider<DreamGreetingNotifier, String>(DreamGreetingNotifier.new);

final dreamSidebarExpandedProvider =
    NotifierProvider<DreamSidebarExpandedNotifier, bool>(
      DreamSidebarExpandedNotifier.new,
    );

Future<void> saveDreamGreeting(String value) async {
  final prefs = await preferences.sharedPreferencesCompleter.future;
  await prefs?.setString(_dreamGreetingKey, value);
}

Future<void> saveDreamSidebarExpanded(bool value) async {
  final prefs = await preferences.sharedPreferencesCompleter.future;
  await prefs?.setBool(_dreamSidebarExpandedKey, value);
}
