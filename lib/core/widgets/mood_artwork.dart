import 'package:flutter/material.dart';

/// The same six category characters used by the Home mood selector.
/// Specific feelings never choose or override the category artwork.
class MoodArtwork extends StatelessWidget {
  const MoodArtwork({super.key, required this.mood, required this.size});

  final String mood;
  final double size;

  static const _assets = {
    'angry': 'assets/png/home_reference_angry.png',
    'sad': 'assets/png/home_reference_sad.png',
    'good': 'assets/png/home_reference_good.png',
    'upset': 'assets/png/home_reference_upset.png',
    'spectacular': 'assets/png/home_reference_spectacular.png',
    'happy': 'assets/png/home_reference_happy.png',
  };

  static String? assetFor(String mood) => _assets[mood.trim().toLowerCase()];

  @override
  Widget build(BuildContext context) {
    final asset = assetFor(mood);
    if (asset == null) return const SizedBox.shrink();
    return Image.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      excludeFromSemantics: true,
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    );
  }
}
