import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../../utils/responsive_extensions.dart';

class OptionSelectionWidget extends StatelessWidget {
  final List<String> options;
  final List<String> selectedOptions;
  final Function(String) onOptionToggle;
  final bool allowMultiple;

  const OptionSelectionWidget({
    super.key,
    required this.options,
    required this.selectedOptions,
    required this.onOptionToggle,
    this.allowMultiple = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: options.map((option) {
        final isSelected = selectedOptions.contains(option);

        return Container(
          margin: EdgeInsets.only(bottom: 1.h),
          child: GestureDetector(
            onTap: () => onOptionToggle(option),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.midGrey,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      option,
                      style: AppTextStyles.body1.copyWith(
                        color: AppColors.black,
                      ),
                    ),
                  ),
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? AppColors.primary
                          : Colors.transparent,
                      border: isSelected
                          ? null
                          : Border.all(color: AppColors.midGrey, width: 1.5),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
