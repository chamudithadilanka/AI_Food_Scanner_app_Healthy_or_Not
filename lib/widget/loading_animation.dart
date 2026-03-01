import 'dart:math';
import 'package:flutter/material.dart';

class LoadingAnimation extends StatefulWidget {
  final double percentage; // 0..100 OR 0..1
  const LoadingAnimation({super.key, required this.percentage});

  @override
  State<LoadingAnimation> createState() => _LoadingAnimationState();
}

class _LoadingAnimationState extends State<LoadingAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _percent; // 0..100

  double _normalizeTo0to100(double p) {
    if (p.isNaN || p.isInfinite) return 0;
    if (p <= 1.0) return (p * 100).clamp(0, 100).toDouble();
    return p.clamp(0, 100).toDouble();
  }

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    final targetPercent = _normalizeTo0to100(widget.percentage);

    _percent = Tween<double>(
      begin: 0.0,
      end: targetPercent,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Color> _gradientColors(double percent) {
    if (percent < 40) {
      return const [
        Color(0xFFE53935),
        Color(0xFFFF7043),
      ]; // red gradient
    } else if (percent < 70) {
      return const [
        Color(0xFFFFB300),
        Color(0xFFFFE082),
      ]; // orange/yellow gradient
    } else {
      return const [
        Color(0xFF43A047),
        Color(0xFF81C784),
      ]; // green gradient
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final p = _percent.value.clamp(0, 100).toDouble();
        final progressValue = (p / 100).clamp(0.0, 1.0);
        final textValue = p.toInt();

        final colors = _gradientColors(p);

        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colors.last.withOpacity(0.4),
                    blurRadius: 40,
                    spreadRadius: 3,
                  ),
                  BoxShadow(
                    color: colors.last.withOpacity(0.2),
                    blurRadius: 80,
                    spreadRadius: 6,
                  ),
                ],
              ),
              child: CustomPaint(
                painter: _GradientCircularPainter(
                  progress: progressValue,
                  colors: colors,
                ),
              ),
            ),

            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "$textValue%",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    foreground: Paint()
                      ..shader = LinearGradient(
                        colors: colors,
                      ).createShader(const Rect.fromLTWH(0, 0, 100, 40)),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Freshness",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.last,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _GradientCircularPainter extends CustomPainter {
  final double progress; // 0.0 - 1.0
  final List<Color> colors;

  _GradientCircularPainter({
    required this.progress,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    const startAngle = -pi / 2;
    final sweepAngle = 2 * pi * progress;

    final bgPaint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;

    canvas.drawCircle(
      size.center(Offset.zero),
      size.width / 2 - 6,
      bgPaint,
    );

    final gradient = SweepGradient(
      startAngle: 0.0,
      endAngle: 2 * pi,
      colors: colors,
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect.deflate(6),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}