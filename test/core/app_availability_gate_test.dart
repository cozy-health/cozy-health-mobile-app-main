import 'package:cozy_health/core/routing/app_router.dart';
import 'package:cozy_health/core/services/app_version.dart';
import 'package:cozy_health/core/services/feature_flags_service.dart';
import 'package:cozy_health/core/widgets/app_availability_gate.dart';
import 'package:cozy_health/features/crisis/presentation/screens/crisis_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import '../support/local_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(installLocalTestFonts);
  tearDownAll(resetLocalTestFonts);

  FeatureFlagsService? service;
  Map<String, dynamic> config = _config();

  setUp(() async {
    config = _config();
    service = FeatureFlagsService(fetch: () async => config);
    await service!.refresh();
  });

  tearDown(() {
    service?.dispose();
  });

  test('compares semantic app versions numerically', () {
    expect(
      AppVersion.tryParse('1.10.0')! > AppVersion.tryParse('1.9.9')!,
      true,
    );
    expect(AppVersion.tryParse('1.0.0+42'), AppVersion.tryParse('1.0.0'));
    expect(AppVersion.tryParse('1.0'), isNull);
  });

  testWidgets('force update blocks the app and opens the platform store', (
    tester,
  ) async {
    config = _config(min: '1.0.1', iosUrl: 'https://apps.apple.com/app/cozy');
    await service!.refresh();
    Uri? launched;

    await _pumpGate(
      tester,
      service: service!,
      version: '1.0.0',
      platform: TargetPlatform.iOS,
      launchStore: (uri) async {
        launched = uri;
        return true;
      },
    );

    expect(find.text('Cozy Health has been updated.'), findsOneWidget);
    expect(find.text('Home content'), findsNothing);

    await tester.tap(find.text('Update now'));
    await tester.pump();
    expect(launched, Uri.parse('https://apps.apple.com/app/cozy'));
  });

  testWidgets('maintenance mode blocks the app and retry refreshes config', (
    tester,
  ) async {
    var maintenance = true;
    service = FeatureFlagsService(
      fetch: () async => _config(
        maintenance: maintenance,
        maintenanceMessage: 'Finishing a quick tune-up.',
      ),
    );
    await service!.refresh();

    await _pumpGate(tester, service: service!, version: '1.0.0');

    expect(find.text("We're doing some quick maintenance."), findsOneWidget);
    expect(find.text('Finishing a quick tune-up.'), findsOneWidget);

    maintenance = false;
    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Home content'), findsOneWidget);
    expect(find.text("We're doing some quick maintenance."), findsNothing);
  });

  testWidgets('crisis hub stays reachable during maintenance mode', (
    tester,
  ) async {
    config = _config(maintenance: true);
    await service!.refresh();

    await _pumpGate(
      tester,
      service: service!,
      version: '1.0.0',
      useRealCrisisHub: true,
    );

    await tester.tap(find.text('Crisis resources'));
    await tester.pumpAndSettle();

    expect(find.text("You're not\nalone."), findsOneWidget);
    expect(find.text('Call 988'), findsOneWidget);
    expect(find.text("We're doing some quick maintenance."), findsNothing);
  });

  testWidgets('soft update banner can be dismissed for twenty-four hours', (
    tester,
  ) async {
    final now = DateTime.utc(2026, 10, 8, 12);
    DateTime? dismissedAt;
    config = _config(latest: '1.0.1');
    await service!.refresh();

    await _pumpGate(
      tester,
      service: service!,
      version: '1.0.0',
      now: () => now,
      loadDismissedAt: () async => dismissedAt,
      saveDismissedAt: (value) async => dismissedAt = value,
    );

    expect(find.text('New version available.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('soft_update_dismiss')));
    await tester.pumpAndSettle();
    expect(dismissedAt, now);
    expect(find.text('New version available.'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await _pumpGate(
      tester,
      service: service!,
      version: '1.0.0',
      now: () => now.add(const Duration(hours: 23)),
      loadDismissedAt: () async => dismissedAt,
      saveDismissedAt: (value) async => dismissedAt = value,
    );
    expect(find.text('New version available.'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await _pumpGate(
      tester,
      service: service!,
      version: '1.0.0',
      now: () => now.add(const Duration(hours: 24)),
      loadDismissedAt: () async => dismissedAt,
      saveDismissedAt: (value) async => dismissedAt = value,
    );
    expect(find.text('New version available.'), findsOneWidget);
  });

  testWidgets(
    'force update shows a friendly message when store URL is absent',
    (tester) async {
      config = _config(min: '1.0.1');
      await service!.refresh();

      await _pumpGate(tester, service: service!, version: '1.0.0');

      await tester.tap(find.text('Update now'));
      await tester.pump();

      expect(
        find.text('The update link is not available yet. Please try again.'),
        findsOneWidget,
      );
    },
  );
}

Map<String, dynamic> _config({
  String min = '1.0.0',
  String latest = '1.0.0',
  bool maintenance = false,
  String? maintenanceMessage,
  String? iosUrl,
  String? androidUrl,
}) => {
  'flags': {
    'ai_assistant': true,
    'push_notifications': true,
    'community': false,
    'content_feed': false,
    'quiz': true,
    'widgets': false,
    'analytics': false,
  },
  'min_app_version': min,
  'latest_app_version': latest,
  'maintenance_mode': maintenance,
  'maintenance_message': maintenanceMessage,
  'update_ios_url': iosUrl,
  'update_android_url': androidUrl,
};

Future<void> _pumpGate(
  WidgetTester tester, {
  required FeatureFlagsService service,
  required String version,
  TargetPlatform platform = TargetPlatform.android,
  StoreLauncher? launchStore,
  DateTimeReader? now,
  Future<DateTime?> Function()? loadDismissedAt,
  Future<void> Function(DateTime value)? saveDismissedAt,
  bool useRealCrisisHub = false,
}) async {
  final router = GoRouter(
    initialLocation: AppRouter.home,
    routes: [
      GoRoute(
        path: AppRouter.home,
        builder: (_, __) => const Scaffold(body: Text('Home content')),
      ),
      GoRoute(
        path: AppRouter.crisisHub,
        builder: (_, __) => useRealCrisisHub
            ? const CrisisResourcesHubScreen()
            : const Scaffold(body: Text('Crisis screen')),
      ),
    ],
  );

  await tester.pumpWidget(
    MaterialApp.router(
      routerConfig: router,
      builder: (context, child) => AppAvailabilityGate(
        flags: service,
        router: router,
        versionLoader: () async => version,
        platform: platform,
        launchStore: launchStore,
        now: now,
        loadSoftUpdateDismissedAt: loadDismissedAt ?? () async => null,
        saveSoftUpdateDismissedAt: saveDismissedAt ?? (_) async {},
        child: child!,
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}
