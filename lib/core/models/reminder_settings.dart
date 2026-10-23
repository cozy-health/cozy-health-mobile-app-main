class ReminderSettings {
  static const defaults = <String, dynamic>{
    'mood_days': [1, 2, 3, 4, 5, 6, 7],
    'journal_time': '18:00',
    'journal_days': [7],
    'streak_enabled': false,
    'streak_time': '20:00',
    'streak_days': [1, 2, 3, 4, 5, 6, 7],
    'affirmation_enabled': false,
    'affirmation_time': '12:00',
    'affirmation_days': [1, 2, 3, 4, 5, 6, 7],
    'community_likes_enabled': true,
    'community_push_enabled': true,
    'quiet_enabled': true,
    'quiet_start': '22:00',
    'quiet_end': '08:00',
  };

  static Map<String, dynamic> resolve(Map<String, dynamic>? settings) => {
    ...defaults,
    ...?settings,
  };
}
