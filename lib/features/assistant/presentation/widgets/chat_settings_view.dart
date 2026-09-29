import 'package:flutter/material.dart';
import 'chat_shared_widgets.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../models/chat.dart';

class ChatSettingsScreen extends StatefulWidget {
  const ChatSettingsScreen({super.key});

  @override
  State<ChatSettingsScreen> createState() => _ChatSettingsScreenState();
}

class _ChatSettingsScreenState extends State<ChatSettingsScreen> {
  String _tone = 'Warm';
  bool _rememberContext = true;
  bool _referenceMood = true;
  bool _referenceJournal = false;
  bool _voiceInput = true;

  @override
  Widget build(BuildContext context) {
    return AssistantSubScaffold(
      title: '',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        children: [
          Text(
            'Cozy settings',
            style: AppTextStyles.heading1.copyWith(
              color: AppColors.text,
              fontSize: 28,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 28),
          SettingsSection(
            title: 'Voice',
            children: [
              SettingRow(
                title: 'Tone',
                value: _tone,
                subtitle: 'Warm, Neutral, Direct',
                onTap: _pickTone,
              ),
            ],
          ),
          SettingsSection(
            title: 'Memory',
            children: [
              SettingSwitch(
                title: 'Remember context',
                subtitle: 'Cozy remembers previous conversations',
                value: _rememberContext,
                onChanged: (value) => setState(() => _rememberContext = value),
              ),
              SettingSwitch(
                title: 'Reference my mood logs',
                subtitle: 'Cozy can see your mood entries for context',
                value: _referenceMood,
                onChanged: (value) => setState(() => _referenceMood = value),
              ),
              SettingSwitch(
                title: 'Reference my journal',
                subtitle: 'Cozy can see your journal entries for context',
                value: _referenceJournal,
                onChanged: (value) => setState(() => _referenceJournal = value),
              ),
            ],
          ),
          SettingsSection(
            title: 'Voice',
            children: [
              SettingSwitch(
                title: 'Voice input',
                subtitle: 'Speak instead of typing',
                value: _voiceInput,
                onChanged: (value) => setState(() => _voiceInput = value),
              ),
            ],
          ),
          SettingsSection(
            title: 'Data',
            children: [
              SettingRow(title: 'Export conversations', onTap: () {}),
              SettingRow(
                title: 'Clear all conversations',
                danger: true,
                onTap: () {},
              ),
              SettingRow(
                title: 'About Cozy',
                subtitle:
                    "I'm here to listen and help you reflect. For anything clinical, a real person is better.",
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _pickTone() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => MenuSheet(
        children: ['Warm', 'Neutral', 'Direct']
            .map(
              (tone) => SheetTile(
                icon: tone == _tone
                    ? Icons.check_rounded
                    : Icons.circle_outlined,
                label: tone,
                onTap: () {
                  setState(() => _tone = tone);
                  Navigator.pop(context);
                },
              ),
            )
            .toList(),
      ),
    );
  }
}

class SettingsSection extends StatelessWidget {
  const SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.heading2.copyWith(color: AppColors.text),
          ),
          const SizedBox(height: 12),
          ...children.expand((child) => [child, const SizedBox(height: 10)]),
        ],
      ),
    );
  }
}

class SettingRow extends StatelessWidget {
  const SettingRow({
    required this.title,
    this.value,
    this.subtitle,
    required this.onTap,
    this.danger = false,
  });

  final String title;
  final String? value;
  final String? subtitle;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return WarmPanel(
      padding: const EdgeInsets.all(16),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.body1.copyWith(
                      color: danger ? AppColors.danger : AppColors.text,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: AppTextStyles.body2.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (value != null)
              Text(
                value!,
                style: AppTextStyles.body2.copyWith(color: AppColors.textMuted),
              ),
          ],
        ),
      ),
    );
  }
}

class SettingSwitch extends StatelessWidget {
  const SettingSwitch({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return WarmPanel(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.body1.copyWith(
                    color: AppColors.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTextStyles.body2.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
