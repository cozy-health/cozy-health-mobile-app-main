import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../../gen/assets.gen.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final GlobalKey? assistantTourKey;
  final bool showAssistant;

  const CustomBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.assistantTourKey,
    this.showAssistant = true,
  });

  @override
  Widget build(BuildContext context) {
    final navTheme = Theme.of(context).bottomNavigationBarTheme;
    final dividerColor = Theme.of(context).dividerTheme.color;

    return Container(
      decoration: BoxDecoration(
        color: navTheme.backgroundColor,
        border: Border(
          top: BorderSide(
            color: (dividerColor ?? AppColors.border).withValues(alpha: .4),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        bottom: true,
        child: SizedBox(
          height: 72,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(context, 0, 'Home', Assets.svg.home),
              _buildNavItem(context, 1, 'Activity', Assets.svg.activity),
              if (showAssistant)
                _buildNavItem(context, 2, 'Assistant', Assets.svg.assistant),
              _buildNavItem(context, 3, 'Community', Assets.svg.community),
              _buildNavItem(context, 4, 'Settings', Assets.svg.settings),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    int index,
    String label,
    String assetPath,
  ) {
    final isSelected = currentIndex == index;
    final navTheme = Theme.of(context).bottomNavigationBarTheme;
    final selectedColor =
        navTheme.selectedItemColor ?? Theme.of(context).colorScheme.primary;
    final unselectedColor =
        navTheme.unselectedItemColor ?? Theme.of(context).colorScheme.onSurface;

    return Semantics(
      key: index == 2 ? assistantTourKey : null,
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
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 200),
                width: 42,
                height: 30,
                decoration: BoxDecoration(
                  color: isSelected
                      ? selectedColor.withValues(alpha: .12)
                      : null,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    assetPath,
                    width: 24,
                    height: 24,
                    colorFilter: ColorFilter.mode(
                      isSelected ? selectedColor : unselectedColor,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: AppTextStyles.body2.copyWith(
                  color: isSelected ? selectedColor : unselectedColor,
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
