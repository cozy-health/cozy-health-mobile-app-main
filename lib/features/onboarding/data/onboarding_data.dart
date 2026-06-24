import '../../../gen/assets.gen.dart';

class OnboardingData {
  final String title;
  final String description;
  final AssetGenImage pngAsset;

  OnboardingData({
    required this.title,
    required this.description,
    required this.pngAsset,
  });

  static List<OnboardingData> get pages => [
        OnboardingData(
          title: 'Understand Your Emotions',
          description: 'Check in with your feelings daily, recognize patterns, and reflect with guided journaling.',
          pngAsset: Assets.png.emotionalWellbeing,
        ),
        OnboardingData(
          title: 'You\'re Not Alone',
          description: 'Join a safe space where you can share experiences, and find encouragement from people who understand your journey',
          pngAsset: Assets.png.onboardTwo,
        ),
        OnboardingData(
          title: 'Your Safe Space',
          description: 'Your mental health journey is personal. We prioritize your privacy with secure data protection and customizable settings',
          pngAsset: Assets.png.onboardThree,
        ),
      ];
}