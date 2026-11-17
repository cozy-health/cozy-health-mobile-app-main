import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cozy_health/core/services/notification_permission_controller.dart';

void main() {
  test(
    'requests coalesce and resume checks cannot cancel the OS response',
    () async {
      final dialog = Completer<PermissionStatus>();
      var requests = 0, reads = 0;
      final permission = NotificationPermissionController(
        read: () async {
          reads++;
          return PermissionStatus.denied;
        },
        request: () {
          requests++;
          return dialog.future;
        },
        wasRequested: () async => false,
        rememberRequest: () async {},
      );
      final first = permission.request();
      final second = permission.request();
      final resumed = permission.check();
      dialog.complete(PermissionStatus.granted);
      await Future.wait([first, second, resumed]);
      expect(requests, 1);
      expect(reads, 0);
      expect(permission.label, 'Allowed');
      permission.dispose();
    },
  );
  test(
    'checking permission without Firebase never opens the OS dialog',
    () async {
      var requests = 0;
      final permission = NotificationPermissionController(
        read: () async => PermissionStatus.denied,
        request: () async {
          requests++;
          return PermissionStatus.granted;
        },
        wasRequested: () async => false,
        rememberRequest: () async {},
      );
      await permission.check();
      expect(permission.label, 'Not requested');
      expect(requests, 0);
      await permission.request();
      expect(requests, 1);
      expect(permission.label, 'Allowed');
      expect(permission.allowed, true);
      permission.dispose();
    },
  );
  test(
    'denial points to phone settings and does not require delivery credentials',
    () async {
      final permission = NotificationPermissionController(
        read: () async => PermissionStatus.denied,
        request: () async => PermissionStatus.permanentlyDenied,
        wasRequested: () async => false,
        rememberRequest: () async {},
      );
      await permission.request();
      expect(permission.label, 'Denied');
      expect(permission.needsSettings, true);
      expect(permission.allowed, false);
      permission.dispose();
    },
  );
  test('returning from phone settings refreshes authorization', () async {
    var status = PermissionStatus.permanentlyDenied;
    final permission = NotificationPermissionController(
      read: () async => status,
      wasRequested: () async => true,
    );
    await permission.check();
    expect(permission.label, 'Denied');
    status = PermissionStatus.granted;
    await permission.check();
    expect(permission.label, 'Allowed');
    permission.dispose();
  });
  test('missing native permission support is reported clearly', () async {
    final permission = NotificationPermissionController(
      read: () async => throw StateError('Unavailable'),
      wasRequested: () async => false,
    );
    await permission.check();
    expect(permission.label, 'Permission check unavailable');
    permission.dispose();
  });
  test(
    'an earlier permission check cannot overwrite a completed request',
    () async {
      final waiting = Completer<PermissionStatus>();
      final permission = NotificationPermissionController(
        read: () => waiting.future,
        request: () async => PermissionStatus.granted,
        wasRequested: () async => false,
        rememberRequest: () async {},
      );
      final checking = permission.check();
      await Future<void>.delayed(Duration.zero);
      await permission.request();
      waiting.complete(PermissionStatus.denied);
      await checking;
      expect(permission.label, 'Allowed');
      permission.dispose();
    },
  );
}
