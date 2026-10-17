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
const _ink = Color(0xFF292D39);

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _focus = <String>{};
  final _challenges = <String>{};
  int _step = 0;
  bool _skipped = false;
  bool _saving = false;

  void _toggle(Set<String> values, String value) => setState(() {
    if (!values.add(value)) values.remove(value);
  });

  void _goTo(int step) {
    if (!_saving) setState(() => _step = step);
  }

  void _skip() {
    if (_saving) return;
    if (_step < 3) {
      _goTo(3);
    } else if (_step == 5) {
      _finish(AppRouter.welcome);
    } else {
      setState(() {
        _skipped = true;
        if (_step == 3) _focus.clear();
        if (_step == 4) _challenges.clear();
        _step++;
      });
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

  Widget _intro() {
    final page = OnboardingData.pages[_step];
    return LayoutBuilder(
      builder: (context, constraints) {
        // Preserve reference spacing; short screens and larger text can scroll.
        final height = constraints.maxHeight < 720
            ? 720.0
            : constraints.maxHeight;
        return SingleChildScrollView(
          key: ValueKey(_step),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: height),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 23),
              child: Column(
                children: [
                  SizedBox(height: height * .13),
                  SizedBox(
                    height: 312,
                    width: 335,
                    child: Image.asset(
                      page.asset,
                      fit: BoxFit.contain,
                      excludeFromSemantics: true,
                    ),
                  ),
                  const SizedBox(height: 59),
                  _progress(_step, 3, 'Introduction progress'),
                  const SizedBox(height: 36),
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
                  SizedBox(height: _step == 0 ? 50 : 26),
                  _button(
                    _step == 2 ? 'Continue' : 'Next',
                    () => _goTo(_step + 1),
                    arrow: _step < 2,
                  ),
                  if (_step < 2) ...[
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _skip,
                      child: const Text(
                        'Skip',
                        style: TextStyle(color: Color(0xFF555555)),
                      ),
                    ),
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
                  _ => const Column(
                    children: [
                      SizedBox(height: 28),
                      Icon(Icons.person_outline, color: _blue, size: 96),
                      SizedBox(height: 32),
                      Text(
                        'Make this space yours.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Create an account to keep your check-ins and thoughts together.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, height: 1.5),
                      ),
                    ],
                  ),
                },
                const Spacer(),
                const SizedBox(height: 20),
                _button(
                  _step == 5 ? 'Create account' : 'Continue',
                  _saving
                      ? null
                      : () {
                          if (_step == 5) {
                            _finish(AppRouter.createAccount);
                          } else {
                            _goTo(_step + 1);
                          }
                        },
                ),
                if (_step == 5)
                  TextButton(
                    onPressed: _saving ? null : () => _finish(AppRouter.login),
                    child: const Text('I already have an account'),
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
    final base = Theme.of(context);
    final theme = base.copyWith(
      scaffoldBackgroundColor: Colors.white,
      iconTheme: base.iconTheme.copyWith(color: _ink),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: _blue),
      ),
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: _blue,
            brightness: Brightness.light,
          ).copyWith(
            primary: _blue,
            onSurface: _ink,
            surface: Colors.white,
            primaryContainer: const Color(0xFFEDF4FF),
            outlineVariant: const Color(0xFFCEDFF9),
          ),
      textTheme: base.textTheme.apply(bodyColor: _ink, displayColor: _ink),
    );
    return Theme(
      data: theme,
      child: PopScope(
        canPop: _step == 0 && !_saving,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && _step > 0) _goTo(_step - 1);
        },
        child: Scaffold(
          body: SafeArea(child: _step < 3 ? _intro() : _preferences()),
        ),
      ),
    );
  }
}
