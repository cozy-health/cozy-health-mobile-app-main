import 'package:flutter/material.dart';

/// Opens the shared quick-action menu and dismisses it before selecting an action.
Future<void> showQuickActionsSheet(
  BuildContext context, {
  required VoidCallback onMood,
  required VoidCallback onJournal,
  required VoidCallback onProvider,
  required VoidCallback onBreathe,
}) async {
  final action = await showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: false,
    backgroundColor: Theme.of(context).colorScheme.surface,
    barrierColor: Theme.of(context).colorScheme.scrim.withValues(alpha: .32),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    clipBehavior: Clip.antiAlias,
    builder: (context) => QuickActionsSheet(
      onSelected: (action) => Navigator.of(context).pop(action),
    ),
  );
  if (!context.mounted || action == null) return;
  [onMood, onJournal, onProvider, onBreathe][action]();
}

class QuickActionsSheet extends StatelessWidget {
  const QuickActionsSheet({super.key, required this.onSelected});

  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .85,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: ExcludeSemantics(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.outlineVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        'Quick actions',
                        style: text.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colors.onSurface,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close quick actions',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              Text(
                'Take a moment for yourself.',
                style: text.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              for (var i = 0; i < _actions.length; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                _QuickActionRow(
                  action: _actions[i],
                  onTap: () => onSelected(i),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

typedef _Action = ({
  String title,
  String description,
  IconData icon,
  Color color,
});

const List<_Action> _actions = [
  (
    title: 'Log mood',
    description: 'Check in with how you feel',
    icon: Icons.favorite_border_rounded,
    color: Color(0xFF28764D),
  ),
  (
    title: 'Journal',
    description: 'Write or record your thoughts',
    icon: Icons.menu_book_outlined,
    color: Color(0xFF2868AD),
  ),
  (
    title: 'Provider',
    description: 'Open your care conversations',
    icon: Icons.forum_outlined,
    color: Color(0xFF7955AB),
  ),
  (
    title: 'Breathe',
    description: 'Pause for a guided breathing exercise',
    icon: Icons.air_outlined,
    color: Color(0xFF167A7A),
  ),
];

class _QuickActionRow extends StatelessWidget {
  const _QuickActionRow({required this.action, required this.onTap});

  final _Action action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final accent = dark
        ? Color.lerp(action.color, Colors.white, .55)!
        : action.color;
    return Semantics(
      button: true,
      label: '${action.title}. ${action.description}',
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 80),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: dark ? .16 : .10),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(action.icon, color: accent, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          action.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colors.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          action.description,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: colors.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
