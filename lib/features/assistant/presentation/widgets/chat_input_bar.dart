import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class ChatInputBar extends StatelessWidget {
  const ChatInputBar({
    super.key,
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
    final colorScheme = Theme.of(context).colorScheme;
    final fillColor = isDark
        ? AppColors.surfaceElevatedDark
        : AppColors.surfaceElevatedLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final mutedColor = isDark
        ? AppColors.textMutedDark
        : AppColors.textMutedLight;
    final subtleColor = isDark
        ? AppColors.textSubtleDark
        : AppColors.textSubtleLight;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 14),
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.fromLTRB(18, 6, 8, 6),
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) {
                  if (hasText && !sending) onSend();
                },
                decoration: InputDecoration(
                  hintText: 'Message Cozy Assistant...',
                  hintMaxLines: 1,
                  hintStyle: AppTextStyles.body1.copyWith(color: subtleColor),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  border: InputBorder.none,
                ),
                style: AppTextStyles.body1.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              tooltip: 'Voice input',
              onPressed: onMic,
              visualDensity: VisualDensity.compact,
              style: IconButton.styleFrom(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: mutedColor,
              ),
              icon: Icon(Icons.mic_none_rounded, color: mutedColor),
            ),
            const SizedBox(width: 2),
            SizedBox(
              width: 38,
              height: 38,
              child: IconButton.filled(
                tooltip: 'Send message',
                onPressed: hasText && !sending ? onSend : null,
                style: IconButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  disabledBackgroundColor: borderColor,
                  foregroundColor: AppColors.white,
                  disabledForegroundColor: subtleColor,
                  padding: EdgeInsets.zero,
                ),
                icon: sending
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : const Icon(Icons.arrow_upward_rounded, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
