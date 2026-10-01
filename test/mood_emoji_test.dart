import 'package:cozy_health/core/models/mood_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  MoodEntry entryWithMood(String mood) {
    return MoodEntry(
      id: 'test-$mood',
      mood: mood,
      intensity: 5,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
  }

  test('all mood emojis are correct', () {
    expect(MoodEntry.moodEmojis['good'], '\u{1F60A}');
    expect(MoodEntry.moodEmojis['calm'], '\u{1F60C}');
    expect(MoodEntry.moodEmojis['okay'], '\u{1F610}');
    expect(MoodEntry.moodEmojis['low'], '\u{1F614}');
    expect(MoodEntry.moodEmojis['anxious'], '\u{1F630}');
    expect(MoodEntry.moodEmojis['angry'], '\u{1F621}');
  });

  test('emoji getter handles case and whitespace', () {
    expect(entryWithMood('Angry').emoji, '\u{1F621}');
    expect(entryWithMood('  Okay  ').emoji, '\u{1F610}');
  });

  test('emoji getter falls back to okay emoji', () {
    expect(entryWithMood('unknown').emoji, '\u{1F610}');
  });
}
