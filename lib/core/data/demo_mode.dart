import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/app_notification.dart';
import '../models/journal_entry.dart';
import '../models/mood_entry.dart';
import '../models/saved_article.dart';
import 'placeholder_data.dart';

/// Opt in with --dart-define=COZY_DEMO=true. Real builds keep account data.
/// All review edits stay in memory and are never sent to the API or sync queue.
class DemoMode extends ChangeNotifier {
  DemoMode({bool enabled = false}) : _enabled = enabled;
  static final instance = DemoMode(
    enabled: const bool.fromEnvironment('COZY_DEMO'),
  );
  bool _enabled;
  bool get enabled => _enabled;
  set enabled(bool value) {
    if (_enabled == value) return;
    _enabled = value;
    notifyListeners();
  }

  final List<MoodEntry> moods = PlaceholderData.moods();
  final List<JournalEntry> journals = PlaceholderData.journals();
  final List<AppNotification> notifications = PlaceholderData.notifications();
  final List<Map<String, dynamic>> posts = PlaceholderData.posts();
  final List<SavedArticle> savedArticles = [];

  void changed() => notifyListeners();

  Stream<List<T>> selectStream<T>({
    required bool Function() useDemo,
    required Stream<List<T>> Function() real,
    required List<T> Function() demo,
  }) {
    late StreamController<List<T>> controller;
    StreamSubscription<List<T>>? subscription;
    List<T>? lastReal;
    void refresh() {
      if (useDemo()) {
        controller.add(List<T>.of(demo()));
      } else {
        if (lastReal != null) controller.add(lastReal!);
        subscription ??= real().listen(
          (rows) {
            lastReal = rows;
            if (!useDemo()) controller.add(rows);
          },
          onError: (Object error, StackTrace stack) {
            if (!useDemo()) controller.addError(error, stack);
          },
        );
      }
    }

    controller = StreamController<List<T>>(
      onListen: () {
        addListener(refresh);
        refresh();
      },
      onCancel: () async {
        removeListener(refresh);
        await subscription?.cancel();
      },
    );
    return controller.stream;
  }

  Stream<List<T>> watch<T>(List<T> Function() read) {
    late StreamController<List<T>> controller;
    void emit() => controller.add(List<T>.of(read()));
    controller = StreamController<List<T>>(
      onListen: () {
        addListener(emit);
        emit();
      },
      onCancel: () => removeListener(emit),
    );
    return controller.stream;
  }

  void upsertMood(MoodEntry entry) {
    moods.removeWhere((row) => row.id == entry.id);
    moods.insert(0, entry);
    changed();
  }

  void upsertJournal(JournalEntry entry) {
    journals.removeWhere((row) => row.id == entry.id);
    journals.insert(0, entry);
    changed();
  }
}
