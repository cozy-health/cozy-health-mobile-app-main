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
    } catch (e) {
      debugPrint('Fetch subscription failed: $e');
    }
    return _local.getSubscriptionStatus();
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
      debugPrint('Verify receipt failed: $e');
      return false;
    }
  }

  Future<bool> restorePurchases() async {
    try {
      await ApiClient.instance.post('/subscription/restore');
      await fetchSubscription();
      return true;
    } catch (e) {
      debugPrint('Restore purchases failed: $e');
      return false;
    }
  }
  
  Stream<SubscriptionStatus?> watchStatus() {
    return _local.watchSubscriptionStatus();
  }

  Future<SubscriptionStatus> purchase(String plan) async {
    final current = await _local.getSubscriptionStatus();
    final updated = (current ?? SubscriptionStatus(
      id: 'sub_${DateTime.now().millisecondsSinceEpoch}',
      isActive: false,
      tier: 'free',
      cancelAtPeriodEnd: false,
    )).copyWith(
      tier: plan,
      isActive: true,
      expiresAt: DateTime.now().add(const Duration(days: 30)).toUtc(),
      cancelAtPeriodEnd: false,
    );
    
    await _local.saveSubscriptionStatus(updated);
    await _local.enqueueSync(
      type: 'subscription',
      action: 'upsert',
      recordId: updated.id,
      payload: updated.toJson(),
    );
    _local.processSyncQueue();
    
    return updated;
  }

  Future<void> cancel() async {
    final current = await _local.getSubscriptionStatus();
    if (current != null) {
      final updated = current.copyWith(
        isActive: false,
        cancelAtPeriodEnd: true,
      );
      await _local.saveSubscriptionStatus(updated);
      await _local.enqueueSync(
        type: 'subscription',
        action: 'cancel',
        recordId: updated.id,
        payload: updated.toJson(),
      );
      _local.processSyncQueue();
    }
  }
}
