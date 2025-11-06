import 'package:flutter/material.dart';
import 'dart:math';

/// Labubu-style colorful avatar widget
/// Generates unique, colorful avatars based on seed
class LabubuAvatar extends StatelessWidget {
  final String? seed;
  final double size;
  final List<Color>? colors;
  final int? variantIndex;

  const LabubuAvatar({
    super.key,
    this.seed,
    this.size = 48.0,
    this.colors,
    this.variantIndex,
  });

  @override
  Widget build(BuildContext context) {
    final variant = _generateVariant();
    final avatarColors = colors ?? variant.colors;
    final expression = variant.expression;
    final hairStyle = variant.hairStyle;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: avatarColors,
        ),
        boxShadow: [
          BoxShadow(
            color: avatarColors[0].withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: CustomPaint(
        painter: LabubuPainter(
          expression: expression,
          hairStyle: hairStyle,
          size: size,
        ),
      ),
    );
  }

  LabubuVariant _generateVariant() {
    final random = seed != null ? Random(seed.hashCode) : Random();
    final index = variantIndex ?? (seed != null ? seed.hashCode.abs() % _colorPalettes.length : random.nextInt(_colorPalettes.length));
    
    return LabubuVariant(
      colors: _colorPalettes[index % _colorPalettes.length],
      expression: _expressions[index % _expressions.length],
      hairStyle: _hairStyles[index % _hairStyles.length],
    );
  }

  // Labubu color palettes (vibrant and colorful)
  static final List<List<Color>> _colorPalettes = [
    // Pink & Purple
    [const Color(0xFFFF6B9D), const Color(0xFFC44569), const Color(0xFFF8BBD9)],
    [const Color(0xFFE056FD), const Color(0xFFBE2EDD), const Color(0xFFF5B3FF)],
    [const Color(0xFFFF69B4), const Color(0xFFFF1493), const Color(0xFFFFB6C1)],
    
    // Blue & Cyan
    [const Color(0xFF4ECDC4), const Color(0xFF44A08D), const Color(0xFFA8E6CF)],
    [const Color(0xFF6C5CE7), const Color(0xFF4834D4), const Color(0xFFA29BFE)],
    [const Color(0xFF00D2FF), const Color(0xFF3A7BD5), const Color(0xFF74B9FF)],
    
    // Green & Yellow
    [const Color(0xFF00F260), const Color(0xFF0575E6), const Color(0xFF7FFF00)],
    [const Color(0xFFFFD700), const Color(0xFFFFA500), const Color(0xFFFFF700)],
    [const Color(0xFF00FF87), const Color(0xFF00D4AA), const Color(0xFF7FFFD4)],
    
    // Orange & Red
    [const Color(0xFFFF6B35), const Color(0xFFF7931E), const Color(0xFFFFB347)],
    [const Color(0xFFFF416C), const Color(0xFFFF4757), const Color(0xFFFF6B9D)],
    [const Color(0xFFFF6B6B), const Color(0xFFEE5A6F), const Color(0xFFFF8A80)],
    
    // Purple & Indigo
    [const Color(0xFF667EEA), const Color(0xFF764BA2), const Color(0xFFB19CD9)],
    [const Color(0xFF9D50BB), const Color(0xFF6E48AA), const Color(0xFFC8A8E9)],
    
    // Teal & Mint
    [const Color(0xFF00CDAC), const Color(0xFF02AAB0), const Color(0xFFA8F5E9)],
    [const Color(0xFF00F5A0), const Color(0xFF00D9F5), const Color(0xFFB2F5EA)],
    
    // Coral & Peach
    [const Color(0xFFFF7E5F), const Color(0xFFFEB47B), const Color(0xFFFFBFA0)],
    [const Color(0xFFFF9A9E), const Color(0xFFFAD0C4), const Color(0xFFFFD1DC)],
    
    // Lavender & Lilac
    [const Color(0xFFE0C3FC), const Color(0xFFB8A9FF), const Color(0xFFD8B4FE)],
    [const Color(0xFFC471F5), const Color(0xFFFA71CD), const Color(0xFFFFB6E1)],
    
    // Sky & Ocean
    [const Color(0xFF00C9FF), const Color(0xFF92FE9D), const Color(0xFFA8E6CF)],
    [const Color(0xFF667EEA), const Color(0xFF764BA2), const Color(0xFFB19CD9)],
    
    // Golden & Amber
    [const Color(0xFFFDC830), const Color(0xFFF37335), const Color(0xFFFFE082)],
    [const Color(0xFFFFD700), const Color(0xFFFFA500), const Color(0xFFFFF59D)],
  ];

