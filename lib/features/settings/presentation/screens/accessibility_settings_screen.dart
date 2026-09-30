import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/services/local_db_service.dart';
import '../../data/profile_repository.dart';

class AccessibilitySettingsScreen extends StatefulWidget {
  const AccessibilitySettingsScreen({super.key});

  @override
  State<AccessibilitySettingsScreen> createState() => _AccessibilitySettingsScreenState();
}

class _AccessibilitySettingsScreenState extends State<AccessibilitySettingsScreen> {
  double _textSize = 1.0;
  bool _reduceMotion = false;
  bool _highContrast = false;
  bool _haptics = true;

  @override
  void initState() {
    super.initState();
    final profile = LocalDbService().getUserProfile();
    if (profile != null) {
      _textSize = profile.textSize;
      _reduceMotion = profile.reduceMotion;
      _highContrast = profile.highContrast;
      _haptics = profile.hapticsEnabled;
    }
  }

  void _updateTextSize(double value) {
    setState(() => _textSize = value);
    ProfileRepository().updateField('textSize', value);
  }

  void _updateReduceMotion(bool value) {
    setState(() => _reduceMotion = value);
    ProfileRepository().updateField('reduceMotion', value);
  }

  void _updateHighContrast(bool value) {
    setState(() => _highContrast = value);
    ProfileRepository().updateField('highContrast', value);
  }

  void _updateHaptics(bool value) {
    setState(() => _haptics = value);
    ProfileRepository().updateField('hapticsEnabled', value);
  }

  void _testScreenReader() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Semantics(
          label: 'This is a test announcement for screen readers',
          child: const Text('Screen reader test played'),
        ),
      ),
    );
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
          tooltip: 'Back',
        ),
        title: Text(
          'Accessibility',
          style: AppTextStyles.heading2.copyWith(color: AppColors.text),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              
              _SettingsSection(
                title: 'Display',
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Text Size',
                          style: AppTextStyles.body1.copyWith(
                            color: AppColors.text,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Text(
                              'A',
                              style: AppTextStyles.body1.copyWith(fontSize: 14, color: AppColors.text),
                            ),
                            Expanded(
                              child: Slider(
                                value: _textSize,
                                min: 0.8,
                                max: 1.5,
                                divisions: 5,
                                activeColor: AppColors.primary,
                                inactiveColor: AppColors.border,
                                onChanged: _updateTextSize,
                                semanticFormatterCallback: (value) => '${(value * 100).round()}% text size',
                              ),
                            ),
                            Text(
                              'A',
                              style: AppTextStyles.body1.copyWith(fontSize: 22, color: AppColors.text),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Divider(
                      height: 1,
                      thickness: 1,
                      color: AppColors.border,
                    ),
                  ),
                  _SettingsToggleRow(
                    label: 'High Contrast',
                    value: _highContrast,
                    onChanged: _updateHighContrast,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              _SettingsSection(
                title: 'Motion & Interaction',
                children: [
                  _SettingsToggleRow(
                    label: 'Reduce Motion',
                    description: 'Limits UI animations and transitions',
                    value: _reduceMotion,
                    onChanged: _updateReduceMotion,
                  ),
                  _SettingsToggleRow(
                    label: 'Haptic Feedback',
                    value: _haptics,
                    onChanged: _updateHaptics,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              _SettingsSection(
                title: 'VoiceOver / TalkBack',
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _testScreenReader,
                      child: Container(
                        height: 56,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Test Screen Reader',
                                style: AppTextStyles.body1.copyWith(
                                  color: AppColors.text,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.record_voice_over,
                              size: 20,
                              color: AppColors.primary,
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
            children: children,
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

  const _SettingsToggleRow({
    required this.label,
    this.description,
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
                    if (description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        description!,
                        style: AppTextStyles.body2.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Semantics(
                label: label,
                value: value ? 'Enabled' : 'Disabled',
                child: CupertinoSwitch(
                  value: value,
                  onChanged: onChanged,
                  activeTrackColor: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
