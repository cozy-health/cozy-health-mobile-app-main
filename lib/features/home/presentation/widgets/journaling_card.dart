import 'package:cozy_health/core/theme/app_surface.dart';
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
        Text(
          'Journaling',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your thoughts deserve a safe space. Write freely, reflect on your journey.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        OutlinedButton(
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
      width: 132,
      height: 132,
      excludeFromSemantics: true,
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: AppSurface.border(context),
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
              art,
              const SizedBox(width: 16),
              Expanded(child: copy),
            ],
          );
        },
      ),
    );
  }
}
