import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/services/local_db_service.dart';
import '../../data/profile_repository.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool _showUsername = true;
  bool _showStats = true;
  bool _referenceMood = true;
  bool _referenceJournal = false;
  bool _improveAi = false;
  bool _shareAnalytics = false;
  bool _shareCrashReports = true;

  @override
  void initState() {
    super.initState();
    final profile = LocalDbService().getUserProfile();
    if (profile != null) {
      _showUsername = profile.showUsername;
      _showStats = profile.showStats;
    }
  }

  void _updateShowUsername(bool value) {
    setState(() => _showUsername = value);
    ProfileRepository().updateField('showUsername', value);
  }

  void _updateShowStats(bool value) {
    setState(() => _showStats = value);
    ProfileRepository().updateField('showStats', value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmBackground,
      appBar: AppBar(
        backgroundColor: AppColors.warmBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.text),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Privacy',
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
                title: 'Profile visibility',
                children: [
                  _SettingsToggleRow(
                    label: 'Show my username',
                    value: _showUsername,
                    onChanged: _updateShowUsername,
                  ),
                  _SettingsToggleRow(
                    label: 'Show my stats',
                    value: _showStats,
                    onChanged: _updateShowStats,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              _SettingsSection(
                title: 'AI & Data',
                children: [
                  _SettingsToggleRow(
                    label: 'Let Cozy reference my mood logs',
                    value: _referenceMood,
                    onChanged: (v) => setState(() => _referenceMood = v),
                  ),
                  _SettingsToggleRow(
                    label: 'Let Cozy reference my journal',
                    value: _referenceJournal,
                    onChanged: (v) => setState(() => _referenceJournal = v),
                  ),
                  _SettingsToggleRow(
                    label: 'Improve AI with my conversations',
                    value: _improveAi,
                    onChanged: (v) => setState(() => _improveAi = v),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              _SettingsSection(
                title: 'Analytics',
                children: [
                  _SettingsToggleRow(
                    label: 'Share anonymous usage data',
                    value: _shareAnalytics,
                    onChanged: (v) => setState(() => _shareAnalytics = v),
                  ),
                  _SettingsToggleRow(
                    label: 'Share crash reports',
                    value: _shareCrashReports,
                    onChanged: (v) => setState(() => _shareCrashReports = v),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              _SettingsSection(
                title: 'Blocked users',
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => context.push(AppRouter.blockedUsers),
                      child: Container(
                        height: 56,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Manage blocked users',
                                style: AppTextStyles.body1.copyWith(
                                  color: AppColors.text,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              size: 20,
                              color: AppColors.textSubtle,
                            ),
                          ],
                        ),
                      ),
                    ),
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
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
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