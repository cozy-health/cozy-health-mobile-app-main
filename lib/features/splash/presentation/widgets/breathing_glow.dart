import 'package:flutter/material.dart';

/// A soft radial glow that breathes (fades in/out) behind the logo.
/// Used on the Splash screen to add warmth without visual noise.
class BreathingGlow extends StatefulWidget {
  final double size;
  final Color color;
  final Duration cycleDuration;

  const BreathingGlow({
    super.key,
    this.size = 220,
    this.color = Colors.white,
    this.cycleDuration = const Duration(seconds: 4),
  });

  @override
  State<BreathingGlow> createState() => _BreathingGlowState();
}

class _BreathingGlowState extends State<BreathingGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.cycleDuration,
    )..repeat(reverse: true);

    _opacity = Tween<double>(begin: 0.10, end: 0.22).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Respect system reduce-motion setting
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    if (reduceMotion) {
      return _buildGlow(0.15);
    }

    return AnimatedBuilder(
      animation: _opacity,
      builder: (_, __) => _buildGlow(_opacity.value),
    );
  }

  Widget _buildGlow(double opacity) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            widget.color.withValues(alpha: opacity),
            widget.color.withValues(alpha: opacity * 0.5),
            widget.color.withValues(alpha: 0),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}
