import 'package:flutter/foundation.dart';
import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';
import '../api/api_client.dart';
import '../storage/token_storage.dart';

class DeviceIntegrityService extends ChangeNotifier {
  DeviceIntegrityService({
    Future<bool> Function()? detect,
    Future<void> Function()? report,
  }) : _detect = detect ?? _nativeDetect,
       _report = report ?? _reportCount;
  static final instance = DeviceIntegrityService();
  final Future<bool> Function() _detect;
  final Future<void> Function() _report;
  bool warning = false;
  bool checked = false;
  bool _reported = false;
  static Future<bool> _nativeDetect() async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      return false;
    }
    return FlutterJailbreakDetection.jailbroken;
  }

  static Future<void> _reportCount() async {
    if (await TokenStorage().getToken() == null) {
      throw StateError('No authenticated session');
    }
    await ApiClient().post('/me/device-security', body: {'detected': true});
  }

  Future<void> check() async {
    if (checked) return;
    checked = true;
    try {
      warning = await _detect();
    } catch (_) {
      warning = false;
    }
    notifyListeners();
    await reportIfDetected();
  }

  Future<void> reportIfDetected() async {
    if (warning && !_reported) {
      try {
        await _report();
        _reported = true;
      } catch (_) {
        /* Detection never blocks app use. */
      }
    }
  }
}
