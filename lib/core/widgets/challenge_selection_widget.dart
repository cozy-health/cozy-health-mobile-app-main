import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../../utils/responsive_extensions.dart';

class ChallengeSelectionWidget extends StatelessWidget {
  final List<String> challenges;
  final List<String> selectedChallenges;
  final Function(String) onChallengeToggle;

  const ChallengeSelectionWidget({
    super.key,
    required this.challenges,
    required this.selectedChallenges,
    required this.onChallengeToggle,
  });

  Color _getChallengeColor(String challenge) {
    switch (challenge) {
      case 'Anxiety':
        return const Color(0xFFFFDDD4); // Light peach
      case 'Grief':
        return const Color(0xFFD4F4DD); // Light green
      case 'Pregnancy':
        return const Color(0xFFFFDDD4); // Light peach
      case 'Trauma':
        return const Color(0xFFFFDDD4); // Light peach
      case 'Health Issues':
        return const Color(0xFFFFB3BA); // Light pink
      case 'Relationships':
        return const Color(0xFFB3D9FF); // Light blue
      case 'Work Stress':
        return const Color(0xFFFFDDD4); // Light peach
      case 'Depression':
        return const Color(0xFFD3D3D3); // Light grey
      case 'Motivation':
        return const Color(0xFFFFB3BA); // Light pink
      case 'Anger':
        return const Color(0xFFD4F4DD); // Light green
      default:
        return const Color(0xFFFFDDD4);
    }
  }

  double _getChallengeSize(String challenge) {
    switch (challenge) {
      case 'Anxiety':
        return 25.w; // Large
      case 'Grief':
        return 18.w; // Medium
      case 'Pregnancy':
        return 28.w; // Extra large
      case 'Trauma':
        return 20.w; // Medium
      case 'Health Issues':
        return 22.w; // Medium-large
      case 'Relationships':
        return 26.w; // Large
      case 'Work Stress':
        return 24.w; // Large
      case 'Depression':
        return 20.w; // Medium
      case 'Motivation':
        return 26.w; // Large
      case 'Anger':
        return 18.w; // Medium
      default:
        return 20.w;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 65.h, // Reduced height to bring circles closer
      child: Stack(
        children: [
          // Anxiety - Top left
          Positioned(
            top: 0,
            left: 8.w,
            child: _buildChallengeCircle('Anxiety'),
          ),
          // Grief - Top right
          Positioned(
            top: 1.h,
            right: 15.w,
            child: _buildChallengeCircle('Grief'),
          ),
          // Pregnancy - Left middle (overlapping with Anxiety)
          Positioned(
            top: 12.h,
            left: 2.w,
            child: _buildChallengeCircle('Pregnancy'),
          ),
          // Trauma - Right middle (closer to Grief)
          Positioned(
            top: 14.h,
            right: 8.w,
            child: _buildChallengeCircle('Trauma'),
          ),
          // Health Issues - Center (overlapping area)
          Positioned(
            top: 22.h,
            left: 32.w,
            child: _buildChallengeCircle('Health Issues'),
          ),
          // Relationships - Left bottom (overlapping with Pregnancy)
          Positioned(
            top: 35.h,
            left: 5.w,
            child: _buildChallengeCircle('Relationships'),
          ),
          // Work Stress - Right bottom (closer to Trauma)
          Positioned(
            top: 38.h,
            right: 2.w,
            child: _buildChallengeCircle('Work Stress'),
          ),
          // Depression - Center bottom (closer to Health Issues)
          Positioned(
            top: 45.h,
            left: 38.w,
            child: _buildChallengeCircle('Depression'),
          ),
          // Motivation - Bottom left (overlapping with Relationships)
          Positioned(
            top: 52.h,
            left: 12.w,
            child: _buildChallengeCircle('Motivation'),
          ),
          // Anger - Bottom right (closer to others)
          Positioned(
            top: 54.h,
            right: 18.w,
            child: _buildChallengeCircle('Anger'),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeCircle(String challenge) {
    final isSelected = selectedChallenges.contains(challenge);
    final size = _getChallengeSize(challenge);
    
    return GestureDetector(
      onTap: () => onChallengeToggle(challenge),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? AppColors.primary : _getChallengeColor(challenge),
          border: isSelected 
              ? Border.all(color: AppColors.primary, width: 3)
              : null,
        ),
        child: Center(
          child: Text(
            challenge,
            style: AppTextStyles.body2.copyWith(
              color: isSelected ? AppColors.white : AppColors.black,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              fontSize: challenge.length > 8 ? 11 : 12,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}