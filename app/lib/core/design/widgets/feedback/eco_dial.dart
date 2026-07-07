import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../tokens/app_colors.dart';

class EcoDial extends StatelessWidget {
  final double value; // Bound: 0.0 to 1.0
  final String label;
  final double size;

  const EcoDial({
    super.key,
    required this.value,
    this.label = 'Eco Life',
    this.size = 100.0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: Size(size, size * 0.6),
          painter: _EcoDialPainter(
            value: value,
            primaryColor: AppColors.primary,
            accentColor: AppColors.secondary,
            borderColor: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${(value * 100).toInt()}%',
          style: GoogleFonts.spaceMono(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurfaceVariant.withOpacity(0.8),
          ),
        ),
      ],
    );
  }
}

class _EcoDialPainter extends CustomPainter {
  final double value;
  final Color primaryColor;
  final Color accentColor;
  final Color borderColor;

  _EcoDialPainter({
    required this.value,
    required this.primaryColor,
    required this.accentColor,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - 8;

    final bgPaint = Paint()
      ..color = borderColor.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    // Draw background track
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi,
      false,
      bgPaint,
    );

    // Draw active colored value track with sweep gradient
    final trackPaint = Paint()
      ..shader = SweepGradient(
        colors: [primaryColor, accentColor],
        startAngle: math.pi,
        endAngle: 2 * math.pi,
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi * value,
      false,
      trackPaint,
    );

    // Draw heavy brutalist outlines
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius + 6),
      math.pi,
      math.pi,
      false,
      borderPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 6),
      math.pi,
      math.pi,
      false,
      borderPaint,
    );

    // Tick segments
    final tickPaint = Paint()
      ..color = borderColor
      ..strokeWidth = 1.5;

    for (int i = 0; i <= 4; i++) {
      final angle = math.pi + (math.pi * (i / 4));
      final start = Offset(
        center.dx + (radius - 10) * math.cos(angle),
        center.dy + (radius - 10) * math.sin(angle),
      );
      final end = Offset(
        center.dx + (radius + 2) * math.cos(angle),
        center.dy + (radius + 2) * math.sin(angle),
      );
      canvas.drawLine(start, end, tickPaint);
    }

    // Pointer needle
    final needleAngle = math.pi + (math.pi * value);
    final needlePaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(
        center.dx + 4 * math.cos(needleAngle + math.pi / 2),
        center.dy + 4 * math.sin(needleAngle + math.pi / 2),
      )
      ..lineTo(
        center.dx + (radius - 2) * math.cos(needleAngle),
        center.dy + (radius - 2) * math.sin(needleAngle),
      )
      ..lineTo(
        center.dx + 4 * math.cos(needleAngle - math.pi / 2),
        center.dy + 4 * math.sin(needleAngle - math.pi / 2),
      )
      ..close();

    canvas.drawPath(path, needlePaint);

    // Center pin
    canvas.drawCircle(center, 6, Paint()..color = borderColor);
    canvas.drawCircle(center, 3, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _EcoDialPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.borderColor != borderColor;
  }
}
