import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/models/safety_plan.dart';
import '../../../core/services/local_db_service.dart';
import '../data/safety_plan_repository.dart';

class SafetyPlanStorage {
  final SafetyPlanRepository _repo = SafetyPlanRepository();
  Timer? _debounce;
  Completer<void>? _pendingSave;
  final _owner = LocalDbService().activeUserId;
  bool _disposed = false;
  bool get _active => !_disposed && _owner == LocalDbService().activeUserId;

  Future<void> save(SafetyPlan plan, {bool debounce = false}) async {
    if (!_active) return;
    if (debounce) {
      _debounce?.cancel();
      final pending = _pendingSave;
      if (pending != null && !pending.isCompleted) {
        pending.complete();
      }
      final completer = _pendingSave = Completer<void>();
      _debounce = Timer(const Duration(milliseconds: 500), () async {
        try {
          await _saveNow(plan);
        } finally {
          if (!completer.isCompleted) {
            completer.complete();
          }
        }
      });
      return completer.future;
    }

    await _saveNow(plan);
  }

  Future<void> _saveNow(SafetyPlan plan) async {
    if (!_active) return;
    try {
      await _repo.saveSafetyPlan(plan);
    } catch (error) {
      // handled in repo
    }
  }

  Future<SafetyPlan?> load() async {
    if (!_active) return null;
    try {
      final plan = await _repo.getSafetyPlan();
      return _active ? plan : null;
    } catch (error) {
      return null;
    }
  }

  Future<void> clear() async {
    if (!_active) return;
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
    _disposed = true;
    _debounce?.cancel();
    final pending = _pendingSave;
    if (pending != null && !pending.isCompleted) {
      pending.complete();
    }
  }
}
