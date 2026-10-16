import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cozy_health/core/data/demo_mode.dart';
import 'package:cozy_health/core/theme/app_theme.dart';
import 'package:cozy_health/core/models/affirmation_assignment.dart';
import 'package:cozy_health/core/models/user_profile.dart';
import 'package:cozy_health/core/repositories/affirmation_repository.dart';
import 'package:cozy_health/core/routing/app_router.dart';
import 'package:cozy_health/core/services/affirmation_controller.dart';
import 'package:cozy_health/core/services/local_db_service.dart';
import 'package:cozy_health/core/storage/token_storage.dart';
import 'package:cozy_health/core/widgets/affirmation_panel.dart';
import 'package:cozy_health/features/content/presentation/screens/daily_affirmation_screen.dart';
import 'package:cozy_health/features/home/presentation/screens/home_screen.dart';
import '../../support/local_fonts.dart';
import '../../support/repository_fixture.dart';
import '../../support/surface_capture.dart';

class FakeAffirmations extends AffirmationRepository {
  FakeAffirmations(this.clock);
  final DateTime Function() clock;
  String? scope = 'session-a';
  AffirmationAssignment? saved, result;
  bool fail = false, storageFail = false;
  int calls = 0;
  Completer<AffirmationAssignment?>? pending;
  @override
  Future<String?> owner() async {
    if (storageFail) throw StateError('Storage unavailable');
    return scope;
  }

  @override
  Future<AffirmationAssignment?> cached({bool allowExpired = false}) async =>
      saved != null && (allowExpired || !saved!.isExpired(clock()))
      ? saved
      : null;
  @override
  Future<AffirmationAssignment?> fetchCurrent({bool force = false}) async {
    if (!force && saved != null && !saved!.isExpired(clock())) return saved;
    calls++;
    if (fail) throw StateError('Offline');
    if (pending != null) return pending!.future;
    return saved = result;
  }
}

