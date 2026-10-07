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
    try {
      final response = await ApiClient.instance.get(
        ApiConstants.moodEntries,
        queryParameters: {'page': page, 'per_page': perPage},
      );
      final items = _extractListData(response.data)
          .whereType<Map>()
          .map((json) => MoodEntry.fromJson(Map<String, dynamic>.from(json)))
          .toList();
      for (final item in items) {
        await _local.saveMoodEntry(item);
      }
      return items;
    } on ApiAuthException {
      rethrow;
    } catch (e) {
      debugPrint('Fetch moods failed: $e');
      return _local.getAllMoodEntries();
    }
  }

  Stream<List<MoodEntry>> watchMoodEntries() async* {
    yield* _local.watchMoodEntries();
  }

  Future<MoodEntry> saveMoodEntry(MoodEntry entry) async {
    await _local.saveMoodEntry(entry);
    await _local.enqueueSync(
      type: 'mood_entry',
      action: 'upsert',
      recordId: entry.id,
      payload: entry.toJson(),
    );
    _local.processSyncQueue();
    return entry;
  }

  Future<MoodEntry> updateMoodEntry(MoodEntry entry) async {
    return await saveMoodEntry(entry);
  }

  Future<void> deleteMoodEntry(String id) async {
    await _local.deleteMoodEntry(id);
    await _local.enqueueSync(
      type: 'mood_entry',
      action: 'delete',
      recordId: id,
      payload: null,
    );
    _local.processSyncQueue();
  }

  /// Alias for saveMoodEntry — some UI code calls save() directly.
  Future<MoodEntry> save(MoodEntry entry) => saveMoodEntry(entry);
}
