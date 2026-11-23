import 'dart:async';

import 'package:cozy_health/core/models/user_profile.dart';
import 'package:cozy_health/core/storage/token_storage.dart';
import 'package:cozy_health/core/theme/app_theme.dart';
import 'package:cozy_health/core/widgets/skeleton_loader.dart';
import 'package:cozy_health/features/settings/data/profile_repository.dart';
import 'package:cozy_health/features/settings/presentation/widgets/settings_profile_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/local_fonts.dart';

class ControlledSettingsProfile extends ProfileRepository {
  final changes = StreamController<UserProfile?>.broadcast();
  final pending = Completer<UserProfile?>();
  int fetches = 0;

  @override
  Stream<UserProfile?> watchProfile() => changes.stream;

  @override
  Future<UserProfile?> fetchProfile() {
    fetches++;
    return pending.future;
  }
}

void main() {
  setUpAll(installLocalTestFonts);
  tearDownAll(resetLocalTestFonts);
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  UserProfile profile() => UserProfile(
    id: 'synthetic-settings',
    name: 'Maya Lin',
    email: 'maya@example.test',
    updatedAt: DateTime.utc(2026, 11, 22),
  );

  Future<void> mount(
    WidgetTester tester,
    ControlledSettingsProfile repository, {
    Future<bool> Function()? guest,
    UserProfile? cached,
    bool dark = false,
    double scale = 1,
  }) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      unawaited(repository.changes.close());
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: dark ? AppTheme.dark : AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: true,
            textScaler: TextScaler.linear(scale),
          ),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: SettingsProfileCard(
              repository: repository,
              isGuestSession: guest ?? () async => false,
              cachedProfile: () => cached,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('loading uses a shaped placeholder and ends after timeout', (
    tester,
  ) async {
    final repository = ControlledSettingsProfile(), guest = Completer<bool>();
    final semantics = tester.ensureSemantics();

    await mount(tester, repository, guest: () => guest.future);
    expect(
      find.byKey(const ValueKey('settings-profile-loading')),
      findsOneWidget,
    );
    expect(find.byType(SkeletonLoader), findsWidgets);
    expect(find.text('Loading...'), findsNothing);
    expect(find.bySemanticsLabel('Loading profile'), findsOneWidget);
    await tester.pump(const Duration(seconds: 8));
    expect(find.text('Profile unavailable'), findsOneWidget);
    expect(find.text('Retry profile'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets(
    'missing profile retries once before redraw and displays recovery',
    (tester) async {
      final repository = ControlledSettingsProfile();
      await mount(tester, repository);
      repository.changes.add(null);
      await tester.pumpAndSettle();
      expect(find.text('Profile unavailable'), findsOneWidget);
      final retry = tester
          .widget<TextButton>(find.widgetWithText(TextButton, 'Retry profile'))
          .onPressed!;
      retry();
      retry();
      expect(repository.fetches, 1);
      repository.pending.complete(profile());
      await tester.pumpAndSettle();
      expect(find.text('Maya Lin'), findsOneWidget);
      expect(find.text('Profile unavailable'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('stream failure retains a cached identity and explains retry', (
    tester,
  ) async {
    final repository = ControlledSettingsProfile();
    await mount(tester, repository, cached: profile());
    repository.changes.addError(StateError('synthetic private diagnostic'));
    await tester.pumpAndSettle();
    expect(find.text('Maya Lin'), findsOneWidget);
    expect(
      find.text('Could not refresh. Your saved profile is shown.'),
      findsOneWidget,
    );
    expect(find.textContaining('private diagnostic'), findsNothing);
    expect(find.byType(SkeletonLoader), findsNothing);
  });

  testWidgets('guest identity does not wait for a profile stream', (
    tester,
  ) async {
    final repository = ControlledSettingsProfile();
    await mount(tester, repository, guest: () async => true);
    await tester.pumpAndSettle();
    expect(find.text('Guest'), findsOneWidget);
    expect(find.text('Create an account to sync your data'), findsOneWidget);
    expect(find.text('Profile unavailable'), findsNothing);
    expect(repository.fetches, 0);
  });

  testWidgets('a late retry cannot populate a replacement session', (
    tester,
  ) async {
    final repository = ControlledSettingsProfile();
    await mount(tester, repository);
    repository.changes.add(null);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retry profile'));
    await tester.pump();
    await TokenStorage().saveSession('synthetic-session', stayLoggedIn: false);
    await tester.pump();
    repository.pending.complete(profile());
    repository.changes.add(null);
    await tester.pumpAndSettle();
    expect(find.text('Maya Lin'), findsNothing);
    expect(find.text('Profile unavailable'), findsOneWidget);
  });

  for (final dark in [false, true]) {
    testWidgets('unavailable card fits 200 percent text dark=$dark', (
      tester,
    ) async {
      final repository = ControlledSettingsProfile();
      await mount(tester, repository, dark: dark, scale: 2);
      repository.changes.addError(StateError('offline'));
      await tester.pumpAndSettle();
      expect(find.text('Retry profile'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
