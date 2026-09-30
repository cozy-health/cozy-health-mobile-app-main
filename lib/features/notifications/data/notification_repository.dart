import 'package:flutter/foundation.dart';
import '../../../core/models/app_notification.dart';
import '../../../core/services/local_db_service.dart';
import '../../../core/api/api_client.dart';

class NotificationRepository {
  final LocalDbService _local = LocalDbService();

  Future<List<AppNotification>> fetchNotifications() async {
    try {
      final response = await ApiClient.instance.get('/notifications');
      final items = (response.data['data'] as List).map((json) => AppNotification.fromJson(json)).toList();
      for (final item in items) {
        await _local.saveAppNotification(item);
      }
      return items;
    } catch (e) {
      return _local.getAllAppNotifications();
    }
  }

  Stream<List<AppNotification>> watchNotifications() {
    return _local.watchAppNotifications();
  }

  Future<void> markAsRead(String id) async {
    try {
      await ApiClient.instance.patch('/notifications/$id/read');
      fetchNotifications();
    } catch(e) {}
  }

  Future<void> markAllAsRead() async {
    try {
      await ApiClient.instance.patch('/notifications/read-all');
      fetchNotifications();
    } catch(e) {}
  }

  Future<void> deleteNotification(String id) async {
    await _local.deleteAppNotification(id);
    await _local.enqueueSync(type: 'app_notification', action: 'delete', recordId: id, payload: null);
    _local.processSyncQueue();
  }
}
