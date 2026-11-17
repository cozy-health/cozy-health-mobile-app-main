import 'package:cozy_health/core/models/mood_entry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive/src/binary/binary_reader_impl.dart';
import 'package:hive/src/binary/binary_writer_impl.dart';

void main() {
  test(
    'existing sequential mood records remain readable without an expression field',
    () {
      final writer = BinaryWriterImpl(Hive);
      writer.writeString('legacy');
      writer.writeString('calm');
      writer.writeInt(5);
      writer.writeList([]);
      writer.writeList(['Work']);
      writer.writeString('');
      writer.writeInt(3);
      writer.writeInt(5);
      writer.writeString('');
      writer.writeList(['Box breathing']);
      writer.writeString('yes');
      writer.writeInt(DateTime(2026).millisecondsSinceEpoch);
      writer.writeInt(DateTime(2026).millisecondsSinceEpoch);
      writer.writeBool(false);
      final row = MoodEntryAdapter().read(
        BinaryReaderImpl(writer.toBytes(), Hive),
      );
      expect(row.mood, 'calm');
      expect(row.expressionSlug, isNull);
      expect(row.copingHelped, 'yes');
    },
  );
  test(
    'expression choice and coping helpfulness survive storage and JSON round trips',
    () {
      final row = MoodEntry(
        id: 'current',
        mood: 'calm',
        intensity: 5,
        expressionSlug: 'peaceful',
        copingHelped: 'somewhat',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
      final writer = BinaryWriterImpl(Hive);
      MoodEntryAdapter().write(writer, row);
      final restored = MoodEntryAdapter().read(
        BinaryReaderImpl(writer.toBytes(), Hive),
      );
      expect(restored.expressionSlug, 'peaceful');
      expect(restored.copingHelped, 'somewhat');
      expect(MoodEntry.fromJson(restored.toJson()).expressionSlug, 'peaceful');
    },
  );
}
