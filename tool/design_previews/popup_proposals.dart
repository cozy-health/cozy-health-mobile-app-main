// Approval-only previews. No production modal calls use these widgets.
import 'package:flutter/material.dart';
import 'package:cozy_health/core/theme/cozy_colors.dart';
import 'package:cozy_health/core/widgets/app_pressable.dart';
import 'package:cozy_health/core/widgets/wellness_panel.dart';

class PopupProposal extends StatelessWidget {
  const PopupProposal({super.key, required this.kind});
  final String kind;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context),
        c = t.colorScheme,
        w = context.cozyColors.wellness;
    final title = switch (kind) {
      'report' => 'Report a post',
      'visibility' => 'Post visibility',
      'provider' => 'Choose a provider',
      'record' => 'Record preview',
      'confirm' => 'Block this member?',
      'avatar' => 'Profile photo',
      'voice' => 'Voice message',
      _ => 'Post options',
    };
    Widget row(
      IconData icon,
      String text, {
      String? detail,
      bool selected = false,
      bool danger = false,
    }) => Padding(
      padding: EdgeInsets.only(bottom: w.small),
      child: AppPressable(
        selected: selected,
        onPressed: () {},
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: w.contentGap,
            vertical: w.contentGap,
          ),
          decoration: BoxDecoration(
            color: selected ? w.accentPanel(c) : c.surface,
            borderRadius: BorderRadius.circular(w.tileRadius),
            border: Border.all(
              color: selected ? wellnessAccentInk(context) : c.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: danger
                    ? context.cozyColors.recording.controlColor(
                        c.error,
                        c.surface,
                        c.onSurface,
                      )
                    : wellnessAccentInk(context),
              ),
              SizedBox(width: w.contentGap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text,
                      style: t.textTheme.titleSmall?.copyWith(
                        color: danger ? c.error : c.onSurface,
                      ),
                    ),
                    if (detail != null) ...[
                      SizedBox(height: w.tight),
                      Text(detail, style: t.textTheme.bodySmall),
                    ],
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_rounded, color: wellnessAccentInk(context)),
            ],
          ),
        ),
      ),
    );
    final content = <Widget>[
      Row(
        children: [
          Expanded(child: Text(title, style: t.textTheme.headlineSmall)),
          AppPressable(
            label: 'Close $title',
            onPressed: () {},
            child: SizedBox(
              width: w.touch,
              height: w.touch,
              child: const Icon(Icons.close_rounded),
            ),
          ),
        ],
      ),
      SizedBox(height: w.contentGap),
      if (kind == 'options') ...[
        const Text('Choose what you’d like to do with this post.'),
        SizedBox(height: w.gap),
        row(Icons.copy_outlined, 'Copy post'),
        row(
          Icons.flag_outlined,
          'Report post',
          detail: 'Send a concern to the moderation team',
        ),
        row(
          Icons.block_outlined,
          'Block member',
          detail: 'Review before hiding their posts',
          danger: true,
        ),
      ] else if (kind == 'visibility') ...[
        const Text('Choose how your name appears on this post.'),
        SizedBox(height: w.gap),
        row(
          Icons.public_outlined,
          'Public',
          detail: 'Members can see this post with your name.',
        ),
        row(
          Icons.person_outline_rounded,
          'Anonymous',
          detail: 'Members can see the post without your name.',
          selected: true,
        ),
        SizedBox(height: w.contentGap),
        const WellnessPanel(
          child: Text('Moderators can still identify the author for safety.'),
        ),
      ] else if (kind == 'report') ...[
        const Text(
          'Choose a reason. Your report is sent privately to moderators.',
        ),
        SizedBox(height: w.gap),
        for (final reason in [
          'Harassment or hate speech',
          'Encourages harm',
          'Spam or scam',
          'Shares private info',
          'Something else',
        ])
          row(
            Icons.radio_button_unchecked,
            reason,
            selected: reason == 'Shares private info',
          ),
        SizedBox(height: w.contentGap),
        const TextField(
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Additional details (optional)',
            hintText: 'Tell us what to review',
          ),
        ),
        SizedBox(height: w.gap),
        WellnessAction(label: 'Submit report', filled: true, onPressed: () {}),
      ] else if (kind == 'provider') ...[
        const Text(
          'Messages and shared records belong to the selected conversation.',
        ),
        SizedBox(height: w.gap),
        row(
          Icons.person_outline_rounded,
          'Dr Alex Morgan',
          detail: 'Current conversation',
          selected: true,
        ),
        row(Icons.person_outline_rounded, 'Dr Jamie Reed'),
      ] else if (kind == 'record') ...[
        const Text('Check what your provider will receive before sending.'),
        SizedBox(height: w.gap),
        WellnessPanel(
          tinted: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Mood check-in', style: t.textTheme.titleMedium),
              SizedBox(height: w.small),
              const Text('Good · Intensity 6 of 10'),
              SizedBox(height: w.small),
              const Text('Synthetic sample record for design review.'),
            ],
          ),
        ),
        SizedBox(height: w.gap),
        WellnessAction(label: 'Done', filled: true, onPressed: () {}),
      ] else if (kind == 'confirm') ...[
        const Text(
          'Their posts will be hidden. You can unblock them in Settings.',
        ),
        SizedBox(height: w.gap),
        WellnessAction(label: 'Keep member unblocked', onPressed: () {}),
        SizedBox(height: w.small),
        AppPressable(
          onPressed: () {},
          child: Container(
            alignment: Alignment.center,
            padding: EdgeInsets.all(w.contentGap),
            decoration: BoxDecoration(
              color: c.error,
              borderRadius: BorderRadius.circular(w.tileRadius),
            ),
            child: Text(
              'Block member',
              style: t.textTheme.labelLarge?.copyWith(color: c.onError),
            ),
          ),
        ),
      ] else if (kind == 'avatar') ...[
        const Text('Choose a photo or keep your CozyHealth character.'),
        SizedBox(height: w.gap),
        row(Icons.camera_alt_outlined, 'Take a photo'),
        row(Icons.photo_library_outlined, 'Choose from library'),
        row(Icons.face_outlined, 'Choose a character'),
        row(Icons.delete_outline_rounded, 'Remove photo', danger: true),
      ] else if (kind == 'voice') ...[
        const Text('Review your recording before you send it.'),
        SizedBox(height: w.gap),
        WellnessPanel(
          tinted: true,
          child: Row(
            children: [
              const Icon(Icons.play_circle_outline_rounded, size: 40),
              SizedBox(width: w.contentGap),
              const Expanded(child: Text('Voice message · 0:24')),
            ],
          ),
        ),
        SizedBox(height: w.gap),
        WellnessAction(
          label: 'Send voice message',
          icon: Icons.send_outlined,
          filled: true,
          onPressed: () {},
        ),
        SizedBox(height: w.small),
        WellnessAction(label: 'Discard recording', onPressed: () {}),
      ],
      if (kind != 'confirm' && kind != 'record') ...[
        SizedBox(height: w.small),
        WellnessAction(label: 'Cancel', onPressed: () {}),
      ],
    ];
    return Scaffold(
      backgroundColor: w.canvas(
        t.brightness,
        MediaQuery.highContrastOf(context),
      ),
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.all(w.page),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Preview for approval',
                    style: t.textTheme.headlineSmall,
                  ),
                  SizedBox(height: w.small),
                  const Text('Pop-up design proposal · sample content'),
                  SizedBox(height: w.sectionSpacing),
                  const WellnessPanel(
                    child: Text(
                      'Underlying page stays in place while you complete this task.',
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: ColoredBox(color: Colors.black.withValues(alpha: .36)),
          ),
          SafeArea(
            child: Align(
              alignment: kind == 'confirm'
                  ? Alignment.center
                  : Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(
                  left: kind == 'confirm' ? w.page : 0,
                  right: kind == 'confirm' ? w.page : 0,
                  bottom: MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * .88,
                    maxWidth: 560,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(w.radius),
                      border: Border.all(color: c.outlineVariant),
                    ),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(w.page),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: content,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
