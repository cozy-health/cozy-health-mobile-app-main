import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/services/local_db_service.dart';
import '../../data/profile_repository.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() => _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState extends State<NotificationPreferencesScreen> {
  bool _masterAllow = true;
  bool _dailyCheckIn = true;
  bool _journalReminder = true;
  bool _comments = true;
  bool _likes = false;
  bool _achievements = true;
  bool _productUpdates = false;
  bool _marketing = false;
  String _dailyCheckinTime = '20:00';

  @override
  void initState() {
    super.initState();
    final profile = LocalDbService().getUserProfile();
    if (profile != null) {
      _masterAllow = profile.notificationsMaster;
      _dailyCheckIn = profile.dailyCheckinEnabled;
      _dailyCheckinTime = profile.dailyCheckinTime;
      _journalReminder = profile.journalReminderEnabled;
      _comments = profile.commentsNotifications;
      _achievements = profile.achievementsNotifications;
      _marketing = profile.marketingNotifications;
    }
  }

  void _updateMasterAllow(bool value) {
    setState(() => _masterAllow = value);
    ProfileRepository().updateField('notificationsMaster', value);
  }

  void _updateDailyCheckIn(bool value) {
    setState(() => _dailyCheckIn = value);
    ProfileRepository().updateField('dailyCheckinEnabled', value);
  }

  void _updateJournalReminder(bool value) {
    setState(() => _journalReminder = value);
    ProfileRepository().updateField('journalReminderEnabled', value);
  }

  void _updateComments(bool value) {
    setState(() => _comments = value);
    ProfileRepository().updateField('commentsNotifications', value);
  }

  void _updateAchievements(bool value) {
    setState(() => _achievements = value);
    ProfileRepository().updateField('achievementsNotifications', value);
  }

  void _updateMarketing(bool value) {
    setState(() => _marketing = value);
    ProfileRepository().updateField('marketingNotifications', value);
  }

  String _formatTime(String timeStr) {
    // Basic format assuming "HH:mm"
    if (timeStr.isEmpty) return '9:00 AM';
    final parts = timeStr.split(':');
    if (parts.length != 2) return timeStr;
    final h = int.tryParse(parts[0]) ?? 9;
    final m = parts[1];
    final ampm = h >= 12 ? 'PM' : 'AM';
    final hr12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$hr12:$m $ampm';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.text),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Notifications',
          style: AppTextStyles.heading2.copyWith(color: AppColors.text),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              
              _SettingsSection(
                title: 'Master',
                children: [
                  _SettingsToggleRow(
                    label: 'Allow notifications',
                    value: _masterAllow,
                    onChanged: _updateMasterAllow,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              _SettingsSection(
                title: 'Reminders',
                children: [
                  _SettingsToggleRow(
                    label: 'Daily check-in',
                    description: 'A gentle reminder to\nlog your mood',
                    value: _dailyCheckIn,
                    onChanged: _updateDailyCheckIn,
                    trailing: InkWell(
                      onTap: () => context.push(AppRouter.reminderTimes),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Time: ${_formatTime(_dailyCheckinTime)}',
                            style: AppTextStyles.body2.copyWith(color: AppColors.text),
                          ),
                          const Icon(Icons.chevron_right, size: 20, color: AppColors.textSubtle),
                        ],
                      ),
                    ),
                  ),
                  _SettingsToggleRow(
                    label: 'Journal reminder',
                    description: 'A weekly prompt to write',
                    value: _journalReminder,
                    onChanged: _updateJournalReminder,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              _SettingsSection(
                title: 'Community',
                children: [
                  _SettingsToggleRow(
                    label: 'Comments',
                    value: _comments,
                    onChanged: _updateComments,
                  ),
                  _SettingsToggleRow(
                    label: 'Likes',
                    value: _likes,
                    onChanged: (v) => setState(() => _likes = v),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              _SettingsSection(
                title: 'App',
                children: [
                  _SettingsToggleRow(
                    label: 'Achievements',
                    value: _achievements,
                    onChanged: _updateAchievements,
                  ),
                  _SettingsToggleRow(
                    label: 'Product updates',
                    value: _productUpdates,
                    onChanged: (v) => setState(() => _productUpdates = v),
                  ),
                  _SettingsToggleRow(
                    label: 'Marketing',
                    value: _marketing,
                    onChanged: _updateMarketing,
                  ),
                ],
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            title,
            style: AppTextStyles.body1.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.text,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Column(
            children: List.generate(
              children.length,
              (index) {
                final isLast = index == children.length - 1;
                return Column(
                  children: [
                    children[index],
                    if (!isLast)
                      Padding(
                        padding: const EdgeInsets.only(left: 16, right: 16),
                        child: Divider(
                          height: 1,
                          thickness: 1,
                          color: AppColors.border.withValues(alpha: 0.4),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsToggleRow extends StatelessWidget {
  final String label;
  final String? description;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Widget? trailing;

  const _SettingsToggleRow({
    required this.label,
    this.description,
    required this.value,
    required this.onChanged,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(!value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          constraints: const BoxConstraints(minHeight: 56),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: AppTextStyles.body1.copyWith(
                        color: AppColors.text,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    if (description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        description!,
                        style: AppTextStyles.body2.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                    if (trailing != null) ...[
                      const SizedBox(height: 8),
                      trailing!,
                    ]
                  ],
                ),
              ),
              const SizedBox(width: 16),
              CupertinoSwitch(
                value: value,
                onChanged: onChanged,
                activeTrackColor: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
