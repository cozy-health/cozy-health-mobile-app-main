import 'package:shared_preferences/shared_preferences.dart';

class GuestSessionService {
  static const _key = 'is_guest_session';

  Future<bool> isGuestSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  Future<void> enterGuestSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }

  Future<void> exitGuestSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
