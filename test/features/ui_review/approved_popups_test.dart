import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cozy_health/core/data/demo_mode.dart';
import 'package:cozy_health/core/theme/app_theme.dart';
import 'package:cozy_health/core/theme/app_colors.dart';
import 'package:cozy_health/core/widgets/wellness_sheet.dart';
import 'package:cozy_health/core/widgets/wellness_panel.dart';
import 'package:cozy_health/features/community/presentation/widgets/report_sheet.dart';
import 'package:cozy_health/features/community/presentation/widgets/visibility_sheet.dart';
import 'package:cozy_health/features/community/presentation/widgets/post_actions.dart';
import 'package:cozy_health/features/community/presentation/community_local_state.dart';
import 'package:cozy_health/features/settings/presentation/widgets/avatar_picker_sheet.dart';
import 'package:cozy_health/features/settings/presentation/widgets/provider_record_picker.dart';
import '../../support/local_fonts.dart';
import '../settings/avatar_picker_test.dart'
    show FakeAvatarRepository, FakePhotoPicker;
import '../settings/provider_record_picker_test.dart' show PickerApi;

const folder = 'docs/design/approved-popups-implemented';
void main() {
  setUpAll(() async {
    await installLocalTestFonts(
      visualFontPath: 'test/golden_assets/Outfit.ttf',
      useRealFonts: true,
    );
    await Directory(folder).create(recursive: true);
  });
  tearDownAll(resetLocalTestFonts);
  setUp(() => DemoMode.instance.enabled = false);
  tearDown(() => DemoMode.instance.enabled = false);
  Future<void> mount(
    WidgetTester tester,
    Widget child, {
    bool dark = false,
    int accent = 0,
    bool large = false,
    bool keyboard = false,
    bool landscape = false,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = landscape
        ? const Size(667, 375)
        : Size(large ? 320 : 375, 812);
    var theme = AppTheme.withAccent(
      dark ? AppTheme.dark : AppTheme.light,
      AppColors.brandPalette[accent],
    );
    if (large) theme = AppTheme.highContrast(theme);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme,
        builder: (context, child) => RepaintBoundary(
          key: const ValueKey('popup-overlay-capture'),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(large ? 2 : 1),
              highContrast: large,
              disableAnimations: true,
              viewInsets: EdgeInsets.only(bottom: keyboard ? 280 : 0),
            ),
            child: child!,
          ),
        ),
        home: RepaintBoundary(
          key: const ValueKey('popup-capture'),
          child: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: TextButton(
                  onPressed: () => showWellnessSheet<void>(
                    context: context,
                    dismissible: false,
                    builder: (_) => child,
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  Future<void> save(WidgetTester tester, String name) async {
    await tester.pump();
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('popup-overlay-capture')),
    );
    await tester.runAsync(() async {
      final img = await boundary.toImage(pixelRatio: 2);
      final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
      await File('$folder/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
      img.dispose();
    });
  }

  Widget sheet(String kind) => switch (kind) {
    'report' => ReportSheet(onSubmit: () {}, onReport: (r, d) async {}),
    'visibility' => VisibilitySheet(
      currentVisibility: PostVisibility.anonymous,
      onSelect: (_) {},
    ),
    'avatar' => AvatarPickerSheet(
      repository: FakeAvatarRepository(),
      picker: FakePhotoPicker(),
    ),
    _ => ProviderRecordPicker(
      api: PickerApi(),
      path: '/provider-conversations/1',
      type: 'moods',
      title: 'mood check-in',
      isCurrent: () => true,
      selected: const [],
    ),
  };
  for (final kind in ['report', 'visibility', 'avatar', 'records']) {
    for (final dark in [false, true]) {
      for (final accent in [0, 1, 2, 3]) {
        testWidgets('implemented $kind dark=$dark accent=$accent', (
          tester,
        ) async {
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await mount(tester, sheet(kind), dark: dark, accent: accent);
          if (kind == 'report') {
            await tester.tap(find.byKey(const ValueKey('report-reason-3')));
            await tester.pumpAndSettle();
          }
          await save(
            tester,
            '$kind-${dark ? 'dark' : 'light'}-${['blue', 'green', 'orange', 'yellow'][accent]}',
          );
          expect(tester.takeException(), isNull);
        });
      }
    }
    for (final landscape in [false, true]) {
      testWidgets('$kind large contrast keyboard landscape=$landscape', (
        tester,
      ) async {
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await mount(
          tester,
          sheet(kind),
          dark: true,
          accent: 3,
          large: true,
          keyboard: kind == 'report' && !landscape,
          landscape: landscape,
        );
        final close = find.byKey(const ValueKey('wellness-sheet-close'));
        await tester.ensureVisible(close);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await save(
          tester,
          '$kind-large-${landscape ? 'landscape' : 'portrait'}',
        );
        if (kind == 'report' && !landscape) {
          final submit = find.byKey(const ValueKey('report-submit'));
          await tester.ensureVisible(submit);
          await tester.pumpAndSettle();
          expect(tester.getRect(submit).bottom, lessThanOrEqualTo(532));
          await save(tester, 'report-large-keyboard-action');
        }
      });
    }
  }
  testWidgets(
    'report retains reason and notes on failure, and rejects duplicate sends',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var attempts = 0, submitted = 0;
      final gate = Completer<void>();
      await mount(
        tester,
        ReportSheet(
          onSubmit: () => submitted++,
          onReport: (reason, details) async {
            attempts++;
            expect(reason, 'Spam or scam');
            expect(details, 'Please review this');
            if (attempts == 1) await gate.future;
          },
        ),
      );
      await tester.tap(find.byKey(const ValueKey('report-reason-2')));
      await tester.enterText(
        find.byKey(const ValueKey('report-details')),
        'Please review this',
      );
      await tester.ensureVisible(find.byKey(const ValueKey('report-submit')));
      await tester.tap(find.byKey(const ValueKey('report-submit')));
      await tester.pump();
      expect(attempts, 1);
      final button = tester.widget<WellnessAction>(
        find.byKey(const ValueKey('report-submit')),
      );
      expect(button.onPressed, isNull);
      gate.completeError(StateError('Offline'));
      await tester.pumpAndSettle();
      expect(submitted, 0);
      expect(find.textContaining('Could not submit'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('report-details')))
            .controller!
            .text,
        'Please review this',
      );
      await tester.ensureVisible(find.byKey(const ValueKey('report-submit')));
      await tester.tap(find.byKey(const ValueKey('report-submit')));
      await tester.pumpAndSettle();
      expect(attempts, 2);
      expect(submitted, 1);
      expect(find.byType(ReportSheet), findsNothing);
    },
  );
  testWidgets(
    'visibility dismissal never changes selection and normal mode excludes followers',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var changes = 0;
      await mount(
        tester,
        VisibilitySheet(
          currentVisibility: PostVisibility.anonymous,
          onSelect: (_) => changes++,
        ),
      );
      expect(find.text('Followers only'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('wellness-sheet-close')));
      await tester.pumpAndSettle();
      expect(changes, 0);
    },
  );
  testWidgets(
    'block requires explicit confirmation; cancel preserves the post',
    (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      DemoMode.instance.enabled = true;
      final post = <String, dynamic>{
        'id': 'review-block',
        'authorId': 'other-review-member',
        'username': 'Review member',
        'content': 'Sample public post',
      };
      CommunityLocalState.instance.clearAccountState();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          builder: (context, child) => RepaintBoundary(
            key: const ValueKey('popup-overlay-capture'),
            child: child!,
          ),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => PostActions.show(context, post),
                child: const Text('Options'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Options'));
      await tester.pumpAndSettle();
      await save(tester, 'post-options-light-blue');
      await tester.tap(find.byKey(const ValueKey('post-block')));
      await tester.pumpAndSettle();
      expect(find.text('Block this member?'), findsOneWidget);
      await save(tester, 'block-confirm-light-blue');
      expect(CommunityLocalState.instance.isVisible(post), true);
      await tester.tap(find.text('Keep member unblocked'));
      await tester.pumpAndSettle();
      expect(CommunityLocalState.instance.isVisible(post), true);
      await tester.tap(find.text('Options'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('post-block')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Block member'));
      await tester.pumpAndSettle();
      expect(CommunityLocalState.instance.isVisible(post), false);
      CommunityLocalState.instance.clearAccountState();
    },
  );
}
