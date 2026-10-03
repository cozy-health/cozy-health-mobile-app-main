import 'package:flutter/material.dart';
import 'chat_shared_widgets.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../models/chat.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    required this.message,
    required this.onLongPress,
    this.onRetry,
  });

  final ChatMessage message;
  final VoidCallback? onLongPress;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == ChatRole.user;
    return Column(
      crossAxisAlignment: isUser
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: GestureDetector(
            onLongPress: onLongPress,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth:
                    MediaQuery.of(context).size.width * (isUser ? .8 : .85),
              ),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: message.status == MessageStatus.sending ? .65 : 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isUser
                        ? Theme.of(context).colorScheme.primary
                        : AppColors.surfaceElevated,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isUser ? 20 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 20),
                    ),
                    border: isUser ? null : Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    message.text,
                    style: AppTextStyles.body1.copyWith(
                      color: isUser ? AppColors.white : AppColors.text,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: isUser
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: [
            Text(formatTime(message.createdAt), style: timestampStyle()),
            if (message.status == MessageStatus.failed) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.error_outline,
                color: AppColors.danger,
                size: 14,
              ),
            ],
          ],
        ),
        if (message.status == MessageStatus.failed && onRetry != null) ...[
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: ActionChip(label: const Text('Retry'), onPressed: onRetry),
          ),
        ],
      ],
    );
  }
}
