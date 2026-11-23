import 'dart:async';
import 'dart:io';

import 'package:cozy_health/core/services/local_db_service.dart';
import 'package:cozy_health/features/settings/services/avatar_photo_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PendingCropPicker extends AvatarPhotoPicker {
  final entered = Completer<void>();
  final result = Completer<Uint8List?>();

  @override
  Future<Uint8List?> crop(BuildContext context, String path) {
    entered.complete();
    return result.future;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory temporary;
  late Box<dynamic> settings;
  var cleaned = false;
  const channel = MethodChannel('plugins.flutter.io/image_picker');

  setUpAll(() async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    temporary = await Directory.systemTemp.createTemp('avatar-lifecycle-');
    Hive.init(temporary.path);
    settings = await LocalDbService().settingsBox();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => 'synthetic-photo.jpg');
  });

  tearDownAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    if (!cleaned) {
      await Hive.close().timeout(const Duration(seconds: 5));
      await temporary.delete(recursive: true);
    }
  });

  testWidgets('avatar capture stays pending until crop completes', (
    tester,
  ) async {
    late BuildContext screenContext;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            screenContext = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    final picker = PendingCropPicker();
    Uint8List? result;
    Object? failure;
    var finished = false;
    final picking = picker.pick(screenContext, camera: false);
    unawaited(
      picking.then(
        (value) {
          result = value;
          finished = true;
        },
        onError: (Object error) {
          failure = error;
          finished = true;
        },
      ),
    );
    Future<void> driveUntil(bool Function() ready) async {
      for (var frame = 0; frame < 100 && !ready(); frame++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump(const Duration(milliseconds: 20));
      }
      expect(ready(), isTrue, reason: 'Bounded picker/crop completion');
    }

    await driveUntil(() => picker.entered.isCompleted || finished);
    expect(failure, isNull);
    expect(picker.entered.isCompleted, isTrue);
    await tester.pump();
    final duringCrop = settings.get('avatar_capture_pending');
    picker.result.complete(Uint8List.fromList([1, 2, 3]));
    await driveUntil(() => finished);
    expect(failure, isNull);
    expect(result, orderedEquals([1, 2, 3]));
    expect(settings.get('avatar_capture_pending'), isNull);
    expect(duringCrop, isTrue);
    var closed = false;
    unawaited(Hive.close().then((_) => closed = true));
    await driveUntil(() => closed);
    await tester.runAsync(() => temporary.delete(recursive: true));
    cleaned = true;
  });
}
