import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/models/safety_plan.dart';
import '../data/safety_plan_repository.dart';

class SafetyPlanStorage {
  final SafetyPlanRepository _repo = SafetyPlanRepository();
  Timer? _debounce;

  Future<void> save(SafetyPlan plan, {bool debounce = false}) async {
    if (debounce) {
      _debounce?.cancel();
      final completer = Completer<void>();
      _debounce = Timer(const Duration(milliseconds: 500), () async {
        await _saveNow(plan);
        completer.complete();
      });
      return completer.future;
    }

    await _saveNow(plan);
  }

  Future<void> _saveNow(SafetyPlan plan) async {
    try {
      await _repo.saveSafetyPlan(plan);
    } catch (error) {
      // handled in repo
    }
  }

  Future<SafetyPlan?> load() async {
    try {
      return await _repo.getSafetyPlan();
    } catch (error) {
      return null;
    }
  }

  Future<void> clear() async {
    try {
      await _repo.clearSafetyPlan();
    } catch (_) {
      debugPrint('Caught error: details withheld.');
    }
  }

  Future<bool> hasPlan() async {
    final plan = await load();
    return plan != null;
  }

  void dispose() {
    _debounce?.cancel();
  }
}
