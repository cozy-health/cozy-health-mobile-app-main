import 'dart:io';
import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cozy_health/core/api/api_client.dart';
import 'package:cozy_health/core/models/subscription_status.dart';
import 'package:cozy_health/core/models/user_profile.dart';
import 'package:cozy_health/core/models/digital_wellbeing_preferences.dart';
import 'package:cozy_health/core/services/local_db_service.dart';
import 'package:cozy_health/core/services/digital_wellbeing_service.dart';
import 'package:cozy_health/core/storage/encrypted_hive.dart';
import 'package:cozy_health/core/theme/app_colors.dart';
import 'package:cozy_health/core/theme/app_theme.dart';
import 'package:cozy_health/core/widgets/wellness_sheet.dart';
import 'package:cozy_health/core/widgets/wellness_panel.dart';
import 'package:cozy_health/features/notifications/presentation/widgets/notification_permission_sheet.dart';
import 'package:cozy_health/features/notifications/presentation/widgets/notification_denied_sheet.dart';
import 'package:cozy_health/features/quiz/presentation/widgets/clinical_disclaimer_sheet.dart';
import 'package:cozy_health/features/quiz/presentation/widgets/quiz_retake_confirm_dialog.dart';
import 'package:cozy_health/features/settings/data/native_billing_service.dart';
import 'package:cozy_health/features/settings/presentation/screens/notification_preferences_screen.dart';
import 'package:cozy_health/features/settings/presentation/screens/digital_wellbeing_screen.dart';
import 'package:cozy_health/features/settings/presentation/screens/student_verification_screen.dart';
import 'package:cozy_health/features/settings/presentation/screens/subscription_screen.dart';
import 'package:cozy_health/features/settings/presentation/screens/active_sessions_screen.dart';
import '../../support/local_fonts.dart';
import '../../student_review_screen_test.dart' show StudentReviewTransport;
import '../settings/active_sessions_test.dart' show Sessions;

class _Wellbeing extends DigitalWellbeingService {
  DigitalWellbeingPreferences value = const DigitalWellbeingPreferences();
  @override
  Future<DigitalWellbeingPreferences> load() async => value;
  @override
  Future<void> save(DigitalWellbeingPreferences preferences) async =>
      value = preferences;
}

class _ReviewTransport extends StudentReviewTransport {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) {
    if (options.path == '/subscription') {
      return Future.value(
        ResponseBody.fromString(
          '{"data":null}',
          200,
          headers: {
            Headers.contentTypeHeader: ['application/json'],
          },
        ),
      );
    }
    return super.fetch(options, requestStream, cancelFuture);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const capture = bool.fromEnvironment('UI_REFRESH_CAPTURE');
  late HttpClientAdapter previousTransport;
  late StudentReviewTransport student;
  final billing = NativeBillingService.instance;
  final local = LocalDbService();

  setUpAll(() async {
    await installLocalTestFonts(
      visualFontPath: 'test/golden_assets/Outfit.ttf',
      useRealFonts: true,
    );
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    Hive.registerAdapter(SubscriptionStatusAdapter());
    Hive.registerAdapter(UserProfileAdapter());
    // UI fixtures use Hive's memory backend. Disk persistence is covered by
    // repository tests; fake-clock widget callbacks must not hold disk writes.
    await Hive.openBox<SubscriptionStatus>(
      EncryptedHive.physicalName(
        local.boxName(LocalDbService.subscriptionStatusBoxName),
      ),
      bytes: Uint8List(0),
    );
    await Hive.openBox<UserProfile>(
      EncryptedHive.physicalName(
        local.boxName(LocalDbService.userProfileBoxName),
      ),
      bytes: Uint8List(0),
    );
    await Hive.openBox<dynamic>(
      EncryptedHive.physicalName(
        local.boxName(LocalDbService.userSettingsBoxName),
      ),
      bytes: Uint8List(0),
    );
  });
  setUp(() async {
    previousTransport = ApiClient().transportForTesting;
    student = _ReviewTransport()..empty = true;
    ApiClient().transportForTesting = student;
    billing.enabled = false;
    billing.products = [];
    billing.studentEligible = false;
    billing.studentReverificationRequired = false;
    billing.busy = false;
    billing.message = null;
    await local.subscriptionStatusBox.clear();
    await local.userProfileBox.put(
      'fixture',
      UserProfile(
        id: 'fixture',
        name: 'Preview',
        email: 'preview@example.test',
        pushConsent: true,
        updatedAt: DateTime(2026, 11, 13),
      ),
    );
  });
  tearDown(() {
    ApiClient().transportForTesting = previousTransport;
    debugDefaultTargetPlatformOverride = null;
    billing.enabled = false;
    billing.products = [];
    billing.studentEligible = false;
    billing.studentReverificationRequired = false;
    billing.busy = false;
  });
  tearDownAll(() async {
    await Hive.close();
    Hive.resetAdapters();
    resetLocalTestFonts();
  });

