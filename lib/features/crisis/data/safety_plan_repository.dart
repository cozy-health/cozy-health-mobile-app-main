import 'package:flutter/foundation.dart';

import '../../../core/models/safety_plan.dart';
import '../../../core/services/local_db_service.dart';
import '../../../core/api/api_client.dart';
import '../../../core/services/user_data_merge.dart';

class SafetyPlanRepository {
  final LocalDbService _local = LocalDbService();

  Future<SafetyPlan?> fetchSafetyPlan() async {
    final scope = _local.boxName(LocalDbService.userSettingsBoxName);
    try {
      final response = await ApiClient.instance.get('/safety-plan');
      if (response.data['data'] != null) {
        await UserDataMerge().apply(
          'safety_plan',
          Map<String, dynamic>.from(response.data['data'] as Map),
          isActive: () =>
              scope == _local.boxName(LocalDbService.userSettingsBoxName),
        );
        return _local.getSafetyPlan();
      }
    } catch (_) {
      debugPrint('Caught error: details withheld.');
    }
    return _local.getSafetyPlan();
  }

  Stream<SafetyPlan?> watchSafetyPlan() {
    return _local.watchSafetyPlan();
  }

  Future<SafetyPlan> saveSafetyPlan(SafetyPlan plan) async {
    await _local.saveSafetyPlan(plan);
    await _local.enqueueSync(
      type: 'safety_plan',
      action: 'upsert',
      recordId: plan.id,
      payload: plan.toJson(),
    );
    _local.processSyncQueue();
    return plan;
  }

  Future<SafetyPlan?> getSafetyPlan() async {
    return _local.getSafetyPlan();
  }

  Future<void> clearSafetyPlan() async {
    final plan = _local.getSafetyPlan();
    await _local.clearSafetyPlan();
    if (plan != null) {
      await _local.enqueueSync(
        type: 'safety_plan',
        action: 'delete',
        recordId: plan.id,
        payload: null,
      );
      await _local.processSyncQueue();
    }
  }
}
