class DigitalWellbeingPreferences {
  const DigitalWellbeingPreferences({
    this.gentleReminders = false,
    this.dailyLimitMinutes = 0,
    this.showUsageSummary = false,
  });
  final bool gentleReminders;

  /// Zero means no suggested limit. These preferences do not enforce a limit.
  final int dailyLimitMinutes;
  final bool showUsageSummary;

  factory DigitalWellbeingPreferences.fromMap(Map<dynamic, dynamic> value) =>
      DigitalWellbeingPreferences(
        gentleReminders: value['gentle_reminders'] == true,
        dailyLimitMinutes:
            const [0, 15, 30, 60].contains(value['daily_limit_minutes'])
            ? value['daily_limit_minutes'] as int
            : 0,
        showUsageSummary: value['show_usage_summary'] == true,
      );

  Map<String, dynamic> toMap() => {
    'gentle_reminders': gentleReminders,
    'daily_limit_minutes': dailyLimitMinutes,
    'show_usage_summary': showUsageSummary,
  };

  DigitalWellbeingPreferences copyWith({
    bool? gentleReminders,
    int? dailyLimitMinutes,
    bool? showUsageSummary,
  }) => DigitalWellbeingPreferences(
    gentleReminders: gentleReminders ?? this.gentleReminders,
    dailyLimitMinutes: dailyLimitMinutes ?? this.dailyLimitMinutes,
    showUsageSummary: showUsageSummary ?? this.showUsageSummary,
  );
}
