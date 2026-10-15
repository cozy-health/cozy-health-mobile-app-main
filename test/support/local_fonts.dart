import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_fonts/src/google_fonts_base.dart' as fonts;

Future<void> installLocalTestFonts({
  String? visualFontPath,
  bool useRealFonts = false,
}) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
  final assets = <String, ByteData>{};
  for (final path in manifest.listAssets()) {
    assets[path] = await rootBundle.load(path);
  }
  final font = await rootBundle.load('fonts/MaterialIcons-Regular.otf');
  final visualFont = File(visualFontPath ?? 'build/surface-review/Outfit.ttf');
  final readableFonts =
      useRealFonts ||
      bool.fromEnvironment('SURFACE_SCREENSHOTS') ||
      bool.fromEnvironment('SURFACE_REAL_FONTS');
  if (useRealFonts && !visualFont.existsSync()) {
    throw StateError(
      'Required test font fixture is missing: ${visualFont.path}',
    );
  }
  final readable = readableFonts && visualFont.existsSync()
      ? ByteData.sublistView(visualFont.readAsBytesSync())
      : font;
  if (readableFonts) {
    await (FontLoader('MaterialIcons')..addFont(Future.value(font))).load();
  }
  fonts.assetManifest = _FontManifest();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMessageHandler('flutter/assets', (message) async {
        final path = utf8.decode(
          message!.buffer.asUint8List(
            message.offsetInBytes,
            message.lengthInBytes,
          ),
        );
        return path.startsWith('test-fonts/') ? readable : assets[path];
      });
}

void resetLocalTestFonts() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMessageHandler('flutter/assets', null);
  fonts.assetManifest = null;
}

class _FontManifest implements AssetManifest {
  @override
  List<String> listAssets() => [
    for (final weight in [
      'Regular',
      'Medium',
      'SemiBold',
      'Bold',
      'Light',
      'ExtraBold',
      'Black',
    ])
      'test-fonts/Outfit-$weight.ttf',
  ];
  @override
  List<AssetMetadata>? getAssetVariants(String key) => null;
}
