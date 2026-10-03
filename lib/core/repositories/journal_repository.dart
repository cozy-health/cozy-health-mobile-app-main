import 'package:flutter/foundation.dart';

import '../models/journal_entry.dart';
import '../services/local_db_service.dart';
import '../api/api_client.dart';
import '../constants/api_constants.dart';

class JournalRepository {
  final LocalDbService _local = LocalDbService();

  List<dynamic> _extractListData(dynamic data) {
    if (data is Map<String, dynamic> && data['data'] is List) {
      return data['data'] as List;
    }
    if (data is List) return data;
    debugPrint('Unexpected journal entries response shape: ${data.runtimeType}');
    return const [];
  }

  Future<List<JournalEntry>> fetchJournalEntries({
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      final response = await ApiClient.instance.get(
        ApiConstants.journalEntries,
        queryParameters: {'page': page, 'per_page': perPage},
      );
      final items = _extractListData(response.data)
          .whereType<Map>()
          .map((json) => JournalEntry.fromJson(Map<String, dynamic>.from(json)))
          .toList();
      for (final item in items) {
        await _local.saveJournalEntry(item);
      }
      return items;
    } catch (e) {
      return _local.getAllJournalEntries();
    }
  }

  Stream<List<JournalEntry>> watchJournalEntries() {
    return _local.watchJournalEntries();
  }

  Stream<JournalEntry?> watchEntryById(String id) {
    return _local.watchJournalEntries().map(
      (entries) => entries.cast<JournalEntry?>().firstWhere(
        (e) => e?.id == id,
        orElse: () => null,
      ),
    );
  }

  Future<JournalEntry> saveJournalEntry(JournalEntry entry) async {
    await _local.saveJournalEntry(entry);
    await _local.enqueueSync(
      type: 'journal_entry',
      action: 'upsert',
      recordId: entry.id,
      payload: entry.toJson(),
    );
    _local.processSyncQueue();
    return entry;
  }

  Future<JournalEntry> updateJournalEntry(JournalEntry entry) async {
    return await saveJournalEntry(entry);
  }

  Future<void> deleteJournalEntry(String id) async {
    await _local.deleteJournalEntry(id);
    await _local.enqueueSync(
      type: 'journal_entry',
      action: 'delete',
      recordId: id,
      payload: null,
    );
    _local.processSyncQueue();
  }

  /// Alias for saveJournalEntry — some UI code calls save() directly.
  Future<JournalEntry> save(JournalEntry entry) => saveJournalEntry(entry);
}
