import 'package:cozy_health/core/models/app_notification.dart';
import 'package:cozy_health/core/services/local_db_service.dart';
import 'package:cozy_health/features/notifications/data/notification_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cozy_health/core/storage/encrypted_hive.dart';

import '../../support/repository_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final fixture = RepositoryFixture<AppNotification>(
    LocalDbService.appNotificationBoxName,
    AppNotificationAdapter(),
  );
  final repository = NotificationRepository();
  setUpAll(() async {
    await fixture.open();
    await EncryptedHive.openBox<String>(LocalDbService.syncQueueBoxName);
  });
  setUp(() async {
    await fixture.reset();
    await LocalDbService().syncQueueBox.clear();
    LocalDbService().syncPaused = false;
  });
  tearDownAll(fixture.close);

  for (final shape in ['paginator', 'raw list', 'data list']) {
    test(
      'fetchNotifications parses $shape and caches the returned records',
      () async {
        final count = shape == 'raw list' ? 2 : 3;
        final items = List.generate(
          count,
          (index) => <String, dynamic>{
            'id': '$shape-$index',
            'mood': 'good',
            'intensity': 5,
            'title': 'Record $index',
            'quiz_slug': 'wellbeing',
            'quiz_title': 'Wellbeing',
            'client_created_at': '2026-10-07T12:00:00Z',
            'client_updated_at': '2026-10-07T12:00:00Z',
          },
        );
        fixture.body = switch (shape) {
          'paginator' => {
            'data': {'data': items, 'current_page': 1, 'last_page': 1},
          },
          'data list' => {'data': items},
          _ => items,
        };

        final result = await repository.fetchNotifications();
        expect(result.map((item) => item.id), items.map((item) => item['id']));
        expect(result, hasLength(count));
        expect(fixture.box.length, count);
        expect(fixture.requests, hasLength(1));
        expect(fixture.requests.single.path, '/api/v1/notifications');
      },
    );
  }

  test(
    'read state is retained in the queue when an upload is not acknowledged',
    () async {
      final local = LocalDbService();
      final item = AppNotification(
        id: 'notification',
        title: 'Synthetic',
        body: 'Synthetic',
        type: 'system',
        read: false,
        createdAt: DateTime.utc(2026, 10, 10),
      );
      await local.saveAppNotification(item);
      await repository.markAsRead(item.id);
      expect(local.getAllAppNotifications().single.read, isTrue);
      expect(local.pendingItems.single.payload!['is_read'], isTrue);
      expect(fixture.requests.single.path, '/api/v1/sync/batch');
      fixture.body = {
        'data': {
          'results': [
            {
              'client_operation_id': local.pendingItems.single.id,
              'success': true,
            },
          ],
        },
      };
      await local.processSyncQueue(force: true);
      expect(local.pendingItems, isEmpty);
    },
  );

  test('mark all read queues every unread record before any upload', () async {
    final local = LocalDbService();
    local.syncPaused = true;
    for (final id in ['one', 'two']) {
      await local.saveAppNotification(
        AppNotification(
          id: id,
          title: 'Synthetic',
          body: 'Synthetic',
          type: 'system',
          read: false,
          createdAt: DateTime.utc(2026, 10, 10),
        ),
      );
    }
    await repository.markAllAsRead();
    expect(local.pendingItems.length, 2);
    expect(
      local.pendingItems.every((item) => item.payload!['is_read'] == true),
      isTrue,
    );
    expect(fixture.requests, isEmpty);
    local.syncPaused = false;
  });

  test(
    'read timestamp and deep link survive encrypted cache reopening',
    () async {
      final readAt = DateTime.utc(2026, 10, 10, 12);
      await fixture.box.put(
        'notification',
        AppNotification(
          id: 'notification',
          title: 'Synthetic',
          body: 'Synthetic',
          type: 'system',
          read: true,
          createdAt: DateTime.utc(2026, 10, 9),
          readAt: readAt,
          deepLink: '/notifications',
        ),
      );
      await fixture.box.close();
      fixture.box = await EncryptedHive.openBox<AppNotification>(
        LocalDbService.appNotificationBoxName,
      );
      expect(fixture.box.get('notification')!.readAt, readAt);
      expect(fixture.box.get('notification')!.deepLink, '/notifications');
    },
  );
}
