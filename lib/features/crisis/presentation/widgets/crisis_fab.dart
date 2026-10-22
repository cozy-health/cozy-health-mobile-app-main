import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/motion.dart';

class CrisisFab extends StatefulWidget {
  const CrisisFab({super.key});

  @override
  State<CrisisFab> createState() => _CrisisFabState();
}

class _CrisisFabState extends State<CrisisFab> {
  void _showQuickCalm() {
    final router = GoRouter.of(context);
    showModalBottomSheet<void>(
      context: context,
      sheetAnimationStyle: shouldReduceMotion(context)
          ? AnimationStyle.noAnimation
          : null,
      builder: (sheetContext) {
        void open(String route) {
          Navigator.of(sheetContext).pop();
          router.push(route);
        }

        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'I need a moment.',
                    style: Theme.of(sheetContext).textTheme.titleLarge,
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.air),
                  title: const Text('Breathe'),
                  onTap: () => open(AppRouter.breathing),
                ),
                ListTile(
                  leading: const Icon(Icons.spa_outlined),
                  title: const Text('Ground'),
                  onTap: () => open(AppRouter.grounding),
                ),
                ListTile(
                  leading: const Icon(Icons.phone_outlined),
                  title: const Text('Contact next of kin'),
                  onTap: () => open(AppRouter.crisisContact),
                ),
                ListTile(
                  leading: const Icon(Icons.close),
                  title: const Text('Close'),
                  onTap: () => Navigator.of(sheetContext).pop(),
                ),
              ],
            ),
          ),
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
        child: GestureDetector(
          onLongPress: _showQuickCalm,
          child: FloatingActionButton(
            heroTag: 'crisis-support',
            tooltip: 'Contact next of kin',
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
    );
  }
}
