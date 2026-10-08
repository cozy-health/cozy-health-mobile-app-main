import '../models/digital_wellbeing_preferences.dart';
import 'local_db_service.dart';

class DigitalWellbeingService {
  static const key = 'digital_wellbeing';
  static const pendingSyncKey = 'digital_wellbeing_sync_pending';
  Future<DigitalWellbeingPreferences> load() async {
    final value = (await LocalDbService().settingsBox()).get(key);
    return value is Map
        ? DigitalWellbeingPreferences.fromMap(value)
        : const DigitalWellbeingPreferences();
  }

  Future<void> save(DigitalWellbeingPreferences preferences) async {
    final settings = await LocalDbService().settingsBox();
    // Backend /sync/batch currently rejects user_settings. Retain a durable
    // intent without consuming the normal queue's retry budget on an unknown type.
    await settings.putAll({key: preferences.toMap(), pendingSyncKey: true});
  }
}
