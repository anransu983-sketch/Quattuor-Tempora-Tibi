import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/icons/icons.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/views/theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'dream_home_prefs.dart';

/// Sidebar metrics, mirroring the original DreamBox layout:
/// the main card overlaps the sidebar by [_overlap], so only
/// [visibleWidth] is actually seen when expanded.
const dreamSidebarFullWidth = 100.0;
const _overlap = 28.0;
const dreamSidebarVisibleWidth = dreamSidebarFullWidth - _overlap;
const dreamSidebarCollapsedWidth = 68.0;

double dreamSidebarDockInset(bool expanded) =>
    expanded ? dreamSidebarVisibleWidth : dreamSidebarCollapsedWidth;

class DreamSidebar extends ConsumerStatefulWidget {
  const DreamSidebar({super.key, this.visibleWidth});

  /// Width the content is laid out in; the rest may sit under the main card.
  final double? visibleWidth;

  @override
  ConsumerState<DreamSidebar> createState() => _DreamSidebarState();
}

class _DreamSidebarState extends ConsumerState<DreamSidebar> {
  Timer? _clockTimer;
  DateTime _now = DateTime.now();
  int _batteryLevel = -1;

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    });
    _loadBattery();
  }

  Future<void> _loadBattery() async {
    try {
      final level = await Battery().batteryLevel;
      if (mounted) {
        setState(() => _batteryLevel = level);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  void _toPage(PageLabel label) {
    ref.read(currentPageLabelProvider.notifier).toPage(label);
  }

  Widget _iconButton({
    required Glyph glyph,
    required String tooltip,
    required VoidCallback onPressed,
    required ColorScheme colorScheme,
    bool expanded = false,
    String? label,
  }) {
    final button = IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: GlyphIcon(glyph, color: colorScheme.onSurfaceVariant),
    );
    if (!expanded || label == null) {
      return SizedBox(width: 44, height: 44, child: button);
    }
    return SizedBox(
      height: 56,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: 44, height: 40, child: button),
          Text(
            label,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(ColorScheme colorScheme) {
    return Container(
      width: 20,
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 10),
      color: colorScheme.outlineVariant,
    );
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    final colorScheme = context.colorScheme;
    final expanded = ref.watch(dreamSidebarExpandedProvider);
    final hour = _now.hour.toString().padLeft(2, '0');
    final minute = _now.minute.toString().padLeft(2, '0');
    final content = SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 20),
          Text(
            hour,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 40,
              fontWeight: FontWeight.w600,
              height: 1.1,
            ),
          ),
          Text(
            '—',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 16,
            ),
          ),
          Text(
            minute,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 40,
              fontWeight: FontWeight.w600,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 14),
          _BatteryCapsule(level: _batteryLevel),
          _divider(colorScheme),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _iconButton(
                    glyph: AppGlyphs.proxies,
                    tooltip: appLocalizations.proxies,
                    onPressed: () => _toPage(PageLabel.proxies),
                    colorScheme: colorScheme,
                    expanded: expanded,
                    label: appLocalizations.proxies,
                  ),
                  _divider(colorScheme),
                  _iconButton(
                    glyph: AppGlyphs.profiles,
                    tooltip: appLocalizations.profiles,
                    onPressed: () => _toPage(PageLabel.profiles),
                    colorScheme: colorScheme,
                    expanded: expanded,
                    label: appLocalizations.profiles,
                  ),
                  _divider(colorScheme),
                  _iconButton(
                    glyph: AppGlyphs.settings,
                    tooltip: appLocalizations.settings,
                    onPressed: () => _toPage(PageLabel.settings),
                    colorScheme: colorScheme,
                    expanded: expanded,
                    label: appLocalizations.settings,
                  ),
                  _divider(colorScheme),
                  _iconButton(
                    glyph: AppGlyphs.palette,
                    tooltip: appLocalizations.theme,
                    onPressed: () =>
                        BaseNavigator.push(context, const ThemeView()),
                    colorScheme: colorScheme,
                    expanded: expanded,
                    label: appLocalizations.theme,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
    final visibleWidth = widget.visibleWidth;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colorScheme.surfaceContainerHigh,
            colorScheme.surfaceContainer,
          ],
        ),
      ),
      child: visibleWidth == null
          ? content
          : Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(width: visibleWidth, child: content),
            ),
    );
  }
}

class _BatteryCapsule extends StatelessWidget {
  const _BatteryCapsule({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final ratio = level < 0 ? 0.0 : (level.clamp(0, 100) / 100.0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 38,
          height: 18,
          child: CustomPaint(
            painter: _BatteryPainter(
              ratio: ratio,
              colorScheme: colorScheme,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          level < 0 ? '--' : '$level%',
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _BatteryPainter extends CustomPainter {
  _BatteryPainter({required this.ratio, required this.colorScheme});

  final double ratio;
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = colorScheme.onSurfaceVariant;
    final bodyRect = RSuperellipse.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width - 5, size.height),
      const Radius.circular(9),
    );
    canvas.drawRSuperellipse(bodyRect, borderPaint);
    final nubRect = RSuperellipse.fromRectAndRadius(
      Rect.fromLTWH(size.width - 4, size.height * 0.32, 3, size.height * 0.36),
      const Radius.circular(1.5),
    );
    canvas.drawRSuperellipse(nubRect, borderPaint..style = PaintingStyle.fill);
    if (ratio > 0) {
      final fillPaint = Paint()..color = colorScheme.onSurface;
      final fillWidth = (size.width - 9) * ratio;
      canvas.drawRSuperellipse(
        RSuperellipse.fromRectAndRadius(
          Rect.fromLTWH(2.5, 2.5, fillWidth, size.height - 5),
          const Radius.circular(6),
        ),
        fillPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BatteryPainter oldDelegate) =>
      oldDelegate.ratio != ratio ||
      oldDelegate.colorScheme != colorScheme;
}
