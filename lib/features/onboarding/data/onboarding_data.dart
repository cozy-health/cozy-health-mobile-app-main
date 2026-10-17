class OnboardingData {
  const OnboardingData({
    required this.title,
    required this.description,
    required this.asset,
  });
  final String title;
  final String description;
  final String asset;
  static const pages = [
    OnboardingData(
      title: 'Understand Your Emotions',
      description:
          'Check in with your feelings daily, recognize patterns, and reflect with guided journaling.',
      asset: 'assets/png/intro_emotions.png',
    ),
    OnboardingData(
      title: 'You\u2019re Not Alone',
      description:
          'Join a safe space where you can share experiences, and find encouragement from people who understand your journey',
      asset: 'assets/png/intro_community.png',
    ),
    OnboardingData(
      title: 'Your Safe Space',
      description:
          'Your mental health journey is personal. We prioritize your privacy with secure data protection and customizable settings',
      asset: 'assets/png/intro_privacy.png',
    ),
  ];
}
