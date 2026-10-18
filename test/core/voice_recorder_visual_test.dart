import 'dart:io';
import 'dart:ui' as ui;
import 'package:cozy_health/core/audio/audio_recorder_service.dart';
import 'package:cozy_health/core/audio/voice_audio.dart';
import 'package:cozy_health/core/audio/voice_recorder_popup.dart';
import 'package:cozy_health/core/permissions/permission_service.dart';
import 'package:cozy_health/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:record/record.dart';
import '../support/local_fonts.dart';

class _VisualRecorder extends Fake implements AudioRecorderService {
  _VisualRecorder(this.path);
  final String path;
  @override
  Stream<Amplitude> get amplitudeStream => Stream.fromIterable(
    List.generate(
      96,
      (i) => Amplitude(current: -42 + (i * 13 % 36).toDouble(), max: -6),
    ),
  );
  @override
  Future<void> start() async {}
  @override
  Future<String?> stop() async => path;
  @override
  Future<void> cancel() async {}
  @override
  Future<void> dispose() async {}
}

void main() {
  const screenshots = bool.fromEnvironment('VOICE_UI_SCREENSHOTS');
  setUpAll(() => installLocalTestFonts(useRealFonts: screenshots));
  tearDownAll(resetLocalTestFonts);
  late Directory folder;
  late File file;
  setUp(() async {
    folder = await Directory.systemTemp.createTemp('voice-visual-');
    file = await File('${folder.path}/voice.m4a').writeAsBytes([1, 2, 3]);
  });
  tearDown(() async {
    await folder.delete(recursive: true);
  });
  for (final dark in [false, true]) {
    testWidgets(
      'voice card fits mobile and keeps privacy detail optional (${dark ? 'dark' : 'light'})',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final boundary = GlobalKey();
        Future<void> capture(String state) async {
          if (!screenshots) return;
          final oldShadows = debugDisableShadows;
          debugDisableShadows = false;
          try {
            await tester.pumpAndSettle();
            final render =
                boundary.currentContext?.findRenderObject()
                    as RenderRepaintBoundary;
            await tester.runAsync(() async {
              final image = await render
                  .toImage(pixelRatio: 1)
                  .timeout(const Duration(seconds: 15));
              final data = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              final output = Directory('build/voice-ui');
              await output.create(recursive: true);
              if (data != null) {
                await File(
                  '${output.path}/$state-${dark ? 'dark' : 'light'}.png',
                ).writeAsBytes(data.buffer.asUint8List());
              }
              image.dispose();
            });
          } finally {
            debugDisableShadows = oldShadows;
            await tester.pump();
          }
        }

        await tester.pumpWidget(
          RepaintBoundary(
            key: boundary,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: dark ? AppTheme.dark : AppTheme.light,
              home: Scaffold(
                appBar: AppBar(title: const Text('Journal')),
                body: const Center(child: Text('A moment for you.')),
                floatingActionButton: Builder(
                  builder: (context) => FloatingActionButton(
                    onPressed: () => showVoiceRecorder(
                      context,
                      journal: true,
                      recorder: _VisualRecorder(file.path),
                      requestMicrophone: () async =>
                          MicPermissionResult.granted,
                      onConfirm: (RecordedAudio audio) async {},
                    ),
                    child: const Icon(Icons.mic),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.byIcon(Icons.mic));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.text('Voice journal'), findsOneWidget);
        expect(find.textContaining('Offline recordings'), findsNothing);
        final card = find.byWidgetPredicate(
          (widget) => widget is Material && widget.elevation == 12,
        );
        final bounds = tester.getRect(card);
        expect(bounds.left, greaterThanOrEqualTo(16));
        expect(bounds.right, lessThanOrEqualTo(374));
        expect(bounds.height, lessThan(400));
        await capture('recording');
        await tester.tap(find.byTooltip('How is this saved?'));
        // The live recording timer keeps scheduling frames. Wait for the
        // interaction rather than requiring an intentionally live UI to settle.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.textContaining('Offline recordings'), findsOneWidget);
        await tester.tap(find.byTooltip('How is this saved?'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await tester.runAsync(() async {
          await tester.tap(find.byTooltip('Stop'));
          await Future<void>.delayed(const Duration(milliseconds: 100));
        });
        await tester.pumpAndSettle();
        expect(find.text('Preview recording'), findsOneWidget);
        await capture('preview');
        expect(tester.takeException(), isNull);
        await tester.tap(find.byTooltip('Discard recording'));
        await tester.pumpAndSettle();
      },
    );
  }
}
