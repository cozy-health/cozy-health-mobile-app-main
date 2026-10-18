import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Asset decoding runs outside the fake clock; an idle frame alone does not
/// guarantee that a cold-cache image has reached the screenshot.
Future<void> settleMoodReviewImages(
  WidgetTester tester, {
  Key captureKey = const ValueKey('capture'),
}) async {
  await tester.pumpAndSettle();
  final context = tester.element(find.byKey(captureKey));
  final providers = tester
      .widgetList<Image>(find.byType(Image))
      .map((image) => image.image)
      .toSet();
  await tester.runAsync(
    () => Future.wait([
      for (final provider in providers) precacheImage(provider, context),
    ]),
  );
  await tester.pumpAndSettle();
}

/// Fresh review artifacts are separate from approved golden baselines.
Future<void> captureMoodReview(
  WidgetTester tester,
  String name, {
  Key captureKey = const ValueKey('capture'),
}) async {
  await settleMoodReviewImages(tester, captureKey: captureKey);
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(captureKey),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) throw StateError('Could not capture $name');
    final directory = Directory('build/mood-selection-review');
    await directory.create(recursive: true);
    await File(
      '${directory.path}/$name.png',
    ).writeAsBytes(bytes.buffer.asUint8List());
    image.dispose();
  });
}
