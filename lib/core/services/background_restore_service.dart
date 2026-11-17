import 'dart:async';
import 'package:flutter/widgets.dart';
import '../storage/token_storage.dart';
import 'local_db_service.dart';
import 'restore_service.dart';

enum BackgroundRestoreState { idle, restoring, partial, complete }

/// One active account-scoped restore; navigation never waits on downloads.
class BackgroundRestoreService extends ChangeNotifier
    with WidgetsBindingObserver {
  BackgroundRestoreService({
    RestoreController Function(String)? createController,
    Future<bool> Function()? hasSession,
  }) : _create =
           createController ?? ((owner) => RestoreController(userId: owner)),
       _hasSession =
           hasSession ?? (() async => await TokenStorage().getToken() != null);
  static final instance = BackgroundRestoreService();
  final RestoreController Function(String) _create;
  final Future<bool> Function() _hasSession;
  RestoreController? _controller;
  Future<void>? _work;
  String? _owner;
  bool _initialized = false, _disposed = false;
  int _generation = 0, _automaticRetries = 0;
  Timer? _retryTimer;
  StreamSubscription<void>? _accounts, _sessions;
  BackgroundRestoreState state = BackgroundRestoreState.idle;
  double get progress => _controller?.progress ?? 0;
  bool get busy => state == BackgroundRestoreState.restoring;
  Future<void>? get activeWork => _work;
  List<String> get failedSections =>
      List.unmodifiable(_controller?.failed ?? const <String>{});

  void initialize() {
    if (_initialized || _disposed) return;
    _initialized = true;
    WidgetsBinding.instance.addObserver(this);
    _accounts = LocalDbService().accountChanges.listen((_) {
      if (_owner != null && _owner != LocalDbService().activeUserId) stop();
    });
    _sessions = TokenStorage.sessionClearing.listen((_) => stop());
  }

  Future<void> start(String owner) {
    if (_disposed || owner.startsWith('guest_')) return Future.value();
    initialize();
    if (_owner == owner && _work != null) return _work!;
    if (_owner == owner && state == BackgroundRestoreState.complete) {
      return Future.value();
    }
    if (_owner == owner && state == BackgroundRestoreState.partial) {
      return retry();
    }
    stop();
    _owner = owner;
    final generation = _generation;
    return _work = _run(owner, generation).whenComplete(() {
      if (_generation == generation) _work = null;
    });
  }

  Future<void> _run(
    String owner,
    int generation, {
    bool retryOnly = false,
  }) async {
    try {
      if (!await _hasSession() ||
          generation != _generation ||
          owner != LocalDbService().activeUserId) {
        return;
      }
      final controller = _controller ??= _create(owner);
      if (!retryOnly) {
        final settings = await LocalDbService().settingsBox();
        if (generation != _generation ||
            owner != LocalDbService().activeUserId) {
          return;
        }
        if (settings.get('restore_incomplete_user') == owner) {
          controller.resumeFailures(
            List<String>.from(
              settings.get('restore_failed') as List? ?? const [],
            ),
          );
        }
      }
      controller.removeListener(_changed);
      controller.addListener(_changed);
      state = BackgroundRestoreState.restoring;
      _changed();
      await controller.run(retryOnly: controller.failed.isNotEmpty);
      if (_disposed ||
          generation != _generation ||
          owner != LocalDbService().activeUserId) {
        return;
      }
      await controller.finish(acceptPartial: true);
      if (_disposed || generation != _generation) return;
      state = controller.failed.isEmpty
          ? BackgroundRestoreState.complete
          : BackgroundRestoreState.partial;
      controller.removeListener(_changed);
      _changed();
      _scheduleRetry();
    } catch (_) {
      if (!_disposed && generation == _generation) {
        state = BackgroundRestoreState.partial;
        _changed();
        _scheduleRetry();
      }
    }
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    if (state == BackgroundRestoreState.partial && _automaticRetries < 3) {
      _retryTimer = Timer(
        Duration(seconds: 30 * (1 << _automaticRetries)),
        () => unawaited(retry(automatic: true)),
      );
    }
  }

  Future<void> retry({bool automatic = false}) {
    if (_disposed ||
        _owner == null ||
        _work != null ||
        state != BackgroundRestoreState.partial) {
      return _work ?? Future.value();
    }
    if (automatic && _automaticRetries >= 3) return Future.value();
    _retryTimer?.cancel();
    if (automatic) {
      _automaticRetries++;
    } else {
      _automaticRetries = 0;
    }
    final generation = _generation;
    return _work = _run(_owner!, generation, retryOnly: true).whenComplete(() {
      if (_generation == generation) _work = null;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(retry(automatic: true));
  }

  void _changed() {
    if (!_disposed) notifyListeners();
  }

  void stop() {
    _generation++;
    _retryTimer?.cancel();
    _retryTimer = null;
    _controller?.removeListener(_changed);
    _controller?.dispose();
    _controller = null;
    _work = null;
    _owner = null;
    _automaticRetries = 0;
    state = BackgroundRestoreState.idle;
    _changed();
  }

  @override
  void dispose() {
    stop();
    _disposed = true;
    _accounts?.cancel();
    _sessions?.cancel();
    if (_initialized) WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
