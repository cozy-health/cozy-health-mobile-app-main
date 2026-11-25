import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';
import 'package:cozy_health/core/widgets/startup_motion.dart';
import 'package:cozy_health/core/widgets/startup_cover.dart';
import 'package:cozy_health/core/theme/app_theme.dart';

class FakeClipPlatform extends VideoPlayerPlatform {
  final events = StreamController<VideoEvent>.broadcast();
  bool disposed = false, failCreation = false;
  final disposedSignal = Completer<void>();
  int creates = 0, plays = 0, pauses = 0;
  double? volume;
  bool? looping;
  DataSource? source;
  @override
  Future<void> init() async {}
  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async {
    creates++;
    source = options.dataSource;
    if (failCreation) throw StateError('fixture decoder failure');
    return 1;
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) => events.stream;
  @override
  Future<void> dispose(int playerId) async {
    disposed = true;
    disposedSignal.complete();
  }

  @override
  Future<void> setLooping(int playerId, bool value) async {
    looping = value;
  }

  @override
  Future<void> setVolume(int playerId, double value) async {
    volume = value;
  }

  @override
  Future<void> play(int playerId) async {
    plays++;
  }

  @override
  Future<void> pause(int playerId) async {
    pauses++;
  }

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}
  @override
  Future<void> seekTo(int playerId, Duration position) async {}
  @override
  Future<Duration> getPosition(int playerId) async => Duration.zero;
  @override
  Future<void> setMixWithOthers(bool value) async {}
  @override
  Widget buildViewWithOptions(VideoViewOptions options) =>
      const SizedBox(key: ValueKey('clip-texture'));
}

void main() {
  late FakeClipPlatform platform;
  late VideoPlayerPlatform original;
  setUp(() {
    original = VideoPlayerPlatform.instance;
    platform = FakeClipPlatform();
    VideoPlayerPlatform.instance = platform;
  });
  tearDown(() async {
    VideoPlayerPlatform.instance = original;
    await platform.events.close();
  });
  Future<void> initialize(WidgetTester tester) async {
    await tester.pump();
    platform.events.add(
      VideoEvent(
        eventType: VideoEventType.initialized,
        duration: const Duration(seconds: 2),
        size: const Size(1080, 1920),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets(
    'local clip is silent, one-shot, pauses on background and disposes',
    (tester) async {
      var completed = 0;
      await tester.pumpWidget(
        MaterialApp(home: StartupMotion(onComplete: () => completed++)),
      );
      await initialize(tester);
      expect(platform.source?.asset, StartupMotion.asset);
      expect(platform.volume, 0);
      expect(platform.looping, isFalse);
      expect(platform.plays, 1);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(platform.pauses, greaterThan(0));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(platform.plays, 2);
      platform.events.add(VideoEvent(eventType: VideoEventType.completed));
      await tester.pump();
      await tester.pump();
      expect(completed, 1);
      await tester.pump(const Duration(seconds: 4));
      expect(completed, 1);
      expect(find.byKey(const ValueKey('clip-texture')), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.runAsync(
        () =>
            platform.disposedSignal.future.timeout(const Duration(seconds: 2)),
      );
      expect(platform.disposed, isTrue);
    },
  );
  testWidgets('decoder creation error falls back and releases readiness', (
    tester,
  ) async {
    platform.failCreation = true;
    var completed = 0;
    await tester.pumpWidget(
      MaterialApp(home: StartupMotion(onComplete: () => completed++)),
    );
    await tester.pump();
    await tester.pump();
    expect(completed, 1);
    expect(find.byType(Image), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'missing decoder initialization is bounded and late events cannot replay',
    (tester) async {
      var completed = 0;
      await tester.pumpWidget(
        MaterialApp(home: StartupMotion(onComplete: () => completed++)),
      );
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
      expect(completed, 1);
      await initialize(tester);
      expect(platform.plays, 0);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.runAsync(
        () =>
            platform.disposedSignal.future.timeout(const Duration(seconds: 2)),
      );
      expect(platform.disposed, isTrue);
    },
  );
  testWidgets('Reduce Motion never creates a video decoder', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: const StartupCover(child: SizedBox()),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(platform.creates, 0);
    expect(find.byType(StartupIcon), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
