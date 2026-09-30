import 'package:flutter_test/flutter_test.dart';
import 'package:cozy_health/main.dart';

void main() {
  testWidgets('App initializes smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const CozyHealthApp());
    expect(find.byType(CozyHealthApp), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
  });
}
