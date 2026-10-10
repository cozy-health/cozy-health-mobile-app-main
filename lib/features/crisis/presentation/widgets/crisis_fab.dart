import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';

class CrisisFab extends StatefulWidget {
  const CrisisFab({super.key});

  @override
  State<CrisisFab> createState() => _CrisisFabState();
}

class _CrisisFabState extends State<CrisisFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3000),
  );
  late final Animation<double> _pulse = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 0.0,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeInOut)),
      weight: 50,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.0,
        end: 0.0,
      ).chain(CurveTween(curve: Curves.easeInOut)),
      weight: 50,
    ),
  ]).animate(_controller);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final media = MediaQuery.of(context);
    if (media.disableAnimations ||
        media.accessibleNavigation ||
        !TickerMode.valuesOf(context).enabled) {
      _controller.stop();
      _controller.value = 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showQuickCalm() {
    final router = GoRouter.of(context);
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        void open(String route) {
          Navigator.of(sheetContext).pop();
          router.push(route);
        }

        return SafeArea(
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
                title: const Text('Call for help'),
                onTap: () => open(AppRouter.crisisHub),
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Close'),
                onTap: () => Navigator.of(sheetContext).pop(),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Crisis support',
      hint: 'Tap to open crisis resources',
      onTap: () => context.push(AppRouter.crisisHub),
      onLongPress: _showQuickCalm,
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (context, child) => Transform.scale(
            scale: 1 + .03 * _pulse.value,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.crisisPrimary.withValues(
                      alpha: .15 + .1 * _pulse.value,
                    ),
                    blurRadius: 4,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: child,
            ),
          ),
          child: GestureDetector(
            onLongPress: _showQuickCalm,
            child: FloatingActionButton.small(
              heroTag: 'crisis-support',
              tooltip: 'Crisis support',
              backgroundColor: AppColors.crisisPrimary,
              foregroundColor: AppColors.crisisTextOnDark,
              shape: const CircleBorder(),
              onPressed: () => context.push(AppRouter.crisisHub),
              child: const Icon(Icons.favorite_border),
            ),
          ),
        ),
      ),
    );
  }
}
