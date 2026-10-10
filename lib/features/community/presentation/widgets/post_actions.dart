import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../community_local_state.dart';
import 'report_sheet.dart';

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
                onTap: () {
                  Navigator.pop(sheetContext);
                  CommunityLocalState.instance.blockUser(
                    post['username'] as String? ?? '',
                  );
                  AppSnackbar.show(
                    context,
                    AppSnackbar.info('User hidden for this session'),
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
                  onSubmit: () {
                    CommunityLocalState.instance.hidePost(post);
                    AppSnackbar.show(
                      context,
                      AppSnackbar.info('Post hidden for this session'),
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
