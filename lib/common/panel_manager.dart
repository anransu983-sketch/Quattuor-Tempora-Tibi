import 'dart:io';

import 'package:archive/archive.dart';
import 'package:dio/dio.dart';
import 'package:fl_clash/common/common.dart';
import 'package:path/path.dart';

enum DreamPanel {
  zashboard(
    'zashboard',
    'Zashboard',
    'https://github.com/Zephyruso/zashboard/releases/latest/download/dist.zip',
  ),
  metacubexd(
    'metacubexd',
    'MetaCubeXD',
    'https://github.com/MetaCubeX/metacubexd/archive/refs/heads/gh-pages.zip',
  ),
  yacd(
    'yacd',
    'Yacd',
    'https://github.com/haishanh/yacd/archive/refs/heads/gh-pages.zip',
  );

  final String value;
  final String label;
  final String downloadUrl;

  const DreamPanel(this.value, this.label, this.downloadUrl);

  static DreamPanel fromValue(String? value) {
    return DreamPanel.values.firstWhere(
      (element) => element.value == value,
      orElse: () => DreamPanel.zashboard,
    );
  }

  /// URL the dashboard JS reads for its backend connection. zashboard keeps
  /// its connection params in the hash, the other two read the query string.
  String dashboardUrl(String host, String port, String secret) {
    final params =
        'hostname=$host&port=$port&secret=${Uri.encodeQueryComponent(secret)}';
    return switch (this) {
      DreamPanel.zashboard => 'http://$host:$port/ui/#/setup?$params',
      DreamPanel.metacubexd ||
      DreamPanel.yacd => 'http://$host:$port/ui/?$params',
    };
  }
}

abstract final class PanelManager {
  static const _prefsKey = 'dreamPanel';

  static Future<String> panelsDir() async {
    return join(await appPath.homeDirPath, 'panels');
  }

  static Future<String> panelDir(DreamPanel panel) async {
    return join(await panelsDir(), panel.value);
  }

  static Future<DreamPanel> selectedPanel() async {
    final prefs = await preferences.sharedPreferencesCompleter.future;
    return DreamPanel.fromValue(prefs?.getString(_prefsKey));
  }

  static Future<bool> isInstalled(DreamPanel panel) async {
    return File(join(await panelDir(panel), 'index.html')).exists();
  }

  /// Absolute external-ui directory for the selected panel, or '' when the
  /// panel is not downloaded yet. Runs on the main isolate only: the profile
  /// task in the compute isolate receives the value through its state.
  static Future<String> panelExternalUiDir() async {
    final panel = await selectedPanel();
    if (!await isInstalled(panel)) {
      return '';
    }
    return panelDir(panel);
  }

  static Future<void> ensureInstalled(
    DreamPanel panel, {
    void Function(int received, int total)? onProgress,
  }) async {
    if (await isInstalled(panel)) {
      return;
    }
    final dir = await panelDir(panel);
    final zipFile = File(join(await panelsDir(), '${panel.value}.zip'));
    try {
      await zipFile.parent.create(recursive: true);
      await Dio().download(
        panel.downloadUrl,
        zipFile.path,
        options: Options(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(minutes: 5),
        ),
        onReceiveProgress: onProgress,
      );
      final archive = ZipDecoder().decodeBytes(await zipFile.readAsBytes());
      final target = Directory(dir);
      if (await target.exists()) {
        await target.delete(recursive: true);
      }
      await target.create(recursive: true);
      for (final file in archive.files) {
        final name = _stripTopDir(file.name);
        if (name.isEmpty) {
          continue;
        }
        final out = join(dir, name);
        if (!isWithin(dir, out)) {
          continue;
        }
        if (file.isFile) {
          final outFile = File(out);
          await outFile.parent.create(recursive: true);
          await outFile.writeAsBytes(file.content as List<int>);
        } else {
          await Directory(out).create(recursive: true);
        }
      }
      if (!await isInstalled(panel)) {
        throw MessageException(
          currentAppLocalizations.dreamPanelFileIncomplete,
        );
      }
    } on DioException catch (e) {
      throw MessageException(
        currentAppLocalizations.dreamPanelDownloadFailed(e.message ?? e.type.name),
      );
    } catch (e) {
      if (e is MessageException) {
        rethrow;
      }
      throw MessageException(
        currentAppLocalizations.dreamPanelInstallFailed('$e'),
      );
    } finally {
      if (await zipFile.exists()) {
        await zipFile.delete();
      }
    }
  }

  static String _stripTopDir(String name) {
    final index = name.indexOf('/');
    if (index < 0) {
      return '';
    }
    return name.substring(index + 1);
  }
}
