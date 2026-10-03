import 'package:permission_handler/permission_handler.dart' as permissions;

enum MicPermissionResult { granted, denied, permanentlyDenied }

class PermissionService {
  static Future<MicPermissionResult> requestMicrophone() async {
    final status = await permissions.Permission.microphone.request();
    if (status.isGranted) return MicPermissionResult.granted;
    if (status.isPermanentlyDenied) {
      return MicPermissionResult.permanentlyDenied;
    }
    return MicPermissionResult.denied;
  }

  static Future<void> openAppSettings() async {
    await permissions.openAppSettings();
  }
}
