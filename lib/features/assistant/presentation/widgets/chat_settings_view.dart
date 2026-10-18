import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:share_plus/share_plus.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/services/local_db_service.dart';
import '../../data/chat_repository.dart';
import 'chat_shared_widgets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

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
  final _owner = LocalDbService().activeUserId;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = await LocalDbService().settingsBox();
    final saved = settings.get('assistant_preferences');
    if (!mounted || _owner != LocalDbService().activeUserId || saved is! Map) {
      return;
    }
    setState(() {
      _tone = saved['tone'] as String? ?? 'Warm';
      _rememberContext = saved['remember_context'] == true;
      _referenceMood = saved['reference_mood'] == true;
      _referenceJournal = saved['reference_journal'] == true;
      _voiceInput = saved['voice_input'] == true;
    });
  }

  Future<void> _persist() async {
    final settings = await LocalDbService().settingsBox();
    if (_owner != LocalDbService().activeUserId) return;
    await settings.put('assistant_preferences', {
      'tone': _tone,
      'remember_context': _rememberContext,
      'reference_mood': _referenceMood,
      'reference_journal': _referenceJournal,
      'voice_input': _voiceInput,
    });
  }

  Future<void> _export() async {
    final local = LocalDbService();
    if (_owner != local.activeUserId) return;
    final json = jsonEncode({
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'scope':
          'Conversations currently saved on this device; cloud-only records may not be included.',
      'conversations': local
          .getAllChatConversations()
          .map((row) => row.toJson())
          .toList(),
      'messages': local.chatMessageBox.values
          .map((row) => row.toJson())
          .toList(),
    });
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(utf8.encode(json), mimeType: 'application/json'),
        ],
        fileNameOverrides: ['cozy-conversations.json'],
      ),
    );
  }

  Future<void> _clear() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete all saved conversations?'),
        content: const Text(
          'This removes conversations saved on this device and queues their deletion for your account. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (yes != true || _owner != LocalDbService().activeUserId) return;
    for (final conversation in LocalDbService().getAllChatConversations()) {
      if (_owner != LocalDbService().activeUserId) return;
      await ChatRepository().deleteConversation(conversation.id);
    }
  }

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
              color: Theme.of(context).colorScheme.onSurface,
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
                onChanged: (value) {
                  setState(() => _rememberContext = value);
                  _persist();
                },
              ),
              SettingSwitch(
                title: 'Reference my mood logs',
                subtitle: 'Cozy can see your mood entries for context',
                value: _referenceMood,
                onChanged: (value) {
                  setState(() => _referenceMood = value);
                  _persist();
                },
              ),
              SettingSwitch(
                title: 'Reference my journal',
                subtitle: 'Cozy can see your journal entries for context',
                value: _referenceJournal,
                onChanged: (value) {
                  setState(() => _referenceJournal = value);
                  _persist();
                },
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
                onChanged: (value) {
                  setState(() => _voiceInput = value);
                  _persist();
                },
              ),
            ],
          ),
          SettingsSection(
            title: 'Data',
            children: [
              SettingRow(
                title: 'Export conversations saved on this device',
                onTap: _export,
              ),
              SettingRow(
                title: 'Clear all conversations',
                danger: true,
                onTap: _clear,
              ),
              SettingRow(
                title: 'About Cozy',
                subtitle:
                    "I'm here to listen and help you reflect. For anything clinical, a real person is better.",
                onTap: () => context.push(AppRouter.about),
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
      shape: const RoundedRectangleBorder(),
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
                  _persist();
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
  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
  });

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
            style: AppTextStyles.heading2.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
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
    super.key,
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
                      color: danger
                          ? AppColors.danger
                          : Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: AppTextStyles.body2.copyWith(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (value != null)
              Text(
                value!,
                style: AppTextStyles.body2.copyWith(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class SettingSwitch extends StatelessWidget {
  const SettingSwitch({
    super.key,
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
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTextStyles.body2.copyWith(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
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
