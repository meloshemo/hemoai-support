import 'package:flutter/material.dart';
import 'dart:math' as math;

class AnimatedBackground extends StatefulWidget {
  final Widget child;
  final List<Color>? colors;
  final Duration duration;

  const AnimatedBackground({
    super.key,
    required this.child,
    this.colors,
    this.duration = const Duration(seconds: 20),
  });

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(_controller);
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final defaultColors = [
      colorScheme.primary.withOpacity(0.1),
      colorScheme.secondary.withOpacity(0.1),
      colorScheme.tertiary.withOpacity(0.1),
    ];

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          painter: AnimatedBackgroundPainter(
            animation: _animation.value,
            colors: widget.colors ?? defaultColors,
          ),
          child: widget.child,
        );
      },
    );
  }
}

class AnimatedBackgroundPainter extends CustomPainter {
  final double animation;
  final List<Color> colors;

  AnimatedBackgroundPainter({
    required this.animation,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    // Create gradient background
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors,
      stops: const [0.0, 0.5, 1.0],
    );

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final shader = gradient.createShader(rect);
    paint.shader = shader;

    canvas.drawRect(rect, paint);

    // Draw animated circles
    _drawAnimatedCircles(canvas, size);
  }

  void _drawAnimatedCircles(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Draw multiple animated circles
    for (int i = 0; i < 3; i++) {
      final radius = 50 + (i * 30);
      final angle = animation + (i * math.pi / 3);
      final x = centerX + math.cos(angle) * (radius * 0.5);
      final y = centerY + math.sin(angle) * (radius * 0.3);

      paint.color = colors[i % colors.length].withOpacity(0.1);
      
      canvas.drawCircle(
        Offset(x, y),
        radius,
        paint,
      );
    }

    // Draw floating particles
    _drawFloatingParticles(canvas, size);
  }

  void _drawFloatingParticles(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 20; i++) {
      final angle = animation + (i * math.pi / 10);
      final radius = 2 + (i % 3);
      final x = (size.width * 0.1) + 
               math.cos(angle) * (size.width * 0.8);
      final y = (size.height * 0.1) + 
               math.sin(angle * 0.5) * (size.height * 0.8);

      paint.color = colors[i % colors.length].withOpacity(0.3);
      
      canvas.drawCircle(
        Offset(x, y),
        radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(AnimatedBackgroundPainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}
