import 'package:cozy_health/core/theme/app_theme.dart';
import 'package:cozy_health/core/widgets/app_pressable.dart';
import 'package:cozy_health/core/widgets/app_snackbar.dart';
import 'package:cozy_health/core/widgets/custom_text_field.dart';
import 'package:cozy_health/core/widgets/wellness_sheet.dart';
import 'package:cozy_health/features/community/data/community_moderation_state.dart';
import 'package:cozy_health/features/community/presentation/screens/community_hub_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AppTheme sets cupertinoOverrideTheme and showDragHandle', (
    tester,
  ) async {
    expect(AppTheme.light.cupertinoOverrideTheme?.primaryColor, isNotNull);
    expect(AppTheme.dark.cupertinoOverrideTheme?.primaryColor, isNotNull);
    expect(AppTheme.light.bottomSheetTheme.showDragHandle, isTrue);
    expect(AppTheme.dark.bottomSheetTheme.showDragHandle, isTrue);
  });

  testWidgets('AppPressable applies easeOutCubic scale and iOS press opacity', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light.copyWith(platform: TargetPlatform.iOS),
        home: Scaffold(
          body: Center(
            child: AppPressable(onPressed: () {}, child: const Text('Tap me')),
          ),
        ),
      ),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Tap me')),
    );
    await tester.pump();
    final scale = tester.widget<AnimatedScale>(find.byType(AnimatedScale));
    final opacity = tester.widget<AnimatedOpacity>(
      find.byType(AnimatedOpacity),
    );
    expect(scale.curve, Curves.easeOutCubic);
    expect(scale.scale, lessThan(1.0));
    expect(opacity.opacity, lessThan(1.0));
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets(
    'confirmWellnessAction renders CupertinoAlertDialog on iOS',
    (tester) async {
      bool? confirmed;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light.copyWith(platform: TargetPlatform.iOS),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  confirmed = await confirmWellnessAction(
                    context,
                    title: 'Log out?',
                    message: 'Confirm sign out.',
                    action: 'Log out',
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.byType(CupertinoAlertDialog), findsOneWidget);
      await tester.tap(find.text('Log out'));
      await tester.pumpAndSettle();
      expect(confirmed, isTrue);
    },
  );

  testWidgets(
    'AppSnackbar keeps offline sync notice non-blocking and swipe-dismissible',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => AppSnackbar.show(
                  context,
                  AppSnackbar.success('Saved locally — will sync when online'),
                ),
                child: const Text('Notify'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Notify'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      expect(find.byKey(const Key('app-top-notice')), findsOneWidget);
      await tester.fling(
        find.byKey(const Key('app-top-notice')),
        const Offset(0, -300),
        1000,
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('app-top-notice')), findsNothing);
    },
  );

  testWidgets('CustomTextField exposes accessible password toggle and hints', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: CustomTextField(
            hintText: 'Password',
            isPassword: true,
            textInputAction: TextInputAction.done,
          ),
        ),
      ),
    );
    expect(find.byTooltip('Show password'), findsOneWidget);
    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();
    expect(find.byTooltip('Hide password'), findsOneWidget);
  });

  testWidgets('CommunityHubScreen hides moderation button unless restricted', (
    tester,
  ) async {
    CommunityModerationState.instance.data = null;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const CommunityHubScreen(posts: []),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Moderation decisions and appeals'), findsNothing);
    expect(find.byType(ListView), findsOneWidget);
  });
}
