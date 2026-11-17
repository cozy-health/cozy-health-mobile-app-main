import '../../../core/api/api_client.dart';
import '../../../core/api/response_data.dart';
import '../../../core/data/demo_mode.dart';
import '../../../core/repositories/mood_repository.dart';
import '../../../core/repositories/journal_repository.dart';
import '../../../core/services/local_db_service.dart';
import '../../../core/services/network_status.dart';
import 'wellness_progress.dart';

class AchievementSnapshot {
  const AchievementSnapshot({
    required this.progress,
    required this.awards,
    required this.localOnly,
    required this.remoteUnavailable,
  });
  final WellnessProgress progress;
  final Map<String, DateTime> awards;
  final bool localOnly, remoteUnavailable;
}

class AchievementsRepository {
  AchievementsRepository({ApiClient? api}) : _api = api ?? ApiClient.instance;
  final ApiClient _api;
  Future<AchievementSnapshot> load() async {
    final local = LocalDbService(), owner = LocalDbService().activeUserId;
    final box = await local.settingsBox();
    bool current() => owner == local.activeUserId;
    final demo = DemoMode.instance.enabled,
        localOnly =
            owner == null ||
            owner.startsWith('guest_') ||
            DemoMode.instance.enabled;
    final progress = WellnessProgress(
      moods: MoodRepository().currentEntries(),
      journals: JournalRepository().currentEntries(),
      now: DateTime.now(),
      calendarTime: local.accountTime,
    );
    final awards = <String, DateTime>{};
    final stored = demo ? null : box.get('earned_milestones_v1');
    if (stored is Map) {
      for (final e in stored.entries) {
        final oldInstant = DateTime.tryParse('${e.value}');
        final isFirstAction = e.key == 'first_mood' || e.key == 'first_journal';
        final d =
            isFirstAction && '${e.value}'.length > 10 && oldInstant != null
            ? wellnessDay(local.accountTime(oldInstant))
            : _date(e.value);
        if (d != null) awards[e.key.toString()] = d;
      }
    }
    var unavailable = false;
    if (!localOnly) {
      try {
        if (networkOffline.value == true) throw StateError('Offline');
        final response = responseMap(await _api.get('/wellness/achievements'));
        if (!current()) throw StateError('Account changed');
        final data = response['data'];
        if (data is! List) throw const FormatException('Invalid achievements');
        for (final row in data) {
          if (row is! Map) continue;
          final date = _date(row['earned_date']);
          if (date != null && row['milestone'] is String) {
            awards[row['milestone'] as String] = date;
          }
        }
      } catch (_) {
        if (!current()) rethrow;
        unavailable = true;
      }
    }
    if (!current()) throw StateError('Account changed');
    for (final award in progress.derivedAwards.entries) {
      awards.putIfAbsent(award.key, () => award.value);
    }
    if (!demo) {
      await box.put('earned_milestones_v1', {
        for (final e in awards.entries)
          e.key: e.value.toIso8601String().substring(0, 10),
      });
    }
    if (!current()) throw StateError('Account changed');
    return AchievementSnapshot(
      progress: progress,
      awards: awards,
      localOnly: localOnly,
      remoteUnavailable: unavailable,
    );
  }

  DateTime? _date(Object? value) {
    final text = value?.toString() ?? '';
    if (text.length < 10) return null;
    final date = DateTime.tryParse(text.substring(0, 10));
    return date == null ? null : wellnessDay(date);
  }
}
