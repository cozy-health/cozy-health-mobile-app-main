import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('API base URL appears exactly once in lib/', () {
    final dir = Directory('lib');
    final pattern = RegExp('cozy-health-api-production');
    var count = 0;

    for (final entity in dir.listSync(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        count += pattern.allMatches(entity.readAsStringSync()).length;
      }
    }

    expect(count, 1);
  });

  test('mood emoji map defined only in mood_entry.dart', () {
    final dir = Directory('lib');
    final pattern = RegExp(r'F60A|F60C|F610|F614|F630|F621');
    final offenders = <String>[];

    for (final entity in dir.listSync(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        if (!entity.path.contains('mood_entry.dart') &&
            pattern.hasMatch(entity.readAsStringSync())) {
          offenders.add(entity.path);
        }
      }
    }

    expect(offenders, isEmpty);
  });
}
