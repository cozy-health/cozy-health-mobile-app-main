import 'package:cozy_health/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

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
      height: 4,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          totalPages,
          (index) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 78,
            height: 4,
            decoration: BoxDecoration(
              color: currentPage == index
                  ? Theme.of(context).colorScheme.primary
                  : AppColors.borderLight,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }
}
