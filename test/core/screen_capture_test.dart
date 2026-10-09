import 'package:cozy_health/core/services/screen_capture_service.dart';
import 'package:cozy_health/core/widgets/security_blur.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('test/cozy_capture');
  late ScreenCaptureService service;
  late List<bool> calls;
  var captured = false;
  final activeBlur = find.byWidgetPredicate(
    (widget) => widget is ImageFiltered && widget.enabled,
  );
  setUp(() {
    calls = [];
    captured = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call.arguments as bool);
          return captured;
        });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    channel.setMethodCallHandler(null);
  });

  testWidgets('capture changes obscure content and preserve interaction', (
    tester,
  ) async {
    service = ScreenCaptureService(channel: channel);
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: SecurityCaptureOverlay(
          service: service,
          child: SecurityBlur(
            service: service,
            child: Scaffold(
              body: Center(
                child: Column(
                  children: [
                    const TextField(),
                    TextButton(
                      onPressed: () => taps++,
                      child: const Text('Sensitive'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(activeBlur, findsNothing);
    await tester.enterText(find.byType(TextField), 'Unsaved journal text');
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      channel.name,
      const StandardMethodCodec().encodeMethodCall(
        const MethodCall('captureChanged', true),
      ),
      (_) {},
    );
    await tester.pumpAndSettle();
    expect(activeBlur, findsWidgets);
    expect(calls, [true]);
    await tester.tap(find.text('Sensitive'));
    expect(taps, 1);
    captured = false;
    service.refresh();
    await tester.pumpAndSettle();
    expect(activeBlur, findsNothing);
    expect(find.text('Unsaved journal text'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    expect(calls.last, false);
  });

  testWidgets('nested protection stays enabled until last screen leaves', (
    tester,
  ) async {
    service = ScreenCaptureService(channel: channel);
    service.acquire();
    service.acquire();
    await tester.pumpAndSettle();
    service.release();
    await tester.pumpAndSettle();
    expect(calls.last, true);
    service.release();
    await tester.pumpAndSettle();
    expect(calls.last, false);
  });

  testWidgets('capture already active at entry and resume is obscured', (
    tester,
  ) async {
    service = ScreenCaptureService(channel: channel);
    captured = true;
    await tester.pumpWidget(
      MaterialApp(
        home: SecurityBlur(
          service: service,
          child: const Scaffold(body: Text('Private journal')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(activeBlur, findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    captured = false;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(activeBlur, findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('native protection failure keeps content obscured', (
    tester,
  ) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async {
          throw PlatformException(code: 'capture_unavailable');
        });
    service = ScreenCaptureService(channel: channel);
    await tester.pumpWidget(
      MaterialApp(
        home: SecurityBlur(
          service: service,
          child: const Scaffold(body: Text('Sensitive content')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(activeBlur, findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    expect(service.shouldHide, false);
  });
}
