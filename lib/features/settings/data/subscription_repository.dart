import 'package:flutter/foundation.dart';
import '../../../core/models/subscription_status.dart';
import '../../../core/services/local_db_service.dart';
import '../../../core/api/api_client.dart';

class SubscriptionRepository {
  final LocalDbService _local = LocalDbService();
  Map<String, dynamic>? _extractMapData(dynamic data) {
    if (data is Map<String, dynamic>) {
      final nested = data['data'];
      if (nested is Map) return Map<String, dynamic>.from(nested);
      if (!data.containsKey('data')) return data;
    }
    debugPrint('Unexpected subscription response shape: ${data.runtimeType}');
    return null;
  }

  Future<SubscriptionStatus?> fetchSubscription() async {
    final owner = _local.activeUserId;
    final subscriptionBox = _local.subscriptionStatusBox;
    try {
      final response = await ApiClient.instance.get('/subscription');
      if (owner != _local.activeUserId) return null;
      final data = _extractMapData(response.data);
      if (data != null) {
        final sub = SubscriptionStatus.fromJson(data);
        // This is a current-status cache, not purchase history. A test grant
        // has its own ID; retaining the old first row would mask grant/revoke.
        await subscriptionBox.clear();
        if (owner != _local.activeUserId) return null;
        await subscriptionBox.put(sub.id, sub);
        return sub;
      }
    } catch (e) {
      debugPrint('Fetch subscription failed: details withheld.');
    }
    return owner == _local.activeUserId ? _local.getSubscriptionStatus() : null;
  }

  Stream<SubscriptionStatus?> watchSubscription() {
    return _local.watchSubscriptionStatus();
  }

  Future<bool> verifyReceipt(Map<String, dynamic> data) async {
    try {
      await ApiClient.instance.post('/subscription/verify-receipt', data: data);
      await fetchSubscription();
      return true;
    } catch (e) {
      debugPrint('Verify receipt failed: details withheld.');
      return false;
    }
  }

  Future<bool> restorePurchases() async {
    try {
      await ApiClient.instance.post('/subscription/restore');
      await fetchSubscription();
      return true;
    } catch (e) {
      debugPrint('Restore purchases failed: details withheld.');
      return false;
    }
  }

  Stream<SubscriptionStatus?> watchStatus() {
    return _local.watchSubscriptionStatus();
  }

  Future<SubscriptionStatus> purchase(String plan) async =>
      throw UnsupportedError('Purchasing is not available yet.');

  Future<void> cancel() async =>
      throw UnsupportedError('Subscription management is not available yet.');
}
