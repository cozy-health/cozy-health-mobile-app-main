import '../models/streak_progress.dart';
import '../services/local_db_service.dart';
import 'home_repository.dart';

/// Only confirmed server snapshots are persisted; projections stay provisional.
class StreakRepository {
  StreakRepository({
    HomeRepository? api,
    DateTime Function()? now,
    String? Function()? account,
  }) : _api = api ?? HomeRepository(),
       now = now ?? DateTime.now,
       _account = account ?? (() => LocalDbService().activeUserId);
  final HomeRepository _api;
  final DateTime Function() now;
  final String? Function() _account;

  StreakProgress _parse(Map<String, dynamic> json) {
    final result = StreakProgress.fromJson(json, receivedAt: now());
    final account = _account();
    if (account != null && result.accountId != account) {
      throw StateError('The streak belongs to a different account.');
    }
    return result;
  }

  Future<StreakProgress?> cached() async {
    final account = _account();
    final json = await _api.getCachedStreak();
    if (account != _account()) throw StateError('Account changed.');
    if (json == null) return null;
    try {
      return _parse(json);
    } catch (_) {
      return null;
    }
  }

  Future<StreakProgress> fetch() async {
    final account = _account();
    final json = await _api.fetchStreak();
    if (account != _account()) throw StateError('Account changed.');
    return _parse(json);
  }
}
