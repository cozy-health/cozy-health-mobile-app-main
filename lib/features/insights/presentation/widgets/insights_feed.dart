import 'package:flutter/material.dart';
import '../../../../core/repositories/insights_repository.dart';
import '../../../../core/api/auth_token_service.dart';

/// Keeps each screen's existing layout while handling cached-first refreshes.
class InsightsFeed extends ChangeNotifier {
  final repository = InsightsRepository();
  List<Map<String, dynamic>>? weeks;
  List<Map<String, dynamic>>? triggers;
  List<Map<String, dynamic>>? sleep;
  bool loading = true;
  bool failed = false;
  bool _disposed = false;

  Future<void> load({
    bool weekly = false,
    bool trigger = false,
    bool sleepMood = false,
  }) async {
    await Future.wait([
      if (weekly)
        _load(
          repository.getCachedWeekly(weeks: 1, allowStale: true),
          () => repository.fetchWeekly(weeks: 1),
          (rows) => weeks = rows,
        ),
      if (trigger)
        _load(
          repository.getCachedTriggers(allowStale: true),
          () => repository.fetchTriggers(),
          (rows) => triggers = rows,
        ),
      if (sleepMood)
        _load(
          repository.getCachedSleepMood(allowStale: true),
          () => repository.fetchSleepMood(),
          (rows) => sleep = rows,
        ),
    ]);
    if (_disposed) return;
    loading = false;
    notifyListeners();
  }

  Future<void> _load(
    Future<List<Map<String, dynamic>>?> cached,
    Future<List<Map<String, dynamic>>> Function() fetch,
    void Function(List<Map<String, dynamic>>) assign,
  ) async {
    try {
      final rows = await cached;
      if (_disposed) return;
      if (rows != null) {
        assign(rows);
        notifyListeners();
      }
      if (!await AuthTokenService.hasToken()) return;
      final fresh = await fetch();
      if (_disposed) return;
      assign(fresh);
      notifyListeners();
    } catch (_) {
      if (!_disposed) {
        failed = true;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class InsightsStatus extends StatelessWidget {
  const InsightsStatus({
    super.key,
    required this.loading,
    required this.failed,
    required this.empty,
  });
  final bool loading;
  final bool failed;
  final bool empty;
  @override
  Widget build(BuildContext context) {
    if (loading) return const LinearProgressIndicator();
    if (failed) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'Could not refresh insights. Saved data is shown when available.',
        ),
      );
    }
    if (empty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Text('Log 3 moods to see trends'),
      );
    }
    return const SizedBox.shrink();
  }
}
