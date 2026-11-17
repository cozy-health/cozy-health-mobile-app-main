import 'package:flutter/material.dart';

class ReadingProgressBar extends StatelessWidget {
  final ScrollController scrollController;

  const ReadingProgressBar({super.key, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: scrollController,
      builder: (context, child) {
        double progress = 0.0;
        if (scrollController.hasClients) {
          final maxScroll = scrollController.position.maxScrollExtent;
          final currentScroll = scrollController.position.pixels;
          if (maxScroll > 0) {
            progress = (currentScroll / maxScroll).clamp(0.0, 1.0);
          }
        }

        return Container(
          height: 3,
          width: double.infinity,
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.4),
          alignment: Alignment.centerLeft,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Container(
                height: 3,
                width: constraints.maxWidth * progress,
                color: Theme.of(context).colorScheme.primary,
              );
            },
          ),
        );
      },
    );
  }
}
