import 'package:cozy_health/core/models/mood_entry.dart';
import 'package:cozy_health/core/repositories/mood_repository.dart';
import 'package:cozy_health/core/repositories/wellness_repository.dart';
import 'package:cozy_health/core/services/mood_draft_service.dart';

class MemoryMoodDrafts extends MoodDraftService {
  Map<String, dynamic>? data;
  bool failSave = false, failClear = false;
  final writes = <Map<String, dynamic>>[];
  @override
  Future<Map<String, dynamic>?> loadToday({DateTime? now}) async => data;
  @override
  Future<void> save(Map<String, dynamic> draft, {DateTime? now}) async {
    if (failSave) throw StateError('Draft write failed');
    data = Map.of(draft);
    writes.add(Map.of(draft));
  }

  @override
  Future<void> clear() async {
    if (failClear) throw StateError('Draft cleanup failed');
    data = null;
  }
}

class MemoryMoodRepository extends MoodRepository {
  final entries = <String, MoodEntry>{};
  final attempts = <MoodEntry>[];
  bool fail = false;
  Future<void>? waitForSave;
  @override
  Future<MoodEntry> save(MoodEntry entry) async {
    attempts.add(entry);
    if (waitForSave != null) await waitForSave;
    if (fail) throw StateError('Persistence failed');
    entries[entry.id] = entry;
    return entry;
  }
}

class MemoryMoodCatalog extends WellnessRepository {
  Map<String, dynamic>? data;
  Future<Map<String, dynamic>?>? pending;
  @override
  Future<Map<String, dynamic>?> catalog() async =>
      pending == null ? data : await pending;
}

MoodEntry historicalMood() => MoodEntry(
  id: 'historical-entry',
  mood: 'angry',
  expressionSlug: 'angry-resentful',
  intensity: 7,
  triggers: const ['Retired cause'],
  copingStrategies: const ['Old response'],
  bodySensations: const ['Chest'],
  sleepQuality: 2,
  energyLevel: 4,
  customTrigger: 'Keep this',
  note: 'A long day',
  copingHelped: 'somewhat',
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);
