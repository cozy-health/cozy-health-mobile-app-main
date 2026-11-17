/// Stable artwork for published Cozy content. Titles remain freely editable.
class ContentArtwork {
  static const _articles = {
    'a-small-start-with-journaling': 'assets/svg/journaling.svg',
    'putting-a-mood-check-in-into-context':
        'assets/png/emotional_wellbeing.png',
    'asking-for-the-kind-of-support-you-want':
        'assets/png/social_relationship.png',
  };

  static const _assessments = {
    'wellbeing-check': 'assets/png/home_quiz_brain.png',
    'cozy-coping-and-resilience': 'assets/png/copingandresilence.png',
    'cozy-emotional-well-being': 'assets/png/emotional_wellbeing.png',
    'cozy-low-mood': 'assets/png/depression.png',
    'cozy-social-and-relationship-well-being':
        'assets/png/social_relationship.png',
    'cozy-stress-and-anxiety': 'assets/png/stressandanxiety.png',
    'gad-7': 'assets/png/stressandanxiety.png',
    'phq-9': 'assets/png/depression.png',
  };

  static String assessment(String? slug) =>
      _assessments[slug] ?? 'assets/png/home_quiz_brain.png';

  static String article({String? slug, String title = '', String? category}) {
    final mapped = _articles[slug];
    if (mapped != null) return mapped;
    final text = '$title ${category ?? ''}'.toLowerCase();
    final name = text.contains('gratitude')
        ? 'gratitude'
        : text.contains('burnout') ||
              text.contains('productiv') ||
              category == 'work'
        ? 'burnout'
        : text.contains('anxiety') ||
              text.contains('depression') ||
              text.contains('stress')
        ? 'anxiety'
        : 'wellbeing';
    return 'assets/png/recommended_$name.png';
  }
}
