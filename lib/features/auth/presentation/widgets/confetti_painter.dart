import 'dart:math';
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Confetti colors extracted from Signup-3.svg
// ---------------------------------------------------------------------------
const List<Color> kConfettiColors = [
  Color(0xFF0460D8), // Brand blue
  Color(0xFFFBBC04), // Yellow
  Color(0xFFEA4335), // Red-coral
  Color(0xFF34A853), // Green
  Color(0xFFFF6B6B), // Pink-red
  Color(0xFFA259FF), // Purple
  Color(0xFF00C2FF), // Cyan
  Color(0xFFFF9500), // Orange
];

enum ConfettiShape { rect, circle, ribbon, arc }

class ConfettiParticle {
  Offset position;
  Offset velocity;
  double rotation;
  double rotationVelocity;
  double size;
  double opacity;
  Color color;
  ConfettiShape shape;
  double scaleX;

  ConfettiParticle({
    required this.position,
    required this.velocity,
    required this.rotation,
    required this.rotationVelocity,
    required this.size,
    required this.opacity,
    required this.color,
    required this.shape,
    required this.scaleX,
  });
}

class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;

  const ConfettiPainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;

    for (final p in particles) {
      if (p.opacity <= 0) continue;

      canvas.save();
      canvas.translate(p.position.dx, p.position.dy);
      canvas.rotate(p.rotation);

      paint.color = p.color.withValues(alpha: p.opacity.clamp(0.0, 1.0));

      switch (p.shape) {
        case ConfettiShape.rect:
          canvas.scale(p.scaleX.abs().clamp(0.15, 1.0), 1.0);
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset.zero,
              width: p.size * 1.6,
              height: p.size * 0.7,
            ),
            paint,
          );
          break;

        case ConfettiShape.ribbon:
          canvas.scale(p.scaleX.abs().clamp(0.1, 1.0), 1.0);
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset.zero,
              width: p.size * 3.5,
              height: p.size * 0.4,
            ),
            paint,
          );
          break;

        case ConfettiShape.circle:
          canvas.drawCircle(Offset.zero, p.size * 0.6, paint);
          break;

        case ConfettiShape.arc:
          paint.style = PaintingStyle.stroke;
          paint.strokeWidth = p.size * 0.35;
          canvas.drawArc(
            Rect.fromCenter(
              center: Offset.zero,
              width: p.size * 1.4,
              height: p.size * 1.4,
            ),
            0,
            pi,
            false,
            paint,
          );
          paint.style = PaintingStyle.fill;
          break;
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant ConfettiPainter oldDelegate) => true;
}
