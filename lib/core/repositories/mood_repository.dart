import '../data/demo_mode.dart';
import '../services/user_data_merge.dart';
import '../services/plan_access_service.dart';
import 'package:flutter/foundation.dart';
import '../models/mood_entry.dart';
import '../services/local_db_service.dart';
import '../api/api_client.dart';
import '../api/api_exceptions.dart';
import '../constants/api_constants.dart';

class MoodStats {
  final Map<String, dynamic> data;
  MoodStats(this.data);
  factory MoodStats.fromJson(Map<String, dynamic> json) => MoodStats(json);
}

class MoodRepository {
  MoodRepository({bool? usePlaceholderData})
    : _placeholderOverride = usePlaceholderData;
  final bool? _placeholderOverride;
  bool get usePlaceholderData =>
      _placeholderOverride ?? DemoMode.instance.enabled;
  List<MoodEntry> currentEntries() => usePlaceholderData
      ? List.of(DemoMode.instance.moods)
      : _local.getAllMoodEntries();
  final LocalDbService _local = LocalDbService();

  List<dynamic> _extractListData(dynamic data) {
    if (data is List) return data;
    if (data is Map && data['data'] is List) {
      return data['data'] as List;
    }
    if (data is Map && data['data'] is Map) {
      final nested = data['data'] as Map;
      if (nested['data'] is List) return nested['data'] as List;
    }
    debugPrint('Unexpected mood entries response shape: ${data.runtimeType}');
    return const [];
  }

  Future<List<MoodEntry>> fetchMoodEntries({
    int page = 1,
    int perPage = 50,
  }) async {
    if (usePlaceholderData) return currentEntries();
    final scope = _local.boxName(LocalDbService.userSettingsBoxName);
    bool active() =>
        scope == _local.boxName(LocalDbService.userSettingsBoxName);
    try {
      final response = await ApiClient.instance.get(
        ApiConstants.moodEntries,
        queryParameters: {'page': page, 'per_page': perPage},
      );
      if (!active()) return [];
      final rows = _extractListData(response.data).whereType<Map>().toList();
      for (final raw in rows) {
        await UserDataMerge().apply(
          'mood_entry',
          Map<String, dynamic>.from(raw),
          isActive: () =>
              scope == _local.boxName(LocalDbService.userSettingsBoxName),
        );
      }
      if (!active()) return [];
      // Return the accepted merge, including local edits and pending tombstones.
      final deleted = _local.pendingItems
          .where((item) => item.type == 'mood_entry' && item.action == 'delete')
          .map((item) => item.recordId)
          .toSet();
      return [
        for (final row in rows)
          if (!deleted.contains(row['id']?.toString()))
            if (_local.moodBox.get(row['id']?.toString()) case final entry?)
              entry,
      ];
    } on ApiAuthException {
      rethrow;
    } catch (e) {
      debugPrint('Fetch moods failed: details withheld.');
      if (!active()) return [];
      return _local.getAllMoodEntries();
    }
  }

  Stream<List<MoodEntry>> watchMoodEntries() => DemoMode.instance.selectStream(
    useDemo: () => usePlaceholderData,
    real: _local.watchMoodEntries,
    demo: () => DemoMode.instance.moods,
  );

  Future<MoodEntry> saveMoodEntry(MoodEntry entry) async {
    if (usePlaceholderData) {
      DemoMode.instance.upsertMood(entry);
      return entry;
    }
    final owner = _local.boxName(LocalDbService.userSettingsBoxName);
    await PlanAccessService.instance.require('mood_checkin');
    if (owner != _local.boxName(LocalDbService.userSettingsBoxName)) {
      throw StateError('Account changed');
    }
    await _local.saveMoodEntry(entry);
    if (owner != _local.boxName(LocalDbService.userSettingsBoxName)) {
      throw StateError('Mood recording account changed');
    }
    await _local.enqueueSync(
      type: 'mood_entry',
      action: 'upsert',
      recordId: entry.id,
      payload: entry.toJson(),
    );
    if (owner != _local.boxName(LocalDbService.userSettingsBoxName)) {
      throw StateError('Mood recording account changed');
    }
    _local.processSyncQueue();
    return entry;
  }

  Future<MoodEntry> updateMoodEntry(MoodEntry entry) async {
    return await saveMoodEntry(entry);
  }

  Future<void> deleteMoodEntry(String id) async {
    final operationOwner = _local.activeUserId;
    if (usePlaceholderData) {
      DemoMode.instance.moods.removeWhere((entry) => entry.id == id);
      DemoMode.instance.changed();
      return;
    }
    await _local.deleteMoodEntry(id);
    if (operationOwner != _local.activeUserId) {
      throw StateError('Account changed');
    }
    await _local.enqueueSync(
      type: 'mood_entry',
      action: 'delete',
      recordId: id,
      payload: null,
    );
    if (operationOwner != _local.activeUserId) {
      throw StateError('Account changed');
    }
    _local.processSyncQueue();
  }

  /// Alias for saveMoodEntry — some UI code calls save() directly.
  Future<MoodEntry> save(MoodEntry entry) => saveMoodEntry(entry);
}
