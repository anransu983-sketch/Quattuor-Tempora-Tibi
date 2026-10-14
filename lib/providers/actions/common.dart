part of '../action.dart';

const _trafficStatsFlushTicks = 60;

@Riverpod(keepAlive: true)
class CommonAction extends _$CommonAction {
  CoreController get _core => ref.read(coreHandlerProvider);
  bool _isUpdatingTraffic = false;
  Traffic? _lastTotalTraffic;
  final _pendingTrafficBuckets = <DateTime, ({int upBytes, int downBytes})>{};
  int _unflushedTrafficTicks = 0;

  @override
  void build() {}

  void toggleRunning() {
    final running = !ref.read(isStartProvider);
    unawaited(
      globalState.safeRun(
        () => ref
            .read(setupActionProvider.notifier)
            .setRunning(
              running,
              initialize: running && !ref.read(initProvider),
            ),
      ),
    );
  }

  void updateSpeedStatistics() {
    ref
        .read(appSettingProvider.notifier)
        .update((state) => state.copyWith(showTrayTitle: !state.showTrayTitle));
  }

  void updateMode() {
    ref.read(patchClashConfigProvider.notifier).update((state) {
      final index = Mode.values.indexWhere((item) => item == state.mode);
      if (index == -1) return state;
      final nextIndex = index + 1 > Mode.values.length - 1 ? 0 : index + 1;
      return state.copyWith(mode: Mode.values[nextIndex]);
    });
  }

  Future<void> updateTraffic() async {
    if (_isUpdatingTraffic) {
      return;
    }
    _isUpdatingTraffic = true;
    try {
      final onlyStatisticsProxy = ref.read(
        appSettingProvider.select((state) => state.onlyStatisticsProxy),
      );
      final [traffic, totalTraffic] = await Future.wait([
        _readTraffic(() => _core.getTraffic(onlyStatisticsProxy)),
        _readTraffic(() => _core.getTotalTraffic(onlyStatisticsProxy)),
      ]);
      if (traffic != null) {
        ref.read(trafficsProvider.notifier).addTraffic(traffic);
      }
      if (totalTraffic != null) {
        ref.read(totalTrafficProvider.notifier).value = totalTraffic;
        _recordTotalTraffic(totalTraffic);
      }
    } finally {
      _isUpdatingTraffic = false;
    }
  }

  /// The core reports cumulative totals, so each tick contributes the delta
  /// since the previous one. A negative delta means the counters reset under
  /// us (core restart) and the new total is traffic of its own.
  void _recordTotalTraffic(Traffic total) {
    final last = _lastTotalTraffic;
    _lastTotalTraffic = total;
    if (last == null) {
      return;
    }
    var upDelta = (total.up - last.up).toInt();
    var downDelta = (total.down - last.down).toInt();
    if (upDelta < 0) {
      upDelta = total.up.toInt();
    }
    if (downDelta < 0) {
      downDelta = total.down.toInt();
    }
    if (upDelta <= 0 && downDelta <= 0) {
      return;
    }
    final now = DateTime.now();
    final hour = DateTime(now.year, now.month, now.day, now.hour);
    final bucket = _pendingTrafficBuckets[hour];
    _pendingTrafficBuckets[hour] = (
      upBytes: (bucket?.upBytes ?? 0) + upDelta,
      downBytes: (bucket?.downBytes ?? 0) + downDelta,
    );
    _unflushedTrafficTicks++;
    if (_unflushedTrafficTicks >= _trafficStatsFlushTicks) {
      unawaited(_flushTrafficStats());
    }
  }

  Future<void> _flushTrafficStats() async {
    final buckets = Map.of(_pendingTrafficBuckets);
    _pendingTrafficBuckets.clear();
    _unflushedTrafficTicks = 0;
    if (buckets.isEmpty) {
      return;
    }
    try {
      await database.trafficHourlyDao.addBuckets(buckets);
    } catch (error) {
      commonPrint.log(
        'flush traffic stats failed: ${compactError(error)}',
        logLevel: LogLevel.warning,
      );
    }
  }

  Future<Traffic?> _readTraffic(Future<Traffic> Function() request) async {
    try {
      return await request();
    } catch (error) {
      commonPrint.log(
        'updateTraffic error: $error',
        logLevel: coreFailureLogLevel(error),
      );
      return null;
    }
  }

  Future<bool> autoCheckUpdate() async {
    if (!ref.read(appSettingProvider).autoCheckUpdate) return false;
    final Map<String, dynamic>? res;
    try {
      res = await request.checkForUpdate();
    } catch (error) {
      commonPrint.log(
        'checkForUpdate failed: ${compactError(error)}',
        logLevel: LogLevel.warning,
      );
      return false;
    }
    await checkUpdateResultHandle(data: res);
    return res != null;
  }

  TextSpan _releaseSpan(BuildContext context, String tagName, String? body) {
    final textTheme = context.textTheme;
    final version = parseReleaseChangelog(body);
    return TextSpan(
      text: '$tagName \n',
      style: textTheme.headlineSmall,
      children: version == null
          ? [
              TextSpan(text: '\n', style: textTheme.bodyMedium),
              for (final submit in parseReleaseBody(body))
                TextSpan(text: '- $submit \n', style: textTheme.bodyMedium),
            ]
          : _changelogSpans(context, version),
    );
  }

  List<TextSpan> _changelogSpans(
    BuildContext context,
    ChangelogVersion version,
  ) {
    final textTheme = context.textTheme;
    return [
      for (final group in version.visibleGroups) ...[
        TextSpan(
          text:
              '\n${changelogGroupTitle(currentAppLocalizations, group.type)}\n',
          style: textTheme.labelLarge?.copyWith(
            color: group.type == ChangelogType.breaking
                ? context.colorScheme.error
                : context.colorScheme.primary,
          ),
        ),
        for (final entry in group.entries)
          TextSpan(text: '• ${entry.text}\n', style: textTheme.bodyMedium),
      ],
    ];
  }

  Future<void> checkUpdateResultHandle({
    Map<String, dynamic>? data,
    bool isUser = false,
  }) async {
    if (data != null) {
      final context = globalState.navigatorKey.currentContext!;
      final res = await dialogs.showMessage(
        title: currentAppLocalizations.discoverNewVersion,
        message: _releaseSpan(
          context,
          data['tag_name'] as String,
          data['body'] as String?,
        ),
        confirmText: currentAppLocalizations.goDownload,
        cancelText: isUser ? null : currentAppLocalizations.noLongerRemind,
      );
      if (res == true) {
        unawaited(
          launchUrl(
            Uri.parse('https://github.com/$repository/releases/latest'),
          ),
        );
      } else if (!isUser && res == false) {
        ref
            .read(appSettingProvider.notifier)
            .update((state) => state.copyWith(autoCheckUpdate: false));
      }
    } else if (isUser) {
      unawaited(
        dialogs.showMessage(
          title: currentAppLocalizations.checkUpdate,
          message: TextSpan(text: currentAppLocalizations.checkUpdateError),
        ),
      );
    }
  }
}
