import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../community_local_state.dart';
import 'report_sheet.dart';
import '../../../../core/data/demo_mode.dart';
import '../../../../core/api/api_client.dart';

class PostActions {
  static void show(BuildContext context, Map<String, dynamic> post) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy post'),
              onTap: () async {
                Navigator.pop(sheetContext);
                await Clipboard.setData(
                  ClipboardData(text: post['content'] as String? ?? ''),
                );
                if (context.mounted) {
                  AppSnackbar.show(context, AppSnackbar.info('Post copied'));
                }
              },
            ),
            if (post['isAnonymous'] != true)
              ListTile(
                leading: const Icon(Icons.block),
                title: const Text('Block user'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  if (!DemoMode.instance.enabled) {
                    try {
                      if (post['authorId'] == null) {
                        throw StateError('Author unavailable');
                      }
                      await ApiClient().post(
                        '/community/users/${post['authorId']}/block',
                      );
                    } catch (_) {
                      if (context.mounted) {
                        AppSnackbar.show(
                          context,
                          AppSnackbar.error(
                            'Could not block this person. Please retry.',
                          ),
                        );
                      }
                      return;
                    }
                  }
                  CommunityLocalState.instance.blockUser(
                    post['username'] as String? ?? '',
                  );
                  if (!context.mounted) return;
                  AppSnackbar.show(
                    context,
                    AppSnackbar.info(
                      DemoMode.instance.enabled
                          ? 'User hidden for this demo session'
                          : 'User blocked',
                    ),
                  );
                },
              ),
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: const Text('Report post'),
              onTap: () {
                Navigator.pop(sheetContext);
                ReportSheet.show(
                  context,
                  onReport: DemoMode.instance.enabled
                      ? null
                      : (reason, details) async {
                          final code =
                              {
                                'Harassment or hate speech': 'harassment',
                                'Encourages harm': 'safety',
                                'Spam or scam': 'spam',
                              }[reason] ??
                              'other';
                          await ApiClient().post(
                            '/community/${post['kind'] ?? 'posts'}/${post['id']}/report',
                            data: {
                              'reason': code,
                              'details': '$reason\n$details',
                            },
                          );
                        },
                  onSubmit: () {
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
              },
            ),
          ],
        ),
      ),
    );
  }
}
