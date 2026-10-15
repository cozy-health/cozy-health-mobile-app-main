import 'package:cozy_health/features/crisis/services/crisis_launcher.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('plugins.flutter.io/url_launcher');
  final launches = <String>[];
  bool succeeds = true;
  setUp(() {
    launches.clear();
    succeeds = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'canLaunch') return true;
          if (call.method == 'launch') {
            launches.add((call.arguments as Map)['url'] as String);
            return succeeds;
          }
          return null;
        });
  });
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );

  test('SMS preserves recipient and encodes the reviewed message', () async {
    const body = 'Call me & check in + please?\nThank you.';
    expect(
      await const CrisisLauncher().sendSms('+234 803 123 4567', body: body),
      LaunchResult.success,
    );
    final uri = Uri.parse(launches.single);
    expect(uri.scheme, 'sms');
    expect(uri.path, '+2348031234567');
    expect(uri.queryParameters['body'], body);
    expect(launches.single, contains('%20'));
  });

  test('failed SMS never falls back to an empty composer', () async {
    succeeds = false;
    expect(
      await const CrisisLauncher().sendSms(
        '+2348031234567',
        body: 'Keep this request',
      ),
      LaunchResult.unknown,
    );
    expect(launches, hasLength(1));
    expect(
      Uri.parse(launches.single).queryParameters['body'],
      'Keep this request',
    );
  });

  test('invalid numbers never launch another app', () async {
    expect(
      await const CrisisLauncher().callPhone('not a number'),
      LaunchResult.invalidNumber,
    );
    expect(launches, isEmpty);
  });
}
