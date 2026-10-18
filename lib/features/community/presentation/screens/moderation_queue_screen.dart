import 'package:flutter/material.dart';

/// Patient sessions must never be used to perform administrative moderation.
class ModerationQueueScreen extends StatelessWidget {
  const ModerationQueueScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Moderation')),
    body: const SafeArea(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Community reports are reviewed in the administrator workspace using an authorized administrator account. The patient app does not provide a moderation queue. To report a post, open its action menu and choose Report post.',
        ),
      ),
    ),
  );
}
