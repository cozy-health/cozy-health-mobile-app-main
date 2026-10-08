import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:cozy_health/core/services/feature_flags_service.dart';
import 'package:cozy_health/core/widgets/feature_gate.dart';
import 'package:cozy_health/core/widgets/bottom_navigation_bar.dart';
import '../support/local_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(installLocalTestFonts);
  tearDownAll(resetLocalTestFonts);
  late Directory directory;
  late Box<dynamic> cache;
  FeatureFlagsService? service;
  final now = DateTime.utc(2026, 10, 8, 12);
  Map<String, dynamic> payload({bool assistant = false}) => {
    'flags': {'ai_assistant': assistant},
    'min_app_version': '1.0.1',
    'maintenance_mode': false,
  };
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('cozy_config_test_');
    Hive.init(directory.path);
    cache = await Hive.openBox<dynamic>('configuration_test');
  });
  tearDown(() async {
    service?.dispose();
    service = null;
    await Hive.close();
    await directory.delete(recursive: true);
  });

  test(
    'fetches flags on initialization and stores a timestamped Hive cache',
    () async {
      var calls = 0;
      service = FeatureFlagsService(
        cache: cache,
        now: () => now,
        fetch: () async {
          calls++;
          return payload();
        },
      );
      await service!.initialize(poll: false);
      await service!.refresh();
      expect(calls, greaterThanOrEqualTo(1));
      expect(service!.isEnabled('ai_assistant'), false);
      expect(service!.minAppVersion, '1.0.1');
      expect(cache.get('configuration')['fetched_at'], now.toIso8601String());
    },
  );

  test('uses a fresh cache when the network is unavailable', () async {
    await cache.put('configuration', {
      'payload': payload(),
      'fetched_at': now.subtract(const Duration(minutes: 59)).toIso8601String(),
    });
    service = FeatureFlagsService(
      cache: cache,
      now: () => now,
      fetch: () async => throw const SocketException('offline'),
    );
    await service!.initialize(poll: false);
    await service!.refresh();
    expect(service!.isEnabled('ai_assistant'), false);
    expect(service!.ready, true);
  });

  test('expires caches at sixty minutes and uses defaults offline', () async {
    await cache.put('configuration', {
      'payload': payload(),
      'fetched_at': now.subtract(const Duration(minutes: 60)).toIso8601String(),
    });
    service = FeatureFlagsService(
      cache: cache,
      now: () => now,
      fetch: () async => throw const SocketException('offline'),
    );
    await service!.initialize(poll: false);
    await service!.refresh();
    expect(service!.isEnabled('ai_assistant'), true);
    expect(service!.isEnabled('community'), false);
  });

  test('ignores corrupt cache and malformed responses', () async {
    await cache.put('configuration', {'fetched_at': 'broken'});
    service = FeatureFlagsService(
      cache: cache,
      fetch: () async => {
        'flags': {'ai_assistant': 'false'},
      },
    );
    await service!.initialize(poll: false);
    await service!.refresh();
    expect(service!.isEnabled('ai_assistant'), true);
  });

  test('cannot switch off any crisis feature', () {
    final config = AppConfiguration.fromJson({
      'flags': {
        'crisis_hub': false,
        'breathing': false,
        'grounding': false,
        'safety_plan': false,
      },
    });
    for (final key in ['crisis_hub', 'breathing', 'grounding', 'safety_plan']) {
      expect(config.isEnabled(key), true);
    }
    expect(config.isEnabled('unknown'), false);
  });

  test('deduplicates concurrent refreshes', () async {
    final response = Completer<Map<String, dynamic>>();
    var calls = 0;
    service = FeatureFlagsService(
      cache: cache,
      fetch: () {
        calls++;
        return response.future;
      },
    );
    final first = service!.refresh();
    final second = service!.refresh();
    expect(calls, 1);
    response.complete(payload());
    await Future.wait([first, second]);
  });

  testWidgets(
    'refreshes every ten minutes while foregrounded and pauses in background',
    (tester) async {
      var calls = 0;
      service = FeatureFlagsService(
        fetch: () async {
          calls++;
          return payload();
        },
      );
      service!.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await tester.pump();
      final initial = calls;
      await tester.pump(const Duration(minutes: 10));
      expect(calls, greaterThan(initial));
      service!.didChangeAppLifecycleState(AppLifecycleState.paused);
      final paused = calls;
      await tester.pump(const Duration(minutes: 20));
      expect(calls, paused);
    },
  );

  testWidgets(
    'disabled assistant does not construct chat and reappears when enabled',
    (tester) async {
      var assistant = false;
      var built = 0;
      service = FeatureFlagsService(
        cache: cache,
        fetch: () async => payload(assistant: assistant),
      );
      await tester.runAsync(() => service!.refresh());
      await tester.pumpWidget(
        MaterialApp(
          home: FeatureGate(
            flags: service,
            feature: 'ai_assistant',
            builder: (_) {
              built++;
              return const Text('Chat content');
            },
          ),
        ),
      );
      expect(find.text('Assistant is temporarily unavailable'), findsOneWidget);
      expect(built, 0);
      assistant = true;
      await tester.runAsync(() => service!.refresh());
      await tester.pump();
      expect(find.text('Chat content'), findsOneWidget);
      expect(built, 1);
    },
  );

  testWidgets('hidden assistant preserves the other navigation indices', (
    tester,
  ) async {
    int? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: CustomBottomNavigationBar(
            currentIndex: 0,
            showAssistant: false,
            onTap: (index) => selected = index,
          ),
        ),
      ),
    );
    expect(find.text('Assistant'), findsNothing);
    await tester.tap(find.text('Community'));
    expect(selected, 3);
    await tester.tap(find.text('Settings'));
    expect(selected, 4);
  });
}
