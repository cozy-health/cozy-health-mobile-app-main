import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cozy_health/core/widgets/startup_cover.dart';
import 'package:cozy_health/core/theme/app_theme.dart';

void main() {
  Future<void> mount(
    WidgetTester tester,
    ValueNotifier<bool> ready, {
    bool reduced = false,
    VoidCallback? retry,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
          child: child!,
        ),
        home: StartupCover(
          child: Builder(
            builder: (context) {
              StartupCover.retryWith(context, retry ?? () {});
              return ValueListenableBuilder<bool>(
                valueListenable: ready,
                builder: (_, value, _) => StartupDestination(
                  ready: value,
                  child: const Scaffold(body: Text('Ready destination')),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets(
    'waits for ready content then shrinks and fades after its first frame',
    (tester) async {
      final ready = ValueNotifier(false);
      addTearDown(ready.dispose);
      await mount(tester, ready);
      expect(find.byKey(const ValueKey('startup-cover')), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      expect(find.byKey(const ValueKey('startup-cover')), findsOneWidget);
      ready.value = true;
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 140));
      final scale = tester.widget<ScaleTransition>(
        find.byKey(const ValueKey('startup-icon-scale')),
      );
      expect(scale.scale.value, lessThan(1));
      expect(scale.scale.value, greaterThan(.92));
      await tester.pump(const Duration(milliseconds: 160));
      expect(find.byKey(const ValueKey('startup-cover')), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('fast preparation retains icon for the minimum presentation', (
    tester,
  ) async {
    final ready = ValueNotifier(true);
    addTearDown(ready.dispose);
    await mount(tester, ready);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byKey(const ValueKey('startup-cover')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 60));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const ValueKey('startup-cover')), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('reduced motion reveals the prepared destination immediately', (
    tester,
  ) async {
    final ready = ValueNotifier(true);
    addTearDown(ready.dispose);
    await mount(tester, ready, reduced: true);
    await tester.pump();
    expect(find.byKey(const ValueKey('startup-cover')), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('timeout offers retry and keeps the destination protected', (
    tester,
  ) async {
    final ready = ValueNotifier(false);
    addTearDown(ready.dispose);
    var retries = 0;
    await mount(
      tester,
      ready,
      reduced: true,
      retry: () {
        retries++;
        ready.value = true;
      },
    );
    await tester.pump(const Duration(seconds: 8));
    expect(find.text('Try again'), findsOneWidget);
    expect(find.byKey(const ValueKey('startup-cover')), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pump();
    await tester.pump();
    expect(retries, 1);
    expect(find.byKey(const ValueKey('startup-cover')), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('disposing during preparation cancels startup timers', (
    tester,
  ) async {
    final ready = ValueNotifier(false);
    addTearDown(ready.dispose);
    await mount(tester, ready);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 10));
    expect(tester.takeException(), isNull);
  });

  testWidgets('background interruption preserves the minimum presentation', (
    tester,
  ) async {
    final ready = ValueNotifier(true);
    addTearDown(ready.dispose);
    await mount(tester, ready);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(milliseconds: 50));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(milliseconds: 50));
    final scale = tester.widget<ScaleTransition>(
      find.byKey(const ValueKey('startup-icon-scale')),
    );
    expect(scale.scale.value, 1);
    await tester.pump(const Duration(milliseconds: 160));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    final pausedScale = scale.scale.value;
    await tester.pump(const Duration(seconds: 1));
    expect(scale.scale.value, pausedScale);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const ValueKey('startup-cover')), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
