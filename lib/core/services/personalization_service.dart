import 'package:shared_preferences/shared_preferences.dart';

class PersonalizationService {
  static const _key = 'has_completed_personalization';

  Future<bool> hasCompletedPersonalization() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  Future<void> markComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }
}
