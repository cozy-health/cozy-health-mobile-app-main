import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class TypingIndicatorBubble extends StatefulWidget {
  const TypingIndicatorBubble({super.key});

  @override
  State<TypingIndicatorBubble> createState() => TypingIndicatorBubbleState();
}

class TypingIndicatorBubbleState extends State<TypingIndicatorBubble>
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

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) {
      return _dotBubble([1, 1, 1]);
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return _dotBubble(
          List.generate(3, (index) {
            final phase = (_controller.value + index * .16) % 1;
            return .3 + (phase < .5 ? phase * 1.4 : (1 - phase) * 1.4);
          }),
        );
      },
    );
  }

  Widget _dotBubble(List<double> opacities) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.surfaceElevatedDark
              : AppColors.surfaceElevatedLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            3,
            (index) => Opacity(
              opacity: opacities[index].clamp(.3, 1),
              child: Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.textMutedDark
                      : AppColors.textMutedLight,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
