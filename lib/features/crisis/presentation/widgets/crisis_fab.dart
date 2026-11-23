import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/widgets/wellness_sheet.dart';

class CrisisFab extends StatefulWidget {
  const CrisisFab({super.key});

  @override
  State<CrisisFab> createState() => _CrisisFabState();
}

class _CrisisFabState extends State<CrisisFab> {
  void _showQuickCalm() {
    AppHaptics.medium();
    final router = GoRouter.of(context);
    showWellnessSheet<void>(
      context: context,
      builder: (sheetContext) {
        void open(String route) {
          Navigator.of(sheetContext).pop();
          router.push(route);
        }

        return WellnessSheet(
          title: 'I need a moment.',
          children: [
            WellnessSheetOption(
              icon: Icons.air_rounded,
              label: 'Breathe',
              onPressed: () => open(AppRouter.breathing),
            ),
            WellnessSheetOption(
              icon: Icons.spa_outlined,
              label: 'Ground',
              onPressed: () => open(AppRouter.grounding),
            ),
            WellnessSheetOption(
              icon: Icons.phone_outlined,
              label: 'Contact next of kin',
              onPressed: () => open(AppRouter.crisisContact),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Contact next of kin',
      hint: 'Tap to contact your next of kin',
      onTap: () => context.push(AppRouter.crisisContact),
      onLongPress: _showQuickCalm,
      child: ExcludeSemantics(
        child: Tooltip(
          message: 'Contact next of kin',
          triggerMode: TooltipTriggerMode.manual,
          child: GestureDetector(
            onLongPress: _showQuickCalm,
            child: FloatingActionButton(
              heroTag: 'crisis-support',
              elevation: 2,
              highlightElevation: 4,
              backgroundColor: AppColors.crisisPrimary,
              foregroundColor: AppColors.crisisTextOnDark,
              shape: const CircleBorder(),
              onPressed: () => context.push(AppRouter.crisisContact),
              child: const Icon(Icons.favorite_border),
            ),
          ),
        ),
      ),
    );
  }
}
