import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../../../../core/services/local_db_service.dart';

class FeatureTourTargets {
  final hero = GlobalKey();
  final journal = GlobalKey();
  final assistant = GlobalKey();
  final crisis = GlobalKey();
}

/// Offers a tour once the loaded Home and its navigation targets are laid out.
class FeatureTour extends StatefulWidget {
  const FeatureTour({super.key, required this.child, this.targets});
  final Widget child;
  final FeatureTourTargets? targets;
  @override
  State<FeatureTour> createState() => _FeatureTourState();
}

class _FeatureTourState extends State<FeatureTour> {
  TutorialCoachMark? _tour;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    if (widget.targets != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _offer());
    }
  }

  Future<void> _offer() async {
    try {
      final settings = await LocalDbService().settingsBox();
      if (!mounted ||
          settings.get('has_seen_tour', defaultValue: false) == true) {
        return;
      }
      if ([
        widget.targets!.hero,
        widget.targets!.journal,
        widget.targets!.assistant,
        widget.targets!.crisis,
      ].any((key) => key.currentContext == null)) {
        return;
      }
      final accepted = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Want a quick look around?'),
          content: const Text(
            'A short tour can help you find your way. You can skip it anytime.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Skip'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Show me'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (accepted == true) {
        _start();
      } else {
        await _complete();
      }
    } catch (_) {
      // A tour should never prevent the user from accessing Home.
    }
  }

  Future<void> _complete() async {
    if (_closing) return;
    _closing = true;
    try {
      await (await LocalDbService().settingsBox()).put('has_seen_tour', true);
    } catch (_) {
      _closing = false;
    }
  }

  void _start() {
    final targets = widget.targets!;
    final reduceMotion =
        MediaQuery.of(context).disableAnimations ||
        MediaQuery.of(context).accessibleNavigation;
    final heroBox =
        targets.hero.currentContext!.findRenderObject() as RenderBox;
    final heroBottom =
        heroBox.localToGlobal(Offset.zero).dy + heroBox.size.height;
    final compactHero = MediaQuery.sizeOf(context).height - heroBottom < 360;
    final steps = [
      (
        targets.hero,
        "Log how you're feeling",
        'Your check-in starts here.',
        ContentAlign.bottom,
      ),
      (
        targets.journal,
        'Keep a private journal',
        'Tap +, then Journal to make room for your thoughts.',
        ContentAlign.top,
      ),
      (
        targets.assistant,
        'Talk to your assistant',
        'Find a space to talk in the Assistant tab.',
        ContentAlign.top,
      ),
      (
        targets.crisis,
        'Get help when you need it',
        'The heart button opens support and grounding resources.',
        ContentAlign.top,
      ),
      (
        targets.crisis,
        "You're all set",
        'Explore at your own pace.',
        ContentAlign.top,
      ),
    ];
    _tour = TutorialCoachMark(
      targets: [
        for (var i = 0; i < steps.length; i++)
          TargetFocus(
            identify: 'feature-$i',
            keyTarget: steps[i].$1,
            shape: ShapeLightFocus.RRect,
            radius: 16,
            enableOverlayTab: false,
            enableTargetTab: false,
            contents: [
              TargetContent(
                align: i == 0 && !compactHero
                    ? ContentAlign.bottom
                    : ContentAlign.custom,
                customPosition: CustomTargetContentPosition(
                  top: i == 0 ? null : 24,
                  bottom: i == 0 ? 24 : null,
                  left: 12,
                  right: 12,
                ),
                builder: (context, controller) => TweenAnimationBuilder<double>(
                  key: ValueKey(i),
                  tween: Tween(begin: reduceMotion ? 1 : 0, end: 1),
                  duration: reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 700),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) => Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, (1 - value) * 8),
                      child: child,
                    ),
                  ),
                  child: Card(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.sizeOf(context).height * .65,
                      ),
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text('Tour ${i + 1} of 5'),
                              const SizedBox(height: 12),
                              Semantics(
                                liveRegion: true,
                                header: true,
                                child: Text(
                                  steps[i].$2,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(steps[i].$3),
                              const SizedBox(height: 24),
                              FilledButton(
                                onPressed: controller.next,
                                child: Text(
                                  i == steps.length - 1 ? 'Done' : 'Next',
                                ),
                              ),
                              TextButton(
                                onPressed: controller.skip,
                                child: const Text('Skip tour'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
      ],
      colorShadow: Theme.of(context).colorScheme.scrim,
      opacityShadow: .65,
      hideSkip: true,
      pulseEnable: false,
      // The package hardcodes its own easing. Animate our cards with easeOutCubic
      // instead, and keep focus changes instantaneous (also safe for reduced motion).
      focusAnimationDuration: Duration.zero,
      unFocusAnimationDuration: Duration.zero,
      backgroundSemanticLabel: 'Feature tour',
      onSkip: () {
        unawaited(_complete());
        return true;
      },
      onFinish: () => unawaited(_complete()),
    )..show(context: context, rootOverlay: true);
  }

  @override
  void dispose() {
    _tour?.removeOverlayEntry();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
