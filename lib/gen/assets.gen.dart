// dart format width=80

/// GENERATED CODE - DO NOT MODIFY BY HAND
/// *****************************************************
///  FlutterGen
/// *****************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: deprecated_member_use,directives_ordering,implicit_dynamic_list_literal,unnecessary_import

import 'package:flutter/widgets.dart';

class $AssetsPngGen {
  const $AssetsPngGen();

  /// File path: assets/png/confetti.png
  AssetGenImage get confetti => const AssetGenImage('assets/png/confetti.png');

  /// File path: assets/png/copingandresilence.png
  AssetGenImage get copingandresilence =>
      const AssetGenImage('assets/png/copingandresilence.png');

  /// File path: assets/png/depression.png
  AssetGenImage get depression =>
      const AssetGenImage('assets/png/depression.png');

  /// File path: assets/png/emotional_wellbeing.png
  AssetGenImage get emotionalWellbeing =>
      const AssetGenImage('assets/png/emotional_wellbeing.png');

  /// File path: assets/png/mental quiz.png
  AssetGenImage get mentalQuiz =>
      const AssetGenImage('assets/png/mental quiz.png');

  /// File path: assets/png/onboard_three.png
  AssetGenImage get onboardThree =>
      const AssetGenImage('assets/png/onboard_three.png');

  /// File path: assets/png/onboard_two.png
  AssetGenImage get onboardTwo =>
      const AssetGenImage('assets/png/onboard_two.png');

  /// File path: assets/png/profile_pic.png
  AssetGenImage get profilePic =>
      const AssetGenImage('assets/png/profile_pic.png');

  /// File path: assets/png/social_relationship.png
  AssetGenImage get socialRelationship =>
      const AssetGenImage('assets/png/social_relationship.png');

  /// File path: assets/png/stressandanxiety.png
  AssetGenImage get stressandanxiety =>
      const AssetGenImage('assets/png/stressandanxiety.png');

  /// List of all assets
  List<AssetGenImage> get values => [
    confetti,
    copingandresilence,
    depression,
    emotionalWellbeing,
    mentalQuiz,
    onboardThree,
    onboardTwo,
    profilePic,
    socialRelationship,
    stressandanxiety,
  ];
}

class $AssetsSvgGen {
  const $AssetsSvgGen();

  /// File path: assets/svg/activity.svg
  String get activity => 'assets/svg/activity.svg';

  /// File path: assets/svg/angry.svg
  String get angry => 'assets/svg/angry.svg';

  /// File path: assets/svg/assistant.svg
  String get assistant => 'assets/svg/assistant.svg';

  /// File path: assets/svg/community.svg
  String get community => 'assets/svg/community.svg';

  /// File path: assets/svg/confetti.svg
  String get confetti => 'assets/svg/confetti.svg';

  /// File path: assets/svg/good.svg
  String get good => 'assets/svg/good.svg';

  /// File path: assets/svg/google.svg
  String get google => 'assets/svg/google.svg';

  /// File path: assets/svg/home.svg
  String get home => 'assets/svg/home.svg';

  /// File path: assets/svg/journaling.svg
  String get journaling => 'assets/svg/journaling.svg';

  /// File path: assets/svg/journaling_icon.svg
  String get journalingIcon => 'assets/svg/journaling_icon.svg';

  /// File path: assets/svg/logo.svg
  String get logo => 'assets/svg/logo.svg';

  /// File path: assets/svg/mental quiz.svg
  String get mentalQuiz => 'assets/svg/mental quiz.svg';

  /// File path: assets/svg/mental_health_quiz.svg
  String get mentalHealthQuiz => 'assets/svg/mental_health_quiz.svg';

  /// File path: assets/svg/mood_check_in.svg
  String get moodCheckIn => 'assets/svg/mood_check_in.svg';

  /// File path: assets/svg/no_notification.svg
  String get noNotification => 'assets/svg/no_notification.svg';

  /// File path: assets/svg/notification.svg
  String get notification => 'assets/svg/notification.svg';

  /// File path: assets/svg/padlock_closed.svg
  String get padlockClosed => 'assets/svg/padlock_closed.svg';

  /// File path: assets/svg/padlock_open.svg
  String get padlockOpen => 'assets/svg/padlock_open.svg';

  /// File path: assets/svg/sad.svg
  String get sad => 'assets/svg/sad.svg';

  /// File path: assets/svg/settings.svg
  String get settings => 'assets/svg/settings.svg';

  /// File path: assets/svg/upset.svg
  String get upset => 'assets/svg/upset.svg';

  /// File path: assets/svg/warning.svg
  String get warning => 'assets/svg/warning.svg';

  /// List of all assets
  List<String> get values => [
    activity,
    angry,
    assistant,
    community,
    confetti,
    good,
    google,
    home,
    journaling,
    journalingIcon,
    logo,
    mentalQuiz,
    mentalHealthQuiz,
    moodCheckIn,
    noNotification,
    notification,
    padlockClosed,
    padlockOpen,
    sad,
    settings,
    upset,
    warning,
  ];
}

class Assets {
  const Assets._();

  static const $AssetsPngGen png = $AssetsPngGen();
  static const $AssetsSvgGen svg = $AssetsSvgGen();
}

class AssetGenImage {
  const AssetGenImage(
    this._assetName, {
    this.size,
    this.flavors = const {},
    this.animation,
  });

  final String _assetName;

  final Size? size;
  final Set<String> flavors;
  final AssetGenImageAnimation? animation;

  Image image({
    Key? key,
    AssetBundle? bundle,
    ImageFrameBuilder? frameBuilder,
    ImageErrorWidgetBuilder? errorBuilder,
    String? semanticLabel,
    bool excludeFromSemantics = false,
    double? scale,
    double? width,
    double? height,
    Color? color,
    Animation<double>? opacity,
    BlendMode? colorBlendMode,
    BoxFit? fit,
    AlignmentGeometry alignment = Alignment.center,
    ImageRepeat repeat = ImageRepeat.noRepeat,
    Rect? centerSlice,
    bool matchTextDirection = false,
    bool gaplessPlayback = true,
    bool isAntiAlias = false,
    String? package,
    FilterQuality filterQuality = FilterQuality.medium,
    int? cacheWidth,
    int? cacheHeight,
  }) {
    return Image.asset(
      _assetName,
      key: key,
      bundle: bundle,
      frameBuilder: frameBuilder,
      errorBuilder: errorBuilder,
      semanticLabel: semanticLabel,
      excludeFromSemantics: excludeFromSemantics,
      scale: scale,
      width: width,
      height: height,
      color: color,
      opacity: opacity,
      colorBlendMode: colorBlendMode,
      fit: fit,
      alignment: alignment,
      repeat: repeat,
      centerSlice: centerSlice,
      matchTextDirection: matchTextDirection,
      gaplessPlayback: gaplessPlayback,
      isAntiAlias: isAntiAlias,
      package: package,
      filterQuality: filterQuality,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
    );
  }

  ImageProvider provider({AssetBundle? bundle, String? package}) {
    return AssetImage(_assetName, bundle: bundle, package: package);
  }

  String get path => _assetName;

  String get keyName => _assetName;
}

class AssetGenImageAnimation {
  const AssetGenImageAnimation({
    required this.isAnimation,
    required this.duration,
    required this.frames,
  });

  final bool isAnimation;
  final Duration duration;
  final int frames;
}
