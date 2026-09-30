import 'package:flutter/material.dart';
import 'chat_shared_widgets.dart';
import 'message_bubble.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/chat_repository.dart';
import '../../models/chat.dart';

class ConversationHistoryScreen extends StatefulWidget {
  const ConversationHistoryScreen({super.key, required this.conversations});

  final List<Conversation> conversations;

  @override
  State<ConversationHistoryScreen> createState() =>
      _ConversationHistoryScreenState();
}

class _ConversationHistoryScreenState extends State<ConversationHistoryScreen> {
  late final List<Conversation> _conversations = [...widget.conversations];

  @override
  Widget build(BuildContext context) {
    return AssistantSubScaffold(
      title: 'History',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        children: [
          WarmPanel(
            color: AppColors.primarySubtle,
            borderColor: AppColors.primary.withValues(alpha: .15),
            padding: const EdgeInsets.all(14),
            child: InkWell(
              onTap: () => Navigator.pop(context, Conversation.empty()),
              child: Text(
                '+ New conversation',
                style: AppTextStyles.body1.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          if (_conversations.isEmpty)
            const ConversationEmptyState()
          else ...[
            HistorySection(
              title: 'Today',
              conversations: _conversations.take(1).toList(),
              onOpen: _openConversation,
              onDelete: _confirmDelete,
            ),
            const SizedBox(height: 28),
            HistorySection(
              title: 'Yesterday',
              conversations: _conversations.skip(1).take(2).toList(),
              onOpen: _openConversation,
              onDelete: _confirmDelete,
            ),
            const SizedBox(height: 28),
            HistorySection(
              title: 'Earlier this week',
              conversations: _conversations.skip(3).toList(),
              onOpen: _openConversation,
              onDelete: _confirmDelete,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openConversation(Conversation conversation) async {
    final resume = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PastConversationScreen(conversation: conversation),
      ),
    );
    if (resume == true && mounted) Navigator.pop(context, conversation);
  }

  void _confirmDelete(Conversation conversation) {
    showDialog<void>(
      context: context,
      builder: (context) => DeleteConversationDialog(
        onDelete: () async {
          Navigator.pop(context);
          final index = _conversations.indexWhere(
            (item) => item.id == conversation.id,
          );
          if (index == -1) return;
          
          final repo = ChatRepository();
          await repo.deleteConversation(conversation.id);
          
          if (!mounted) return;
          
          setState(() => _conversations.removeAt(index));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Conversation deleted'),
              action: SnackBarAction(
                label: 'Undo',
                onPressed: () {
                  setState(() => _conversations.insert(index, conversation));
                  repo.saveConversation(conversation.toChatConversation());
                  // also need to restore messages, but for now just saving the conversation back is enough
                }
              ),
            ),
          );
        },
      ),
    );
  }
}

class PastConversationScreen extends StatelessWidget {
  const PastConversationScreen({super.key, required this.conversation});

  final Conversation conversation;

  @override
  Widget build(BuildContext context) {
    return AssistantSubScaffold(
      title: conversation.title,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
              children: conversation.messages
                  .map(
                    (message) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: MessageBubble(
                        message: message,
                        onLongPress: null,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: PrimaryButton(
              label: 'Continue conversation',
              onPressed: () => Navigator.pop(context, true),
            ),
          ),
        ],
      ),
    );
  }
}

class HistorySection extends StatelessWidget {
  const HistorySection({
    required this.title,
    required this.conversations,
    required this.onOpen,
    required this.onDelete,
  });

  final String title;
  final List<Conversation> conversations;
  final ValueChanged<Conversation> onOpen;
  final ValueChanged<Conversation> onDelete;

  @override
  Widget build(BuildContext context) {
    if (conversations.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.heading2.copyWith(color: AppColors.text),
        ),
        const SizedBox(height: 12),
        for (final conversation in conversations) ...[
          ConversationCard(
            conversation: conversation,
            onTap: () => onOpen(conversation),
            onLongPress: () => onDelete(conversation),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class ConversationCard extends StatelessWidget {
  const ConversationCard({
    required this.conversation,
    required this.onTap,
    required this.onLongPress,
  });

  final Conversation conversation;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(16),
      child: WarmPanel(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conversation.title,
                    style: AppTextStyles.body1.copyWith(
                      color: AppColors.text,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '"${conversation.lastMessagePreview}"',
                    style: AppTextStyles.body2.copyWith(
                      color: AppColors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(formatTime(conversation.updatedAt), style: timestampStyle()),
          ],
        ),
      ),
    );
  }
}

class ConversationEmptyState extends StatelessWidget {
  const ConversationEmptyState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 80),
        const Icon(
          Icons.chat_bubble_outline_rounded,
          size: 56,
          color: AppColors.primary,
        ),
        const SizedBox(height: 22),
        Text(
          'No conversations yet.',
          style: AppTextStyles.heading2.copyWith(color: AppColors.text),
        ),
        const SizedBox(height: 10),
        Text(
          "Start one whenever\nyou're ready.",
          textAlign: TextAlign.center,
          style: AppTextStyles.body1.copyWith(
            color: AppColors.textMuted,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class DeleteConversationDialog extends StatelessWidget {
  const DeleteConversationDialog({required this.onDelete});

  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: WarmPanel(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Delete this\nconversation?',
              textAlign: TextAlign.center,
              style: AppTextStyles.heading2.copyWith(color: AppColors.text),
            ),
            const SizedBox(height: 12),
            Text(
              'All messages will be\npermanently removed.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body1.copyWith(
                color: AppColors.textMuted,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: onDelete,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Delete'),
              ),
            ),
            const SizedBox(height: 10),
            SecondaryButton(
              label: 'Cancel',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
