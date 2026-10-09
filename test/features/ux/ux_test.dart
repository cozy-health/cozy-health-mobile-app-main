import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cozy_health/core/services/mood_draft_service.dart';
import 'package:cozy_health/core/services/local_db_service.dart';
import 'package:cozy_health/core/widgets/app_button.dart';
import 'package:cozy_health/core/widgets/app_snackbar.dart';
import 'package:cozy_health/core/widgets/skeleton_loader.dart';
import 'package:cozy_health/core/widgets/friendly_error.dart';
import 'package:cozy_health/features/auth/presentation/widgets/auth_ui.dart';
import 'package:cozy_health/features/auth/presentation/screens/login_screen.dart';
import 'package:cozy_health/features/mood_check_in/presentation/screens/mood_feeling_screen.dart';
import '../../support/local_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final drafts = MoodDraftService();
  late Directory directory;
  setUpAll(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await installLocalTestFonts();
    directory = await Directory.systemTemp.createTemp('cozy_ux_');
    Hive.init(directory.path);
    await LocalDbService().settingsBox();
  });
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await drafts.clear();
  });
  tearDownAll(() async {
    await Hive.close();
    await directory.delete(recursive: true);
    resetLocalTestFonts();
  });

  test('mood draft preserves every answer and step for today', () async {
    final data = {
      'step': 7,
      'mood': 'calm',
      'intensity': 6,
      'body': ['Shoulders'],
      'triggers': ['Work'],
      'custom_trigger': 'Meeting',
      'sleep': 4,
      'energy': 3,
      'note': 'A short pause.',
      'coping': ['Walking'],
    };
    await drafts.save(data, now: DateTime(2026, 10, 8));
    expect(
      await drafts.loadToday(now: DateTime(2026, 10, 8)),
      containsPair('note', 'A short pause.'),
    );
    expect(
      await drafts.loadToday(now: DateTime(2026, 10, 8)),
      containsPair('step', 7),
    );
    await (await LocalDbService().settingsBox()).close();
    expect(
      await drafts.loadToday(now: DateTime(2026, 10, 8)),
      containsPair('custom_trigger', 'Meeting'),
    );
  });
  test('mood drafts from yesterday expire', () async {
    await drafts.save({'step': 2}, now: DateTime(2026, 10, 7));
    expect(await drafts.loadToday(now: DateTime(2026, 10, 8)), isNull);
  });
  test('discarding or saving clears the mood draft', () async {
    await drafts.save({'step': 2});
    await drafts.clear();
    expect(await drafts.loadToday(), isNull);
  });
  test('snackbars use one duration, rounded shape and elevation', () {
    for (final snack in [
      AppSnackbar.success('Saved'),
      AppSnackbar.error('Try again'),
      AppSnackbar.info('Hello'),
      AppSnackbar.warning('Please check'),
    ]) {
      expect(snack.duration, const Duration(milliseconds: 3000));
      expect(snack.elevation, 3);
      expect(snack.shape, isA<RoundedRectangleBorder>());
    }
    expect(
      AppSnackbar.friendly('SocketException: private URL'),
      "We couldn't complete that. Check your connection and try again.",
    );
  });

  Future<void> mount(WidgetTester tester, Widget child) => tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Scaffold(body: child),
      ),
    ),
  );
  testWidgets('loading submit prevents duplicate taps and shows inline label', (
    tester,
  ) async {
    var taps = 0;
    await mount(
      tester,
      AppButton(text: 'Save', isLoading: true, onPressed: () => taps++),
    );
    expect(find.text('Loading...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byType(ElevatedButton));
    expect(taps, 0);
  });
  testWidgets('skeleton respects reduced motion', (tester) async {
    await mount(tester, const SkeletonLoader());
    await tester.pumpAndSettle();
    expect(tester.hasRunningAnimations, isFalse);
    expect(find.byType(SkeletonLoader), findsOneWidget);
  });
  testWidgets('auth fields carry autofill hints', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await mount(
      tester,
      AuthTextField(
        label: 'Email',
        controller: controller,
        autofillHints: const [AutofillHints.email],
      ),
    );
    expect(tester.widget<TextField>(find.byType(TextField)).autofillHints, [
      AutofillHints.email,
    ]);
  });
  testWidgets('unsupported biometrics have no nonfunctional login button', (
    tester,
  ) async {
    await mount(tester, const LoginScreen());
    await tester.pumpAndSettle();
    expect(find.text('Log in with Face ID'), findsNothing);
    expect(find.text('Log in with fingerprint'), findsNothing);
  });
  testWidgets(
    'three consecutive failures offer support and retry remains functional',
    (tester) async {
      var retries = 0;
      await mount(
        tester,
        Builder(
          builder: (context) => TextButton(
            onPressed: () => AppSnackbar.show(
              context,
              AppSnackbar.error(
                'Check your connection.',
                onRetry: () => retries++,
              ),
            ),
            child: const Text('Fail'),
          ),
        ),
      );
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text('Fail'));
        await tester.pumpAndSettle();
      }
      expect(find.text('Help & Support'), findsOneWidget);
      await tester.tap(find.text('Try again'));
      expect(retries, 1);
    },
  );
  testWidgets('friendly error keeps technical details out and exposes retry', (
    tester,
  ) async {
    var retries = 0;
    await mount(
      tester,
      FriendlyError(onRetry: () => retries++, failureCount: 3),
    );
    expect(find.text("We couldn't load your data."), findsOneWidget);
    expect(find.text('Help & Support'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    expect(retries, 1);
  });
  testWidgets('today draft offers resume and restores the saved step', (
    tester,
  ) async {
    await tester.runAsync(
      () => drafts.save({'step': 2, 'mood': 'calm', 'intensity': 6}),
    );
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await mount(tester, const MoodFeelingScreen());
    await tester.pumpAndSettle();
    expect(find.text('You have an unsaved check-in. Resume?'), findsOneWidget);
    await tester.tap(find.text('Resume'));
    await tester.pumpAndSettle();
    expect(find.text('Step 2 of 9'), findsOneWidget);
    expect(find.text('You have an unsaved check-in. Resume?'), findsNothing);
  });
}
