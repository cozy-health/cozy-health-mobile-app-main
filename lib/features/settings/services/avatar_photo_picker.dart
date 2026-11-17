import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/local_db_service.dart';

class AvatarPhotoPicker {
  Future<Uint8List?> pick(BuildContext context, {required bool camera}) async {
    final box = await LocalDbService().settingsBox();
    await box.put('avatar_capture_pending', true);
    try {
      final file = await ImagePicker().pickImage(
        source: camera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 4096,
        maxHeight: 4096,
        requestFullMetadata: false,
      );
      if (file == null || !context.mounted) return null;
      return crop(context, file.path);
    } finally {
      await box.delete('avatar_capture_pending');
    }
  }

  Future<String?> recover() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    final box = await LocalDbService().settingsBox();
    if (box.get('avatar_capture_pending') != true) return null;
    final response = await ImagePicker().retrieveLostData();
    await box.delete('avatar_capture_pending');
    return response.files?.firstOrNull?.path;
  }

  Future<Uint8List?> crop(BuildContext context, String path) async {
    final colors = Theme.of(context).colorScheme;
    final result = await ImageCropper().cropImage(
      sourcePath: path,
      maxWidth: 512,
      maxHeight: 512,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 85,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop profile picture',
          toolbarColor: colors.surface,
          toolbarWidgetColor: colors.onSurface,
          backgroundColor: colors.surface,
          activeControlsWidgetColor: colors.primary,
          lockAspectRatio: true,
        ),
        IOSUiSettings(
          title: 'Crop profile picture',
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
        ),
        if (kIsWeb) WebUiSettings(context: context),
      ],
    );
    return result?.readAsBytes();
  }
}