void main() {
  late DateTime now;
  late FakeAffirmations repository;
  late AffirmationController controller;
  late RepositoryFixture<UserProfile> fixture;
  AffirmationAssignment entry(int id, {DateTime? start}) {
    final assigned = start ?? now;
    return AffirmationAssignment(
      id: id,
      body: 'A gentle affirmation $id.',
      assignedAt: assigned,
      expiresAt: assigned.add(const Duration(hours: 24)),
    );
  }

  setUpAll(() async {
    await installLocalTestFonts();
    SharedPreferences.setMockInitialValues({});
    fixture = RepositoryFixture(
      LocalDbService.userProfileBoxName,
      UserProfileAdapter(),
    );
    await fixture.open();
    await fixture.box.put(
      'profile',
      UserProfile(
        id: 'profile',
        name: 'Person',
        email: 'person@example.test',
        updatedAt: DateTime.utc(2026),
      ),
    );
  });
  setUp(() {
    now = DateTime.utc(2026, 10, 16, 14, 30);
    repository = FakeAffirmations(() => now);
    controller = AffirmationController(repository: repository, now: () => now);
    repository.result = entry(1);
  });
  tearDown(() {
    controller.dispose();
    DemoMode.instance.enabled = false;
  });
  tearDownAll(() async {
    await fixture.close();
    resetLocalTestFonts();
  });
  Future<void> mount(WidgetTester tester, {bool compact = false}) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AffirmationPanel(controller: controller, compact: compact),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'visible consumers coalesce loads and stop timers on last detach',
    (tester) async {
      controller.attach();
      controller.attach();
      await tester.pump();
      expect(repository.calls, 1);
      expect(controller.state.assignment!.id, 1);
      controller.detach();
      now = now.add(const Duration(hours: 24));
      repository.result = entry(2);
      await tester.pump(const Duration(hours: 24, milliseconds: 101));
      expect(repository.calls, 2);
      expect(controller.state.assignment!.id, 2);
      controller.detach();
      await tester.pump(const Duration(days: 2));
      expect(repository.calls, 2);
    },
  );
  testWidgets(
    'expiry shows saved copy offline and retry replaces it on both consumers',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AffirmationPanel(controller: controller),
                AffirmationPanel(controller: controller),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      repository.fail = true;
      now = now.add(const Duration(hours: 24));
      await tester.pump(const Duration(hours: 24, milliseconds: 101));
      await tester.pumpAndSettle();
      expect(find.text('Last saved affirmation'), findsNWidgets(2));
      expect(find.text('A gentle affirmation 1.'), findsNWidgets(2));
      repository.fail = false;
      repository.result = entry(2);
      await tester.tap(find.text('Retry affirmation').first);
      await tester.pumpAndSettle();
      expect(find.text('A gentle affirmation 2.'), findsNWidgets(2));
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'empty catalog retries after five minutes rather than waiting a day',
    (tester) async {
      repository.result = null;
      await mount(tester);
      expect(controller.state.status, AffirmationStatus.empty);
      expect(find.text(AffirmationState.encouragement), findsOneWidget);
      repository.result = entry(1);
      now = now.add(const Duration(minutes: 5));
      await tester.pump(const Duration(minutes: 5));
      await tester.pumpAndSettle();
      expect(repository.calls, 2);
      expect(find.text('A gentle affirmation 1.'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'guest and failed account lookup have honest fallback and retry',
    (tester) async {
      repository.scope = null;
      await mount(tester);
      expect(find.text('General encouragement'), findsOneWidget);
      expect(repository.calls, 0);
      repository.storageFail = true;
      await controller.refresh();
      await tester.pumpAndSettle();
      expect(find.text('Retry affirmation'), findsOneWidget);
      repository.storageFail = false;
      repository.scope = 'session-b';
      await tester.tap(find.text('Retry affirmation'));
      await tester.pumpAndSettle();
      expect(find.text('A gentle affirmation 1.'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets('resume refreshes while backgrounding cancels timers', (
    tester,
  ) async {
    await mount(tester);
    controller.didChangeAppLifecycleState(AppLifecycleState.paused);
    now = now.add(const Duration(hours: 25));
    repository.result = entry(2);
    await tester.pump(const Duration(hours: 25));
    expect(repository.calls, 1);
    controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(repository.calls, 2);
    expect(controller.state.assignment!.id, 2);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
    'late response from previous session cannot appear or overwrite state',
    (tester) async {
      repository.pending = Completer<AffirmationAssignment?>();
      await mount(tester);
      repository.scope = 'session-b';
      repository.pending!.complete(entry(9));
      repository.pending = null;
      repository.saved = null;
      repository.result = entry(2);
      await tester.pumpAndSettle();
      expect(controller.state.assignment?.id, isNot(9));
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'session clearing removes visible content before outstanding work finishes',
    (tester) async {
      await mount(tester);
      repository.pending = Completer<AffirmationAssignment?>();
      final work = controller.refresh(force: true);
      await tester.pump();
      await TokenStorage().clearToken();
      repository.scope = null;
      expect(controller.state.assignment, isNull);
      repository.pending!.complete(entry(9));
      await work;
      await tester.pumpAndSettle();
      expect(find.text('A gentle affirmation 9.'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets('hidden panels stop refresh work', (tester) async {
    await mount(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: TickerMode(
          enabled: false,
          child: Scaffold(body: AffirmationPanel(controller: controller)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(days: 2));
    expect(repository.calls, 1);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
    'Home card opens actual detail with same text and copies exactly that text',
    (tester) async {
      DemoMode.instance.enabled = true;
      String? copied;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            if (call.method == 'Clipboard.setData') {
              copied = (call.arguments as Map)['text'] as String;
            }
            return null;
          });
      final router = GoRouter(
        initialLocation: AppRouter.home,
        routes: [
          GoRoute(
            path: AppRouter.home,
            builder: (_, __) => HomeScreen(affirmationController: controller),
          ),
          GoRoute(
            path: AppRouter.dailyAffirmation,
            builder: (_, __) => DailyAffirmationScreen(controller: controller),
          ),
          GoRoute(
            path: AppRouter.categoryDetail,
            builder: (_, state) =>
                Scaffold(body: Text((state.extra as Map)['id'])),
          ),
        ],
      );
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const Key('home-affirmation-card')),
      );
      await tester.tap(find.byKey(const Key('home-affirmation-card')));
      await tester.pumpAndSettle();
      expect(find.byType(DailyAffirmationScreen), findsOneWidget);
      expect(find.text('A gentle affirmation 1.'), findsOneWidget);
      await tester.ensureVisible(find.text('Copy affirmation'));
      await tester.tap(find.text('Copy affirmation'));
      await tester.pumpAndSettle();
      expect(copied, 'A gentle affirmation 1.');
      ScaffoldMessenger.of(
        tester.element(find.byType(DailyAffirmationScreen)),
      ).hideCurrentSnackBar();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Read related articles'));
      await tester.tap(find.text('Read related articles'));
      await tester.pumpAndSettle();
      expect(find.text('self-compassion'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      router.dispose();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    },
  );

  for (final dark in [false, true]) {
    for (final contrast in [false, true]) {
      for (final landscape in [false, true]) {
        testWidgets(
          'detail layout dark=$dark contrast=$contrast landscape=$landscape',
          (tester) async {
            tester.view.physicalSize = landscape
                ? const Size(667, 375)
                : const Size(375, 667);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            final theme = dark ? AppTheme.dark : AppTheme.light;
            await tester.pumpWidget(
              MaterialApp(
                theme: contrast ? AppTheme.highContrast(theme) : theme,
                builder: (context, child) => RepaintBoundary(
                  key: surfaceCaptureKey,
                  child: MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(textScaler: const TextScaler.linear(2)),
                    child: child!,
                  ),
                ),
                home: DailyAffirmationScreen(controller: controller),
              ),
            );
            await tester.pumpAndSettle();
            final prefix =
                'affirmation_dark$dark-contrast$contrast-landscape$landscape';
            await captureSurface(tester, '$prefix-body');
            await tester.ensureVisible(find.text('Read related articles'));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            await captureSurface(tester, '$prefix-actions');
            await tester.pumpWidget(const SizedBox.shrink());
          },
        );
      }
    }
  }
  testWidgets('completed token replacement refreshes an already open panel', (
    tester,
  ) async {
    await mount(tester);
    repository.scope = 'session-b';
    repository.saved = null;
    repository.result = entry(2);
    await TokenStorage().saveToken('2|other');
    await tester.pumpAndSettle();
    expect(find.text('A gentle affirmation 1.'), findsNothing);
    expect(find.text('A gentle affirmation 2.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
    'account activation clears old content and waits for the new auth token',
    (tester) async {
      final events = StreamController<void>.broadcast(sync: true);
      String? user = 'user-a';
      controller.dispose();
      controller = AffirmationController(
        repository: repository,
        now: () => now,
        accountChanges: events.stream,
        activeUserId: () => user,
      );
      await mount(tester);
      expect(find.text('A gentle affirmation 1.'), findsOneWidget);
      user = 'user-b';
      events.add(null);
      await tester.pumpAndSettle();
      expect(controller.state.assignment, isNull);
      expect(repository.calls, 1);
      await controller.refresh(force: true);
      expect(repository.calls, 1);
      repository.scope = 'session-b';
      repository.saved = null;
      repository.result = entry(2);
      await TokenStorage().saveToken('2|other');
      await tester.pumpAndSettle();
      expect(find.text('A gentle affirmation 2.'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await events.close();
    },
  );
  testWidgets(
    'reattaching after an unobserved resume restores expiry scheduling',
    (tester) async {
      await mount(tester);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pumpWidget(const SizedBox.shrink());
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await mount(tester);
      now = now.add(const Duration(hours: 24));
      repository.result = entry(2);
      await tester.pump(const Duration(hours: 24, milliseconds: 101));
      await tester.pumpAndSettle();
      expect(find.text('A gentle affirmation 2.'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
