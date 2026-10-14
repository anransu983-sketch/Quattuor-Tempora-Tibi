import 'dart:async';

import 'package:fl_clash/common/common.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _dreamPanelKey = 'dreamPanel';

class DreamPanelNotifier extends Notifier<String> {
  @override
  String build() => DreamPanel.zashboard.value;

  void set(String value) {
    if (state == value) {
      return;
    }
    state = value;
    unawaited(saveDreamPanel(value));
  }

  Future<void> load() async {
    final prefs = await preferences.sharedPreferencesCompleter.future;
    state = prefs?.getString(_dreamPanelKey) ?? DreamPanel.zashboard.value;
  }
}

final dreamPanelProvider = NotifierProvider<DreamPanelNotifier, String>(
  DreamPanelNotifier.new,
);

Future<void> saveDreamPanel(String value) async {
  final prefs = await preferences.sharedPreferencesCompleter.future;
  await prefs?.setString(_dreamPanelKey, value);
}
