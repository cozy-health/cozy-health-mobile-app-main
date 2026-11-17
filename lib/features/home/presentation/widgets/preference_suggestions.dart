import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/models/user_preferences.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/services/home_suggestions.dart';
import '../../../../core/services/local_db_service.dart';
import '../../../../core/theme/cozy_colors.dart';
import '../../../../core/widgets/app_pressable.dart';
import '../../../journal/presentation/screens/journal_screen.dart';
import 'home_design_widgets.dart';

class PreferenceSuggestions extends StatefulWidget {
  const PreferenceSuggestions({super.key});
  @override
  State<PreferenceSuggestions> createState() => _PreferenceSuggestionsState();
}

class _PreferenceSuggestionsState extends State<PreferenceSuggestions> {
  late final _box = LocalDbService().preferencesBox();
  bool _expanded = false;
  @override
  Widget build(BuildContext context) => FutureBuilder<Box<UserPreferences>>(
    future: _box,
    builder: (context, snapshot) {
      final box = snapshot.data;
      if (box == null || !box.isOpen) return _content(null);
      return ValueListenableBuilder<Box<UserPreferences>>(
        valueListenable: box.listenable(keys: const ['current']),
        builder: (context, box, _) => _content(box.get('current')),
      );
    },
  );

  void _openSuggestion(HomeSuggestion suggestion) {
    final prompt = suggestion.prompt;
    if (prompt == null) {
      context.push(AppRouter.breathing);
    } else {
      context.push(
        '/journal-compose',
        extra: JournalPrompt(
          id: suggestion.id,
          category: 'A moment for you',
          text: prompt,
        ),
      );
    }
  }

  Widget _content(UserPreferences? preferences) {
    final choices = homeSuggestions(preferences);
    final personalised = choices.isNotEmpty;
    final rows = personalised
        ? choices
        : const [
            HomeSuggestion(
              id: 'breathing',
              title: 'Take a breathing break',
              reason: 'A quiet moment, at your own pace.',
            ),
          ];
    final theme = Theme.of(context), t = context.cozyColors.wellness;
    final fill = t.accentPanel(theme.colorScheme);
    final action = context.cozyColors.recording.controlColor(
      theme.colorScheme.primary,
      fill,
      theme.colorScheme.onSurface,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Your next little reset',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: t.small),
        for (final suggestion in _expanded ? rows : rows.take(1)) ...[
          AppPressable(
            key: ValueKey('home-suggestion-${suggestion.id}'),
            label: [
              suggestion.title,
              suggestion.reason,
              suggestion.isBreathing ? 'Try breathing' : 'Write about this',
            ].join('. '),
            onPressed: () => _openSuggestion(suggestion),
            child: HomeDesignCard(
              color: fill,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    personalised
                        ? 'BASED ON YOUR PREFERENCES'
                        : 'A MOMENT FOR YOU',
                    style: theme.textTheme.labelMedium,
                  ),
                  SizedBox(height: t.small),
                  Text(
                    suggestion.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: t.tight),
                  Text(suggestion.reason),
                  SizedBox(height: t.contentGap),
                  Text(
                    suggestion.isBreathing
                        ? 'Try breathing →'
                        : 'Write about this →',
                    style: TextStyle(
                      color: action,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) SizedBox(height: t.small),
        ],
        if (rows.length > 1)
          AppPressable(
            label: _expanded ? 'Fewer suggestions' : 'More suggestions',
            expanded: _expanded,
            onPressed: () => setState(() => _expanded = !_expanded),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _expanded ? 'Fewer suggestions' : 'More suggestions',
                style: TextStyle(
                  color: context.cozyColors.recording.controlColor(
                    theme.colorScheme.primary,
                    t.canvas(
                      theme.brightness,
                      MediaQuery.highContrastOf(context),
                    ),
                    theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
