import 'package:shared_preferences/shared_preferences.dart';

import '../storage/token_storage.dart';
import 'local_db_service.dart';

class InstallMarkerService {
  static const _key = 'install_marker_set';

  Future<void> clearLingeringSessionOnFreshInstall() async {
    final prefs = await SharedPreferences.getInstance();
    final markerSet = prefs.getBool(_key) ?? false;

    if (markerSet) return;

    await TokenStorage().clearToken();
    await LocalDbService.instance.activateGuest();
    await prefs.setBool(_key, true);
  }
}
