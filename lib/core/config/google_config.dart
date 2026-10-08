/// Supply OAuth IDs using --dart-define in Phase 4c.
class GoogleConfig {
  static const iosClientId = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');
  static const androidClientId = String.fromEnvironment(
    'GOOGLE_ANDROID_CLIENT_ID',
  );
  // Android requires the web/server OAuth client ID, not the Android client ID.
  static const serverClientId = String.fromEnvironment('GOOGLE_CLIENT_ID');
}
