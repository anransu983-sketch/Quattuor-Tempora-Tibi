import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

class DreamOrb extends StatelessWidget {
  const DreamOrb({super.key, this.diameter = 220});

  final double diameter;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: diameter,
      height: diameter,
      child: CustomPaint(painter: _DreamOrbPainter()),
    );
  }
}

class _DreamOrbPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final glowPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0x8C7FD4C1), Color(0x007FD4C1)],
      ).createShader(
        Rect.fromCircle(center: center, radius: radius * 1.7),
      );
    canvas.drawCircle(center, radius * 1.7, glowPaint);
    final spherePaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.35, -0.38),
        stops: [0.0, 0.55, 1.0],
        colors: [Color(0xFFFDFEFF), Color(0xFFC2C9D5), Color(0xFF767F8C)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, spherePaint);
    final highlightPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xB3FFFFFF), Color(0x00FFFFFF)],
      ).createShader(
        Rect.fromCircle(
          center: center + Offset(-radius * 0.32, -radius * 0.36),
          radius: radius * 0.42,
        ),
      );
    canvas.drawCircle(
      center + Offset(-radius * 0.32, -radius * 0.36),
      radius * 0.42,
      highlightPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
