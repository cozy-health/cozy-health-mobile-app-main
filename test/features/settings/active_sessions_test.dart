import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cozy_health/features/settings/data/session_repository.dart';
import 'package:cozy_health/features/settings/presentation/screens/active_sessions_screen.dart';

class Sessions extends Fake implements SessionRepository {
  bool failed = false;
  final revoked = <String>[];
  @override
  Future<List<Map<String, dynamic>>> list() async => [
    {
      'id': 1,
      'device': 'Real phone',
      'last_used': '2026-10-09',
      'is_current': true,
    },
    {
      'id': 2,
      'device': 'Real tablet',
      'last_used': '2026-10-08',
      'is_current': false,
    },
  ];
  @override
  Future<void> revoke(String id) async {
    if (failed) throw StateError('offline');
    revoked.add(id);
  }
}

void main() {
  testWidgets(
    'loads real sessions and revokes only after server confirmation',
    (tester) async {
      final repository = Sessions();
      await tester.pumpWidget(
        MaterialApp(home: ActiveSessionsScreen(repository: repository)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Real phone'), findsOneWidget);
      expect(find.text('This device'), findsOneWidget);
      await tester.tap(find.byTooltip('Revoke session'));
      await tester.pumpAndSettle();
      expect(repository.revoked, ['2']);
      expect(find.text('Real tablet'), findsNothing);
    },
  );
  testWidgets('failed revocation leaves session visible', (tester) async {
    final repository = Sessions()..failed = true;
    await tester.pumpWidget(
      MaterialApp(home: ActiveSessionsScreen(repository: repository)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Revoke session'));
    await tester.pumpAndSettle();
    expect(find.text('Real tablet'), findsOneWidget);
    expect(repository.revoked, isEmpty);
  });
}
