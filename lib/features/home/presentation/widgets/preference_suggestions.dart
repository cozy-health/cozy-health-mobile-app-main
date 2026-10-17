import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/models/user_preferences.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/services/home_suggestions.dart';
import '../../../../core/services/local_db_service.dart';
import '../../../journal/presentation/screens/journal_screen.dart';

class PreferenceSuggestions extends StatefulWidget {
  const PreferenceSuggestions({super.key});

  @override
  State<PreferenceSuggestions> createState() => _PreferenceSuggestionsState();
}

class _PreferenceSuggestionsState extends State<PreferenceSuggestions> {
  late final _box = LocalDbService().preferencesBox();

  @override
  Widget build(BuildContext context) => FutureBuilder<Box<UserPreferences>>(
    future: _box,
    builder: (context, snapshot) {
      final box = snapshot.data;
      if (box == null || !box.isOpen) return const SizedBox.shrink();
      return ValueListenableBuilder<Box<UserPreferences>>(
        valueListenable: box.listenable(keys: const ['current']),
        builder: (context, box, _) {
          final suggestions = homeSuggestions(box.get('current'));
          if (suggestions.isEmpty) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'A starting point for you',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                for (final suggestion in suggestions)
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            suggestion.title,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(suggestion.reason),
                          if (suggestion.prompt case final prompt?) ...[
                            const SizedBox(height: 12),
                            Text(prompt),
                          ],
                          TextButton(
                            onPressed: () {
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
                            },
                            child: Text(
                              suggestion.isBreathing
                                  ? 'Try breathing'
                                  : 'Write about this',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      );
    },
  );
}
