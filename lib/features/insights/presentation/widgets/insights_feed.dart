import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import '../../../../core/repositories/insights_repository.dart';
import '../../../../core/api/auth_token_service.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../../../core/widgets/friendly_error.dart';

/// Keeps each screen's existing layout while handling cached-first refreshes.
class InsightsFeed extends ChangeNotifier {
  final repository = InsightsRepository();
  List<Map<String, dynamic>>? weeks;
  List<Map<String, dynamic>>? triggers;
  List<Map<String, dynamic>>? sleep;
  bool loading = true;
  bool failed = false;
  int failures = 0;
  bool _disposed = false;

  Future<void> load({
    bool weekly = false,
    bool trigger = false,
    bool sleepMood = false,
  }) async {
    loading = true;
    failed = false;
    if (!_disposed) notifyListeners();
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
    failures = failed ? failures + 1 : 0;
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
    this.onRetry,
    this.failureCount = 1,
  });
  final bool loading;
  final bool failed;
  final bool empty;
  final VoidCallback? onRetry;
  final int failureCount;
  @override
  Widget build(BuildContext context) {
    if (loading) return const SkeletonLoader(height: 160);
    if (failed) {
      return FriendlyError(
        title: "We couldn't refresh your insights.",
        message:
            'Saved data is shown when available. Check your connection and try again.',
        onRetry: onRetry,
        failureCount: failureCount,
      );
    }
    if (empty) {
      return EmptyState(
        icon: Icons.insights_outlined,
        title: 'Log a few moods to see patterns.',
        primaryCtaLabel: 'Log a mood',
        onPrimaryCta: () => context.push(AppRouter.moodFeeling),
      );
    }
    return const SizedBox.shrink();
  }
}
