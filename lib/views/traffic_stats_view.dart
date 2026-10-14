import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/database/database.dart';
import 'package:fl_clash/icons/icons.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

const _upChartColor = Color(0xFF7FB3E5);

List<String> _sortLabels(AppLocalizations appLocalizations) => [
      appLocalizations.dreamTrafficSortByName,
      appLocalizations.dreamTrafficUp,
      appLocalizations.dreamTrafficDown,
      appLocalizations.dreamTrafficTotal,
    ];

extension on TrafficStatsRange {
  String label(AppLocalizations appLocalizations) => switch (this) {
    TrafficStatsRange.day => appLocalizations.dreamTrafficDay,
    TrafficStatsRange.week => appLocalizations.dreamTrafficWeek,
    TrafficStatsRange.month => appLocalizations.dreamTrafficMonth,
  };
}

class TrafficStatsView extends ConsumerStatefulWidget {
  const TrafficStatsView({super.key});

  @override
  ConsumerState<TrafficStatsView> createState() => _TrafficStatsViewState();
}

class _TrafficStatsViewState extends ConsumerState<TrafficStatsView> {
  TrafficStatsRange _range = TrafficStatsRange.day;
  int _sortIndex = 0;

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      title: context.appLocalizations.dreamTrafficStats,
      iconActions: [
        IconButtonData(
          glyph: AppGlyphs.delete,
          tooltip: context.appLocalizations.dreamTrafficClear,
          onPressed: _handleClear,
        ),
      ],
      body: Builder(
        builder: (context) {
          final bottomInset = BottomInsetScope.of(context);
          return Consumer(
            builder: (context, ref, _) {
              final rows =
                  ref.watch(trafficHourlyStatsProvider(_range.index)).value ??
                  const <TrafficHourlyData>[];
              final now = DateTime.now();
              final appLocalizations = context.appLocalizations;
              final buckets = _bucketize(_range, rows, now, appLocalizations);
              var upBytes = 0;
              var downBytes = 0;
              for (final row in rows) {
                upBytes += row.upBytes;
                downBytes += row.downBytes;
              }
              return ListView(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset),
                children: [
                  _RangeSelector(
                    range: _range,
                    onChanged: (range) => setState(() => _range = range),
                  ),
                  const SizedBox(height: 16),
                  _ChartCard(buckets: buckets),
                  const SizedBox(height: 20),
                  _SectionHeader(label: appLocalizations.dreamTrafficTotal),
                  _TotalsCard(upBytes: upBytes, downBytes: downBytes),
                  const SizedBox(height: 20),
                  _SectionHeader(
                    label: appLocalizations.dreamTrafficPerApp,
                    action: _SortButton(
                      sortIndex: _sortIndex,
                      onChanged: (index) => setState(() => _sortIndex = index),
                    ),
                  ),
                  _EmptyCard(label: appLocalizations.dreamTrafficNoAppData),
                  const SizedBox(height: 20),
                  _SectionHeader(label: appLocalizations.dreamTrafficPerNode),
                  _EmptyCard(label: appLocalizations.dreamTrafficNoNodeData),
                  const SizedBox(height: 20),
                  _SectionHeader(label: appLocalizations.dreamTrafficFootprint),
                  _EmptyCard(label: appLocalizations.dreamTrafficNoFootprint),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _handleClear() async {
    final confirmed = await dialogs.showMessage(
      context: context,
      title: context.appLocalizations.dreamTrafficClear,
      message: TextSpan(
        text: context.appLocalizations.dreamTrafficClearConfirm,
      ),
      confirmText: context.appLocalizations.dreamTrafficClearAction,
    );
    if (confirmed != true) {
      return;
    }
    await globalState.safeRun(() => database.trafficHourlyDao.clear());
  }
}

class _ChartBucket {
  const _ChartBucket({
    required this.label,
    required this.upBytes,
    required this.downBytes,
  });

  final String label;
  final int upBytes;
  final int downBytes;
}

List<_ChartBucket> _bucketize(
  TrafficStatsRange range,
  List<TrafficHourlyData> rows,
  DateTime now,
  AppLocalizations appLocalizations,
) {
  switch (range) {
    case TrafficStatsRange.day:
      return _dayBuckets(rows, now);
    case TrafficStatsRange.week:
      return _weekBuckets(rows, now, appLocalizations);
    case TrafficStatsRange.month:
      return _monthBuckets(rows, now);
  }
}

List<_ChartBucket> _dayBuckets(List<TrafficHourlyData> rows, DateTime now) {
  final dayStart = DateTime(now.year, now.month, now.day);
  final byHour = {for (final row in rows) row.hour: row};
  final buckets = <_ChartBucket>[];
  for (var i = 0; i < 24; i++) {
    final row = byHour[dayStart.add(Duration(hours: i))];
    buckets.add(
      _ChartBucket(
        label: i.toString().padLeft(2, '0'),
        upBytes: row?.upBytes ?? 0,
        downBytes: row?.downBytes ?? 0,
      ),
    );
  }
  return buckets;
}

Map<DateTime, ({int upBytes, int downBytes})> _groupByDay(
  List<TrafficHourlyData> rows,
) {
  final byDay = <DateTime, ({int upBytes, int downBytes})>{};
  for (final row in rows) {
    final hour = row.hour;
    final day = DateTime(hour.year, hour.month, hour.day);
    final acc = byDay[day];
    byDay[day] = (
      upBytes: (acc?.upBytes ?? 0) + row.upBytes,
      downBytes: (acc?.downBytes ?? 0) + row.downBytes,
    );
  }
  return byDay;
}

_ChartBucket _daySumBucket(
  Map<DateTime, ({int upBytes, int downBytes})> byDay,
  DateTime day,
  String label,
) {
  final acc = byDay[day];
  return _ChartBucket(
    label: label,
    upBytes: acc?.upBytes ?? 0,
    downBytes: acc?.downBytes ?? 0,
  );
}

List<_ChartBucket> _weekBuckets(
  List<TrafficHourlyData> rows,
  DateTime now,
  AppLocalizations appLocalizations,
) {
  final weekdayLabels = [
    appLocalizations.dreamTrafficMon,
    appLocalizations.dreamTrafficTue,
    appLocalizations.dreamTrafficWed,
    appLocalizations.dreamTrafficThu,
    appLocalizations.dreamTrafficFri,
    appLocalizations.dreamTrafficSat,
    appLocalizations.dreamTrafficSun,
  ];
  final weekStart = DateTime(
    now.year,
    now.month,
    now.day,
  ).subtract(Duration(days: now.weekday - 1));
  final byDay = _groupByDay(rows);
  final buckets = <_ChartBucket>[];
  for (var i = 0; i < 7; i++) {
    buckets.add(
      _daySumBucket(byDay, weekStart.add(Duration(days: i)), weekdayLabels[i]),
    );
  }
  return buckets;
}

List<_ChartBucket> _monthBuckets(List<TrafficHourlyData> rows, DateTime now) {
  final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
  final byDay = _groupByDay(rows);
  final buckets = <_ChartBucket>[];
  for (var d = 1; d <= daysInMonth; d++) {
    buckets.add(
      _daySumBucket(
        byDay,
        DateTime(now.year, now.month, d),
        d % 5 == 1 ? '$d' : '',
      ),
    );
  }
  return buckets;
}

class _RangeSelector extends StatelessWidget {
  const _RangeSelector({required this.range, required this.onChanged});

  final TrafficStatsRange range;
  final ValueChanged<TrafficStatsRange> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: ShapeDecoration(
        shape: AppShape.full,
        color: context.colorScheme.surfaceContainerHighest,
      ),
      child: Row(
        children: [
          for (final item in TrafficStatsRange.values)
            Expanded(
              child: _RangeSegment(
                label: item.label(context.appLocalizations),
                selected: item == range,
                onTap: () => onChanged(item),
              ),
            ),
        ],
      ),
    );
  }
}

class _RangeSegment extends StatelessWidget {
  const _RangeSegment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    return InkWell(
      onTap: onTap,
      customBorder: AppShape.full,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: selected
            ? ShapeDecoration(shape: AppShape.full, color: colorScheme.primary)
            : null,
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: selected
                  ? colorScheme.onPrimary
                  : colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.buckets});

  final List<_ChartBucket> buckets;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: ShapeDecoration(
        shape: AppShape.lg,
        color: colorScheme.surfaceContainerLowest,
      ),
      child: Column(
        children: [
          _Legend(downColor: colorScheme.primary, upColor: _upChartColor),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            width: double.infinity,
            child: CustomPaint(
              painter: _TrafficChartPainter(
                downValues: [
                  for (final bucket in buckets) bucket.downBytes.toDouble(),
                ],
                upValues: [
                  for (final bucket in buckets) bucket.upBytes.toDouble(),
                ],
                labels: [for (final bucket in buckets) bucket.label],
                downColor: colorScheme.primary,
                upColor: _upChartColor,
                labelColor: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.downColor, required this.upColor});

  final Color downColor;
  final Color upColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendDot(color: downColor),
        const SizedBox(width: 6),
        Text(context.appLocalizations.dreamTrafficDown),
        const SizedBox(width: 16),
        _LegendDot(color: upColor),
        const SizedBox(width: 6),
        Text(context.appLocalizations.dreamTrafficUp),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 6,
      decoration: ShapeDecoration(shape: AppShape.full, color: color),
    );
  }
}

class _TrafficChartPainter extends CustomPainter {
  _TrafficChartPainter({
    required this.downValues,
    required this.upValues,
    required this.labels,
    required this.downColor,
    required this.upColor,
    required this.labelColor,
  });

  final List<double> downValues;
  final List<double> upValues;
  final List<String> labels;
  final Color downColor;
  final Color upColor;
  final Color labelColor;

  @override
  void paint(Canvas canvas, Size size) {
    final count = downValues.length;
    if (count == 0) {
      return;
    }
    const labelHeight = 20.0;
    final chartHeight = size.height - labelHeight;
    var maxValue = 0.0;
    for (var i = 0; i < count; i++) {
      if (downValues[i] > maxValue) {
        maxValue = downValues[i];
      }
      if (upValues[i] > maxValue) {
        maxValue = upValues[i];
      }
    }
    final groupWidth = size.width / count;
    final barWidth = (groupWidth * 0.24).clamp(2.0, 10.0);
    final barGap = (groupWidth * 0.08).clamp(1.0, 4.0);
    final labelStyle = TextStyle(fontSize: 10, color: labelColor);
    for (var i = 0; i < count; i++) {
      final centerX = i * groupWidth + groupWidth / 2;
      _paintBar(
        canvas,
        centerX - barWidth - barGap / 2,
        barWidth,
        downValues[i],
        maxValue,
        chartHeight,
        downColor,
      );
      _paintBar(
        canvas,
        centerX + barGap / 2,
        barWidth,
        upValues[i],
        maxValue,
        chartHeight,
        upColor,
      );
      final label = i < labels.length ? labels[i] : '';
      if (label.isNotEmpty) {
        final textPainter =
            TextPainter(
              text: TextSpan(text: label, style: labelStyle),
              textDirection: TextDirection.ltr,
            )..layout(maxWidth: groupWidth);
        textPainter.paint(
          canvas,
          Offset(centerX - textPainter.width / 2, chartHeight + 4),
        );
      }
    }
  }

  void _paintBar(
    Canvas canvas,
    double left,
    double width,
    double value,
    double maxValue,
    double chartHeight,
    Color color,
  ) {
    if (value <= 0 || maxValue <= 0) {
      return;
    }
    final height = (value / maxValue * chartHeight).clamp(3.0, chartHeight);
    canvas.drawRSuperellipse(
      RSuperellipse.fromRectAndRadius(
        Rect.fromLTWH(left, chartHeight - height, width, height),
        const Radius.circular(2),
      ),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _TrafficChartPainter oldDelegate) {
    return !listEquals(oldDelegate.downValues, downValues) ||
        !listEquals(oldDelegate.upValues, upValues) ||
        !listEquals(oldDelegate.labels, labels) ||
        oldDelegate.downColor != downColor ||
        oldDelegate.upColor != upColor ||
        oldDelegate.labelColor != labelColor;
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, this.action});

  final String label;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.colorScheme.primary,
              ),
            ),
          ),
          action ?? const SizedBox.shrink(),
        ],
      ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.upBytes, required this.downBytes});

  final int upBytes;
  final int downBytes;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: ShapeDecoration(
        shape: AppShape.lg,
        color: colorScheme.surfaceContainerLowest,
      ),
      child: Column(
        children: [
          _TotalRow(
            label: context.appLocalizations.dreamTrafficDown,
            value: downBytes.shortTraffic.show,
            valueColor: colorScheme.primary,
          ),
          _TotalRow(
            label: context.appLocalizations.dreamTrafficUp,
            value: upBytes.shortTraffic.show,
            valueColor: _upChartColor,
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w600, color: valueColor),
          ),
        ],
      ),
    );
  }
}

class _SortButton extends StatelessWidget {
  const _SortButton({required this.sortIndex, required this.onChanged});

  final int sortIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return CommonPopupBox(
      targetBuilder: (open) {
        return IconButton(
          tooltip: context.appLocalizations.dreamTrafficSort,
          onPressed: () => open(offset: const Offset(0, 8)),
          icon: const GlyphIcon(AppGlyphs.sort),
        );
      },
      popupBuilder: (context) => CommonPopupMenu(
        items: [
          for (var i = 0; i < _sortLabels(context.appLocalizations).length; i++)
            CommonPopupMenuItem(
              label: _sortLabels(context.appLocalizations)[i],
              checked: i == sortIndex,
              onPressed: () => onChanged(i),
            ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: ShapeDecoration(
        shape: AppShape.lg,
        color: colorScheme.surfaceContainerLowest,
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}
