import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class PageIndicator extends StatelessWidget {
  final int currentPage;
  final int totalPages;

  const PageIndicator({
    super.key,
    required this.currentPage,
    required this.totalPages,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 6,
      child: Stack(
        children: [
          // Background indicators (all pages)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              totalPages,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 60,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          // Active indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              totalPages,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 60,
                height: 4,
                decoration: BoxDecoration(
                  color: currentPage == index ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}