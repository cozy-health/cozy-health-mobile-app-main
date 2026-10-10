import 'package:cozy_health/core/theme/app_theme.dart';
import 'package:cozy_health/core/theme/appearance_preferences.dart';
import 'package:cozy_health/core/theme/cozy_colors.dart';
import 'package:cozy_health/core/utils/motion.dart';
import 'package:cozy_health/core/widgets/skeleton_loader.dart';
import 'package:cozy_health/core/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/local_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(installLocalTestFonts);
  tearDown(resetLocalTestFonts);

  for (final (device, app, expected) in [
    (1.0, 1.0, 1.0),
    (1.0, 1.5, 1.5),
    (1.3, 1.0, 1.3),
    (1.3, 1.5, 1.95),
    (1.5, 1.5, 2.0),
    (1.0, .8, .8),
    (3.0, 1.0, 3.0),
  ]) {
    test('device $device times app $app produces $expected', () {
      final result = appearanceMediaQuery(
        MediaQueryData(textScaler: TextScaler.linear(device)),
        textMultiplier: app,
      );
      expect(result.textScaler.scale(20), closeTo(20 * expected, .001));
    });
  }

  test('nonlinear device scaling is preserved per font size', () {
    final scaler = AppearanceTextScaler(const _NonlinearScaler(), 1.2);
    expect(scaler.scale(10), closeTo(18, .001));
    expect(scaler.scale(30), closeTo(39.6, .001));
  });

  test('app preferences never disable device accessibility flags', () {
    final data = appearanceMediaQuery(
      const MediaQueryData(
        highContrast: true,
        boldText: true,
        disableAnimations: true,
      ),
    );
    expect(data.highContrast, isTrue);
    expect(data.boldText, isTrue);
    expect(data.disableAnimations, isTrue);
    expect(data.accessibleNavigation, isTrue);
    expect(
      appearanceMediaQuery(
        const MediaQueryData(accessibleNavigation: true),
      ).disableAnimations,
      isTrue,
    );
    expect(
      appearanceMediaQuery(
        const MediaQueryData(),
        reduceMotion: true,
      ).disableAnimations,
      isTrue,
    );
    expect(
      appearanceMediaQuery(const MediaQueryData()).disableAnimations,
      isFalse,
    );
  });

  for (final dark in [false, true]) {
    test(
      'high contrast palette and accent contrast in ${dark ? 'dark' : 'light'}',
      () {
        final normal = dark ? AppTheme.dark : AppTheme.light;
        for (final accent in [
          Colors.blue,
          Colors.purple,
          Colors.pink,
          Colors.orange,
          Colors.teal,
        ]) {
          final theme = AppTheme.highContrast(
            normal.copyWith(
              colorScheme: normal.colorScheme.copyWith(primary: accent),
            ),
          );
          final surface = dark ? Colors.black : Colors.white;
          final foreground = dark ? Colors.white : Colors.black;
          expect(theme.colorScheme.surface, surface);
          expect(theme.colorScheme.onSurface, foreground);
          expect(theme.colorScheme.outline, foreground);
          expect(theme.dividerTheme.thickness, 2);
          expect(theme.dialogTheme.backgroundColor, surface);
          expect(theme.bottomSheetTheme.backgroundColor, surface);
          expect(theme.disabledColor.a, closeTo(.6, .01));
          expect(
            _contrast(theme.colorScheme.primary, surface),
            greaterThanOrEqualTo(4.5),
          );
          expect(
            _contrast(theme.colorScheme.primary, theme.colorScheme.onPrimary),
            greaterThanOrEqualTo(4.5),
          );
          expect(theme.extension<CozyColors>()!.calendarBg, surface);
        }
        expect(
          normal.colorScheme.onSurface,
          isNot(dark ? Colors.white : Colors.black),
        );
      },
    );
  }

  testWidgets('saved motion preference stops and restarts skeleton animation', (
    tester,
  ) async {
    Future<void> pump(bool reduce) => tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: appearanceMediaQuery(
            const MediaQueryData(),
            reduceMotion: reduce,
          ),
          child: const Scaffold(body: SkeletonLoader()),
        ),
      ),
    );
    await pump(true);
    final opacity = tester
        .widget<FadeTransition>(find.byType(FadeTransition).last)
        .opacity;
    expect(opacity.value, .4);
    await tester.pump(const Duration(milliseconds: 500));
    expect(opacity.value, .4);
    await pump(false);
    await tester.pump(const Duration(milliseconds: 500));
    expect(opacity.value, isNot(.4));
    await pump(true);
    expect(opacity.value, .4);
  });

  testWidgets('shared snackbar content has zero animation when reduced', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: appearanceMediaQuery(
            const MediaQueryData(),
            reduceMotion: true,
          ),
          child: Scaffold(body: AppSnackbar.info('Saved').content),
        ),
      ),
    );
    final tween = tester.widget<TweenAnimationBuilder<double>>(
      find.byType(TweenAnimationBuilder<double>),
    );
    expect(tween.duration, Duration.zero);
  });

  testWidgets('reduced page transitions return content immediately', (
    tester,
  ) async {
    late BuildContext pageContext;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            pageContext = context;
            return const SizedBox();
          },
        ),
      ),
    );
    final theme = motionTheme(AppTheme.light, true);
    const content = Text('Destination');
    final builder =
        theme.pageTransitionsTheme.builders[TargetPlatform.android]!;
    expect(
      builder.buildTransitions<void>(
        MaterialPageRoute<void>(builder: (_) => content),
        pageContext,
        const AlwaysStoppedAnimation(0),
        const AlwaysStoppedAnimation(0),
        content,
      ),
      same(content),
    );
    expect(
      motionTheme(
        AppTheme.light,
        false,
      ).pageTransitionsTheme.builders[TargetPlatform.android],
      isNot(isA<NoMotionPageTransitionsBuilder>()),
    );
  });

  for (final kind in ['dialog', 'sheet', 'menu', 'tooltip', 'snackbar']) {
    testWidgets('open $kind follows system theme and high contrast changes', (
      tester,
    ) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      final contrast = ValueNotifier(false);
      addTearDown(contrast.dispose);
      late BuildContext triggerContext;
      final tooltipKey = GlobalKey<TooltipState>();
      ThemeData? overlayTheme;
      Widget probe(BuildContext context) {
        overlayTheme = Theme.of(context);
        return const Text('Overlay content');
      }

      await tester.pumpWidget(
        ValueListenableBuilder<bool>(
          valueListenable: contrast,
          builder: (_, high, _) => MaterialApp(
            themeMode: ThemeMode.system,
            themeAnimationDuration: Duration.zero,
            theme: high
                ? AppTheme.highContrast(AppTheme.light)
                : AppTheme.light,
            darkTheme: high
                ? AppTheme.highContrast(AppTheme.dark)
                : AppTheme.dark,
            builder: (context, child) =>
                LiveAppearanceTheme(theme: Theme.of(context), child: child!),
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  triggerContext = context;
                  return Tooltip(
                    key: tooltipKey,
                    showDuration: const Duration(seconds: 20),
                    richMessage: WidgetSpan(child: Builder(builder: probe)),
                    child: const Text('Page'),
                  );
                },
              ),
            ),
          ),
        ),
      );
      if (kind == 'dialog') {
        showDialog<void>(
          context: triggerContext,
          builder: (context) => AlertDialog(content: probe(context)),
        );
      } else if (kind == 'sheet') {
        showModalBottomSheet<void>(context: triggerContext, builder: probe);
      } else if (kind == 'menu') {
        showMenu<void>(
          context: triggerContext,
          position: const RelativeRect.fromLTRB(0, 0, 100, 100),
          items: [PopupMenuItem<void>(child: Builder(builder: probe))],
        );
      } else if (kind == 'tooltip') {
        tooltipKey.currentState!.ensureTooltipVisible();
      } else {
        ScaffoldMessenger.of(
          triggerContext,
        ).showSnackBar(SnackBar(content: Builder(builder: probe)));
      }
      await tester.pumpAndSettle();
      expect(overlayTheme!.brightness, Brightness.light);
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      await tester.pumpAndSettle();
      expect(find.text('Overlay content'), findsOneWidget);
      expect(overlayTheme!.brightness, Brightness.dark);
      contrast.value = true;
      await tester.pumpAndSettle();
      expect(overlayTheme!.colorScheme.surface, Colors.black);
      expect(overlayTheme!.colorScheme.onSurface, Colors.white);
      contrast.value = false;
      await tester.pumpAndSettle();
      expect(
        overlayTheme!.colorScheme.surface,
        AppTheme.dark.colorScheme.surface,
      );
    });
  }
}

double _contrast(Color a, Color b) {
  final first = a.computeLuminance();
  final second = b.computeLuminance();
  return first > second
      ? (first + .05) / (second + .05)
      : (second + .05) / (first + .05);
}

class _NonlinearScaler extends TextScaler {
  const _NonlinearScaler();
  @override
  double scale(double fontSize) => fontSize * (fontSize < 20 ? 1.5 : 1.1);
  @override
  double get textScaleFactor => 1.5;
}
