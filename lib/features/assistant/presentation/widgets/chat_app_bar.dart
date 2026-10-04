import 'package:flutter/material.dart';
import '../../../../core/theme/app_text_styles.dart';

class ChatTopBar extends StatelessWidget {
  const ChatTopBar({required this.onBack, required this.onMenu});

  final VoidCallback onBack;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back',
            onPressed: onBack,
            icon: Icon(Icons.arrow_back, color: textColor),
          ),
          Expanded(
            child: Text(
              'Cozy',
              textAlign: TextAlign.center,
              style: AppTextStyles.heading2.copyWith(color: textColor),
            ),
          ),
          IconButton(
            tooltip: 'Conversation menu',
            onPressed: onMenu,
            icon: Icon(Icons.more_horiz, color: textColor),
          ),
        ],
      ),
    );
  }
}
