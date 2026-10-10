import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/cozy_colors.dart';
import '../../../../gen/assets.gen.dart';

class JournalingCard extends StatelessWidget {
  const JournalingCard({super.key});

  @override
  Widget build(BuildContext context) {
    final background = context.cozyColors.journalingBg;
    final theme = Theme.of(context);
    final copy = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Journaling', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'Make space for your thoughts. Your journal is yours.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => context.push(AppRouter.journal),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: Text('Start Writing')),
              SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 18),
            ],
          ),
        ),
      ],
    );
    final art = SvgPicture.asset(
      Assets.svg.journaling,
      width: 80,
      height: 80,
      excludeFromSemantics: true,
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 280 ||
              MediaQuery.textScalerOf(context).scale(14) > 20) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                copy,
                const SizedBox(height: 12),
                Align(alignment: Alignment.centerRight, child: art),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: copy),
              const SizedBox(width: 16),
              art,
            ],
          );
        },
      ),
    );
  }
}
