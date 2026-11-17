import 'package:flutter/material.dart';
import '../../../../core/data/demo_mode.dart';
import '../../../../core/theme/cozy_colors.dart';
import '../../../../core/widgets/wellness_sheet.dart';
import '../../../../core/widgets/wellness_panel.dart';

enum PostVisibility { public, followers, anonymous }

class VisibilitySheet extends StatelessWidget {
  const VisibilitySheet({
    super.key,
    required this.currentVisibility,
    required this.onSelect,
  });
  final PostVisibility currentVisibility;
  final ValueChanged<PostVisibility> onSelect;
  static void show(
    BuildContext context, {
    required PostVisibility currentVisibility,
    required ValueChanged<PostVisibility> onSelect,
  }) {
    showWellnessSheet<void>(
      context: context,
      builder: (_) => VisibilitySheet(
        currentVisibility: currentVisibility,
        onSelect: onSelect,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = context.cozyColors.wellness;
    Widget option(
      String title,
      String subtitle,
      PostVisibility value,
      IconData icon,
    ) => WellnessSheetOption(
      key: ValueKey('visibility-${value.name}'),
      label: title,
      subtitle: subtitle,
      icon: icon,
      selected: currentVisibility == value,
      onPressed: () {
        onSelect(value);
        Navigator.pop(context);
      },
    );
    return WellnessSheet(
      title: 'Post visibility',
      children: [
        const Text('Choose how your name appears on this post.'),
        SizedBox(height: w.gap),
        option(
          'Public',
          'Members can see this post with your name.',
          PostVisibility.public,
          Icons.public_outlined,
        ),
        if (DemoMode.instance.enabled)
          option(
            'Followers only',
            'Demo visibility only.',
            PostVisibility.followers,
            Icons.people_outline_rounded,
          ),
        option(
          'Anonymous',
          'Members can see the post without your name.',
          PostVisibility.anonymous,
          Icons.person_outline_rounded,
        ),
        SizedBox(height: w.contentGap),
        const WellnessPanel(
          child: Text('Moderators can still identify the author for safety.'),
        ),
        SizedBox(height: w.gap),
        WellnessAction(
          label: 'Cancel',
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}
