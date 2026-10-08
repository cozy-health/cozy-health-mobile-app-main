import 'package:cozy_health/core/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/user_preferences.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/services/local_db_service.dart';
import '../../../../core/services/onboarding_service.dart';
import '../../../../core/services/personalization_service.dart';
import '../../../../core/widgets/app_button.dart';
import 'steps/welcome_step.dart';
import 'steps/focus_areas_step.dart';
import 'steps/challenges_step.dart';
import 'steps/frequency_step.dart';
import 'steps/attribution_step.dart';
import 'steps/preview_step.dart';
import 'steps/step_widgets.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final _pages = PageController();
  late final _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  late final _fade = CurvedAnimation(
    parent: _entrance,
    curve: Curves.easeOutCubic,
  );
  final _focus = <String>{};
  final _challenges = <String>{};
  String _frequency = 'A few times a week';
  String? _attribution;
  int _step = 0;
  bool _skipped = false;
  bool _moving = false;
  bool _saving = false;
  bool get _reduceMotion =>
      MediaQuery.of(context).disableAnimations ||
      MediaQuery.of(context).accessibleNavigation;
  bool get _canContinue =>
      !_moving &&
      !_saving &&
      (_step != 1 || _focus.isNotEmpty) &&
      (_step != 2 || _challenges.isNotEmpty);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reduceMotion) {
      _entrance.value = 1;
    } else {
      _entrance.forward();
    }
  }

  @override
  void dispose() {
    _pages.dispose();
    _fade.dispose();
    _entrance.dispose();
    super.dispose();
  }

  void _toggle(Set<String> values, String value) => setState(() {
    if (!values.add(value)) values.remove(value);
  });

  Future<void> _goTo(int step) async {
    if (_moving || _saving) return;
    setState(() => _moving = true);
    if (_reduceMotion) {
      _pages.jumpToPage(step);
    } else {
      await _pages.animateToPage(
        step,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
      );
    }
    if (mounted) setState(() => _moving = false);
  }

  void _changed(int step) {
    setState(() => _step = step);
    if (_reduceMotion) {
      _entrance.value = 1;
    } else {
      _entrance.forward(from: 0);
    }
  }

  Future<void> _skip() async {
    if (_moving || _saving) return;
    setState(() {
      _skipped = true;
      if (_step == 1) _focus.clear();
      if (_step == 2) _challenges.clear();
      if (_step == 4) _attribution = null;
    });
    if (_step == 6) {
      await _finish(AppRouter.welcome);
    } else {
      await _goTo(_step + 1);
    }
  }

  Future<void> _finish(String route) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await LocalDbService().saveUserPreferences(
        UserPreferences(
          focusAreas: _focus.toList(),
          currentChallenges: _challenges.toList(),
          checkInFrequency: _frequency,
          attribution: _attribution,
          completedAt: DateTime.now().toUtc(),
          skipped: _skipped,
        ),
      );
      await OnboardingService().markOnboardingComplete();
      await PersonalizationService().markComplete();
      if (mounted) context.go(route);
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        AppSnackbar.show(
          context,
          AppSnackbar.fromLegacy(
            content: Text("We couldn't save your choices. Please try again."),
          ),
        );
      }
    }
  }

  Widget _page(int index) => switch (index) {
    0 => const WelcomeStep(),
    1 => FocusAreasStep(selected: _focus, onToggle: (v) => _toggle(_focus, v)),
    2 => ChallengesStep(
      selected: _challenges,
      onToggle: (v) => _toggle(_challenges, v),
    ),
    3 => FrequencyStep(
      selected: _frequency,
      onChanged: (v) => setState(() => _frequency = v),
    ),
    4 => AttributionStep(
      selected: _attribution ?? 'Prefer not to say',
      onChanged: (v) =>
          setState(() => _attribution = v == 'Prefer not to say' ? null : v),
    ),
    5 => PreviewStep(
      focusAreas: _focus,
      challenges: _challenges,
      frequency: _frequency,
      onEdit: () => _goTo(1),
    ),
    _ => const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StepHeading(
          title: 'Make this space yours.',
          subtitle:
              'Create an account to keep your check-ins and thoughts together.',
        ),
        Icon(Icons.person_outline, size: 120),
      ],
    ),
  };

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _step == 0 && !_saving,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop && _step > 0) _goTo(_step - 1);
    },
    child: Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            children: [
              Row(
                children: [
                  if (_step > 0)
                    IconButton(
                      tooltip: 'Back',
                      onPressed: _moving || _saving
                          ? null
                          : () => _goTo(_step - 1),
                      icon: const Icon(Icons.arrow_back),
                    ),
                  Expanded(
                    child: Text(
                      'Step ${_step + 1} of 7',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  // Frequency has a default and intentionally has no Skip control.
                  if (_step != 3)
                    TextButton(
                      onPressed: _moving || _saving ? null : _skip,
                      child: const Text('Skip'),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Semantics(
                label: 'Onboarding progress',
                value: 'Step ${_step + 1} of 7',
                child: LinearProgressIndicator(value: (_step + 1) / 7),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: PageView.builder(
                  controller: _pages,
                  itemCount: 7,
                  onPageChanged: _changed,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) => SingleChildScrollView(
                    child: FadeTransition(opacity: _fade, child: _page(index)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              AppButton(
                text: _step == 5
                    ? 'Looks good'
                    : _step == 6
                    ? 'Create account'
                    : 'Continue',
                isLoading: _saving,
                onPressed: _canContinue
                    ? () {
                        if (_step == 6) {
                          _finish(AppRouter.createAccount);
                        } else {
                          _goTo(_step + 1);
                        }
                      }
                    : null,
              ),
              if (_step == 6)
                TextButton(
                  onPressed: _saving ? null : () => _finish(AppRouter.login),
                  child: const Text('I already have an account'),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
