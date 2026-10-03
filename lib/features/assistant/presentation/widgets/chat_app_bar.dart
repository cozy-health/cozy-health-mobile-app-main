import 'package:flutter/material.dart';
import 'chat_shared_widgets.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../models/chat.dart';

class ChatTopBar extends StatelessWidget {
  const ChatTopBar({required this.onBack, required this.onMenu});

  final VoidCallback onBack;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back',
            onPressed: onBack,
            icon: Icon(Icons.arrow_back, color: AppColors.text),
          ),
          Expanded(
            child: Text(
              'Cozy',
              textAlign: TextAlign.center,
              style: AppTextStyles.heading2.copyWith(color: AppColors.text),
            ),
          ),
          IconButton(
            tooltip: 'Conversation menu',
            onPressed: onMenu,
            icon: Icon(Icons.more_horiz, color: AppColors.text),
          ),
        ],
      ),
    );
  }
}
