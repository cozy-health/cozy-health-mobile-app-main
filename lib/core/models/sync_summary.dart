class SyncSummary {
  const SyncSummary({this.synced = 0, this.failed = 0});
  final int synced;
  final int failed;
  int get attempted => synced + failed;
  String get message => failed == 0
      ? '$synced items synced'
      : synced == 0
      ? "Couldn't sync. Tap to retry"
      : '$synced synced, $failed failed — tap to retry';
}
