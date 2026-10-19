import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/user_preferences.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/services/local_db_service.dart';
import '../../../../core/services/onboarding_service.dart';
import '../../../../core/services/personalization_service.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../data/onboarding_data.dart';
import 'steps/focus_areas_step.dart';
import 'steps/challenges_step.dart';

const _blue = Color(0xFF0066FF);

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _focus = <String>{};
  final _challenges = <String>{};
  final _pages = PageController();
  int _step = 0;
  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  bool _skipped = false;
  bool _saving = false;

  void _toggle(Set<String> values, String value) => setState(() {
    if (!values.add(value)) values.remove(value);
  });

  void _goTo(int step) {
    if (_saving) return;
    if (step < 3 && _step < 3 && _pages.hasClients) {
      if (MediaQuery.of(context).disableAnimations) {
        _pages.jumpToPage(step);
      } else {
        _pages.animateToPage(
          step,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    } else {
      setState(() => _step = step);
      if (step < 3) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _pages.hasClients) _pages.jumpToPage(step);
        });
      }
    }
  }

  void _skip() {
    if (_saving) return;
    if (_step < 3) {
      _goTo(3);
    } else {
      setState(() {
        _skipped = true;
        if (_step == 3) _focus.clear();
        if (_step == 4) _challenges.clear();
      });
      if (_step == 4) {
        _finish(AppRouter.welcome);
      } else {
        _goTo(4);
      }
    }
  }

  Future<void> _finish(String route) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final existing = await LocalDbService().getUserPreferences();
      await LocalDbService().saveUserPreferences(
        UserPreferences(
          focusAreas: _focus.toList(),
          currentChallenges: _challenges.toList(),
          checkInFrequency: existing?.checkInFrequency ?? 'A few times a week',
          attribution: existing?.attribution,
          completedAt: DateTime.now().toUtc(),
          skipped: _skipped || (_focus.isEmpty && _challenges.isEmpty),
        ),
      );
      await PersonalizationService().markComplete();
      await OnboardingService().markOnboardingComplete();
      if (mounted) context.go(route);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppSnackbar.show(
        context,
        AppSnackbar.fromLegacy(
          content: const Text(
            "We couldn't save your choices. Please try again.",
          ),
        ),
      );
    }
  }

  Widget _progress(int index, int count, String label) => Semantics(
    label: label,
    value: '${index + 1} of $count',
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        count,
        (i) => Container(
          width: count == 3 ? 78 : 100,
          height: 4,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: i == index ? _blue : const Color(0xFFCEDFF9),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    ),
  );

  Widget _button(String label, VoidCallback? onPressed, {bool arrow = false}) =>
      OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: _blue,
          minimumSize: const Size(double.infinity, 48),
          side: const BorderSide(color: _blue),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        child: _saving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(child: Text(label, textAlign: TextAlign.center)),
                  if (arrow) ...[
                    const SizedBox(width: 12),
                    const Icon(Icons.arrow_forward, size: 20),
                  ],
                ],
              ),
      );

  Widget _intro(int index) {
    final page = OnboardingData.pages[index];
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        final illustrationHeight = (height * .38).clamp(120.0, 312.0);
        return SingleChildScrollView(
          key: ValueKey(index),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: height),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 23),
              child: Column(
                children: [
                  SizedBox(height: height * .035),
                  SizedBox(
                    height: illustrationHeight,
                    width: 335,
                    child: Image.asset(
                      page.asset,
                      fit: BoxFit.contain,
                      excludeFromSemantics: true,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _progress(index, 3, 'Introduction progress'),
                  const SizedBox(height: 24),
                  Text(
                    page.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    page.description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                  SizedBox(height: 24),
                  _button(
                    index == 2 ? 'Continue' : 'Next',
                    () => _goTo(index + 1),
                    arrow: index < 2,
                  ),
                  if (index < 2) ...[
                    const SizedBox(height: 12),
                    TextButton(onPressed: _skip, child: const Text('Skip')),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _preferences() => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      key: ValueKey(_step),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: IntrinsicHeight(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(23, 8, 23, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Back',
                      onPressed: _saving ? null : () => _goTo(_step - 1),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    Expanded(
                      child: _step < 5
                          ? Text(
                              'Your preferences · ${_step - 2} of 2',
                              textAlign: TextAlign.center,
                            )
                          : const SizedBox.shrink(),
                    ),
                    TextButton(
                      onPressed: _saving ? null : _skip,
                      child: const Text('Skip'),
                    ),
                  ],
                ),
                if (_step < 5) ...[
                  const SizedBox(height: 20),
                  _progress(_step - 3, 2, 'Preference progress'),
                ],
                const SizedBox(height: 32),
                switch (_step) {
                  3 => FocusAreasStep(
                    selected: _focus,
                    onToggle: (v) => _toggle(_focus, v),
                  ),
                  4 => ChallengesStep(
                    selected: _challenges,
                    onToggle: (v) => _toggle(_challenges, v),
                  ),
                  _ => const SizedBox.shrink(),
                },
                const Spacer(),
                const SizedBox(height: 20),
                _button(
                  'Continue',
                  _saving
                      ? null
                      : () {
                          if (_step == 4) {
                            _finish(AppRouter.welcome);
                          } else {
                            _goTo(_step + 1);
                          }
                        },
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == 0 && !_saving,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _step > 0) _goTo(_step - 1);
      },
      child: Scaffold(
        body: SafeArea(
          child: _step < 3
              ? PageView.builder(
                  controller: _pages,
                  itemCount: OnboardingData.pages.length,
                  onPageChanged: (index) => setState(() => _step = index),
                  itemBuilder: (context, index) => _intro(index),
                )
              : _preferences(),
        ),
      ),
    );
  }
}
