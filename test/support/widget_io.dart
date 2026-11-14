import 'package:flutter_test/flutter_test.dart';

/// Allow real storage/network-adapter futures to complete before asserting UI.
/// Fake-clock settling alone cannot complete an outstanding filesystem call.
Future<void> pumpUntilVisible(
  WidgetTester tester,
  Finder expected, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final elapsed = Stopwatch()..start();
  while (expected.evaluate().isEmpty && elapsed.elapsed < timeout) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 16));
  }
  expect(
    expected,
    findsOneWidget,
    reason: 'Expected UI after real I/O completes',
  );
}
