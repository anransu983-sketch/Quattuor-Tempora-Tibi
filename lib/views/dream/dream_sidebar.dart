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

const _sidebarGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0xFF3A3A3C), Color(0xFF1C1C1E)],
);

class DreamSidebar extends ConsumerStatefulWidget {
  const DreamSidebar({super.key});

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
    bool expanded = false,
    String? label,
  }) {
    final button = IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: GlyphIcon(glyph, color: Colors.white),
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
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 20,
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 10),
      color: Colors.white24,
    );
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    final expanded = ref.watch(dreamSidebarExpandedProvider);
    final hour = _now.hour.toString().padLeft(2, '0');
    final minute = _now.minute.toString().padLeft(2, '0');
    return Container(
      width: expanded ? 116 : 76,
      decoration: const BoxDecoration(gradient: _sidebarGradient),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(
              hour,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 40,
                fontWeight: FontWeight.w600,
                height: 1.1,
              ),
            ),
            const Text(
              '—',
              style: TextStyle(color: Colors.white54, fontSize: 16),
            ),
            Text(
              minute,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 40,
                fontWeight: FontWeight.w600,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 14),
            _BatteryCapsule(level: _batteryLevel),
            _divider(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _iconButton(
                      glyph: AppGlyphs.proxies,
                      tooltip: appLocalizations.proxies,
                      onPressed: () => _toPage(PageLabel.proxies),
                      expanded: expanded,
                      label: appLocalizations.proxies,
                    ),
                    _divider(),
                    _iconButton(
                      glyph: AppGlyphs.profiles,
                      tooltip: appLocalizations.profiles,
                      onPressed: () => _toPage(PageLabel.profiles),
                      expanded: expanded,
                      label: appLocalizations.profiles,
                    ),
                    _divider(),
                    _iconButton(
                      glyph: AppGlyphs.settings,
                      tooltip: appLocalizations.settings,
                      onPressed: () => _toPage(PageLabel.settings),
                      expanded: expanded,
                      label: appLocalizations.settings,
                    ),
                    _divider(),
                    _iconButton(
                      glyph: AppGlyphs.palette,
                      tooltip: appLocalizations.theme,
                      onPressed: () =>
                          BaseNavigator.push(context, const ThemeView()),
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
      ),
    );
  }
}

class _BatteryCapsule extends StatelessWidget {
  const _BatteryCapsule({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    final ratio = level < 0 ? 0.0 : (level.clamp(0, 100) / 100.0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 38,
          height: 18,
          child: CustomPaint(
            painter: _BatteryPainter(ratio: ratio),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          level < 0 ? '--' : '$level%',
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }
}

class _BatteryPainter extends CustomPainter {
  _BatteryPainter({required this.ratio});

  final double ratio;

  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Colors.white70;
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
      final fillPaint = Paint()..color = Colors.white;
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
      oldDelegate.ratio != ratio;
}
