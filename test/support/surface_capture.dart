import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

const surfaceCaptureKey = ValueKey('surface-review-capture');

/// Optional visual artifacts; ordinary test runs do not write screenshots.
Future<void> captureSurface(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('SURFACE_SCREENSHOTS')) return;
  await tester.pump();
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(surfaceCaptureKey),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final directory = Directory('build/surface-review');
      await directory.create(recursive: true);
      final safe = name.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      await File(
        '${directory.path}/$safe.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  });
}
