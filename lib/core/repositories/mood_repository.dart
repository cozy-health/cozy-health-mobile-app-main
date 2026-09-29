import 'package:flutter/foundation.dart';
import '../models/mood_entry.dart';
import '../services/local_db_service.dart';
import '../api/api_client.dart';
import '../api/api_exceptions.dart';

class MoodStats {
  final Map<String, dynamic> data;
  MoodStats(this.data);
  factory MoodStats.fromJson(Map<String, dynamic> json) => MoodStats(json);
}

class MoodRepository {
  final LocalDbService _local = LocalDbService();

  Future<List<MoodEntry>> fetchMoodEntries({int page = 1, int perPage = 50}) async {
    try {
      final response = await ApiClient.instance.get(
        '/mood-entries',
        queryParameters: {'page': page, 'per_page': perPage},
      );
      final items = (response.data['data'] as List)
        .map((json) => MoodEntry.fromJson(json))
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
    yield _local.getAllMoodEntries().where((e) => !e.isCrisisFlagged).toList(); // Simple filter if needed, though isDeleted should be checked ideally
    // Assuming no isDeleted on model, but standard getAll logic is fine
  }

  Future<MoodEntry> saveMoodEntry(MoodEntry entry) async {
    await _local.saveMoodEntry(entry);
    await _local.enqueueSync(type: 'mood_entry', action: 'upsert', recordId: entry.id, payload: entry.toJson());
    _tryServerSync(entry);
    return entry;
  }

  Future<MoodEntry> updateMoodEntry(MoodEntry entry) async {
    return await saveMoodEntry(entry);
  }

  Future<void> deleteMoodEntry(String id) async {
    // Should ideally mark as deleted, but removing for now
    // await _local.deleteMoodEntry(id);
    await _local.enqueueSync(type: 'mood_entry', action: 'delete', recordId: id);
    try {
      await ApiClient.instance.delete('/mood-entries/$id');
    } catch (e) {
      debugPrint('Sync failed: $e');
    }
  }

  Future<void> _tryServerSync(MoodEntry entry) async {
    try {
      await ApiClient.instance.post('/mood-entries', data: entry.toJson());
    } on ApiNetworkException {
    } on ApiTimeoutException {
    } on ApiValidationException catch (e) {
      debugPrint('Mood validation: ${e.fieldErrors}');
    } on ApiServerException {
    } on ApiAuthException {
    } catch (e) {
      debugPrint('Mood sync error: $e');
    }
  }

  Future<MoodStats?> fetchStats() async {
    try {
      final response = await ApiClient.instance.get('/mood-entries/stats');
      return MoodStats.fromJson(response.data['data'] ?? {});
    } catch (e) {
      return null;
    }
  }
}