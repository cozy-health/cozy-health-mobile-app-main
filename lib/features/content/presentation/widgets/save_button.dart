import 'package:flutter/material.dart';
import '../../../../core/theme/app_text_styles.dart';

class SaveButton extends StatelessWidget {
  final bool isSaved;
  final VoidCallback onToggle;
  final bool isIconOnly;

  const SaveButton({
    super.key,
    required this.isSaved,
    required this.onToggle,
    this.isIconOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isIconOnly) {
      return IconButton(
        icon: Icon(
          isSaved ? Icons.bookmark : Icons.bookmark_border,
          color: isSaved
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface,
        ),
        onPressed: onToggle,
      );
    }

    return GestureDetector(
      onTap: onToggle,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSaved ? Icons.bookmark : Icons.bookmark_border,
              color: isSaved
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface,
              size: 20,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                isSaved ? 'Saved for later' : 'Save for later',
                style: AppTextStyles.body1.copyWith(
                  fontWeight: FontWeight.w500,
                  color: isSaved
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
