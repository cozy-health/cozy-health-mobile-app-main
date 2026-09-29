import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../../gen/assets.gen.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        border: Border(
          top: BorderSide(color: AppColors.border.withValues(alpha: .4)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, 'Home', Assets.svg.home),
          _buildNavItem(1, 'Activity', Assets.svg.activity),
          _buildNavItem(2, 'Assistant', Assets.svg.assistant),
          _buildNavItem(3, 'Community', Assets.svg.community),
          _buildNavItem(4, 'Settings', Assets.svg.settings),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, String label, String assetPath) {
    final isSelected = currentIndex == index;

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: GestureDetector(
        onTap: () => onTap(index),
        child: Container(
          width: 64,
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 42,
                height: 30,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primarySoft
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    assetPath,
                    width: 24,
                    height: 24,
                    colorFilter: ColorFilter.mode(
                      isSelected ? AppColors.primary : AppColors.textMuted,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: AppTextStyles.body2.copyWith(
                  color: isSelected ? AppColors.primary : AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
