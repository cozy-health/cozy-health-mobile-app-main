class SyncSummary {
  const SyncSummary({this.synced = 0, this.failed = 0, this.errorCode});
  final int synced;
  final int failed;
  final String? errorCode;
  int get attempted => synced + failed;
  String get message => failed > 0 && errorCode == 'session_expired'
      ? 'Log in again to sync your saved changes.'
      : failed > 0 && errorCode == 'access_denied'
      ? 'This account cannot sync right now. Contact support.'
      : failed > 0 && errorCode == 'connection'
      ? 'Saved on this device. Check your connection and retry.'
      : failed > 0 && errorCode == 'server'
      ? 'Saved on this device. Sync is temporarily unavailable.'
      : failed > 0 && errorCode == 'invalid_payload'
      ? 'Some saved changes need attention. Open pending changes.'
      : failed > 0 && errorCode == 'secure_connection'
      ? 'Secure connection unavailable. Check for an app update.'
      : failed == 0
      ? '$synced items synced'
      : synced == 0
      ? "Couldn't sync. Tap to retry"
      : '$synced synced, $failed failed — tap to retry';
}
