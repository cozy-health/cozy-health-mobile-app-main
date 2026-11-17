import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cozy_health/core/services/device_integrity_service.dart';
import 'package:cozy_health/core/widgets/device_integrity_notice.dart';

void main() {
  testWidgets('root warning is dismissible and content remains usable', (
    tester,
  ) async {
    var counts = 0;
    final service = DeviceIntegrityService(
      detect: () async => true,
      report: () async {
        counts++;
      },
    );
    await tester.pumpWidget(
      MaterialApp(
        home: DeviceIntegrityNotice(
          service: service,
          child: const Scaffold(body: Text('App content')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('App content'), findsOneWidget);
    expect(find.text('Dismiss'), findsOneWidget);
    expect(counts, 1);
    await tester.tap(find.text('Dismiss'));
    await tester.pumpAndSettle();
    expect(find.text('App content'), findsOneWidget);
    expect(find.text('Dismiss'), findsNothing);
    await service.check();
    expect(counts, 1);
  });
  test('unsupported detection or plugin error never blocks use', () async {
    final service = DeviceIntegrityService(
      detect: () async => throw StateError('unavailable'),
      report: () async {},
    );
    await service.check();
    expect(service.warning, false);
  });
}
