import 'package:flutter/material.dart';
import '../../../../core/widgets/wellness_sheet.dart';

Future<void> showQuickActionsSheet(
  BuildContext context, {
  required VoidCallback onMood,
  required VoidCallback onJournal,
  required VoidCallback onProvider,
  required VoidCallback onBreathe,
}) async {
  final action = await showWellnessSheet<int>(
    context: context,
    builder: (context) =>
        QuickActionsSheet(onSelected: (i) => Navigator.pop(context, i)),
  );
  if (!context.mounted || action == null) return;
  [onMood, onJournal, onProvider, onBreathe][action]();
}

class QuickActionsSheet extends StatelessWidget {
  const QuickActionsSheet({super.key, required this.onSelected});
  final ValueChanged<int> onSelected;
  @override
  Widget build(BuildContext context) => WellnessSheet(
    title: 'What would you like to do?',
    children: [
      const Text('Choose an action to open its screen.'),
      WellnessSheetOption(
        key: const ValueKey('quick-mood'),
        label: 'Check in with your mood',
        subtitle: 'Record how you feel right now.',
        icon: Icons.face_outlined,
        onPressed: () => onSelected(0),
      ),
      WellnessSheetOption(
        key: const ValueKey('quick-journal'),
        label: 'Open your journal',
        subtitle: 'Read saved entries or start a new one.',
        icon: Icons.menu_book_outlined,
        onPressed: () => onSelected(1),
      ),
      WellnessSheetOption(
        key: const ValueKey('quick-provider'),
        label: 'Your provider',
        subtitle: 'Open your provider area.',
        icon: Icons.forum_outlined,
        onPressed: () => onSelected(2),
      ),
      WellnessSheetOption(
        key: const ValueKey('quick-breathing'),
        label: 'Start breathing',
        subtitle: 'Follow a timed breathing exercise.',
        icon: Icons.air_outlined,
        onPressed: () => onSelected(3),
      ),
    ],
  );
}
