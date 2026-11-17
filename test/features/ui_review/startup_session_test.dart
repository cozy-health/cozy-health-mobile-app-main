import 'dart:async';
import 'dart:typed_data';
import 'package:cozy_health/core/api/api_client.dart';
import 'package:cozy_health/core/models/mood_entry.dart';
import 'package:cozy_health/core/models/user_profile.dart';
import 'package:cozy_health/core/routing/app_router.dart';
import 'package:cozy_health/core/services/local_db_service.dart';
import 'package:cozy_health/core/storage/token_storage.dart';
import 'package:cozy_health/features/splash/presentation/screens/splash_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../support/mobile_sync_contract.dart';
import '../../support/repository_fixture.dart';

class HeldSessionTransport implements HttpClientAdapter {
  final release = Completer<void>();
  int requests = 0;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancelFuture,
  ) async {
    requests++;
    await release.future;
    throw DioException(
      requestOptions: options,
      type: DioExceptionType.connectionError,
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  final local = LocalDbService();
  final fixture = RepositoryFixture<MoodEntry>(
    LocalDbService.moodBoxName,
    MoodEntryAdapter(),
  );
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({
      'install_marker_set': true,
      'has_completed_onboarding': true,
    });
    await fixture.open();
    registerSyncAdapters();
    await local.activateAccount('startup-owner');
    await local.saveUserProfile(
      UserProfile(
        id: 'startup-owner',
        name: 'Startup fixture',
        email: 'startup@example.test',
        updatedAt: DateTime.utc(2026, 11, 16),
      ),
    );
    await TokenStorage().saveToken('synthetic-startup-token');
  });
  tearDownAll(() async {
    await local.waitForSyncIdle();
    await fixture.close();
  });

  testWidgets('saved account opens before online validation completes', (
    tester,
  ) async {
    final transport = HeldSessionTransport();
    ApiClient().transportForTesting = transport;
    final router = GoRouter(
      initialLocation: '/splash',
      routes: [
        GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
        GoRoute(
          path: AppRouter.home,
          builder: (_, _) => const Scaffold(body: Text('Saved Home')),
        ),
        GoRoute(
          path: AppRouter.welcome,
          builder: (_, _) => const Scaffold(body: Text('Welcome')),
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    for (var frame = 0; frame < 20; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Saved Home'), findsOneWidget);
    expect(transport.requests, 1);
    expect(transport.release.isCompleted, isFalse);
    transport.release.complete();
    for (var frame = 0; frame < 10; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Saved Home'), findsOneWidget);
    expect(local.activeUserId, 'startup-owner');
    expect(await TokenStorage().getToken(), 'synthetic-startup-token');
    await tester.pumpWidget(const SizedBox.shrink());
    router.dispose();
  });
}
