import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../utils/responsive_extensions.dart';
import '../../../../gen/assets.gen.dart';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final List<ChatMessage> messages = [
    ChatMessage(
      text: "Hey there! I'm Cozy, your mental health companion. Want to check in with how you're feeling today?",
      isFromAssistant: true,
    ),
  ];

  final TextEditingController _messageController = TextEditingController();
  bool hasResponded = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      messages.add(ChatMessage(
        text: _messageController.text.trim(),
        isFromAssistant: false,
      ));

      // Simulate assistant reply
      if (!hasResponded) {
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            setState(() {
              messages.add(ChatMessage(
                text: "Thank you for sharing. I'm here to listen without judgment. Would you like to talk more about what's been on your mind?",
                isFromAssistant: true,
              ));
            });
          }
        });
        hasResponded = true;
      }
    });

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: Row(
          children: [
            SvgPicture.asset(
              Assets.svg.assistant,
              width: 32,
              height: 32,
            ),
            3.sw,
            Text(
              'Cozy Assistant',
              style: AppTextStyles.heading2,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                return _buildChatBubble(message);
              },
            ),
          ),

          // Input area
          Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: AppColors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: "Type your message...",
                      hintStyle: AppTextStyles.body1.copyWith(color: AppColors.grey),
                      filled: true,
                      fillColor: AppColors.lightGrey,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.5.h),
                    ),
                    maxLines: null,
                  ),
                ),
                3.sw,
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send,
                      color: AppColors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage message) {
    if (message.isFromAssistant) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: SvgPicture.asset(
              Assets.svg.assistant,
              width: 24,
              height: 24,
            ),
          ),
          3.sw,
          Expanded(
            child: Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FFF0),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                message.text,
                style: AppTextStyles.body1,
              ),
            ),
          ),
        ],
      );
    } else {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            message.text,
            style: AppTextStyles.body1.copyWith(color: AppColors.white),
          ),
        ),
      );
    }
  }
}

class ChatMessage {
  final String text;
  final bool isFromAssistant;

  ChatMessage({
    required this.text,
    required this.isFromAssistant,
  });
}