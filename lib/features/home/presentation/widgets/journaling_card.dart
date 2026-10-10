import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/cozy_colors.dart';
import '../../../../core/widgets/illustrated_card.dart';
import '../../../../gen/assets.gen.dart';

class JournalingCard extends StatelessWidget {
  const JournalingCard({super.key, required this.affirmation});
  final Widget affirmation;

  @override
  Widget build(BuildContext context) {
    final background = context.cozyColors.journalingBg;
    return Container(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          IllustratedCard(
            title: 'Journaling',
            description: 'Make space for your thoughts. Your journal is yours.',
            illustration: SvgPicture.asset(Assets.svg.journaling),
            illustrationSize: 80,
            backgroundColor: background,
            actionLabel: 'Start Writing',
            onAction: () => context.push(AppRouter.journal),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: affirmation,
          ),
        ],
      ),
    );
  }
}