  // Expression types
  static final List<ExpressionType> _expressions = [
    ExpressionType.happy,
    ExpressionType.excited,
    ExpressionType.cool,
    ExpressionType.wink,
    ExpressionType.surprised,
    ExpressionType.love,
    ExpressionType.shy,
    ExpressionType.cheerful,
  ];

  // Hair styles
  static final List<HairStyle> _hairStyles = [
    HairStyle.spiky,
    HairStyle.curly,
    HairStyle.wavy,
    HairStyle.puffy,
    HairStyle.short,
    HairStyle.long,
    HairStyle.bob,
    HairStyle.afro,
  ];
}

class LabubuVariant {
  final List<Color> colors;
  final ExpressionType expression;
  final HairStyle hairStyle;

  LabubuVariant({
    required this.colors,
    required this.expression,
    required this.hairStyle,
  });
}

enum ExpressionType {
  happy,
  excited,
  cool,
  wink,
  surprised,
  love,
  shy,
  cheerful,
}

enum HairStyle {
  spiky,
  curly,
  wavy,
  puffy,
  short,
  long,
  bob,
  afro,
}

class LabubuPainter extends CustomPainter {
  final ExpressionType expression;
  final HairStyle hairStyle;
  final double size;

  LabubuPainter({
    required this.expression,
    required this.hairStyle,
    required this.size,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw hair
    _drawHair(canvas, center, radius);

    // Draw face (circle)
    final facePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.85, facePaint);

    // Draw face outline
    final outlinePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius * 0.85, outlinePaint);

    // Draw eyes
    _drawEyes(canvas, center, radius);

    // Draw mouth
    _drawMouth(canvas, center, radius);

