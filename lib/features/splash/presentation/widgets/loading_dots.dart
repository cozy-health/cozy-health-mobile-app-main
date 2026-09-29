import 'package:flutter/material.dart';

/// Three dots that pulse in a gentle left-to-right wave.
/// Feels like breathing, not spinning.
class LoadingDots extends StatefulWidget {
  final Color color;
  final double dotSize;
  final double spacing;

  const LoadingDots({
    super.key,
    this.color = Colors.white,
    this.dotSize = 6,
    this.spacing = 4,
  });

  @override
  State<LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<LoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _opacityFor(int index) {
    // Each dot peaks 200ms after the previous one.
    final phase = (_controller.value + index * 0.1667) % 1.0;
    // Triangle wave: 0 → 1 → 0
    final t = phase < 0.5 ? phase * 2 : (1 - phase) * 2;
    return 0.4 + (t * 0.6); // 0.4 → 1.0
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    if (reduceMotion) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) => _dot(0.7, i)),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) => _dot(_opacityFor(i), i)),
      ),
    );
  }

  Widget _dot(double opacity, int index) {
    return Padding(
      padding: EdgeInsets.only(
        right: index < 2 ? widget.spacing : 0,
      ),
      child: Opacity(
        opacity: opacity,
        child: Container(
          width: widget.dotSize,
          height: widget.dotSize,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
