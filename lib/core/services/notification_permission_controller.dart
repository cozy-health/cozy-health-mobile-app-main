import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:permission_handler/permission_handler.dart';

/// Phone permission is independent of Firebase configuration and APNs signing.
class NotificationPermissionController extends ChangeNotifier {
  NotificationPermissionController({
    Future<PermissionStatus> Function()? read,
    Future<PermissionStatus> Function()? request,
    Future<bool> Function()? wasRequested,
    Future<void> Function()? rememberRequest,
  }) : _read = read ?? (() => Permission.notification.status),
       _request = request ?? (() => Permission.notification.request()),
       _wasRequested =
           wasRequested ??
           (() async => await _storage.read(key: _key) == 'true'),
       _remember =
           rememberRequest ?? (() => _storage.write(key: _key, value: 'true'));
  static const _storage = FlutterSecureStorage();
  static const _key = 'notification_permission_requested';
  final Future<PermissionStatus> Function() _read, _request;
  final Future<bool> Function() _wasRequested;
  final Future<void> Function() _remember;
  PermissionStatus? status;
  bool requested = false, unavailable = false;
  int _revision = 0;
  Future<void>? _requestWork;
  bool _disposed = false;
  bool get requesting => _requestWork != null;
  bool get allowed =>
      status == PermissionStatus.granted ||
      status == PermissionStatus.provisional;
  bool get needsSettings =>
      status == PermissionStatus.permanentlyDenied ||
      status == PermissionStatus.restricted ||
      (requested && status == PermissionStatus.denied);
  String get label => unavailable
      ? 'Permission check unavailable'
      : allowed
      ? 'Allowed'
      : needsSettings
      ? 'Denied'
      : status == null
      ? 'Checking…'
      : 'Not requested';

  Future<void> check() async {
    if (_disposed) return;
    if (_requestWork != null) {
      await _requestWork;
      return;
    }
    final revision = ++_revision;
    try {
      final asked = await _wasRequested();
      final result = await _read();
      if (revision != _revision) return;
      requested = requested || asked;
      status = result;
      unavailable = false;
    } catch (_) {
      if (revision == _revision) unavailable = true;
    }
    if (revision == _revision) notifyListeners();
  }

  Future<void> request() {
    if (_disposed) return Future.value();
    return _requestWork ??= _requestNative().whenComplete(
      () => _requestWork = null,
    );
  }

  Future<void> _requestNative() async {
    final revision = ++_revision;
    try {
      final result = await _request();
      if (revision != _revision) return;
      status = result;
      requested = true;
      unavailable = false;
      await _remember();
    } catch (_) {
      if (revision == _revision) unavailable = true;
    }
    if (revision == _revision) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _revision++;
    super.dispose();
  }
}
