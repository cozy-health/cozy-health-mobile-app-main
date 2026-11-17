import '../models/user_preferences.dart';

class HomeSuggestion {
  const HomeSuggestion({
    required this.id,
    required this.title,
    required this.reason,
    this.prompt,
  });

  final String id;
  final String title;
  final String reason;
  final String? prompt;
  bool get isBreathing => prompt == null;
}

/// Stable display order, independent of the order in which answers were tapped.
List<HomeSuggestion> homeSuggestions(UserPreferences? preferences) {
  if (preferences == null) return const [];
  const focuses = {
    'Anxiety': 'What is on your mind, and what could help you feel supported?',
    'Low mood':
        'How are you feeling today, and what is one small kindness you could offer yourself?',
    'Stress':
        'What feels demanding today, and what could you set down for a moment?',
    'Sleep': 'What thoughts are you carrying into your evening?',
    'Relationships':
        'What do you need from the relationships in your life right now?',
    'Self-growth': 'What is something you are learning about yourself?',
  };
  const challenges = {
    'Work': 'What has felt difficult about work lately?',
    'School': 'What has felt difficult about school lately?',
    'Family': 'What has felt difficult about family life lately?',
    'Health': 'What feelings have come up around your health lately?',
    'Money': 'What feelings have come up around money lately?',
    'Loneliness':
        'When have you felt lonely lately, and what connection would feel helpful?',
  };
  final selectedFocus = focuses.keys
      .where(preferences.focusAreas.contains)
      .toList();
  final selectedChallenges = challenges.keys
      .where(preferences.currentChallenges.contains)
      .toList();
  final result = <HomeSuggestion>[];
  final breathingFocus = selectedFocus
      .where((v) => v == 'Anxiety' || v == 'Stress')
      .firstOrNull;
  if (breathingFocus != null) {
    result.add(
      HomeSuggestion(
        id: 'breathing',
        title: 'Take a breathing break',
        reason: 'Based on your focus on ${breathingFocus.toLowerCase()}',
      ),
    );
  }
  final challenge = selectedChallenges.firstOrNull;
  final journalFocus = selectedFocus
      .where((v) => v != 'Anxiety' && v != 'Stress')
      .firstOrNull;
  final key = challenge ?? journalFocus;
  if (key != null) {
    final prompt = challenge != null ? challenges[key] : focuses[key];
    if (prompt == null) return result;
    result.add(
      HomeSuggestion(
        id: 'onboarding_${challenge != null ? 'challenge' : 'focus'}_${key.toLowerCase().replaceAll(' ', '_')}',
        title: 'Make space for your thoughts',
        reason: challenge != null
            ? 'Based on what you shared about ${challenge.toLowerCase()}'
            : 'Based on your focus on ${key.toLowerCase()}',
        prompt: prompt,
      ),
    );
  }
  return result;
}
