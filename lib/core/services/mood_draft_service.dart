import 'local_db_service.dart';

class MoodDraftService {
  String _day(DateTime now) => '${now.year}-${now.month}-${now.day}';
  Future<Map<String, dynamic>?> loadToday({DateTime? now}) async {
    final settings = await LocalDbService().settingsBox();
    final value = settings.get('mood_draft');
    if (value is! Map) return null;
    if (value['day'] != _day(now ?? DateTime.now())) {
      await settings.delete('mood_draft');
      return null;
    }
    return Map<String, dynamic>.from(value);
  }

  Future<void> save(Map<String, dynamic> draft, {DateTime? now}) async =>
      (await LocalDbService().settingsBox()).put('mood_draft', {
        ...draft,
        'day': _day(now ?? DateTime.now()),
      });
  Future<void> clear() async =>
      (await LocalDbService().settingsBox()).delete('mood_draft');
}
