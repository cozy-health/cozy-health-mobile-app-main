import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/mood_entry.dart';
import '../models/streak_progress.dart';
import '../models/sync_summary.dart';
import '../repositories/mood_repository.dart';
import '../repositories/streak_repository.dart';
import 'local_db_service.dart';
import '../storage/token_storage.dart';

class StreakController extends ChangeNotifier {
  StreakController({
    StreakRepository? repository,
    DateTime Function()? now,
    List<MoodEntry> Function()? localMoods,
    Stream<List<MoodEntry>>? moodChanges,
    Stream<void>? accountChanges,
    Stream<SyncSummary>? syncResults,
    Stream<void>? sessionClearing,
    Stream<void>? sessionChanges,
    this.tick = true,
  }) : _repository = repository ?? StreakRepository(),
       now = now ?? DateTime.now,
       _localMoods = localMoods ?? (() => MoodRepository().currentEntries()),
       _moodChanges = moodChanges ?? MoodRepository().watchMoodEntries(),
       _accountChanges = accountChanges ?? LocalDbService().accountChanges,
       _syncResults = syncResults ?? LocalDbService().syncResults,
       _sessionClearing = sessionClearing ?? TokenStorage.sessionClearing,
       _sessionChanges = sessionChanges ?? TokenStorage.sessionChanges;

  final StreakRepository _repository;
  final DateTime Function() now;
  final List<MoodEntry> Function() _localMoods;
  final Stream<List<MoodEntry>> _moodChanges;
  final Stream<void> _accountChanges;
  final Stream<SyncSummary> _syncResults;
  final Stream<void> _sessionClearing, _sessionChanges;
  final bool tick;
  StreakProgress? _confirmed;
  StreakProgress? progress;
  bool loading = false, offline = false;
  bool _disposed = false, _started = false;
  int _revision = 0;
  Timer? _timer;
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  void start() {
    if (_started) return;
    _started = true;
    _subscriptions.add(_moodChanges.listen((_) => _project()));
    _subscriptions.add(
      _accountChanges.listen((_) {
        _invalidate();
        unawaited(refresh());
      }),
    );
    _subscriptions.add(_sessionClearing.listen((_) => _invalidate()));
    _subscriptions.add(
      _sessionChanges.listen((_) {
        _invalidate();
        unawaited(refresh());
      }),
    );
    _subscriptions.add(
      _syncResults.listen((result) {
        if (result.synced > 0) unawaited(refresh());
      }),
    );
    unawaited(refresh());
  }

  void _invalidate() {
    if (_disposed) return;
    _revision++;
    _timer?.cancel();
    _confirmed = progress = null;
    loading = offline = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    if (_disposed) return;
    final revision = ++_revision;
    loading = true;
    notifyListeners();
    try {
      final cached = await _repository.cached();
      if (_disposed || revision != _revision) return;
      _confirmed = cached;
      _project();
      final fresh = await _repository.fetch();
      if (_disposed || revision != _revision) return;
      _confirmed = fresh;
      offline = false;
    } catch (_) {
      if (_disposed || revision != _revision) return;
      offline = true;
    } finally {
      if (!_disposed && revision == _revision) {
        loading = false;
        _project();
      }
    }
  }

  void _project() {
    if (_disposed) return;
    progress = _confirmed?.project(now(), _localMoods());
    _timer?.cancel();
    if (tick && _confirmed != null) {
      // Reproject promptly at account-local midnight; resume also refreshes.
      _timer = Timer(_confirmed!.untilNextDay(now()), _project);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _revision++;
    _timer?.cancel();
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    super.dispose();
  }
}
