// Review-only layouts. These are not registered production routes.
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cozy_health/core/theme/cozy_colors.dart';
import 'package:cozy_health/core/widgets/app_pressable.dart';
import 'package:cozy_health/core/widgets/wellness_panel.dart';

class ProfileCommunityProposal extends StatelessWidget {
  const ProfileCommunityProposal({super.key, required this.screen});
  final String screen;
  @override
  Widget build(BuildContext context) {
    final w = context.cozyColors.wellness,
        t = Theme.of(context),
        c = t.colorScheme;
    final profile = screen == 'profile', member = screen == 'member';
    Widget title(String label) => Text(
      label,
      style: t.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600),
    );
    Widget gap() => SizedBox(height: w.sectionSpacing);
    Widget heading(String label) => Padding(
      padding: EdgeInsets.only(bottom: w.contentGap),
      child: Text(
        label,
        style: t.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
    Widget row(IconData icon, String label, String subtitle) => Padding(
      padding: EdgeInsets.only(bottom: w.contentGap),
      child: AppPressable(
        onPressed: () {},
        label: label,
        child: WellnessPanel(
          child: Row(
            children: [
              Icon(icon),
              SizedBox(width: w.contentGap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: t.textTheme.titleMedium),
                    SizedBox(height: w.tight),
                    Text(subtitle, style: t.textTheme.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
    return Scaffold(
      backgroundColor: w.canvas(
        t.brightness,
        MediaQuery.highContrastOf(context),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(w.page),
          child: Column(
            key: const ValueKey('profile-community-content'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (profile || member) ...[
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Back',
                      onPressed: () {},
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    Expanded(
                      child: title(member ? 'Member profile' : 'Your profile'),
                    ),
                  ],
                ),
                gap(),
                WellnessPanel(
                  tinted: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: w.artworkSurface,
                          shape: BoxShape.circle,
                        ),
                        padding: EdgeInsets.all(w.small),
                        child: SvgPicture.asset(
                          'assets/avatars/open_peeps/open-peeps-01.svg',
                          fit: BoxFit.contain,
                        ),
                      ),
                      SizedBox(height: w.gap),
                      Text(
                        'Sam Taylor',
                        style: t.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: w.tight),
                      Text(
                        '@samtaylor',
                        style: t.textTheme.bodyMedium?.copyWith(
                          color: c.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(height: w.contentGap),
                      if (profile)
                        const Text(
                          'Learning to make room for small, steady steps.',
                        ),
                      if (profile) ...[
                        gap(),
                        WellnessAction(
                          label: 'Edit profile',
                          icon: Icons.edit_outlined,
                          filled: true,
                          onPressed: () {},
                        ),
                      ],
                    ],
                  ),
                ),
                gap(),
                if (profile) ...[
                  heading('Your space'),
                  Text(
                    'Only you can see your personal check-in stats here.',
                    style: t.textTheme.bodySmall,
                  ),
                  SizedBox(height: w.contentGap),
                  LayoutBuilder(
                    builder: (context, box) {
                      final single =
                          MediaQuery.textScalerOf(context).scale(w.label) > 21;
                      Widget stat(String value, String label) => WellnessPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              value,
                              style: t.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: w.tight),
                            Text(label, style: t.textTheme.bodyMedium),
                          ],
                        ),
                      );
                      return single
                          ? Column(
                              children: [
                                stat('24', 'Saved check-ins'),
                                SizedBox(height: w.contentGap),
                                stat('3 days', 'Current check-in streak'),
                              ],
                            )
                          : IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: stat('24', 'Saved check-ins'),
                                  ),
                                  SizedBox(width: w.contentGap),
                                  Expanded(
                                    child: stat(
                                      '3 days',
                                      'Current check-in streak',
                                    ),
                                  ),
                                ],
                              ),
                            );
                    },
                  ),
                  gap(),
                  row(
                    Icons.history_rounded,
                    'Recent entries',
                    'Return to your mood log',
                  ),
                  row(
                    Icons.emoji_events_outlined,
                    'Achievements',
                    'See the milestones you’ve earned',
                  ),
                  row(
                    Icons.bookmark_border_rounded,
                    'Saved articles',
                    'Keep helpful reads close',
                  ),
                  gap(),
                  heading('Your community identity'),
                  WellnessPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your community identity appears with public posts. Anonymous posts keep your identity hidden.',
                        ),
                        SizedBox(height: w.contentGap),
                        WellnessAction(
                          label: 'Preview public profile',
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                  gap(),
                ] else ...[
                  heading('Public posts'),
                  const Text(
                    'Only non-anonymous posts appear on this profile. This public view does not show mood records or journal entries.',
                  ),
                  SizedBox(height: w.gap),
                  const ProposedPost(anonymous: false),
                  gap(),
                  WellnessAction(label: 'Block this person', onPressed: () {}),
                ],
              ] else ...[
                Row(
                  children: [
                    Expanded(child: title('Community')),
                    IconButton(
                      tooltip: 'Notifications',
                      onPressed: () {},
                      icon: const Icon(Icons.notifications_none_rounded),
                    ),
                  ],
                ),
                SizedBox(height: w.tight),
                const Text('Share at your own pace.'),
                gap(),
                AppPressable(
                  onPressed: () {},
                  label: 'Search community',
                  child: WellnessPanel(
                    child: Row(
                      children: [
                        const Icon(Icons.search_rounded),
                        SizedBox(width: w.contentGap),
                        const Expanded(child: Text('Search posts and groups')),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: w.contentGap),
                WellnessSegments(
                  labels: const ['Posts', 'Groups'],
                  selected: screen == 'groups' ? 1 : 0,
                  onSelected: (_) {},
                  keyPrefix: 'community-review-tab',
                ),
                gap(),
                if (screen == 'groups') ...[
                  heading('Find your people'),
                  const Text('Choose a group that feels right for you.'),
                  gap(),
                  for (final group in [
                    (
                      'Anxiety support',
                      'Share experiences and everyday coping ideas.',
                    ),
                    (
                      'Small self-care steps',
                      'Make space for rest and daily routines.',
                    ),
                  ]) ...[
                    WellnessPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.groups_outlined, size: 32),
                          SizedBox(height: w.contentGap),
                          Text(group.$1, style: t.textTheme.titleLarge),
                          SizedBox(height: w.small),
                          Text(group.$2),
                          SizedBox(height: w.gap),
                          WellnessAction(label: 'View group', onPressed: () {}),
                        ],
                      ),
                    ),
                    gap(),
                  ],
                ] else ...[
                  WellnessAction(
                    label: 'Create a post',
                    icon: Icons.add_rounded,
                    filled: true,
                    onPressed: () {},
                  ),
                  SizedBox(height: w.contentGap),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final topic in [
                          'All',
                          'Anxiety',
                          'Sleep',
                          'Self-care',
                        ])
                          Padding(
                            padding: EdgeInsets.only(right: w.small),
                            child: AppPressable(
                              onPressed: () {},
                              label: topic,
                              selected: topic == 'All',
                              child: Container(
                                constraints: BoxConstraints(minHeight: w.touch),
                                alignment: Alignment.center,
                                padding: EdgeInsets.symmetric(
                                  horizontal: w.gap,
                                ),
                                decoration: BoxDecoration(
                                  color: topic == 'All' ? c.primary : c.surface,
                                  border: Border.all(
                                    color: topic == 'All'
                                        ? c.primary
                                        : c.outlineVariant,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    w.tileRadius,
                                  ),
                                ),
                                child: Text(
                                  topic,
                                  style: t.textTheme.bodyMedium?.copyWith(
                                    color: topic == 'All'
                                        ? c.onPrimary
                                        : c.onSurface,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  gap(),
                  heading('Latest posts'),
                  const ProposedPost(anonymous: false),
                  SizedBox(height: w.gap),
                  const ProposedPost(anonymous: true),
                  gap(),
                ],
                AppPressable(
                  onPressed: () {},
                  label: 'Read community guidelines',
                  child: WellnessPanel(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.shield_outlined),
                        SizedBox(width: w.contentGap),
                        const Expanded(
                          child: Text(
                            'Help keep this space kind. Read the community guidelines.',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                gap(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class ProposedPost extends StatelessWidget {
  const ProposedPost({super.key, required this.anonymous});
  final bool anonymous;
  @override
  Widget build(BuildContext context) {
    final w = context.cozyColors.wellness,
        t = Theme.of(context),
        c = t.colorScheme;
    return WellnessPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: w.touch,
                height: w.touch,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: w.accentPanel(c),
                ),
                child: anonymous
                    ? const Icon(Icons.person_outline_rounded)
                    : Text('ST', style: t.textTheme.titleMedium),
              ),
              SizedBox(width: w.contentGap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      anonymous ? 'Anonymous' : 'Sam Taylor',
                      style: t.textTheme.titleMedium,
                    ),
                    Text(
                      anonymous
                          ? 'Sleep · 1 hour ago'
                          : 'Self-care · 20 min ago',
                      style: t.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Post actions: report or hide',
                onPressed: () {},
                icon: const Icon(Icons.more_horiz_rounded),
              ),
            ],
          ),
          SizedBox(height: w.contentGap),
          Text(
            anonymous
                ? 'Trying a quieter evening routine this week. What helps you switch off before bed?'
                : 'I took a short walk today, even though I nearly talked myself out of it. A small step, but I’m glad I made space for it.',
            style: t.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
          SizedBox(height: w.gap),
          Wrap(
            spacing: w.contentGap,
            runSpacing: w.small,
            children: [
              WellnessAction(
                label: anonymous ? '4 likes' : '12 likes',
                icon: Icons.favorite_border_rounded,
                onPressed: () {},
              ),
              WellnessAction(
                label: anonymous ? '3 comments' : '5 comments',
                icon: Icons.chat_bubble_outline_rounded,
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}
