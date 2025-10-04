import 'package:flutter/material.dart';

/// A tiny, dependency-free sparkline for 1D numeric series.
/// - Expects [values] length >= 2; otherwise renders a dashed placeholder line.
/// - Scales to the provided constraints (use fixed height for best results).
class MiniSparkline extends StatelessWidget {
  final List<double> values;
  final Color color;
  final double strokeWidth;
  final bool showDot;
  final double dotRadius;
  final Color? background;

  const MiniSparkline({
    super.key,
    required this.values,
    this.color = Colors.blue,
    this.strokeWidth = 2.0,
    this.showDot = true,
    this.dotRadius = 2.5,
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SparklinePainter(
        values: values,
        color: color,
        strokeWidth: strokeWidth,
        showDot: showDot,
        dotRadius: dotRadius,
        background: background ?? Colors.transparent,
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> values;
  final Color color;
  final double strokeWidth;
  final bool showDot;
  final double dotRadius;
  final Color background;

  _SparklinePainter({
    required this.values,
    required this.color,
    required this.strokeWidth,
    required this.showDot,
    required this.dotRadius,
    required this.background,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = background..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, bgPaint);

    if (values.length < 2) {
      // Draw a subtle dashed baseline as placeholder
      final baseline = size.height * 0.5;
      final dashPaint = Paint()
        ..color = color.withValues(alpha: 0.3)
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke;
      const dashWidth = 4.0;
      const dashSpace = 3.0;
      double x = 0;
      while (x < size.width) {
        final double x2 = (x + dashWidth) > size.width ? size.width : (x + dashWidth);
        canvas.drawLine(Offset(x, baseline), Offset(x2, baseline), dashPaint);
        x += dashWidth + dashSpace;
      }
      return;
    }

    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final range = (maxV - minV).abs();
    final safeRange = range == 0 ? 1.0 : range;

    final dx = size.width / (values.length - 1);
    final path = Path();

    double yFor(double v) {
      // Invert y (higher values at top), add small padding
      final t = (v - minV) / safeRange;
      final pad = 2.0;
      return pad + (1 - t) * (size.height - 2 * pad);
    }

    for (int i = 0; i < values.length; i++) {
      final x = i * dx;
      final y = yFor(values[i]);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);

    if (showDot) {
      final lastX = (values.length - 1) * dx;
      final lastY = yFor(values.last);
      final dotPaint = Paint()..color = color;
      canvas.drawCircle(Offset(lastX, lastY), dotRadius, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.showDot != showDot ||
        oldDelegate.dotRadius != dotRadius ||
        oldDelegate.background != background;
  }
}
