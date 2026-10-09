import 'package:flutter/foundation.dart';
import '../../../core/models/app_notification.dart';
import '../../../core/services/local_db_service.dart';
import '../../../core/api/api_client.dart';

class NotificationRepository {
  final LocalDbService _local = LocalDbService();

  List<dynamic> _extractListData(dynamic data) {
    if (data is List) return data;
    if (data is Map && data['data'] is List) {
      return data['data'] as List;
    }
    if (data is Map && data['data'] is Map) {
      final nested = data['data'] as Map;
      if (nested['data'] is List) return nested['data'] as List;
    }
    debugPrint('Unexpected notifications response shape: ${data.runtimeType}');
    return const [];
  }

  Future<List<AppNotification>> fetchNotifications() async {
    try {
      final response = await ApiClient.instance.get('/notifications');
      final items = _extractListData(response.data)
          .whereType<Map>()
          .map(
            (json) => AppNotification.fromJson(Map<String, dynamic>.from(json)),
          )
          .toList();
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
    } catch (_) {
      debugPrint('Caught error: details withheld.');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await ApiClient.instance.patch('/notifications/read-all');
      fetchNotifications();
    } catch (_) {
      debugPrint('Caught error: details withheld.');
    }
  }

  Future<void> deleteNotification(String id) async {
    await _local.deleteAppNotification(id);
    await _local.enqueueSync(
      type: 'app_notification',
      action: 'delete',
      recordId: id,
      payload: null,
    );
    _local.processSyncQueue();
  }
}