  Future<void> mount(
    WidgetTester tester,
    Widget screen, {
    bool dark = false,
    int accent = 0,
    bool large = false,
    bool landscape = false,
    bool keyboard = false,
  }) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = landscape
        ? const Size(667, 375)
        : Size(large ? 320 : 390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
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
          key: const ValueKey('refresh-capture'),
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
        home: screen,
      ),
    );
    await tester.pumpAndSettle();
    debugDefaultTargetPlatformOverride = null;
    expect(tester.takeException(), isNull);
  }

  Future<void> snap(WidgetTester tester, String name) async {
    if (!capture) return;
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('refresh-capture')),
    );
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final directory = Directory('../output/ui-refresh-captures');
      await directory.create(recursive: true);
      await File(
        '${directory.path}/$name.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  Widget opener(Future<Object?> Function(BuildContext) open) => Scaffold(
    body: Builder(
      builder: (context) => Center(
        child: TextButton(
          onPressed: () => open(context),
          child: const Text('Open'),
        ),
      ),
    ),
  );

  Future<void> reveal(WidgetTester tester, Finder finder) async {
    if (finder.evaluate().isEmpty) {
      final scrollable = find.byType(Scrollable).first;
      tester.state<ScrollableState>(scrollable).position.jumpTo(0);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(finder, 180, scrollable: scrollable);
    } else {
      await tester.ensureVisible(finder);
    }
    await tester.pumpAndSettle();
  }

  for (final dark in [false, true]) {
    for (var accent = 0; accent < 4; accent++) {
      final label = '${dark ? 'dark' : 'light'}-$accent';
      testWidgets('reminder choices and dismissal $label', (tester) async {
        await mount(
          tester,
          opener(NotificationPermissionSheet.show),
          dark: dark,
          accent: accent,
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        final journal = find.byKey(const ValueKey('reminder-journal'));
        expect(tester.widget<WellnessSheetOption>(journal).selected, false);
        await tester.tap(journal);
        await tester.pump();
        expect(tester.widget<WellnessSheetOption>(journal).selected, true);
        expect(
          tester
              .widget<WellnessSheetOption>(
                find.byKey(const ValueKey('reminder-mood')),
              )
              .onPressed,
          isNull,
        );
        await snap(tester, 'reminders-$label');
        await reveal(tester, find.byKey(const ValueKey('reminder-decline')));
        await tester.tap(find.byKey(const ValueKey('reminder-decline')));
        await tester.pumpAndSettle();
        expect(find.byType(NotificationPermissionSheet), findsNothing);
        expect((await local.settingsBox()).get('push_declined_at'), isNotNull);
        expect(local.getUserProfile()!.pushConsent, true);
      });
      testWidgets('plans and Student entry $label', (tester) async {
        await mount(
          tester,
          const SubscriptionScreen(),
          dark: dark,
          accent: accent,
        );
        expect(find.text('Paid activation coming later'), findsNothing);
        await snap(tester, 'plans-$label');
        await reveal(
          tester,
          find.byKey(const ValueKey('restore-store-purchases')),
        );
        expect(
          find.byKey(const ValueKey('restore-store-purchases')),
          findsOneWidget,
        );
        expect(find.text('Restore purchases'), findsOneWidget);
        await snap(tester, 'store-options-$label');
        final action = find.byKey(const ValueKey('student-verification'));
        await reveal(tester, action);
        expect(
          find.ancestor(of: action, matching: find.byType(WellnessPanel)),
          findsOneWidget,
        );
        await snap(tester, 'student-plan-$label');
        await tester.tap(action);
        await tester.pumpAndSettle();
        expect(find.byType(StudentVerificationScreen), findsOneWidget);
        await snap(tester, 'student-email-$label');
      });
    }
  }

  for (final mode in ['large-light', 'large-dark', 'landscape', 'keyboard']) {
    final large = mode.startsWith('large');
    final dark = mode == 'large-dark';
    for (final entry in <String, Widget>{
      'reminder': const NotificationPermissionSheet(),
      'denied': const NotificationDeniedSheet(),
      'disclaimer': const ClinicalDisclaimerSheet(),
      'retake': const QuizRetakeConfirmDialog(),
    }.entries) {
      testWidgets('${entry.key} fits $mode', (tester) async {
        await mount(
          tester,
          opener(
            (context) => showWellnessSheet<void>(
              context: context,
              builder: (_) => entry.value,
            ),
          ),
          large: large,
          dark: dark,
          landscape: mode == 'landscape',
          keyboard: mode == 'keyboard',
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await snap(tester, '${entry.key}-$mode');
        final actionKey = switch (entry.key) {
          'reminder' => 'reminder-enable',
          'denied' => 'notification-open-settings',
          'disclaimer' => 'disclaimer-accept',
          _ => 'assessment-retake',
        };
        final action = find.byKey(ValueKey(actionKey));
        await reveal(tester, action);
        expect(action.hitTestable(), findsOneWidget);
        await snap(tester, '${entry.key}-$mode-actions');
        final close = find.byKey(const ValueKey('wellness-sheet-close'));
        await reveal(tester, close);
        await tester.tap(close);
        await tester.pumpAndSettle();
        expect(find.byType(WellnessSheet), findsNothing);
      });
    }
    testWidgets('settings and student fit $mode', (tester) async {
      await mount(
        tester,
        const NotificationPreferencesScreen(),
        large: large,
        dark: dark,
        landscape: mode == 'landscape',
        keyboard: mode == 'keyboard',
      );
      await snap(tester, 'notification-settings-$mode');
      final days = find.byKey(const ValueKey('reminder-days-mood'));
      await reveal(tester, days);
      await snap(tester, 'reminder-settings-$mode');
      await tester.tap(days);
      await tester.pumpAndSettle();
      await snap(tester, 'reminder-days-$mode');
      for (var i = 1; i <= 7; i++) {
        final day = find.byKey(ValueKey('reminder-day-$i'));
        await reveal(tester, day);
        await tester.tap(day);
        await tester.pump();
      }
      final save = find.byKey(const ValueKey('reminder-days-save'));
      expect(tester.widget<WellnessAction>(save).onPressed, isNull);
      await reveal(tester, find.byKey(const ValueKey('reminder-days-cancel')));
      await tester.tap(find.byKey(const ValueKey('reminder-days-cancel')));
      await tester.pumpAndSettle();
      expect(local.getUserProfile()!.reminderSettings, isEmpty);
      await mount(
        tester,
        DigitalWellbeingScreen(service: _Wellbeing()),
        large: large,
        dark: dark,
        landscape: mode == 'landscape',
        keyboard: mode == 'keyboard',
      );
      await snap(tester, 'wellbeing-$mode');
      student.empty = false;
      student.status = 'approved';
      student.renewal = true;
      await mount(
        tester,
        const StudentVerificationScreen(),
        large: large,
        dark: dark,
        landscape: mode == 'landscape',
        keyboard: mode == 'keyboard',
      );
      await reveal(tester, find.textContaining('Current eligibility ends:'));
      await snap(tester, 'student-status-$mode');
      await reveal(
        tester,
        find.byKey(const ValueKey('student-privacy-details')),
      );
      await tester.tap(find.byKey(const ValueKey('student-privacy-details')));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('a protected email fingerprint'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await snap(tester, 'student-privacy-$mode');
    });
  }

  for (final mode in ['large-light', 'large-dark', 'landscape']) {
    testWidgets('plans and current subscription fit $mode', (tester) async {
      await tester.runAsync(
        () => local.saveSubscriptionStatus(
          SubscriptionStatus.fromJson({
            'id': 'fixture-plan',
            'plan': 'premium',
            'status': 'active',
            'platform': 'apple',
            'store_management': {'store': 'Apple App Store'},
            'store_state': 'canceled',
            'auto_renews': false,
            'expires_at': DateTime.now()
                .add(const Duration(days: 30))
                .toIso8601String(),
          }),
        ),
      );
      await mount(
        tester,
        const SubscriptionScreen(),
        large: mode.startsWith('large'),
        dark: mode == 'large-dark',
        landscape: mode == 'landscape',
      );
      expect(find.text('Automatic renewal off'), findsOneWidget);
      await snap(tester, 'current-plan-$mode');
      await reveal(tester, find.byKey(const ValueKey('plan-details-premium')));
      expect(find.text('Current plan'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('plan-details-premium')));
      await tester.pumpAndSettle();
      await snap(tester, 'plan-details-$mode');
      await tester.tap(find.byKey(const ValueKey('wellness-sheet-close')));
      await tester.pumpAndSettle();
      await reveal(
        tester,
        find.byKey(const ValueKey('restore-store-purchases')),
      );
      expect(find.text('Restore purchases'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('retake returns each existing result without invented age', (
    tester,
  ) async {
    String? result;
    await mount(
      tester,
      opener((context) async {
        result = await QuizRetakeConfirmDialog.show(context);
        return result;
      }),
    );
    for (final choice in ['retake', 'view-previous', 'cancel']) {
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('You took this 2 weeks ago.'), findsNothing);
      final key = choice == 'retake'
          ? 'assessment-retake'
          : choice == 'cancel'
          ? 'assessment-retake-cancel'
          : 'assessment-view-previous';
      await tester.tap(find.byKey(ValueKey(key)));
      await tester.pumpAndSettle();
      expect(result, choice == 'view-previous' ? 'view' : choice);
    }
  });

  testWidgets('disclaimer retains supplied content and explicit consent', (
    tester,
  ) async {
    bool? result;
    await mount(
      tester,
      opener((context) async {
        result = await ClinicalDisclaimerSheet.show(
          context,
          disclaimer: 'Fixture disclaimer',
        );
        return result;
      }),
    );
    for (final accept in [false, true]) {
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Fixture disclaimer'), findsOneWidget);
      await tester.tap(
        find.byKey(
          ValueKey(accept ? 'disclaimer-accept' : 'disclaimer-cancel'),
        ),
      );
      await tester.pumpAndSettle();
      expect(result, accept);
    }
  });

  testWidgets('permission recovery opens actual platform settings', (
    tester,
  ) async {
    const channel = MethodChannel('flutter.baseflow.com/permissions/methods');
    final calls = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call.method);
          return true;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );
    await mount(tester, opener(NotificationDeniedSheet.show));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('notification-open-settings')));
    await tester.pumpAndSettle();
    expect(calls, ['openAppSettings']);
    expect(find.byType(NotificationDeniedSheet), findsNothing);
  });

  testWidgets(
    'plan details reflect available store products without duplicate restore',
    (tester) async {
      billing.enabled = true;
      billing.products = [
        ProductDetails(
          id: 'fixture-premium',
          title: 'Premium monthly',
          description: 'Fixture',
          price: '₦1,234',
          rawPrice: 1234,
          currencyCode: 'NGN',
        ),
      ];
      await mount(tester, const SubscriptionScreen());
      await reveal(tester, find.byKey(const ValueKey('plan-details-standard')));
      await tester.tap(find.byKey(const ValueKey('plan-details-standard')));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Available prices and purchase options'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Store purchases are currently unavailable'),
        findsNothing,
      );
      await tester.tap(find.byKey(const ValueKey('wellness-sheet-close')));
      await tester.pumpAndSettle();
      await reveal(
        tester,
        find.byKey(const ValueKey('purchase-fixture-premium')),
      );
      expect(find.text('Premium monthly · ₦1,234'), findsOneWidget);
      expect(find.text('Restore purchases'), findsOneWidget);
      await snap(tester, 'store-products');
    },
  );

  testWidgets('logging out everywhere can be cancelled without revocation', (
    tester,
  ) async {
    final repository = Sessions();
    await mount(tester, ActiveSessionsScreen(repository: repository));
    await tester.tap(find.byKey(const ValueKey('logout-all-devices')));
    await tester.pumpAndSettle();
    expect(
      find.text('This includes this device. You will need to sign in again.'),
      findsOneWidget,
    );
    expect(find.byType(WellnessDestructiveAction), findsOneWidget);
    await snap(tester, 'logout-confirmation');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(repository.revoked, isEmpty);
    expect(find.byType(Dialog), findsNothing);
  });
}
