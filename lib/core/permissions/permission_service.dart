import 'package:permission_handler/permission_handler.dart' as permissions;

enum MicPermissionResult { granted, denied, permanentlyDenied, restricted }

class PermissionService {
  static Future<MicPermissionResult> requestMicrophone() async {
    final status = await permissions.Permission.microphone.request();
    return _microphoneResult(status);
  }

  static Future<MicPermissionResult> microphoneStatus() async =>
      _microphoneResult(await permissions.Permission.microphone.status);

  static MicPermissionResult _microphoneResult(
    permissions.PermissionStatus status,
  ) {
    if (status.isGranted) return MicPermissionResult.granted;
    if (status.isRestricted) return MicPermissionResult.restricted;
    if (status.isPermanentlyDenied) {
      return MicPermissionResult.permanentlyDenied;
    }
    return MicPermissionResult.denied;
  }

  static Future<bool> openAppSettings() => permissions.openAppSettings();
}
