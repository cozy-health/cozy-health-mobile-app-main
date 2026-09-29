import 'package:flutter/foundation.dart';
import '../../../core/models/subscription_status.dart';
import '../../../core/services/local_db_service.dart';
import '../../../core/api/api_client.dart';

class SubscriptionRepository {
  final LocalDbService _local = LocalDbService();

  Future<SubscriptionStatus?> fetchSubscription() async {
    try {
      final response = await ApiClient.instance.get('/subscription');
      if (response.data['data'] != null) {
        final sub = SubscriptionStatus.fromJson(response.data['data']);
        await _local.saveSubscriptionStatus(sub);
        return sub;
      }
    } catch (e) {}
    return _local.getSubscriptionStatus();
  }

  Stream<SubscriptionStatus?> watchSubscription() {
    return _local.watchSubscriptionStatus();
  }

  Future<void> verifyReceipt(Map<String, dynamic> data) async {
    try {
      await ApiClient.instance.post('/subscription/verify-receipt', data: data);
      fetchSubscription();
    } catch (e) {}
  }

  Future<void> restorePurchases() async {
    try {
      await ApiClient.instance.post('/subscription/restore');
      fetchSubscription();
    } catch (e) {}
  }
}