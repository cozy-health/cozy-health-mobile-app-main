import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class ChatInputBar extends StatelessWidget {
  const ChatInputBar({
    required this.controller,
    required this.sending,
    required this.onMic,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onMic;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final hasText = controller.text.trim().isNotEmpty;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.only(left: 18, right: 8),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.surfaceElevatedDark
              : AppColors.surfaceElevatedLight,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Message Cozy...',
                  hintStyle: AppTextStyles.body1.copyWith(
                    color: isDark
                        ? AppColors.textSubtleDark
                        : AppColors.textSubtleLight,
                  ),
                  border: InputBorder.none,
                ),
                style: AppTextStyles.body1.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Voice input',
              onPressed: onMic,
              icon: Icon(
                Icons.mic_none_rounded,
                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: SizedBox(
                width: 32,
                height: 32,
                child: ElevatedButton(
                  onPressed: hasText && !sending ? onSend : null,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    disabledBackgroundColor:
                        isDark ? AppColors.borderDark : AppColors.borderLight,
                    foregroundColor: AppColors.white,
                    disabledForegroundColor:
                        isDark ? AppColors.textSubtleDark : AppColors.textSubtleLight,
                    elevation: 0,
                    shape: const CircleBorder(),
                  ),
                  child: sending
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      : Icon(Icons.arrow_upward_rounded, size: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
