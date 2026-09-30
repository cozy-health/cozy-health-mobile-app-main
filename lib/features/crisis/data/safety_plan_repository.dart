import 'package:flutter/foundation.dart';
import '../../../core/models/safety_plan.dart';
import '../../../core/services/local_db_service.dart';
import '../../../core/api/api_client.dart';

class SafetyPlanRepository {
  final LocalDbService _local = LocalDbService();

  Future<SafetyPlan?> fetchSafetyPlan() async {
    try {
      final response = await ApiClient.instance.get('/safety-plan');
      if (response.data['data'] != null) {
        final plan = SafetyPlan.fromJson(response.data['data']);
        await _local.saveSafetyPlan(plan);
        return plan;
      }
    } catch (e) {
    }
    return _local.getSafetyPlan();
  }
  
  Stream<SafetyPlan?> watchSafetyPlan() {
    return _local.watchSafetyPlan();
  }

  Future<SafetyPlan> saveSafetyPlan(SafetyPlan plan) async {
    await _local.saveSafetyPlan(plan);
    await _local.enqueueSync(type: 'safety_plan', action: 'upsert', recordId: plan.id, payload: plan.toJson());
    try {
      await ApiClient.instance.put('/safety-plan', data: plan.toJson());
    } catch(e) {}
    return plan;
  }

  Future<SafetyPlan?> getSafetyPlan() async {
    return _local.getSafetyPlan();
  }

  Future<void> clearSafetyPlan() async {
    await _local.clearSafetyPlan();
  }
}