    // Draw cheeks (optional, for happy expressions)
    if (expression == ExpressionType.happy || expression == ExpressionType.cheerful) {
      _drawCheeks(canvas, center, radius);
    }
  }

  void _drawHair(Canvas canvas, Offset center, double radius) {
    final hairPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    switch (hairStyle) {
      case HairStyle.spiky:
        // Draw spiky hair on top
        for (int i = 0; i < 5; i++) {
          final angle = (i * 2 - 4) * 0.3;
          final x = center.dx + (radius * 0.7) * sin(angle);
          final y = center.dy - radius * 0.6 + (i % 2) * 3;
          final path = Path();
          path.moveTo(x, y);
          path.lineTo(x + 4, y - 8);
          path.lineTo(x - 4, y - 8);
          path.close();
          canvas.drawPath(path, hairPaint);
        }
        break;
      case HairStyle.curly:
        // Draw curly hair
        for (int i = 0; i < 6; i++) {
          final angle = (i - 3) * 0.4;
          final x = center.dx + (radius * 0.6) * sin(angle);
          final y = center.dy - radius * 0.5;
          canvas.drawCircle(Offset(x, y), 6, hairPaint);
        }
        break;
      case HairStyle.wavy:
        // Draw wavy hair
        final path = Path();
        path.moveTo(center.dx - radius * 0.6, center.dy - radius * 0.5);
        for (int i = 0; i < 5; i++) {
          final x = center.dx - radius * 0.6 + (i * radius * 0.3);
          final y = center.dy - radius * 0.5 + sin(i * 0.8) * 4;
          path.quadraticBezierTo(x, y, x + radius * 0.15, y);
        }
        path.lineTo(center.dx + radius * 0.6, center.dy - radius * 0.5);
        canvas.drawPath(path, hairPaint);
        break;
      case HairStyle.puffy:
        // Draw puffy hair
        canvas.drawCircle(
          Offset(center.dx, center.dy - radius * 0.4),
          radius * 0.4,
          hairPaint,
        );
        break;
      case HairStyle.short:
        // Draw short hair
        final path = Path();
        path.addRRect(RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(center.dx, center.dy - radius * 0.5),
            width: radius * 1.2,
            height: radius * 0.3,
          ),
          const Radius.circular(8),
        ));
        canvas.drawPath(path, hairPaint);
        break;
      case HairStyle.long:
        // Draw long hair
        final path = Path();
        path.moveTo(center.dx - radius * 0.5, center.dy - radius * 0.5);
        path.lineTo(center.dx - radius * 0.5, center.dy + radius * 0.3);
        path.lineTo(center.dx + radius * 0.5, center.dy + radius * 0.3);
        path.lineTo(center.dx + radius * 0.5, center.dy - radius * 0.5);
        path.close();
        canvas.drawPath(path, hairPaint);
        break;
      case HairStyle.bob:
        // Draw bob cut
        final path = Path();
        path.addRRect(RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(center.dx, center.dy - radius * 0.3),
            width: radius * 1.0,
            height: radius * 0.5,
          ),
          const Radius.circular(12),
        ));
        canvas.drawPath(path, hairPaint);
        break;
      case HairStyle.afro:
        // Draw afro
        canvas.drawCircle(
          Offset(center.dx, center.dy - radius * 0.3),
          radius * 0.5,
          hairPaint,
        );
        break;
    }
  }

  void _drawEyes(Canvas canvas, Offset center, double radius) {
    final eyePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    switch (expression) {
      case ExpressionType.happy:
      case ExpressionType.cheerful:
        // Curved eyes (happy)
        final leftEye = Path();
        leftEye.moveTo(center.dx - radius * 0.25, center.dy - radius * 0.1);
        leftEye.quadraticBezierTo(
          center.dx - radius * 0.35,
          center.dy - radius * 0.2,
          center.dx - radius * 0.15,
          center.dy - radius * 0.2,
        );
        leftEye.quadraticBezierTo(
          center.dx - radius * 0.25,
          center.dy - radius * 0.1,
          center.dx - radius * 0.25,
          center.dy - radius * 0.1,
        );
        canvas.drawPath(leftEye, eyePaint);

        final rightEye = Path();
        rightEye.moveTo(center.dx + radius * 0.25, center.dy - radius * 0.1);
        rightEye.quadraticBezierTo(
          center.dx + radius * 0.35,
          center.dy - radius * 0.2,
          center.dx + radius * 0.15,
          center.dy - radius * 0.2,
        );
        rightEye.quadraticBezierTo(
          center.dx + radius * 0.25,
          center.dy - radius * 0.1,
          center.dx + radius * 0.25,
          center.dy - radius * 0.1,
        );
        canvas.drawPath(rightEye, eyePaint);
        break;

      case ExpressionType.wink:
        // One eye closed, one open
        final leftEye = Path();
        leftEye.moveTo(center.dx - radius * 0.25, center.dy - radius * 0.15);
        leftEye.quadraticBezierTo(
          center.dx - radius * 0.35,
          center.dy - radius * 0.15,
          center.dx - radius * 0.15,
          center.dy - radius * 0.15,
        );
        canvas.drawPath(leftEye, eyePaint);

        // Right eye (circle)
        canvas.drawCircle(
          Offset(center.dx + radius * 0.25, center.dy - radius * 0.15),
          radius * 0.08,
          eyePaint,
        );
        break;

      case ExpressionType.surprised:
        // Round eyes
        canvas.drawCircle(
          Offset(center.dx - radius * 0.25, center.dy - radius * 0.15),
          radius * 0.1,
          eyePaint,
        );
        canvas.drawCircle(
          Offset(center.dx + radius * 0.25, center.dy - radius * 0.15),
          radius * 0.1,
          eyePaint,
        );
        break;

      case ExpressionType.love:
        // Heart eyes (simplified as star eyes)
        _drawStar(canvas, Offset(center.dx - radius * 0.25, center.dy - radius * 0.15), radius * 0.08);
        _drawStar(canvas, Offset(center.dx + radius * 0.25, center.dy - radius * 0.15), radius * 0.08);
        break;

      default:
        // Default: simple circles
        canvas.drawCircle(
          Offset(center.dx - radius * 0.25, center.dy - radius * 0.15),
          radius * 0.08,
          eyePaint,
        );
        canvas.drawCircle(
          Offset(center.dx + radius * 0.25, center.dy - radius * 0.15),
          radius * 0.08,
          eyePaint,
        );
    }
  }

  void _drawMouth(Canvas canvas, Offset center, double radius) {
    final mouthPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    switch (expression) {
      case ExpressionType.happy:
      case ExpressionType.cheerful:
      case ExpressionType.excited:
        // Smile
        final smile = Path();
        smile.moveTo(center.dx - radius * 0.2, center.dy + radius * 0.1);
        smile.quadraticBezierTo(
          center.dx,
          center.dy + radius * 0.25,
          center.dx + radius * 0.2,
          center.dy + radius * 0.1,
        );
        canvas.drawPath(smile, mouthPaint);
        break;

      case ExpressionType.wink:
        // Small smile
        final smile = Path();
        smile.moveTo(center.dx - radius * 0.15, center.dy + radius * 0.15);
        smile.quadraticBezierTo(
          center.dx,
          center.dy + radius * 0.2,
          center.dx + radius * 0.15,
          center.dy + radius * 0.15,
        );
        canvas.drawPath(smile, mouthPaint);
        break;

      case ExpressionType.surprised:
        // O mouth
        canvas.drawCircle(
          Offset(center.dx, center.dy + radius * 0.15),
          radius * 0.1,
          mouthPaint,
        );
        break;

      case ExpressionType.love:
        // Heart mouth
        _drawHeart(canvas, Offset(center.dx, center.dy + radius * 0.15), radius * 0.08);
        break;

      default:
        // Neutral mouth
        final mouth = Path();
        mouth.moveTo(center.dx - radius * 0.15, center.dy + radius * 0.15);
        mouth.lineTo(center.dx + radius * 0.15, center.dy + radius * 0.15);
        canvas.drawPath(mouth, mouthPaint);
    }
  }

  void _drawCheeks(Canvas canvas, Offset center, double radius) {
    final cheekPaint = Paint()
      ..color = Colors.pink.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(center.dx - radius * 0.4, center.dy + radius * 0.05),
      radius * 0.08,
      cheekPaint,
    );
    canvas.drawCircle(
      Offset(center.dx + radius * 0.4, center.dy + radius * 0.05),
      radius * 0.08,
      cheekPaint,
    );
  }

  void _drawStar(Canvas canvas, Offset center, double radius) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final angle = (i * 4 * pi / 5) - pi / 2;
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = Colors.pink..style = PaintingStyle.fill);
  }

  void _drawHeart(Canvas canvas, Offset center, double size) {
    final path = Path();
    path.moveTo(center.dx, center.dy + size * 0.3);
    path.cubicTo(
      center.dx - size * 0.5,
      center.dy - size * 0.2,
      center.dx - size * 0.5,
      center.dy - size * 0.5,
      center.dx,
      center.dy - size * 0.5,
    );
    path.cubicTo(
      center.dx + size * 0.5,
      center.dy - size * 0.5,
      center.dx + size * 0.5,
      center.dy - size * 0.2,
      center.dx,
      center.dy + size * 0.3,
    );
    canvas.drawPath(path, Paint()..color = Colors.pink..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

