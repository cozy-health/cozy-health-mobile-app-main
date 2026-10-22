import 'local_db_service.dart';

class MoodDraftService {
  MoodDraftService() : _scope = _currentScope();
  final String _scope;
  static String _currentScope() =>
      LocalDbService().boxName(LocalDbService.userSettingsBoxName);
  void _checkScope() {
    if (_scope != _currentScope()) {
      throw StateError('Mood draft account changed');
    }
  }

  String _day(DateTime now) => '${now.year}-${now.month}-${now.day}';
  Future<Map<String, dynamic>?> loadToday({DateTime? now}) async {
    _checkScope();
    final settings = await LocalDbService().settingsBox();
    _checkScope();
    final value = settings.get('mood_draft');
    if (value is! Map) return null;
    if (value['day'] != _day(now ?? DateTime.now())) {
      await settings.delete('mood_draft');
      return null;
    }
    return Map<String, dynamic>.from(value);
  }

  Future<void> save(Map<String, dynamic> draft, {DateTime? now}) async {
    _checkScope();
    final settings = await LocalDbService().settingsBox();
    _checkScope();
    await settings.put('mood_draft', {
      ...draft,
      'day': _day(now ?? DateTime.now()),
    });
  }

  Future<void> clear() async {
    _checkScope();
    final settings = await LocalDbService().settingsBox();
    _checkScope();
    await settings.delete('mood_draft');
  }
}
