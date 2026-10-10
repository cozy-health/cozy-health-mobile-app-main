import '../../../core/data/demo_mode.dart';
import 'package:flutter/foundation.dart';
import '../../../core/models/app_notification.dart';
import '../../../core/services/local_db_service.dart';
import '../../../core/api/api_client.dart';
import '../../../core/services/user_data_merge.dart';

class NotificationRepository {
  NotificationRepository({bool? usePlaceholderData})
    : _placeholderOverride = usePlaceholderData;
  final bool? _placeholderOverride;
  bool get usePlaceholderData =>
      _placeholderOverride ?? DemoMode.instance.enabled;
  List<AppNotification> currentEntries() => usePlaceholderData
      ? List.of(DemoMode.instance.notifications)
      : _local.getAllAppNotifications();
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
    if (usePlaceholderData) return currentEntries();
    final scope = _local.boxName(LocalDbService.userSettingsBoxName);
    try {
      final response = await ApiClient.instance.get('/notifications');
      for (final raw in _extractListData(response.data).whereType<Map>()) {
        await UserDataMerge().apply(
          'app_notification',
          Map<String, dynamic>.from(raw),
          isActive: () =>
              scope == _local.boxName(LocalDbService.userSettingsBoxName),
        );
      }
      return _local.getAllAppNotifications();
    } catch (e) {
      return _local.getAllAppNotifications();
    }
  }

  Stream<List<AppNotification>> watchNotifications() {
    return DemoMode.instance.selectStream(
      useDemo: () => usePlaceholderData,
      real: _local.watchAppNotifications,
      demo: () => DemoMode.instance.notifications,
    );
  }

  Future<void> markAsRead(String id) async {
    if (usePlaceholderData) {
      final items = DemoMode.instance.notifications;
      final index = items.indexWhere((item) => item.id == id);
      if (index >= 0) {
        items[index] = items[index].copyWith(
          read: true,
          readAt: DateTime.now(),
        );
      }
      DemoMode.instance.changed();
      return;
    }
    final item = currentEntries().where((item) => item.id == id).firstOrNull;
    if (item != null) {
      final updated = item.copyWith(read: true, readAt: DateTime.now());
      await _local.saveAppNotification(updated);
      await _local.enqueueSync(
        type: 'app_notification',
        action: 'upsert',
        recordId: updated.id,
        payload: updated.toJson(),
      );
      await _local.processSyncQueue();
      return;
    }
    try {
      await ApiClient.instance.patch('/notifications/$id/read');
      fetchNotifications();
    } catch (_) {
      debugPrint('Caught error: details withheld.');
    }
  }

  Future<void> markAllAsRead() async {
    if (usePlaceholderData) {
      final items = DemoMode.instance.notifications;
      for (var i = 0; i < items.length; i++) {
        items[i] = items[i].copyWith(read: true, readAt: DateTime.now());
      }
      DemoMode.instance.changed();
      return;
    }
    for (final item in currentEntries().where((item) => !item.read)) {
      final updated = item.copyWith(read: true, readAt: DateTime.now());
      await _local.saveAppNotification(updated);
      await _local.enqueueSync(
        type: 'app_notification',
        action: 'upsert',
        recordId: updated.id,
        payload: updated.toJson(),
      );
    }
    await _local.processSyncQueue();
  }

  Future<void> deleteNotification(String id) async {
    if (usePlaceholderData) {
      DemoMode.instance.notifications.removeWhere((entry) => entry.id == id);
      DemoMode.instance.changed();
      return;
    }
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
