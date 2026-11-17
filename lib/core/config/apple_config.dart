/// Enable only after the Apple App ID, signing and backend keys are configured.
class AppleConfig {
  static const enabled = bool.fromEnvironment('APPLE_SIGN_IN_ENABLED');
  // Reserved for a future web flow. Native iOS uses the signed app's Bundle ID.
  static const serviceId = String.fromEnvironment('APPLE_SERVICE_ID');
}
