import 'dart:math';
import 'package:flutter/material.dart';

/// Renders an analog clock face with hour and minute hands.
/// Visual asset format: "clock|hour|minute"  (e.g. "clock|3|15")
class ClockFace extends StatelessWidget {
  final int hour;
  final int minute;
  final double size;

  const ClockFace({
    super.key,
    required this.hour,
    required this.minute,
    this.size = 180,
  });

  static ClockFace? tryParse(String visualAsset) {
    if (!visualAsset.startsWith('clock|')) return null;
    final parts = visualAsset.split('|');
    if (parts.length != 3) return null;
    final h = int.tryParse(parts[1]);
    final m = int.tryParse(parts[2]);
    if (h == null || m == null) return null;
    return ClockFace(hour: h, minute: m);
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _ClockPainter(hour, minute),
    );
  }
}

class _ClockPainter extends CustomPainter {
  final int hour;
  final int minute;

  _ClockPainter(this.hour, this.minute);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final facePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFF2D2D2D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // Clock face circle
    canvas.drawCircle(center, radius - 2, facePaint);
    canvas.drawCircle(center, radius - 2, borderPaint);

    // Hour markers (ticks)
    final tickPaint = Paint()
      ..color = const Color(0xFF2D2D2D)
      ..strokeWidth = 2;

    for (int i = 0; i < 12; i++) {
      final angle = (i * 30 - 90) * pi / 180;
      final inner = radius * 0.82;
      final outer = radius * 0.92;
      canvas.drawLine(
        Offset(center.dx + inner * cos(angle), center.dy + inner * sin(angle)),
        Offset(center.dx + outer * cos(angle), center.dy + outer * sin(angle)),
        tickPaint,
      );
    }

    // Hour numbers
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    for (int i = 1; i <= 12; i++) {
      final angle = (i * 30 - 90) * pi / 180;
      final numberRadius = radius * 0.65;
      final pos = Offset(
        center.dx + numberRadius * cos(angle),
        center.dy + numberRadius * sin(angle),
      );

      textPainter.text = TextSpan(
        text: i.toString(),
        style: TextStyle(
          color: const Color(0xFF2D2D2D),
          fontSize: radius * 0.18,
          fontWeight: FontWeight.w600,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(pos.dx - textPainter.width / 2, pos.dy - textPainter.height / 2),
      );
    }

    // Hour hand
    final hourAngle = ((hour % 12) * 30 + minute * 0.5 - 90) * pi / 180;
    final hourLength = radius * 0.5;
    final hourWidth = radius * 0.06;
    final hourPaint = Paint()
      ..color = const Color(0xFF2D2D2D)
      ..strokeWidth = hourWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      center,
      Offset(
        center.dx + hourLength * cos(hourAngle),
        center.dy + hourLength * sin(hourAngle),
      ),
      hourPaint,
    );

    // Minute hand
    final minuteAngle = (minute * 6 - 90) * pi / 180;
    final minuteLength = radius * 0.75;
    final minuteWidth = radius * 0.04;
    final minutePaint = Paint()
      ..color = const Color(0xFF2D2D2D)
      ..strokeWidth = minuteWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      center,
      Offset(
        center.dx + minuteLength * cos(minuteAngle),
        center.dy + minuteLength * sin(minuteAngle),
      ),
      minutePaint,
    );

    // Center dot
    canvas.drawCircle(
      center,
      radius * 0.06,
      Paint()..color = const Color(0xFF2D2D2D),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
