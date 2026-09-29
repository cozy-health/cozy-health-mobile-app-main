import 'package:flutter/material.dart';
import 'chat_shared_widgets.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../models/chat.dart';

class TypingIndicatorBubble extends StatefulWidget {
  const TypingIndicatorBubble();

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
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
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
                decoration: const BoxDecoration(
                  color: AppColors.textMuted,
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
