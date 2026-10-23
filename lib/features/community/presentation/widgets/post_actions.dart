import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/wellness_sheet.dart';
import '../../../../core/widgets/wellness_panel.dart';
import '../../../../core/theme/cozy_colors.dart';
import '../community_local_state.dart';
import 'report_sheet.dart';
import '../../../../core/data/demo_mode.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/services/local_db_service.dart';

class PostActions {
  static Future<void> show(
    BuildContext context,
    Map<String, dynamic> post,
  ) async {
    final owner = LocalDbService().activeUserId;
    bool current() => context.mounted && owner == LocalDbService().activeUserId;
    final canBlock =
        post['isAnonymous'] != true &&
        post['isOwner'] != true &&
        post['authorId']?.toString() != owner &&
        (DemoMode.instance.enabled || post['authorId'] != null);
    final choice = await showWellnessSheet<String>(
      context: context,
      builder: (context) => WellnessSheet(
        title: 'Post options',
        children: [
          const Text('Choose what you’d like to do with this post.'),
          SizedBox(height: context.cozyColors.wellness.gap),
          WellnessSheetOption(
            key: const ValueKey('post-copy'),
            label: 'Copy post',
            icon: Icons.copy_outlined,
            onPressed: () => Navigator.pop(context, 'copy'),
          ),
          WellnessSheetOption(
            key: const ValueKey('post-report'),
            label: 'Report post',
            subtitle: 'Send a concern to the moderation team',
            icon: Icons.flag_outlined,
            onPressed: () => Navigator.pop(context, 'report'),
          ),
          if (canBlock)
            WellnessSheetOption(
              key: const ValueKey('post-block'),
              label: 'Block member',
              subtitle: 'Review before hiding their posts',
              icon: Icons.block_outlined,
              destructive: true,
              onPressed: () => Navigator.pop(context, 'block'),
            ),
          WellnessAction(
            label: 'Cancel',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
    if (!context.mounted || !current() || choice == null) return;
    if (choice == 'copy') {
      await Clipboard.setData(
        ClipboardData(text: post['content'] as String? ?? ''),
      );
      if (context.mounted && current()) {
        AppSnackbar.show(context, AppSnackbar.info('Post copied'));
      }
    } else if (choice == 'block') {
      final confirmed = await confirmWellnessAction(
        context,
        title: 'Block this member?',
        message:
            'Their posts will be hidden. You can unblock them in Settings.',
        action: 'Block member',
        cancel: 'Keep member unblocked',
      );
      if (!confirmed || !current()) return;
      try {
        if (!DemoMode.instance.enabled) {
          await ApiClient().post('/community/users/${post['authorId']}/block');
        }
        if (!context.mounted || !current()) return;
        CommunityLocalState.instance.blockUser(
          post['username'] as String? ?? '',
        );
        AppSnackbar.show(
          context,
          AppSnackbar.info(
            DemoMode.instance.enabled
                ? 'User hidden for this demo session'
                : 'User blocked',
          ),
        );
      } catch (_) {
        if (context.mounted && current()) {
          AppSnackbar.show(
            context,
            AppSnackbar.error('Could not block this person. Please retry.'),
          );
        }
      }
    } else if (choice == 'report') {
      ReportSheet.show(
        context,
        onReport: DemoMode.instance.enabled
            ? null
            : (reason, details) async {
                if (!current()) throw StateError('Account changed');
                final code =
                    {
                      'Harassment or hate speech': 'harassment',
                      'Encourages harm': 'safety',
                      'Spam or scam': 'spam',
                    }[reason] ??
                    'other';
                await ApiClient().post(
                  '/community/${post['kind'] ?? 'posts'}/${post['id']}/report',
                  data: {'reason': code, 'details': '$reason\n$details'},
                );
                if (!current()) throw StateError('Account changed');
              },
        onSubmit: () {
          if (!context.mounted || !current()) return;
          CommunityLocalState.instance.hidePost(post);
          AppSnackbar.show(
            context,
            AppSnackbar.info(
              DemoMode.instance.enabled
                  ? 'Post hidden for this demo session'
                  : 'Report received for moderation',
            ),
          );
        },
      );
    }
  }
}
