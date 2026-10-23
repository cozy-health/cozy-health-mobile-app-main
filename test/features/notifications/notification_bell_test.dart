import 'dart:async';
import 'package:cozy_health/core/models/app_notification.dart';
import 'package:cozy_health/core/routing/app_router.dart';
import 'package:cozy_health/features/notifications/presentation/widgets/notification_bell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('both bells share unread updates and open the same inbox', (
    tester,
  ) async {
    final changes = StreamController<List<AppNotification>>.broadcast();
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => Scaffold(
            body: Row(
              children: [
                NotificationBell(notifications: changes.stream),
                NotificationBell(notifications: changes.stream),
              ],
            ),
          ),
        ),
        GoRoute(
          path: AppRouter.notifications,
          builder: (_, __) => const Scaffold(body: Text('Shared inbox')),
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    final unread = AppNotification(
      id: 'notice',
      title: 'Reply',
      body: 'Community reply',
      type: 'community',
      read: false,
      createdAt: DateTime.utc(2026),
    );
    changes.add([unread]);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('notification-unread-dot')),
      findsNWidgets(2),
    );
    changes.add([unread.copyWith(read: true)]);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('notification-unread-dot')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('notification-bell')).last);
    await tester.pumpAndSettle();
    expect(find.text('Shared inbox'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    await changes.close();
  });
}
