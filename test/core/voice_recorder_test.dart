import 'dart:io';
import 'package:cozy_health/core/audio/audio_recorder_service.dart';
import 'package:cozy_health/core/audio/voice_audio.dart';
import 'package:cozy_health/core/audio/voice_recorder_popup.dart';
import 'package:cozy_health/core/permissions/permission_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:record/record.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cozy_health/core/storage/token_storage.dart';

class FakeRecorder extends Fake implements AudioRecorderService {
  FakeRecorder(this.path);
  final String path;
  int starts = 0, cancels = 0;
  @override
  Stream<Amplitude> get amplitudeStream => const Stream.empty();
  @override
  Future<void> start() async {
    starts++;
  }

  @override
  Future<String?> stop() async => path;
  @override
  Future<void> cancel() async {
    cancels++;
  }

  @override
  Future<void> dispose() async {}
}

void main() {
  Future<void> driveUntil(WidgetTester tester, bool Function() ready) async {
    for (var attempt = 0; attempt < 50 && !ready(); attempt++) {
      await tester.pump(const Duration(milliseconds: 20));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
    }
    expect(ready(), isTrue);
  }

  late Directory temporary;
  late FakeRecorder recorder;
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    temporary = await Directory.systemTemp.createTemp('voice-widget-');
    final file = await File(
      '${temporary.path}/voice.m4a',
    ).writeAsBytes([1, 2, 3]);
    recorder = FakeRecorder(file.path);
  });
  tearDown(() async {
    await temporary.delete(recursive: true);
  });

  Future<void> open(
    WidgetTester tester, {
    required bool journal,
    required Future<void> Function(RecordedAudio) confirm,
    bool denied = false,
    MicPermissionResult? permission,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: const Text('Conversation remains visible'),
          floatingActionButton: Builder(
            builder: (context) => FloatingActionButton(
              onPressed: () => showVoiceRecorder(
                context,
                journal: journal,
                recorder: recorder,
                requestMicrophone: () async =>
                    permission ??
                    (denied
                        ? MicPermissionResult.denied
                        : MicPermissionResult.granted),
                onConfirm: confirm,
              ),
              child: const Icon(Icons.mic),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.mic));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets(
    'compact recorder previews before sending and preserves failed sends for retry',
    (tester) async {
      var attempts = 0;
      await open(
        tester,
        journal: false,
        confirm: (audio) async {
          attempts++;
          if (attempts == 1) throw StateError('Offline');
        },
      );
      expect(find.text('Recording'), findsOneWidget);
      expect(find.text('Conversation remains visible'), findsOneWidget);
      final panel = find.byWidgetPredicate(
        (widget) => widget is Material && widget.elevation == 12,
      );
      expect(
        tester.getSize(panel).height,
        lessThan(tester.view.physicalSize.height * .6),
      );
      expect(attempts, 0);
      await tester.runAsync(() async {
        await tester.tap(find.byTooltip('Stop'));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await driveUntil(
        tester,
        () => find.text('Preview recording').evaluate().isNotEmpty,
      );
      await tester.pumpAndSettle();
      expect(find.text('Preview recording'), findsOneWidget);
      expect(attempts, 0);
      await tester.tap(find.byKey(const ValueKey('voice-confirm')));
      await tester.pumpAndSettle();
      expect(find.textContaining('ready to retry'), findsOneWidget);
      expect(await tester.runAsync(() => File(recorder.path).exists()), isTrue);
      await tester.tap(find.byKey(const ValueKey('voice-confirm')));
      await tester.pumpAndSettle();
      expect(attempts, 2);
      expect(find.text('Preview recording'), findsNothing);
    },
  );

  testWidgets('microphone denial explains access and never starts recording', (
    tester,
  ) async {
    await open(tester, journal: true, denied: true, confirm: (_) async {});
    expect(recorder.starts, 0);
    expect(find.text('Microphone access is needed to record.'), findsOneWidget);
    await tester.ensureVisible(find.byTooltip('Discard recording'));
    await tester.tap(find.byTooltip('Discard recording'));
    await driveUntil(tester, () => recorder.cancels == 1);
    await tester.pumpAndSettle();
  });

  testWidgets('cancel stops capture without saving', (tester) async {
    var saved = false;
    await open(
      tester,
      journal: true,
      confirm: (_) async {
        saved = true;
      },
    );
    await tester.ensureVisible(find.byTooltip('Discard recording'));
    await tester.tap(find.byTooltip('Discard recording'));
    await tester.pump();
    expect(
      find.text('Discard this recording? It has not been saved.'),
      findsOneWidget,
    );
    expect(recorder.cancels, 0);
    await tester.ensureVisible(
      find.byKey(const ValueKey('voice-discard-confirm')),
    );
    await tester.tap(find.byKey(const ValueKey('voice-discard-confirm')));
    await driveUntil(tester, () => recorder.cancels == 1);
    await tester.pumpAndSettle();
    expect(recorder.cancels, 1);
    expect(saved, isFalse);
  });
  testWidgets(
    'device restrictions explain why microphone access cannot be requested',
    (tester) async {
      await open(
        tester,
        journal: true,
        permission: MicPermissionResult.restricted,
        confirm: (_) async {},
      );
      expect(recorder.starts, 0);
      expect(
        find.text(
          'Microphone access is restricted by your device settings or administrator.',
        ),
        findsOneWidget,
      );
      await tester.ensureVisible(find.byTooltip('Discard recording'));
      await tester.tap(find.byTooltip('Discard recording'));
      await driveUntil(tester, () => recorder.cancels == 1);
      await tester.pumpAndSettle();
    },
  );

  testWidgets('account replacement closes and cancels the previous recording', (
    tester,
  ) async {
    var saved = false;
    await open(tester, journal: true, confirm: (_) async => saved = true);
    expect(find.text('Recording'), findsOneWidget);
    await TokenStorage().saveToken('different-account', stayLoggedIn: false);
    await tester.pumpAndSettle();
    expect(find.text('Voice journal'), findsNothing);
    expect(recorder.cancels, greaterThanOrEqualTo(1));
    expect(saved, isFalse);
  });
}
