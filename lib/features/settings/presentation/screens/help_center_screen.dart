import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/widgets/empty_state.dart';

class FaqItem {
  const FaqItem(this.category, this.question, this.answer);
  final String category;
  final String question;
  final String answer;
}

const helpFaqs = <FaqItem>[
  FaqItem(
    'Getting Started',
    'Where can I begin?',
    'Start with a mood check-in on Home. A few words are enough, and you can explore the other features at your own pace.',
  ),
  FaqItem(
    'Getting Started',
    'Do I have to answer every onboarding question?',
    'You can skip the optional questions. Choose a check-in rhythm that feels comfortable; there is no perfect routine.',
  ),
  FaqItem(
    'Getting Started',
    'What does the feature tour show?',
    'The optional tour introduces mood check-ins, the Journal quick action, your assistant, and help resources. You can leave the tour whenever you like.',
  ),
  FaqItem(
    'Mood & Journal',
    'How do I log my mood?',
    'Choose Log your mood on Home, select how you feel, and continue through the check-in. Save when you are ready.',
  ),
  FaqItem(
    'Mood & Journal',
    'Can I come back to an unfinished check-in?',
    'A draft is saved as you move between check-in steps. Open check-in again on the same day and choose Resume, or Discard to start fresh.',
  ),
  FaqItem(
    'Mood & Journal',
    'How do I write a journal entry?',
    'Open Journal from the + quick action and choose a new entry. You can write freely or use a prompt. Your entry does not need to be long.',
  ),
  FaqItem(
    'Mood & Journal',
    'Why are my insights empty?',
    'Patterns need a little history. Log a few moods to begin; some cards need at least three check-ins. There is no need to rush.',
  ),
  FaqItem(
    'Crisis Resources',
    'Where can I find help resources?',
    'Use the help button on Home to open crisis resources. You can review support options, professional providers, and your safety plan.',
  ),
  // Emergency guidance is grounded in NHS urgent mental health guidance:
  // https://www.nhs.uk/nhs-services/mental-health-services/where-to-get-urgent-help-for-mental-health/
  FaqItem(
    'Crisis Resources',
    'What if someone is in immediate danger?',
    'Contact your local emergency services or go to the nearest emergency department now. Cozy Health is not an emergency service; do not wait for an app response.',
  ),
  FaqItem(
    'Crisis Resources',
    'What is a safety plan?',
    'A safety plan brings together warning signs, coping ideas, trusted contacts, and professional support. You can create one in help resources and review it with a qualified professional.',
  ),
  FaqItem(
    'Crisis Resources',
    'Can the assistant replace a therapist?',
    'The assistant offers space for reflection. It cannot replace a qualified professional or emergency care. Reach out to a professional when you need personal clinical guidance.',
  ),
  FaqItem(
    'Privacy & Data',
    'How can I protect my journal on this device?',
    'Review the privacy and security settings and your device lock. Use a device you trust, especially if other people can unlock it.',
  ),
  FaqItem(
    'Privacy & Data',
    'What happens to my entries without a connection?',
    'Entries are stored on your device, and supported changes are queued for sync. A connection is needed for server features. Keep the app installed while changes are waiting to upload.',
  ),
  FaqItem(
    'Privacy & Data',
    'Where can I learn how my data is handled?',
    'Open the privacy policy from Settings to review data handling. Use Help & Support to report a concern, and avoid including private journal or chat content in your report.',
  ),
  FaqItem(
    'Account',
    'How do I sign in?',
    'Use the email and password for your account, or an available Google or Apple sign-in option. Biometric sign-in appears on supported devices with a saved session.',
  ),
  FaqItem(
    'Account',
    'What if I forget my password?',
    'Choose Forgot password on the sign-in screen and follow the reset steps. Check that the email address matches the one you used for your account.',
  ),
  FaqItem(
    'Account',
    'How do I delete my account?',
    'Open the account deletion option in Settings and read the confirmation carefully. The shared review demo account cannot be deleted.',
  ),
  FaqItem(
    'Community',
    'Do I have to share in Community?',
    'Sharing is optional. You can focus on your own check-ins and journal, and take part only when it feels right for you.',
  ),
  FaqItem(
    'Community',
    'What should I keep out of a public post?',
    'Keep names, contact details, addresses, and other identifying information out of public posts. Share only what you feel comfortable making public.',
  ),
  FaqItem(
    'Community',
    'What can I do if something feels uncomfortable?',
    'It is okay to step away. Use the available block or report controls, or send a problem report through Help & Support. For urgent help, use local emergency services.',
  ),
];

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});
  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final _search = TextEditingController();
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final items = helpFaqs
        .where(
          (item) =>
              '${item.question} ${item.answer}'.toLowerCase().contains(query),
        )
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          Text('Help center', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            decoration: const InputDecoration(
              labelText: 'Search help',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 24),
          if (items.isEmpty)
            EmptyState(
              icon: Icons.search,
              title: 'No questions match your search.',
              primaryCtaLabel: 'Clear search',
              onPrimaryCta: () => setState(_search.clear),
            ),
          for (final category
              in items.map((item) => item.category).toSet()) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                category,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            for (final item in items.where((item) => item.category == category))
              ExpansionTile(
                key: ValueKey(item.question),
                tilePadding: EdgeInsets.zero,
                title: Text(
                  item.question,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        item.answer,
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
          const SizedBox(height: 24),
          Text(
            'Still need help?',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          TextButton.icon(
            onPressed: () => context.push(AppRouter.reportProblem),
            icon: const Icon(Icons.help_outline),
            label: const Text('Report a problem'),
          ),
          TextButton.icon(
            onPressed: () => context.push(AppRouter.feedback),
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text('Send feedback'),
          ),
        ],
      ),
    );
  }
}
