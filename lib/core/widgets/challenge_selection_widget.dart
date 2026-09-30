import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../../utils/responsive_extensions.dart';

class BubbleTheme {
  final Color background;
  final Color border;
  const BubbleTheme(this.background, this.border);
}

class ChallengeSelectionWidget extends StatelessWidget {
  final List<String> challenges;
  final List<String> selectedChallenges;
  final Function(String) onChallengeToggle;

  static const List<BubbleTheme> _themes = [
    BubbleTheme(Color(0xFFFFE0D0), Color(0xFFCC5500)), // Peach/Orange
    BubbleTheme(Color(0xFFD1F2D9), Color(0xFF16A34A)), // Mint/Emerald
    BubbleTheme(Color(0xFFFFC5C5), Color(0xFFB91C1C)), // Pink/Red
    BubbleTheme(Color(0xFFCBE3FF), Color(0xFF1D4ED8)), // Blue/Dark Blue
    BubbleTheme(Color(0xFFFFF0C2), Color(0xFFCA8A04)), // Yellow/Dark Yellow
    BubbleTheme(Color(0xFFE8D1FF), Color(0xFF7E22CE)), // Lavender/Purple
    BubbleTheme(Color(0xFFE2E2E2), Color(0xFF4B5563)), // Grey/Dark Grey
  ];

  const ChallengeSelectionWidget({
    super.key,
    required this.challenges,
    required this.selectedChallenges,
    required this.onChallengeToggle,
  });

  BubbleTheme _getTheme(String challenge) {
    int index = challenges.indexOf(challenge);
    if (index == -1) index = challenge.hashCode.abs();
    
    // Multiply by a prime (3) to shuffle the 7 themes. 
    // This guarantees adjacent bubbles in the Wrap never share a color.
    int colorIndex = (index * 3) % _themes.length;
    return _themes[colorIndex];
  }

  double _getChallengeSize(String challenge) {
    if (challenge.length > 12) return 28.w;
    if (challenge.length > 8) return 26.w;
    
    int index = challenges.indexOf(challenge);
    if (index == -1) index = challenge.hashCode.abs();

    return 22.w + ((index * 2) % 3) * 2.w; 
  }

  Alignment _getAlignment(int index) {
    // A precisely calculated interlocking honeycomb matrix to ensure 
    // bubbles scatter organically without ever eclipsing each other's text.
    const alignments = [
      Alignment(-0.9, -1.0), // Row 1, Left
      Alignment(0.0, -1.0),  // Row 1, Center
      Alignment(0.9, -1.0),  // Row 1, Right
      Alignment(-0.5, -0.6), // Row 2, Mid-Left
      Alignment(0.5, -0.6),  // Row 2, Mid-Right
      Alignment(-0.9, -0.2), // Row 3, Left
      Alignment(0.0, -0.2),  // Row 3, Center
      Alignment(0.9, -0.2),  // Row 3, Right
      Alignment(-0.5, 0.2),  // Row 4, Mid-Left
      Alignment(0.5, 0.2),   // Row 4, Mid-Right
      Alignment(-0.9, 0.6),  // Row 5, Left
      Alignment(0.0, 0.6),   // Row 5, Center
      Alignment(0.9, 0.6),   // Row 5, Right
      Alignment(-0.5, 1.0),  // Row 6, Mid-Left
      Alignment(0.5, 1.0),   // Row 6, Mid-Right
    ];
    return alignments[index % alignments.length];
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        clipBehavior: Clip.none,
        children: challenges.asMap().entries.map((entry) {
          return Align(
            alignment: _getAlignment(entry.key),
            child: _buildChallengeCircle(entry.value),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChallengeCircle(String challenge) {
    if (!challenges.contains(challenge)) return const SizedBox.shrink();
    final isSelected = selectedChallenges.contains(challenge);
    final size = _getChallengeSize(challenge);
    final theme = _getTheme(challenge);

    return GestureDetector(
      onTap: () => onChallengeToggle(challenge),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: theme.background,
          border: isSelected 
              ? Border.all(color: theme.border, width: 2.5)
              : Border.all(color: Colors.transparent, width: 2.5),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Text(
              challenge,
              style: AppTextStyles.body2.copyWith(
                color: AppColors.black,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                fontSize: challenge.length > 8 ? 11 : 13,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ),
        ),
      ),
    );
  }
}