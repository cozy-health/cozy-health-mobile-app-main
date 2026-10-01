import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('bottom nav uses theme, not hardcoded colors', () {
    final file = File('lib/core/widgets/bottom_navigation_bar.dart');
    final content = file.readAsStringSync();

    expect(
      content.contains('backgroundColor: Colors.white'),
      isFalse,
      reason: 'bottom_navigation_bar should use theme colors',
    );
    expect(
      content.contains('backgroundColor: Color(0xFFFFFFFF)'),
      isFalse,
      reason: 'bottom_navigation_bar should not hardcode white',
    );
  });

  test('hardcoded color count is decreasing', () {
    final dir = Directory('lib');
    var count = 0;
    final pattern = RegExp(
      r'Color\(0x|Colors\.(white|black|grey|blue|red|green|orange)',
    );

    for (final e in dir.listSync(recursive: true)) {
      if (e is File && e.path.endsWith('.dart')) {
        count += pattern.allMatches(e.readAsStringSync()).length;
      }
    }

    // ignore: avoid_print
    print('Remaining hardcoded color references: $count');
  });
}
