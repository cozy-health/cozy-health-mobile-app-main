import 'package:cozy_health/features/home/presentation/widgets/quick_actions_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../support/local_fonts.dart';
import '../../support/surface_capture.dart';

void main() {
  setUpAll(installLocalTestFonts);
  tearDownAll(resetLocalTestFonts);

  Future<void> open(
    WidgetTester tester, {
    bool dark = false,
    bool narrow = false,
    ValueChanged<int>? onAction,
  }) async {
    tester.view.physicalSize = narrow
        ? const Size(320, 568)
        : const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          fontFamily: 'Outfit',
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0460D8),
            brightness: dark ? Brightness.dark : Brightness.light,
          ),
        ),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(narrow ? 2 : 1)),
          child: RepaintBoundary(key: surfaceCaptureKey, child: child!),
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () => showQuickActionsSheet(
                  context,
                  onMood: () => onAction?.call(0),
                  onJournal: () => onAction?.call(1),
                  onProvider: () => onAction?.call(2),
                  onBreathe: () => onAction?.call(3),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  for (final dark in [false, true]) {
    testWidgets('compact sheet renders all actions, dark=$dark', (
      tester,
    ) async {
      await open(tester, dark: dark);
      expect(find.text('Quick actions'), findsOneWidget);
      for (final title in ['Log mood', 'Journal', 'Provider', 'Breathe']) {
        expect(find.text(title).hitTestable(), findsOneWidget);
      }
      expect(find.text('Cancel'), findsNothing);
      expect(tester.takeException(), isNull);
      await captureSurface(tester, 'quick-actions-${dark ? 'dark' : 'light'}');
    });
  }

  testWidgets('large text on a narrow phone scrolls to the last action', (
    tester,
  ) async {
    int? selected;
    await open(tester, narrow: true, onAction: (value) => selected = value);
    expect(tester.takeException(), isNull);
    await captureSurface(tester, 'quick-actions-large-text');
    await tester.scrollUntilVisible(
      find.text('Breathe'),
      150,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Breathe'));
    await tester.pumpAndSettle();
    expect(selected, 3);
    expect(find.byType(QuickActionsSheet), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final entry in [
    'Log mood',
    'Journal',
    'Provider',
    'Breathe',
  ].asMap().entries) {
    testWidgets('${entry.value} dismisses before invoking its destination', (
      tester,
    ) async {
      int? selected;
      await open(
        tester,
        onAction: (value) {
          expect(find.byType(QuickActionsSheet).hitTestable(), findsNothing);
          selected = value;
        },
      );
      await tester.tap(find.text(entry.value));
      await tester.pumpAndSettle();
      expect(selected, entry.key);
      expect(find.byType(QuickActionsSheet), findsNothing);
    });
  }

  for (final method in ['close', 'outside', 'back', 'swipe']) {
    testWidgets('$method dismisses without selecting an action', (
      tester,
    ) async {
      int? selected;
      await open(tester, onAction: (value) => selected = value);
      switch (method) {
        case 'close':
          await tester.tap(find.byTooltip('Close quick actions'));
        case 'outside':
          await tester.tapAt(const Offset(10, 40));
        case 'back':
          await tester.binding.handlePopRoute();
        case 'swipe':
          await tester.fling(
            find.text('Quick actions'),
            const Offset(0, 600),
            1600,
          );
      }
      await tester.pumpAndSettle();
      expect(find.byType(QuickActionsSheet), findsNothing);
      expect(selected, isNull);
    });
  }

  testWidgets('each action exposes one descriptive accessible button', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await open(tester);
    expect(
      find.bySemanticsLabel('Log mood. Check in with how you feel'),
      findsOneWidget,
    );
      expect(
        find.bySemanticsLabel('Provider. Open your care conversations'),
        findsOneWidget,
      );
      semantics.dispose();
  });
}
