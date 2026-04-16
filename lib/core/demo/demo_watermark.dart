/// EduX School Management System
/// Demo Watermark Overlay — draws repeating diagonal "DEMO" text
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'demo_config.dart';

/// Wraps [child] with a translucent repeating "DEMO" watermark.
/// Does nothing when [DemoConfig.isDemo] is false.
class DemoWatermark extends StatelessWidget {
  final Widget child;
  const DemoWatermark({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!DemoConfig.isDemo) return child;

    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: _WatermarkPainter()),
          ),
        ),
      ],
    );
  }
}

class _WatermarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final textStyle = TextStyle(
      color: Colors.grey.withValues(alpha: 0.06),
      fontSize: 60,
      fontWeight: FontWeight.w900,
      letterSpacing: 12,
    );

    final paragraphBuilder =
        TextPainter(textDirection: TextDirection.ltr, text: TextSpan(text: 'DEMO', style: textStyle));
    paragraphBuilder.layout();

    final textWidth = paragraphBuilder.width;
    final textHeight = paragraphBuilder.height;
    const angle = -30 * math.pi / 180;
    const spacingX = 80.0;
    const spacingY = 120.0;

    canvas.save();
    canvas.rotate(angle);

    // Cover the rotated canvas area — expand bounds to ensure full coverage
    final diagonal = math.sqrt(size.width * size.width + size.height * size.height);
    final startX = -diagonal;
    final startY = -diagonal * 0.3;
    final endX = diagonal;
    final endY = diagonal;

    var y = startY;
    while (y < endY) {
      var x = startX;
      while (x < endX) {
        paragraphBuilder.paint(canvas, Offset(x, y));
        x += textWidth + spacingX;
      }
      y += textHeight + spacingY;
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
