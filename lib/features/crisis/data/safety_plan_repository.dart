import 'package:flutter/foundation.dart';

import '../../../core/models/safety_plan.dart';
import '../../../core/services/local_db_service.dart';
import '../../../core/api/api_client.dart';
import '../../../core/services/user_data_merge.dart';

class SafetyPlanRepository {
  final LocalDbService _local = LocalDbService();

  Future<SafetyPlan?> fetchSafetyPlan() async {
    final scope = _local.boxName(LocalDbService.userSettingsBoxName);
    bool active() =>
        scope == _local.boxName(LocalDbService.userSettingsBoxName);
    try {
      final response = await ApiClient.instance.get('/safety-plan');
      if (!active()) return null;
      if (response.data['data'] != null) {
        await UserDataMerge().apply(
          'safety_plan',
          Map<String, dynamic>.from(response.data['data'] as Map),
          isActive: () =>
              scope == _local.boxName(LocalDbService.userSettingsBoxName),
        );
        if (!active()) return null;
        return _local.getSafetyPlan();
      }
    } catch (_) {
      debugPrint('Caught error: details withheld.');
    }
    if (!active()) return null;
    return _local.getSafetyPlan();
  }

  Stream<SafetyPlan?> watchSafetyPlan() {
    return _local.watchSafetyPlan();
  }

  Future<SafetyPlan> saveSafetyPlan(SafetyPlan plan) async {
    final operationOwner = _local.activeUserId;
    await _local.saveSafetyPlan(plan);
    if (operationOwner != _local.activeUserId) {
      throw StateError('Account changed');
    }
    await _local.enqueueSync(
      type: 'safety_plan',
      action: 'upsert',
      recordId: plan.id,
      payload: plan.toJson(),
    );
    if (operationOwner != _local.activeUserId) {
      throw StateError('Account changed');
    }
    _local.processSyncQueue();
    return plan;
  }

  Future<SafetyPlan?> getSafetyPlan() async {
    return _local.getSafetyPlan();
  }

  Future<void> clearSafetyPlan() async {
    final operationOwner = _local.activeUserId;
    final plan = _local.getSafetyPlan();
    await _local.clearSafetyPlan();
    if (operationOwner != _local.activeUserId) {
      throw StateError('Account changed');
    }
    if (plan != null) {
      await _local.enqueueSync(
        type: 'safety_plan',
        action: 'delete',
        recordId: plan.id,
        payload: null,
      );
      if (operationOwner != _local.activeUserId) {
        throw StateError('Account changed');
      }
      await _local.processSyncQueue();
      if (operationOwner != _local.activeUserId) {
        throw StateError('Account changed');
      }
    }
  }
}
